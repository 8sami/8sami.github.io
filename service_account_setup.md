# Service Account Setup Guide

Service accounts in Care use static authentication tokens instead of session-based logins.


### Step 1: Create the User Account
To create a service account, send a `POST` request to the user endpoint.

- **URL**: `{{base_url}}/api/v1/users/`
- **Method**: `POST`
- **Headers**:
    - `Content-Type: application/json`
    - `Authorization: Bearer <Your_Admin_JWT_Token>`
- **Body (Raw JSON)**:
```json
{
  "username": "external_service_svc",
  "email": "service@example.com",
  "first_name": "External",
  "last_name": "Service",
  "phone_number": "+918888888888",
  "user_type": "staff",
  "gender": "non_binary",
  "is_service_account": true
}
```

### Step 2: Generate an Authentication Token
Once the account exists, generate a static token.

- **URL**: `{{base_url}}/api/v1/users/external_service_svc/generate_service_account_token/`
- **Method**: `POST`
- **Headers**:
    - `Authorization: Bearer <Your_Admin_JWT_Token>`
- **Response Example**:
```json
{
    "token": "9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b",
    "user": "external_service_svc",
    "created": "2026-03-10T10:00:00Z"
}
```

### Step 3: Use the Token in Requests
Include the token in the Authorization header of all subsequent API calls.

- **Format**: `Authorization: Token 9944b09199c62bcf9418ad846dd0e4bbdfc6ee4b`
- **Note**: Ensure you use the prefix **Token**, not **Bearer**, for these static tokens.

---

## Creating a "Read Only" Service Account

To restrict a service account to read-only access, follow these steps:

### A. Create a Custom Read-Only Role
Define a new role that only includes "view" and "list" permissions.

- **URL**: `{{base_url}}/api/v1/role/`
- **Method**: `POST`
- **Headers**: `Authorization: Bearer <Admin_JWT>`
- **Body (Raw JSON)**:
```json
{
  "name": "Service Account Read Only",
  "description": "Role with restricted list and view permissions for IM wrapper use",
  "permissions": [
    "can_view_organization",
    "can_list_patients",
    "can_view_clinical_data",
    "can_read_facility",
    "can_list_user",
    "can_read_encounter",
    "can_list_encounter",
    "can_view_facility_organization",
    "can_list_devices"
  ]
}
```

### B. Link the Role to the Service Account
Link the service account to the relevant Organization or Facility using this new role.

- **URL**: `POST {{base_url}}/api/v1/organization/{org_id}/users/`
- **Body**:
```json
{
  "user": "{service_account_external_id}",
  "role": "{new_role_external_id}"
}
```
*Tip: You can find the external ID of your service account and the new role by listing users and roles.*

---

## Lifecycle & Management Endpoints

### List Active Service Accounts
Filter the user list for service accounts.
- **URL**: `GET {{base_url}}/api/v1/users/?is_service_account=true`

### Revoke Token
Immediately invalidate a compromised or unused token.
- **URL**: `DELETE {{base_url}}/api/v1/users/{username}/revoke_service_account_token/`

### List Available Permissions
Get a full list of all permission slugs to customize your roles.
- **URL**: `GET {{base_url}}/api/v1/permission/`