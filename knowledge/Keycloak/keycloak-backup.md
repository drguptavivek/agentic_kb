---
title: Keycloak Backup and Restore
type: reference
domain: Keycloak
tags:
  - keycloak
  - backup
  - restore
  - export
  - import
  - migration
  - disaster-recovery
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Backup and Restore

## Overview

Keycloak provides multiple mechanisms for backing up and restoring data, including export/import functionality, database backups, and configuration backups. Proper backup strategy is critical for disaster recovery and migration.

## Backup Types

### Full Backup

**Includes:**
- Database (all data)
- Configuration files
- Providers and custom themes
- Filesystem data

### Export/Import

**Includes:**
- Realm configuration
- Users (optional)
- Clients and roles
- Groups
- Identity providers

### Configuration Backup

**Includes:**
- Server configuration
- SPI provider settings
- Theme settings

## Export/Import

### Exporting Realms

**Admin Console:**
1. Realm Settings → Realm Actions
2. Click **Export** (partial or full)
3. Select export format: JSON or YAML
4. Click **Download**

**CLI:**
```bash
# Export specific realm
kcadm.sh export realms/myrealm --dir ./backup

# Export all realms
kcadm.sh export --dir ./backup

# Export with users
kcadm.sh export realms/myrealm --users --dir ./backup

# Export to file
kcadm.sh export realms/myrealm > backup/myrealm.json
```

**Export options:**
```bash
--users           # Include users
  --users-from-file # Export users from file
--realm <realm>   # Specific realm
--dir <dir>       # Output directory
--file <file>     # Output file
```

### Importing Realms

**Admin Console:**
1. Realm Settings → Realm Actions → Import
2. Select JSON/YAML file
3. Choose import strategy:
   - **Skip** - Skip existing
   - **Overwrite** - Replace existing
4. Click **Import**

**CLI:**
```bash
# Import from file
kcadm.sh create realms -s realm=imported-realm \
  -s enabled=true -f backup/myrealm.json

# Import with strategy
kcadm.sh update realms/myrealm \
  -f backup/myrealm.json

# Partial import
kcadm.sh partial-import realms/myrealm \
  -f backup/partial.json
```

**Import strategies:**

**Skip (default):**
- Doesn't update existing resources
- Only adds new resources
- Safer for incremental updates

**Overwrite:**
- Replaces existing resources
- Can lose data
- Use with caution

### Export Format

**JSON example:**
```json
{
  "realm": "myrealm",
  "enabled": true,
  "displayName": "My Realm",
  "registrationAllowed": true,
  "loginWithEmailAllowed": true,
  "resetPasswordAllowed": true,
  "editUsernameAllowed": true,
  "bruteForceProtected": true,
  "roles": {
    "realm": [
      {
        "name": "user",
        "description": "User role"
      },
      {
        "name": "admin",
        "description": "Administrator role"
      }
    ]
  },
  "clients": [
    {
      "clientId": "myapp",
      "enabled": true,
      "clientAuthenticatorType": "client-secret",
      "secret": "your-secret-here",
      "redirectUris": ["http://localhost:3000/*"],
      "webOrigins": ["http://localhost:3000"],
      "publicClient": false,
      "protocol": "openid-connect",
      "attributes": {}
    }
  ],
  "users": [
    {
      "username": "admin",
      "enabled": true,
      "emailVerified": true,
      "email": "admin@example.com",
      "credentials": [
        {
          "type": "password",
          "value": "hashed-password",
          "temporary": false
        }
      ],
      "realmRoles": ["admin"],
      "clientRoles": {}
    }
  ],
  "browserSecurityHeaders": {
    "contentSecurityPolicyReportOnly": "",
    "xContentTypeOptions": "nosniff",
    "xRobotsTag": "none",
    "xFrameOptions": "SAMEORIGIN",
    "contentSecurityPolicy": "",
    "xXSSProtection": "1; mode=block",
    "strictTransportSecurity": "max-age=31536000; includeSubDomains"
  }
}
```

## Database Backup

### PostgreSQL

**Backup:**
```bash
# Full database backup
pg_dump -U keycloak -h localhost -p 5432 keycloak > backup/keycloak_$(date +%Y%m%d).sql

# Compressed backup
pg_dump -U keycloak -h localhost keycloak | gzip > backup/keycloak_$(date +%Y%m%d).sql.gz

# Custom format (parallel restore)
pg_dump -U keycloak -h localhost -Fc -f backup/keycloak_$(date +%Y%m%d).dump keycloak

# Schema only
pg_dump -U keycloak -h localhost -s keycloak > backup/keycloak_schema_$(date +%Y%m%d).sql
```

**Restore:**
```bash
# From SQL file
psql -U keycloak -h localhost -d keycloak < backup/keycloak_20250129.sql

# From compressed file
gunzip -c backup/keycloak_20250129.sql.gz | psql -U keycloak -h localhost keycloak

# From custom format
pg_restore -U keycloak -h localhost -d keycloak -j 4 backup/keycloak_20250129.dump
```

