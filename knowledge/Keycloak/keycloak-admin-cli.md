---
title: Keycloak Admin CLI (kcadm)
type: reference
domain: Keycloak
tags:
  - keycloak
  - kcadm
  - cli
  - administration
  - automation
  - scripting
  - devops
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Admin CLI (kcadm)

## Overview

`kcadm.sh` (or `kcadm.bat` on Windows) is the Keycloak Admin CLI tool for administrative operations via the REST API. It enables automation, scripting, and batch operations without using the Admin Console. <https://www.keycloak.org/docs/latest/server_admin/#admin-cli>

## Installation and Access

### Location

**After installation:**
```bash
/opt/keycloak/bin/kcadm.sh      # Linux/mac
bin\kcadm.bat                    # Windows
```

### Authentication

**Before using kcadm, authenticate:**
```bash
kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin
```

**Prompts for password interactively**

**Or specify password (less secure):**
```bash
kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin \
  --password 'admin-password'
```

**Service account authentication:**
```bash
kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --client admin-cli
```

**Check current configuration:**
```bash
kcadm.sh config credentials
```

**Output:**
```
server: http://localhost:8080
realm: master
user: admin
```

## Basic Command Structure

### Command Format

```bash
kcadm.sh [global-options] command [command-options]
```

**Global options:**
```bash
--server <url>          # Keycloak server URL
--realm <realm>         # Target realm
--user <username>       # Username (for auth)
--password <password>   # Password (not recommended)
--client <client-id>    # Client ID (for service account)
--config <file>         # Config file
--token <token>         # Direct bearer token
--no-config             # Don't use config file
--debug                # Enable debug output
--quiet                # Suppress output
```

## Common Operations

### Realm Operations

**List realms:**
```bash
kcadm.sh get realms
```

**Get realm info:**
```bash
kcadm.sh get realms/myrealm
```

**Create realm:**
```bash
kcadm.sh create realms \
  -s realm=myrealm \
  -s enabled=true
```

**Update realm:**
```bash
kcadm.sh update realms/myrealm \
  -s displayName="My Realm" \
  -s registrationAllowed=true
```

**Delete realm:**
```bash
kcadm.sh delete realms/myrealm
```

### User Operations

**List users:**
```bash
# All users
kcadm.sh get users

# Filter by username
kcadm.sh get users -q username=admin

# Filter by email
kcadm.sh get users -q email=*@example.com

# Limit results
kcadm.sh get users --max 10
```

**Get user details:**
```bash
# By ID
kcadm.sh get users/<id>

# By username (more common)
USER_ID=$(kcadm.sh get users -q username=john.doe --id)
kcadm.sh get users/$USER_ID
```

**Create user:**
```bash
kcadm.sh create users \
  -r myrealm \
  -s username=john.doe \
  -s enabled=true \
  -s email=john.doe@example.com \
  -s firstName=John \
  -s lastName=Doe \
  -s emailVerified=true \
  -s 'attributes=["department=Engineering","location=SF"]'
```

**Update user:**
```bash
kcadm.sh update users/$USER_ID \
  -r myrealm \
  -s enabled=false
```

**Delete user:**
```bash
kcadm.sh delete users/$USER_ID -r myrealm
```

**Set password:**
```bash
kcadm.sh set-password \
  -r myrealm \
  --username john.doe \
  --new-password 'new-password' \
  --temporary false
```

**Add user to group:**
```bash
kcadm.sh update users/$USER_ID/groups/$GROUP_ID \
  -r myrealm
```

**Remove user from group:**
```bash
kcadm.sh delete users/$USER_ID/groups/$GROUP_ID \
  -r myrealm
```

**List user's groups:**
```bash
kcadm.sh get users/$USER_ID/groups -r myrealm
```

### Role Operations

**List realm roles:**
```bash
kcadm.sh get roles -r myrealm
```

**List client roles:**
```bash
kcadm.sh get roles -r myrealm --c client-id
```

