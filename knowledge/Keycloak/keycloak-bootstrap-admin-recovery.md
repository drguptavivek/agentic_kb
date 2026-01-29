---
title: Keycloak Bootstrap Admin Recovery
domain: Keycloak
type: howto
status: draft
tags: [keycloak, admin, recovery, bootstrap, account-creation]
created: 2026-01-29
related: [[keycloak-server-configuration-guide]], [[keycloak-security]], [[keycloak-admin-cli]]
---

# Keycloak Bootstrap Admin Recovery

## Overview

The `bootstrap-admin` command allows creating temporary admin access to Keycloak when:
- Initial admin user creation was skipped
- Admin credentials are lost
- Automated recovery is needed
- Service account access is required

**Important:** All Keycloak nodes must be stopped before running this command.

## Creating Temporary Admin User

### Interactive Mode

```bash
bin/kc.sh bootstrap-admin user
```

Prompts for:
- Username (default: `admin`)
- Password

### Command-Line Mode

```bash
bin/kc.sh bootstrap-admin user \
  --username tmpadmin \
  --password changeme
```

### Using Environment Variables

```bash
export PASSWORD=changeme
bin/kc.sh bootstrap-admin user \
  --username tmpadmin \
  --password:env PASSWORD
```

### What It Does

1. Creates initial master realm (if first-time)
2. Creates temporary admin user
3. Ignores startup options for bootstrap
4. User can be deleted after recovery

## Creating Temporary Service Account

### Interactive Mode

```bash
bin/kc.sh bootstrap-admin service
```

Prompts for:
- Client ID (default: `admin-cli`)
- Client secret

### Command-Line Mode

```bash
bin/kc.sh bootstrap-admin service \
  --client-id tmpclient \
  --client-secret changeme
```

### Using Environment Variables

```bash
export SECRET=changeme
bin/kc.sh bootstrap-admin service \
  --client-id tmpclient \
  --client-secret:env SECRET
```

### Use Cases for Service Accounts

- Automated recovery scripts
- CI/CD pipelines
- Admin API access without interactive login
- Multi-factor recovery scenarios

## Default Values

### Admin User Defaults

| Setting | Default Value |
|---------|---------------|
| Username | `admin` |
| Realm | `master` |
| Enabled | `true` |

### Service Account Defaults

| Setting | Default Value |
|---------|---------------|
| Client ID | `admin-cli` |
| Realm | `master` |
| Client Authenticator | `client-secret` |

## When to Use Bootstrap Admin

### Scenarios

| Scenario | Solution |
|----------|----------|
| Forgot admin password | Create temporary user, reset original |
| Initial setup skipped | Create initial admin |
| Automation needs | Create service account |
| Lockout prevention | Create backup access |

### Before Using

1. **Stop all Keycloak nodes**
2. **Verify database is accessible**
3. **Have database credentials ready**
4. **Plan for cleanup after recovery**

## Database Options

### Recommended: Include DB Options

```bash
bin/kc.sh bootstrap-admin user \
  --db=postgres \
  --db-url-host=localhost \
  --db-username=keycloak \
  --db-password=changeme \
  --username=tmpadmin \
  --password changeme
```

### Why Include DB Options

- Ensures connection to correct database
- Faster execution
- Avoids configuration issues
- Same options as server startup

## Optimized Builds

### With Optimized Build

```bash
bin/kc.sh bootstrap-admin user \
  --optimized \
  --username tmpadmin \
  --password changeme
```

Skips build check, faster startup.

### Without Optimized Build

```bash
bin/kc.sh bootstrap-admin user \
  --username tmpadmin \
  --password changeme
```

May update optimized build (affects next server start).

## Security Considerations

### Temporary Accounts

1. **Delete immediately after use**
2. **Use strong passwords**
3. **Log account creation**
4. **Monitor usage**
5. **Document recovery process**

### Cleanup After Recovery

```bash
# Delete temporary user
kcadm.sh delete users/<tmp-user-id> -r master

# Or via Admin UI
# Users → View all users → Select user → Delete
```

### Service Account Cleanup

```bash
# Delete temporary client
kcadm.sh delete clients/<tmp-client-id> -r master

# Or via Admin UI
# Clients → Select client → Delete
```

## Automated Recovery Example

### Script for Admin User Recovery