### MySQL / MariaDB

**Backup:**
```bash
# Full database backup
mysqldump -u keycloak -p keycloak > backup/keycloak_$(date +%Y%m%d).sql

# Compressed backup
mysqldump -u keycloak -p keycloak | gzip > backup/keycloak_$(date +%Y%m%d).sql.gz

# All databases
mysqldump -u root -p --all-databases > backup/all_databases_$(date +%Y%m%d).sql
```

**Restore:**
```bash
# From SQL file
mysql -u keycloak -p keycloak < backup/keycloak_20250129.sql

# From compressed file
gunzip -c backup/keycloak_20250129.sql.gz | mysql -u keycloak -p keycloak
```

### Oracle

**Backup:**
```bash
# Using expdp
expdp keycloak/password@ORCL DIRECTORY=backup_dir \
  DUMPFILE=keycloak_$(date +%Y%m%d).dmp \
  LOGFILE=keycloak_$(date +%Y%m%d).log
```

**Restore:**
```bash
# Using impdp
impdp keycloak/password@ORCL DIRECTORY=backup_dir \
  DUMPFILE=keycloak_20250129.dmp \
  LOGFILE=keycloak_restore_$(date +%Y%m%d).log
```

### Microsoft SQL Server

**Backup:**
```sql
-- Full backup
BACKUP DATABASE keycloak
TO DISK = 'C:\backup\keycloak_20250129.bak'
WITH FORMAT,
MEDIANAME = 'keycloak_Backup',
NAME = 'Full Backup of keycloak';
```

**Restore:**
```sql
RESTORE DATABASE keycloak
FROM DISK = 'C:\backup\keycloak_20250129.bak'
WITH REPLACE;
```

## Configuration Backup

### Keycloak Configuration Files

**Files to backup:**
```bash
# Configuration files
conf/keycloak.conf
conf/quarkus.properties

# Providers directory
providers/

# Themes directory
themes/

# Data directory (if used)
data/
```

**Backup script:**
```bash
#!/bin/bash
BACKUP_DIR="./backup/config_$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Copy configuration
cp -r conf "$BACKUP_DIR/"
cp -r providers "$BACKUP_DIR/"
cp -r themes "$BACKUP_DIR/"

# Tar and compress
tar -czf "$BACKUP_DIR.tar.gz" "$BACKUP_DIR"
```

### Environment Variables

**Export environment variables:**
```bash
# List all Keycloak environment variables
env | grep KEYCLOAK > backup/keycloak_env_$(date +%Y%m%d).txt

# Or from running container
docker exec keycloak env | grep KEYCLOAK > backup/keycloak_env.txt
```

## Automated Backup Scripts

### Full Backup Script

```bash
#!/bin/bash
# Keycloak Full Backup Script

set -e

# Configuration
BACKUP_DIR="/backup/keycloak"
DATE=$(date +%Y%m%d_%H%M%S)
REALM="myrealm"

# Create backup directory
mkdir -p "$BACKUP_DIR/$DATE"

echo "Starting Keycloak backup at $DATE"

# Export realm
echo "Exporting realm..."
kcadm.sh config credentials \
  --server http://localhost:8080 \
  --realm master \
  --user admin

kcadm.sh export realms/$REALM \
  --users \
  --dir "$BACKUP_DIR/$DATE"

# Database backup
echo "Backing up database..."
case "$DB_TYPE" in
  postgresql)
    pg_dump -U $DB_USER -h $DB_HOST $DB_NAME \
      | gzip > "$BACKUP_DIR/$DATE/database.sql.gz"
    ;;
  mysql)
    mysqldump -u $DB_USER -p$DB_PASSWORD $DB_NAME \
      | gzip > "$BACKUP_DIR/$DATE/database.sql.gz"
    ;;
esac

# Configuration backup
echo "Backing up configuration..."
tar -czf "$BACKUP_DIR/$DATE/config.tar.gz" \
  conf/ providers/ themes/ 2>/dev/null || true

# Cleanup old backups (keep last 30 days)
echo "Cleaning up old backups..."
find "$BACKUP_DIR" -type d -mtime +30 -exec rm -rf {} \;

echo "Backup completed: $BACKUP_DIR/$DATE"
```

### Scheduled Backup with Cron

```bash
# Daily backup at 2 AM
0 2 * * * /opt/scripts/keycloak-backup.sh >> /var/log/keycloak-backup.log 2>&1

# Weekly full backup on Sunday at 3 AM
0 3 * * 0 /opt/scripts/keycloak-full-backup.sh >> /var/log/keycloak-backup.log 2>&1
```

## Docker/Kubernetes Backup

### Docker Volume Backup

```bash
# Backup named volume
docker run --rm \
  -v keycloak_data:/data \
  -v $(pwd)/backup:/backup \
  alpine tar czf /backup/keycloak_data_$(date +%Y%m%d).tar.gz -C /data .

# List volumes
docker volume ls

# Restore volume
docker run --rm \
  -v keycloak_data:/data \
  -v $(pwd)/backup:/backup \
  alpine tar xzf /backup/keycloak_data_20250129.tar.gz -C /data
```