**Get role details:**
```bash
# Realm role
kcadm.sh get roles/admin -r myrealm

# Client role
kcadm.sh get roles/client-id/admin -r myrealm
```

**Create role:**
```bash
# Realm role
kcadm.sh create roles \
  -r myrealm \
  -s name=developer \
  -s description="Application developer"
```

**Delete role:**
```bash
kcadm.sh delete roles/developer -r myrealm
```

**Assign role to user:**
```bash
# Realm role
kcadm.sh add-roles \
  -r myrealm \
  --uusername john.doe \
  --rolename admin

# Client role
kcadm.sh add-roles \
  -r myrealm \
  --uusername john.doe \
  --cclient-id myapp \
  --rolename editor

# By user ID
kcadm.sh add-roles \
  -r myrealm \
  --uid $USER_ID \
  --rolename admin
```

**Remove role from user:**
```bash
kcadm.sh delete-roles \
  -r myrealm \
  --uusername john.doe \
  --rolename admin
```

**List user's roles:**
```bash
USER_ID=$(kcadm.sh get users -q username=john.doe --id)
kcadm.sh get users/$USER_ID/role-mappings -r myrealm
```

### Group Operations

**List groups:**
```bash
kcadm.sh get groups -r myrealm
```

**Get group details:**
```bash
# By ID
GROUP_ID=$(kcadm.sh get groups -q name==Developers --id)
kcadm.sh get groups/$GROUP_ID -r myrealm
```

**Create group:**
```bash
kcadm.sh create groups \
  -r myrealm \
  -s name=Developers \
  -s 'attributes=["department=Engineering","location=SF"]'
```

**Create nested group:**
```bash
PARENT_ID=$(kcadm.sh get groups -q name==Engineering --id)
kcadm.sh create groups/$PARENT_ID/children \
  -r myrealm \
  -s name=Frontend
```

**Update group:**
```bash
kcadm.sh update groups/$GROUP_ID \
  -r myrealm \
  -s 'attributes=["team=Backend","location=Building1"]'
```

**Delete group:**
```bash
kcadm.sh delete groups/$GROUP_ID -r myrealm
```

**Assign role to group:**
```bash
# Realm role
kcadm.sh create groups/$GROUP_ID/role-mappings/realm \
  -r myrealm \
  -s roleId=$(kcadm.sh get roles/developer -r myrealm --id) \
  -s scope=false

# Client role
ROLE_ID=$(kcadm.sh get roles/client-id/editor -r myrealm --id)
kcadm.sh create groups/$GROUP_ID/role-mappings/clients/client-id \
  -r myrealm \
  -s roleId=$ROLE_ID \
  -s scope=false
```

**List group members:**
```bash
kcadm.sh get groups/$GROUP_ID/members -r myrealm
```

**Get group's roles:**
```bash
kcadm.sh get groups/$GROUP_ID/role-mappings -r myrealm
```

### Client Operations

**List clients:**
```bash
kcadm.sh get clients -r myrealm
```

**Get client details:**
```bash
# By client ID
kcadm.sh get clients/myapp -r myrealm
```

**Get client by ID:**
```bash
CLIENT_ID=$(kcadm.sh get clients -r myrealm -q clientId==myapp --id)
kcadm.sh get clients/$CLIENT_ID -r myrealm
```

**Create OIDC client:**
```bash
kcadm.sh create clients \
  -r myrealm \
  -s clientId=myapp \
  -s enabled=true \
  -s clientAuthenticatorType=client-secret \
  -s secret=my-secret \
  -s publicClient=false \
  -s redirectUris=["http://localhost:3000/*"] \
  -s webOrigins=["http://localhost:3000"] \
  -s 'protocol=openid-connect' \
  -s 'attributes=["access.token.lifespan=300"]'
```

