# POC Plugin Setup Guide

## Prerequisites

- Care running locally via Docker Compose (`make up`)
- Python 3.10+

---

## 1. Clone the plugin inside care at the same level as `manage.py`

```bash
git clone git@github.com:8sami/im_wrapper_poc.git
cd im_wrapper_poc
```

## 2. Connect the Plugin to Care (Docker Setup)

### Step 1. Create `plug_config.py` in your Care repo

In the root of the `care` repository, create a file called `plug_config.py`:

```python
from plugs.manager import PlugManager
from plugs.plug import Plug
import os

IM_WRAPPER_CONFIG = {
    # WhatsApp Business API
    "WHATSAPP_API_URL": 'https://graph.facebook.com/v18.0',
    "WHATSAPP_PHONE_NUMBER_ID": 'insert_whatsapp_phone_number_id_here',
    "WHATSAPP_ACCESS_TOKEN": 'insert_whatsapp_temporary_or_system_access_token_here',

    # Cache
    "IM_WRAPPER_CACHE_REDIS_URL": 'redis://redis:6379/1',
    "IM_WRAPPER_BASE_URL": 'http://backend:9000',

    # Security
    "IM_WRAPPER_ENABLE_PII_SANITIZATION": True,
    "IM_WRAPPER_ENABLE_AUDIT_LOGGING": True,

    # Rate Limiting
    "IM_WRAPPER_RATE_LIMIT_PER_PHONE": 20,
    "IM_WRAPPER_RATE_LIMIT_PER_IP": 100,
    "IM_WRAPPER_MAX_AUTH_ATTEMPTS": 3,
    "IM_WRAPPER_AUTH_LOCKOUT_DURATION": 15,

    # Service Account: Generate via admin and set via environment variable
    # Required permissions: can_list_patients, can_view_clinical_data, can_read_encounter, can_list_encounter

    # or let the setup script set these up for you automatically
    "IM_WRAPPER_SERVICE_ACCOUNT_TOKEN": 'insert_service_account_token_here',
    "IM_WRAPPER_SERVICE_ACCOUNT_USERNAME": 'insert_service_account_username_here',

    # Cache TTLs (seconds)
    "IM_WRAPPER_TTL_RECORDS": 600,
    "IM_WRAPPER_TTL_MEDICATIONS": 300,
    "IM_WRAPPER_TTL_PROCEDURES": 600,

    # Development
    "IM_WRAPPER_TEST_MODE": False,
    "IM_WRAPPER_DEBUG": False,
}

im_wrapper_poc = Plug(
    name="im_wrapper_poc",
    package_name="./im_wrapper_poc", # assuming that you have cloned this repo inside care at root level
    version="",  # Empty for local development
    configs=IM_WRAPPER_CONFIG,
)

plugs = [im_wrapper_poc]
manager = PlugManager(plugs)
```

Tweak the code in `plugs/manager.py` to update the pip install command with the `-e` flag for editable installation

```python
subprocess.check_call(
    [sys.executable, "-m", "pip", "install", "-e", *packages] # add -e flag to install in editable mode
)
```

### Step 2. Rebuild Care

```bash
make re-build up
```

Care will install the plugin during image build. Your plugin's URLs will be available at `/api/im_wrapper_poc/`.

Making a GET request to `/api/im_wrapper_poc/hello` should return:

```json
{
    "message": "Hello from im_wrapper_poc"
}
```