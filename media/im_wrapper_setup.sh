#!/bin/bash
# =============================================================================
# IM Wrapper Setup Script
# Automates: Docker startup, git pull, service account creation, role creation,
# and assignment of the read-only role to all organizations.
# =============================================================================

set -e  # Exit immediately on any error

# --- Config ---
BASE_URL="http://localhost:9000"
ADMIN_USER="admin"
ADMIN_PASS="admin"
SVC_USERNAME="im_wrapper_service"
SVC_EMAIL="im_wrapper@care.local"
SVC_PHONE="+919999999999"
ROLE_NAME="IM Wrapper Read Only"
ROLE_DESCRIPTION="Read-only role for the IM Wrapper service account. Used for patient and encounter lookups."
CARE_DIR="$HOME/gsoc/care" # change this according to your care path

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $1"; }
info() { echo -e "${YELLOW}[→]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1"; exit 1; }

# =============================================================================
# STEP 0: Ensure Docker is running
# =============================================================================
info "Checking Docker..."
if ! docker info > /dev/null 2>&1; then
    fail "Docker is not running. Please start Docker and try again."
fi
log "Docker is running."

# =============================================================================
# STEP 1: Git pull + rebuild
# =============================================================================
info "Pulling latest code..."
cd "$CARE_DIR" || fail "Could not find $CARE_DIR"
git pull

info "Rebuilding containers..."
make re-build up

info "Waiting for server to be ready..."
for i in $(seq 1 30); do
    if curl -s "$BASE_URL/api/v1/auth/login/" > /dev/null 2>&1; then
        log "Server is up."
        break
    fi
    if [ "$i" -eq 30 ]; then
        fail "Server did not start in time."
    fi
    echo "  Waiting... ($i/30)"
    sleep 5
done

info "Loading fixtures..."
if make load-fixtures; then
    log "Fixtures loaded."
else
    echo -e "${YELLOW}[!]${NC} load-fixtures failed (likely a known pydantic 'role_orgs' bug in Care fixtures)."
    echo -e "${YELLOW}[!]${NC} Continuing with setup — fixtures may be partially loaded."
fi


# =============================================================================
# STEP 2: Authenticate as admin, get JWT
# =============================================================================
info "Authenticating as admin..."
LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/auth/login/" \
    -H "Content-Type: application/json" \
    -d "{\"username\": \"$ADMIN_USER\", \"password\": \"$ADMIN_PASS\"}")

ACCESS_TOKEN=$(echo "$LOGIN_RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['access'])" 2>/dev/null)

if [ -z "$ACCESS_TOKEN" ]; then
    echo "Login response: $LOGIN_RESPONSE"
    fail "Failed to get access token. Check admin credentials."
fi
log "Got JWT access token."
AUTH_HEADER="Authorization: Bearer $ACCESS_TOKEN"

# =============================================================================
# STEP 3: Create service account user
# =============================================================================
info "Creating service account '$SVC_USERNAME'..."
CREATE_USER_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/users/" \
    -H "Content-Type: application/json" \
    -H "$AUTH_HEADER" \
    -d "{
        \"username\": \"$SVC_USERNAME\",
        \"email\": \"$SVC_EMAIL\",
        \"first_name\": \"IM\",
        \"last_name\": \"Wrapper\",
        \"phone_number\": \"$SVC_PHONE\",
        \"user_type\": \"staff\",
        \"gender\": \"non_binary\",
        \"is_service_account\": true,
        \"role_orgs\": []
    }")