**Create SAML client:**
```bash
kcadm.sh create clients \
  -r myrealm \
  -s clientId=mysamlapp \
  -s enabled=true \
  -s 'protocol=saml' \
  -s 'redirectUris=["http://localhost:3000/saml"]' \
  -s rootUrl=http://localhost:3000 \
  -s 'attributes=["saml.assertion.signature=RS256"]'
```

**Update client:**
```bash
kcadm.sh update clients/myapp -r myrealm \
  -s enabled=false
```

**Delete client:**
```bash
kcadm.sh delete clients/myapp -r myrealm
```

**Get client secret:**
```bash
kcadm.sh get clients/myapp/client-secret -r myrealm
```

**Regenerate client secret:**
```bash
kcadm.sh update clients/myapp/client-secret -r myrealm
```

**Get client scopes:**
```bash
kcadm.sh get clients/myapp/client-scopes -r myrealm
```

**Add client scope:**
```bash
# Optional scope
kcadm.sh create clients/myapp/client-scopes/my-scope \
  -r myrealm \
  -s content=client \
  -s name=my-scope

# Default scope
kcadm.sh update clients/myapp/optional-client-scopes \
  -r myrealm \
  -n '["my-scope"]'
```

## Advanced Operations

### Export/Import

**Export realm:**
```bash
# Export to directory
kcadm.sh export myrealm --dir ./backup

# Export with users
kcadm.sh export myrealm --users --dir ./backup

# Export to file
kcadm.sh export myrealm > backup/myrealm.json
```

**Import realm:**
```bash
# From file
kcadm.sh create realms -s realm=imported-realm -f backup/myrealm.json

# Update existing realm
kcadm.sh update realms/myrealm -f backup/myrealm.json

# Partial import
kcadm.sh partial-import realms/myrealm -f backup/partial.json
```

### Events

**List admin events:**
```bash
# All events
kcadm.sh get events/admin

# Filter by date
kcadm.sh get events/admin \
  --from 2025-01-01 \
  --to 2025-01-29

# Filter by operation
kcadm.sh get events/admin \
  --operation CREATE \
  --operation UPDATE

# Filter by resource type
kcadm.sh get events/admin \
  --resource-type USER

# Filter by auth type
kcadm.sh get events/admin \
  --auth-type CLIENT
```

**List user events:**
```bash
# All events
kcadm.sh get events

# Filter by type
kcadm.sh get events --type LOGIN
kcadm.sh get events --type LOGIN_ERROR
kcadm.sh get events --type REGISTER
kcadm.sh get events --type UPDATE_PASSWORD
```

### Sessions

**Get user sessions:**
```bash
USER_ID=$(kcadm.sh get users -q username=john.doe --id)
kcadm.sh get users/$USER_ID/sessions -r myrealm
```

**Logout user:**
```bash
# All sessions
kcadm.sh delete users/$USER_ID/sessions -r myrealm

# Specific session
kcadm.sh delete users/$USER_ID/sessions/<session-id> -r myrealm
```

**Logout all users:**
```bash
# Not directly supported via kcadm
# Use Admin REST API directly or script it
```

### Identity Providers

**List identity providers:**
```bash
kcadm.sh get identity-provider/instances -r myrealm
```

**Get identity provider:**
```bash
kcadm.sh get identity-provider/instances/google -r myrealm
```

**Create identity provider:**
```bash
kcadm.sh create identity-provider/instances/google \
  -r myrealm \
  -s alias=google \
  -s displayName="Google Sign-In" \
  -s providerId=google \
  -s 'config={"clientId":"your-client-id","clientSecret":"your-secret","hostedDomain":"example.com"}'
```

**Delete identity provider:**
```bash
kcadm.sh delete identity-provider/instances/google -r myrealm
```

### Components (SPI Providers)

**List components:**
```bash
kcadm.sh get components -r myrealm
```

**Get component:**
```bash
kcadm.sh get components/<id> -r myrealm
```

**Create component:**
```bash
kcadm.sh create components \
  -r myrealm \
  -s name=my-event-listener \
  -s provider=events-listener \
  -s 'config={"enabled":"true","excludeEvents":["LOGIN_ERROR"]}'
```