### Kubernetes Backup

```yaml
# backup-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: keycloak-backup
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:16
            command:
            - /bin/sh
            - -c
            - |
              pg_dump -U $POSTGRES_USER -h $POSTGRES_HOST $POSTGRES_DATABASE \
                | gzip > /backup/keycloak_$(date +%Y%m%d).sql.gz
            env:
            - name: POSTGRES_USER
              value: "keycloak"
            - name: POSTGRES_HOST
              value: "postgres-service"
            - name: POSTGRES_DATABASE
              value: "keycloak"
            volumeMounts:
            - name: backup
              mountPath: /backup
          volumes:
          - name: backup
            persistentVolumeClaim:
              claimName: backup-pvc
          restartPolicy: OnFailure
```

## Migration and Upgrades

### Export Before Upgrade

**Always export before upgrading:**
```bash
# Export all realms
kcadm.sh export --users --dir ./pre-upgrade-backup

# Verify export
ls -la ./pre-upgrade-backup/
```

### Upgrade Process

1. **Stop Keycloak:**
   ```bash
   systemctl stop keycloak
   # or
   docker stop keycloak
   ```

2. **Backup database:**
   ```bash
   pg_dump -U keycloak keycloak > backup/pre-upgrade.sql
   ```

3. **Backup configuration:**
   ```bash
   tar -czf backup/config_pre-upgrade.tar.gz conf/ providers/ themes/
   ```

4. **Upgrade Keycloak:**
   ```bash
   # Download new version
   wget https://github.com/keycloak/keycloak/releases/download/26.5.0/keycloak-26.5.0.tar.gz

   # Extract
   tar -xzf keycloak-26.5.0.tar.gz

   # Copy configuration
   cp -r conf/ keycloak-26.5.0/conf/
   ```

5. **Run database migration:**
   ```bash
   cd keycloak-26.5.0
   bin/kc.sh build
   ```

6. **Start new version:**
   ```bash
   bin/kc.sh start
   ```

7. **Verify:** Check logs, test login, verify data

## Disaster Recovery

### Recovery Scenarios

**Scenario 1: Database corruption**
1. Stop Keycloak
2. Restore database from backup
3. Start Keycloak
4. Verify data integrity

**Scenario 2: Server failure**
1. Deploy new Keycloak instance
2. Restore configuration files
3. Restore database
4. Verify all realms
5. Update DNS/load balancer

**Scenario 3: Accidental deletion**
1. Import realm from export
2. Verify users and clients
3. Update application configuration

## Backup Best Practices

### ✅ DO

- **Automate backups** - Use cron/scheduled jobs
- **Test restores** - Regularly test restore procedures
- **Off-site storage** - Store backups in multiple locations
- **Encrypt backups** - Protect sensitive data
- **Document procedures** - Maintain runbooks
- **Monitor backups** - Alert on failures
- **Version control** - Keep multiple backup versions
- **Verify integrity** - Check backup after creation

### ❌ DON'T

- Store only on same server
- Skip testing restores
- Forget configuration files
- Ignore backup logs
- Store unencrypted backups
- Keep all backups forever (cleanup old ones)
- Backup only database (need config too)
- Skip off-site backup

## Backup Retention

**Recommended retention:**
- **Hourly:** Keep 24-48 hours
- **Daily:** Keep 7-30 days
- **Weekly:** Keep 4-8 weeks
- **Monthly:** Keep 3-12 months

**Archive strategy:**
- Move old backups to cold storage
- Compress historical backups
- Maintain archive for compliance

## Troubleshooting

### Export Fails

**Common issues:**
- Insufficient permissions
- Realm not found
- Too many users (memory issue)

**Solutions:**
```bash
# Export users in batches
kcadm.sh export realms/myrealm --users-from-file users.txt

# Increase memory
export JAVA_OPTS="-Xmx2g -Xms2g"
kcadm.sh export realms/myrealm --users
```

### Import Fails

**Common issues:**
- Invalid JSON/YAML format
- Duplicate resources
- Schema changes

**Solutions:**
```bash
# Validate JSON
jq . backup/myrealm.json

# Import with different strategy
kcadm.sh partial-import realms/myrealm -f backup/partial.json
```

### Database Restore Fails

**Common issues:**
- Version mismatch
- Encoding issues
- Lock conflicts

**Solutions:**
```bash
# Drop existing database
psql -U keycloak -c "DROP DATABASE keycloak;"

# Create fresh database
psql -U keycloak -c "CREATE DATABASE keycloak;"

# Restore
psql -U keycloak keycloak < backup/keycloak.sql
```

## References

- <https://www.keycloak.org/docs/latest/upgrading/>
- <https://www.keycloak.org/docs/latest/server_admin/#export-import>
- Backup and restore documentation

## Related

- [[keycloak-server-administration]]
- [[keycloak-security]]
- [[keycloak-migration]]