```bash
#!/bin/bash
# recover-admin.sh

set -e

KC_HOME=/opt/keycloak
TEMP_USER="recovery_$(date +%s)"
TEMP_PASSWORD=$(openssl rand -base64 16)

echo "Creating temporary admin user: $TEMP_USER"

$KC_HOME/bin/kc.sh bootstrap-admin user \
  --db=postgres \
  --db-url-host=$DB_HOST \
  --db-username=$DB_USER \
  --db-password=$DB_PASSWORD \
  --username $TEMP_USER \
  --password $TEMP_PASSWORD

echo "Temporary user created. Credentials:"
echo "  Username: $TEMP_USER"
echo "  Password: $TEMP_PASSWORD"
echo ""
echo "IMPORTANT: Delete this user after recovery!"
```

### Script for Service Account Recovery

```bash
#!/bin/bash
# recover-service.sh

set -e

KC_HOME=/opt/keycloak
TEMP_CLIENT="recovery_$(date +%s)"
TEMP_SECRET=$(openssl rand -base64 32)

echo "Creating temporary service account: $TEMP_CLIENT"

$KC_HOME/bin/kc.sh bootstrap-admin service \
  --db=postgres \
  --db-url-host=$DB_HOST \
  --db-username=$DB_USER \
  --db-password=$DB_PASSWORD \
  --client-id $TEMP_CLIENT \
  --client-secret $TEMP_SECRET

echo "Temporary service account created. Credentials:"
echo "  Client ID: $TEMP_CLIENT"
echo "  Client Secret: $TEMP_SECRET"
echo ""
echo "IMPORTANT: Delete this client after recovery!"
```

## Troubleshooting

### "Nodes are still running"

```bash
# Stop all nodes before bootstrap
systemctl stop keycloak
# or
docker-compose down
```

### "Database connection failed"

```bash
# Include database options
bin/kc.sh bootstrap-admin user \
  --db=postgres \
  --db-url-host=localhost \
  --db-username=keycloak \
  --db-password=changeme \
  --username tmpadmin
```

### "User already exists"

```bash
# Use different username
bin/kc.sh bootstrap-admin user \
  --username tmpadmin2 \
  --password changeme
```

## Best Practices

1. **Document recovery procedures**
2. **Use automation scripts**
3. **Include database options**
4. **Clean up temporary accounts**
5. **Log all recovery operations**
6. **Secure recovery scripts**
7. **Test recovery procedures regularly**
8. **Use strong passwords/secrets**
9. **Monitor for bootstrap usage**
10. **Consider service accounts for automation**

## Comparison: User vs Service Account

| Aspect | Admin User | Service Account |
|--------|-----------|-----------------|
| **Access Type** | Interactive | API-only |
| **Authentication** | Username/password | Client ID/secret |
| **Use Case** | Admin Console access | Admin API automation |
| **Session** | Browser-based | Token-based |
| **Best For** | Manual recovery | Automated recovery |
| **Security** | MFA possible | Requires secret protection |

## Integration with Admin CLI

### Using Bootstrap with kcadm.sh

```bash
# After bootstrap, use kcadm.sh
kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user tmpadmin \
  --password changeme

# Perform recovery operations
kcadm.sh get users
kcadm.sh update users/<id> -r master -s 'enabled=true'
```

### Reset Original Admin Password

```bash
# With bootstrap user
kcadm.sh set-password \
  --username admin \
  --new-password newpassword \
  -r master

# Verify login works
kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password newpassword

# Delete bootstrap user
kcadm.sh delete users/<tmp-user-id> -r master
```

## Production Deployment Considerations

### Container Environments

```yaml
# Kubernetes Job for recovery
apiVersion: batch/v1
kind: Job
metadata:
  name: keycloak-bootstrap
spec:
  template:
    spec:
      containers:
      - name: keycloak
        image: quay.io/keycloak/keycloak:latest
        command:
        - /opt/keycloak/bin/kc.sh
        - bootstrap-admin
        - user
        - --username
        - recovery-admin
        - --password:env
        - RECOVERY_PASSWORD
        env:
        - name: RECOVERY_PASSWORD
          valueFrom:
            secretKeyRef:
              name: recovery-secret
              key: password
        - name: KC_DB
          value: postgres
        - name: KC_DB_URL_HOST
          value: postgres
      restartPolicy: Never
```

### Monitoring Bootstrap Usage

Monitor for unexpected bootstrap commands:
- Audit logs
- Database changes
- New user/client creation
- Admin access logs

## Related Topics

- [[keycloak-admin-cli]] - Admin CLI usage
- [[keycloak-server-configuration-guide]] - Server configuration
- [[keycloak-security]] - Security best practices

## Additional Resources

- [Bootstrap and Recovery Documentation](https://www.keycloak.org/docs/latest/server/bootstrap-admin-recovery)