## Scripting with kcadm

### Bash Script Example

**Automated user creation:**
```bash
#!/bin/bash

# Authenticate
kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin

# Create realm
kcadm.sh create realms \
  -s realm=myapp \
  -s enabled=true

# Create roles
kcadm.sh create roles -r myapp \
  -s name=ADMIN \
  -s description="Administrator"

kcadm.sh create roles -r myapp \
  -s name=USER \
  -s description="Standard user"

# Create groups
GROUPS=("Engineering" "Sales" "Operations")

for group in "${GROUPS[@]}"; do
  kcadm.sh create groups \
    -r myapp \
    -s name="$group"
done

# Create users from CSV
while IFS=, read -r username email firstname lastname; do
  kcadm.sh create users \
    -r myapp \
    -s username="$username" \
    -s email="$email" \
    -s firstName="$firstname" \
    -s lastName="$lastname" \
    -s enabled=true \
    -s emailVerified=true

  # Add to Users group
  USER_ID=$(kcadm.sh get users -q username="$username" --id)
  GROUP_ID=$(kcadm.sh get groups -q name==Users --id)

  kcadm.sh update users/$USER_ID/groups/$GROUP_ID -r myapp
done < users.csv

echo "Setup complete!"
```

### JSON Processing with jq

**Query and process JSON:**
```bash
# Get all users as JSON
kcadm.sh get users -r myrealm -q | jq .

# Get specific fields
kcadm.sh get users -r myrealm -q | jq '.[] | {username, email}'

# Filter users
kcadm.sh get users -r myrealm -q | jq '.[] | select(.enabled == true)'

# Get user count
kcadm.sh get users -r myrealm -q | jq 'length'

# Extract usernames
kcadm.sh get users -r myrealm -q | jq -r '.[].username'

# Get specific user
kcadm.sh get users -r myrealm -q | jq '.[] | select(.username == "admin")'

# Get user's roles
USER_ID=$(kcadm.sh get users -q username=admin --id)
kcadm.sh get users/$USER_ID/role-mappings -r myrealm | jq '.realmMappings[].name'
```

### Batch Operations

**Batch role assignment:**
```bash
# Assign role to multiple users
ROLE="developer"

for user in $(cat users.txt); do
  kcadm.sh add-roles \
    -r myrealm \
    --uusername "$user" \
    --rolename "$ROLE"

  echo "Added $ROLE to $user"
done
```

**Batch group membership:**
```bash
# Add users to group
GROUP_ID=$(kcadm.sh get groups -q name==Developers --id)

for user in $(cat developers.txt); do
  USER_ID=$(kcadm.sh get users -q username="$user" --id)

  kcadm.sh update users/$USER_ID/groups/$GROUP_ID -r myrealm

  echo "Added $user to Developers group"
done
```

## Configuration Files

### Config File

**Create config file:**
```bash
# ~/.keycloak/kcadm.config
server=http://localhost:8080
realm=master
user=admin
# password=secret (not recommended)
client=admin-cli
```

**Use config file:**
```bash
kcadm.sh --config ~/.keycloak/kcadm.config get users
```

### Environment Variables

**Set environment variables:**
```bash
export KEYCLOAK_SERVER=http://localhost:8080
export KEYCLOAK_REALM=master
export KEYCLOAK_USER=admin
# export KEYCLOAK_PASSWORD=secret
```

**Use in commands:**
```bash
kcadm.sh get users
```

## Tips and Tricks

### Tab Completion

**Enable tab completion:**
```bash
# Add to .bashrc or .zshrc
source <(kcadm.sh completion bash)
```

### Debugging

**Enable debug output:**
```bash
kcadm.sh --debug get users
```

### Pretty Print JSON

**Use jq with kcadm:**
```bash
kcadm.sh get users -r myrealm -q | jq '.'
```

### Count Resources