SVC_USER_ID=$(echo "$CREATE_USER_RESPONSE" | python3 -c "import sys, json;
try:
    print(json.load(sys.stdin).get('id', ''))
except Exception:
    print('')
" 2>/dev/null)

if [ -z "$SVC_USER_ID" ]; then
    # Check if account already exists
    EXISTING=$(curl -s -G "$BASE_URL/api/v1/users/" \
        --data-urlencode "username=$SVC_USERNAME" \
        --data-urlencode "is_service_account=true" \
        -H "$AUTH_HEADER")
    SVC_USER_ID=$(echo "$EXISTING" | python3 -c "import sys, json;
try:
    d = json.load(sys.stdin)
    print(d['results'][0]['id'] if d.get('results') else '')
except Exception:
    print('')
" 2>/dev/null)
    if [ -z "$SVC_USER_ID" ]; then
        echo "Create user response: $CREATE_USER_RESPONSE"
        fail "Failed to create or find service account."
    fi
    log "Service account already exists. Using existing: $SVC_USER_ID"
else
    log "Service account created: $SVC_USER_ID"
fi

# =============================================================================
# STEP 4: Generate service account token
# =============================================================================
info "Generating service account token..."
TOKEN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/users/$SVC_USERNAME/generate_service_account_token/" \
    -H "$AUTH_HEADER")

SVC_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import sys, json;
try:
    print(json.load(sys.stdin).get('token', ''))
except Exception:
    print('')
" 2>/dev/null)

if [ -z "$SVC_TOKEN" ]; then
    echo "Token response: $TOKEN_RESPONSE"
    fail "Failed to generate service account token."
fi
log "Service account token: $SVC_TOKEN"

# =============================================================================
# STEP 5: List available permissions (read-only ones)
# =============================================================================
info "Fetching available permissions..."
ALL_PERMS=$(curl -s "$BASE_URL/api/v1/permission/?limit=1000" -H "$AUTH_HEADER")

# Extract the slugs we need
READ_ONLY_PERMS=$(echo "$ALL_PERMS" | python3 -c "
import sys, json
perms = json.load(sys.stdin).get('results', [])
readonly_slugs = [
    'can_view_organization',
    'can_list_organization_users',
    'can_list_patients',
    'can_view_clinical_data',
    'can_view_questionnaire_responses',
    'can_read_facility',
    'can_list_user',
    'can_read_encounter',
    'can_list_encounter',
    'can_view_facility_organization',
    'can_list_facility_organization_users',
    'can_list_devices',
    'can_list_facility_locations',
]
available = [p['slug'] for p in perms if p['slug'] in readonly_slugs]
print(json.dumps(available))
" 2>/dev/null)

if [ -z "$READ_ONLY_PERMS" ] || [ "$READ_ONLY_PERMS" = "[]" ]; then
    fail "Could not fetch permissions from API. Is the server running and synced?"
fi
log "Found permissions: $READ_ONLY_PERMS"

# =============================================================================
# STEP 6: Create the Read-Only role
# =============================================================================
info "Creating role '$ROLE_NAME'..."
ROLE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/role/" \
    -H "Content-Type: application/json" \
    -H "$AUTH_HEADER" \
    -d "{
        \"name\": \"$ROLE_NAME\",
        \"description\": \"$ROLE_DESCRIPTION\",
        \"permissions\": $READ_ONLY_PERMS,
        \"contexts\": [\"FACILITY\", \"GOVT_ORG\", \"ROLE_ORG\"]
    }")

ROLE_ID=$(echo "$ROLE_RESPONSE" | python3 -c "import sys, json;
try:
    print(json.load(sys.stdin).get('id', ''))
except Exception:
    print('')
" 2>/dev/null)

if [ -z "$ROLE_ID" ]; then
    # Role might already exist — fetch it
    EXISTING_ROLE=$(curl -s -G "$BASE_URL/api/v1/role/" --data-urlencode "name=$ROLE_NAME" -H "$AUTH_HEADER")
    ROLE_ID=$(echo "$EXISTING_ROLE" | python3 -c "import sys, json;
try:
    d = json.load(sys.stdin)
    print(d['results'][0]['id'] if d.get('results') else '')
except Exception:
    print('')
" 2>/dev/null)
    if [ -z "$ROLE_ID" ]; then
        echo "Role creation response: $ROLE_RESPONSE"
        fail "Failed to create or find role."
    fi
    log "Role already exists. Using: $ROLE_ID"
else
    log "Role created: $ROLE_ID"
fi

# =============================================================================
# STEP 7: Get all organizations and assign the service account
# =============================================================================
info "Fetching all organizations..."
ORGS_RESPONSE=$(curl -s "$BASE_URL/api/v1/organization/?limit=100" -H "$AUTH_HEADER")

ORG_IDS=$(echo "$ORGS_RESPONSE" | python3 -c "
import sys, json
orgs = json.load(sys.stdin).get('results', [])
for org in orgs:
    print(org['id'])
" 2>/dev/null)

if [ -z "$ORG_IDS" ]; then
    fail "No organizations found. Did the fixtures load correctly?"
fi

log "Found organizations. Assigning service account to each..."
while IFS= read -r ORG_ID; do
    ASSIGN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/v1/organization/$ORG_ID/users/" \
        -H "Content-Type: application/json" \
        -H "$AUTH_HEADER" \
        -d "{
            \"user\": \"$SVC_USER_ID\",
            \"role\": \"$ROLE_ID\"
        }")

    STATUS=$(echo "$ASSIGN_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print('ok' if d.get('id') else d.get('detail','error'))" 2>/dev/null)
    echo "  Org $ORG_ID: $STATUS"
done <<< "$ORG_IDS"

# =============================================================================
# STEP 8: Auto-patch plug_config.py
# =============================================================================
PLUG_CONFIG="$CARE_DIR/plug_config.py"

if [ ! -f "$PLUG_CONFIG" ]; then
    fail "Could not find plug_config.py at $PLUG_CONFIG"
fi

info "Patching $PLUG_CONFIG with service account credentials..."

# Replace the token value (handles any existing value between the quotes)
sed -i "s|\"IM_WRAPPER_SERVICE_ACCOUNT_TOKEN\":.*|\"IM_WRAPPER_SERVICE_ACCOUNT_TOKEN\": '$SVC_TOKEN',|g" "$PLUG_CONFIG"

# Replace the username value
sed -i "s|\"IM_WRAPPER_SERVICE_ACCOUNT_USERNAME\":.*|\"IM_WRAPPER_SERVICE_ACCOUNT_USERNAME\": '$SVC_USERNAME',|g" "$PLUG_CONFIG"

log "plug_config.py updated."

# =============================================================================
# DONE — Print summary
# =============================================================================
echo ""
echo "============================================================"
echo "  IM Wrapper Setup Complete"
echo "============================================================"
echo "  Service Account : $SVC_USERNAME"
echo "  User ID         : $SVC_USER_ID"
echo "  Role            : $ROLE_NAME ($ROLE_ID)"
echo "  Token           : $SVC_TOKEN"
echo ""
echo "  plug_config.py has been updated automatically."
echo "============================================================"
echo ""

# =============================================================================
# STEP 9: Launch ngrok
# =============================================================================
if command -v ngrok &> /dev/null; then
    info "Launching ngrok on port 9000..."
    info "Copy the https URL from the ngrok interface and paste it into the Meta Developer Console."
    sleep 2
    ngrok http 9000
else
    echo -e "${YELLOW}[!]${NC} ngrok not found. Please install ngrok to expose your local server,"
    echo "    or run 'ngrok http 9000' manually if it's already installed."
fi