**Count users:**
```bash
kcadm.sh get users -r myrealm -q | jq '. | length'
```

### Check Authentication

**Test authentication:**
```bash
kcadm.sh get realms
```

**Re-authenticate if needed:**
```bash
kcadm.sh config credentials --server http://localhost:8080 --realm master
```

### Using Wildcards

**Search with wildcards:**
```bash
# Get all realms starting with 'test'
kcadm.sh get realms -q realm^test

# Get all emails containing @example.com
kcadm.sh get users -q email=*@example.com
```

## Error Handling

### Common Errors

**"Unknown error: Failed to connect to server"**
- Check server URL
- Verify server is running
- Check network connectivity

**"401 Unauthorized"**
- Re-authenticate
- Check credentials
- Verify user has admin role

**"403 Forbidden"**
- Check permissions
- Verify user has required roles
- Check fine-grained permissions

**"404 Not Found"**
- Verify resource exists
- Check realm name
- Check resource ID

### Error Handling in Scripts

```bash
#!/bin/bash
set -e  # Exit on error

# Create realm
if kcadm.sh create realms -s realm=testrealm 2>/dev/null; then
  echo "Realm created successfully"
else
  echo "Realm already exists or creation failed"
fi

# Create user
if kcadm.sh create users -r testrealm -s username=testuser; then
  echo "User created successfully"
else
  echo "Failed to create user"
  exit 1
fi
```

## Performance Tips

### Batch Operations

**Use transactions for bulk operations:**
```bash
# Not directly supported, but use scripts
for item in $(cat items.txt); do
  kcadm.sh create ... "$item"
done
```

### Reduce Output

**Quiet mode:**
```bash
kcadm.sh --quiet get users
```

**Get specific fields only:**
```bash
kcadm.sh get users -r myrealm -q username --id
```

## Security Considerations

### Protect Credentials

**✅ DO:**
- Use config files with proper permissions (600)
- Use service accounts when possible
- Avoid passwords in scripts
- Use environment variables
- Enable SSL/TLS
- Limit token lifetime
- Rotate credentials regularly

**❌ DON'T:**
- Hardcode passwords in scripts
- Commit credentials to version control
- Share config files with secrets
- Use HTTP in production
- Skip authentication
- Reuse tokens indefinitely

### Store Password Securely

**Using pass (macOS/Linux):**
```bash
# Store password
pass | insert mypassword

# Use in script
PASSWORD=$(pass show mypassword)
kcadm.sh config credentials \
  --server http://localhost:8080 \
  --user admin \
  --password "$PASSWORD"
unset PASSWORD
```

**Using environment variables:**
```bash
# Set in .env file
KEYCLOAK_PASSWORD=mypassword

# Load in script
source .env
kcadm.sh config credentials \
  --server http://localhost:8080 \
  --user admin \
  --password "$KEYCLOAK_PASSWORD"
```

## Best Practices

### Script Organization

**Structure:**
```
scripts/
├── lib/
│   ├── auth.sh        # Authentication functions
│   ├── users.sh       # User operations
│   └── roles.sh       # Role operations
├── setup/
│   ├── realm.sh       # Realm setup
│   ├── clients.sh     # Client setup
│   └── users.sh       # Initial users
└── maintenance/
    ├── backup.sh      # Backup scripts
    └── cleanup.sh     # Cleanup scripts
```

### Idempotency

**Make scripts idempotent:**
```bash
# Check before creating
if ! kcadm.sh get realms/myapp > /dev/null 2>&1; then
  kcadm.sh create realms -s realm=myapp
fi
```

### Error Handling

**Robust error handling:**
```bash
#!/bin/bash
set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

# Trap errors
trap 'echo "Error on line $LINENO"; exit 1' ERR

# Your script here
```

## References

- <https://www.keycloak.org/docs/latest/server_admin/#admin-cli>
- Admin REST API documentation
- kcadm.sh --help

## Related

- [[keycloak-server-administration]]
- [[keycloak-rest-api]]
