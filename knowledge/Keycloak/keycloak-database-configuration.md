---
title: Keycloak Database Configuration
domain: Keycloak
type: howto
status: draft
tags: [keycloak, database, postgres, mysql, oracle, configuration]
created: 2026-01-29
related: [[keycloak-server-configuration-guide]], [[keycloak-caching-clustering]], [[keycloak-advanced-configuration]]
---

# Keycloak Database Configuration

## Overview

Keycloak requires a relational database to store user, client, realm, and configuration data. This guide covers database configuration for production deployments.

## Supported Databases

| Database | Option Value | Tested Version |
|----------|--------------|----------------|
| PostgreSQL | `postgres` | 17 |
| MySQL | `mysql` | 8.4 |
| MariaDB | `mariadb` | 11.4 |
| Microsoft SQL Server | `mssql` | 2022 |
| Oracle Database | `oracle` | 23.5 |
| Amazon Aurora PostgreSQL | `postgres` | 16.8 |

**Default:** `dev-file` - NOT suitable for production

## Basic Configuration

### Configuration File Approach (Recommended)

Create `conf/keycloak.conf`:

```properties
# Database vendor
db=postgres

# Connection settings
db-username=keycloak
db-password=change_me
db-url-host=keycloak-postgres
db-url-database=keycloak
db-url-port=5432

# Schema (optional, default: keycloak)
db-schema=keycloak
```

### Command-Line Approach

```bash
bin/kc.sh start \
  --db=postgres \
  --db-url-host=keycloak-postgres \
  --db-username=keycloak \
  --db-password=change_me
```

### Using Environment Variables

```bash
export KC_DB=postgres
export KC_DB_USERNAME=keycloak
export KC_DB_PASSWORD=change_me
export KC_DB_URL_HOST=keycloak-postgres
```

## JDBC URL Configuration

### Default URL Construction

Keycloak constructs default URLs based on vendor:

```bash
# PostgreSQL: jdbc:postgresql://localhost/keycloak
# MySQL: jdbc:mysql://localhost:3306/keycloak
# MariaDB: jdbc:mariadb://localhost:3306/keycloak
# MSSQL: jdbc:sqlserver://localhost:1433;databaseName=keycloak
# Oracle: jdbc:oracle:thin:@localhost:1521:keycloak
```

### Custom JDBC URL

```bash
bin/kc.sh start \
  --db=postgres \
  --db-url=jdbc:postgresql://mypostgres:5432/mydatabase
```

### Connection Properties

```bash
bin/kc.sh start \
  --db-url-properties='?ssl=true&sslmode=verify-full'
```

## Database-Specific Configuration

### PostgreSQL

#### Basic Setup

```bash
bin/kc.sh start \
  --db=postgres \
  --db-url-host=postgres.example.com \
  --db-username=keycloak \
  --db-password=change_me \
  --db-database=keycloak
```

#### SSL Configuration

```bash
bin/kc.sh start \
  --db-url=jdbc:postgresql://db.example.com:5432/keycloak?sslmode=verify-full
```

#### Connection Pool

```bash
--spi-connections-jpa--quarkus--max-pool-size=20
--spi-connections-jpa--quarkus--min-pool-size=5
```

### MySQL/MariaDB

#### Basic Setup

```bash
bin/kc.sh start \
  --db=mysql \
  --db-url-host=mysql.example.com \
  --db-username=keycloak \
  --db-password=change_me \
  --db-database=keycloak
```

#### Important MySQL Configuration

**Disable generated invisible primary keys** (MySQL 8.0.30+):

```sql
-- In MySQL server configuration
SET GLOBAL sql_generate_invisible_primary_key=OFF;
```

#### Character Encoding

```sql
-- Create database with UTF-8 support
CREATE DATABASE keycloak CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

#### Connection Properties

```bash
--db-url-properties='?useSSL=true&characterEncoding=UTF-8'
```

### Microsoft SQL Server

```bash
bin/kc.sh start \
  --db=mssql \
  --db-url-host=mssql.example.com \
  --db-username=keycloak \
  --db-password=change_me \
  --db-database=keycloak
```

**Performance tip:** Set `sendStringParametersAsUnicode=false`

### Oracle Database

#### Installing Oracle Driver

Oracle driver is not included. Install manually:

```bash
# Download ojdbc17 and orai18n JARs
# Place in providers/ directory

# For containers
FROM quay.io/keycloak/keycloak:latest
ADD --chown=keycloak:keycloak --chmod=644 \
  https://repo1.maven.org/maven2/com/oracle/database/jdbc/ojdbc17/23.6.0.24.10/ojdbc17-23.6.0.24.10.jar \
  /opt/keycloak/providers/ojdbc17.jar
ADD --chown=keycloak:keycloak --chmod=644 \
  https://repo1.maven.org/maven2/com/oracle/database/nls/orai18n/23.6.0.24.10/orai18n-23.6.0.24.10.jar \
  /opt/keycloak/providers/orai18n.jar
ENV KC_DB=oracle
RUN /opt/keycloak/bin/kc.sh build
```

#### Configuration

```bash
bin/kc.sh start \
  --db=oracle \
  --db-url-host=oracle.example.com \
  --db-username=keycloak \
  --db-password=change_me
```

#### Unicode Support

For databases without Unicode support in VARCHAR/CHAR:

```bash
# Set system properties
export JAVA_OPTS_APPEND="-Doracle.jdbc.defaultNChar=true"
```

## Amazon Aurora PostgreSQL

### Using AWS JDBC Driver

**Benefits:** Connection transfer during writer instance changes

```bash
# Install driver
ADD --chmod=0666 \
  https://github.com/awslabs/aws-advanced-jdbc-wrapper/releases/download/2.5.6/aws-advanced-jdbc-wrapper-2.5.6.jar \
  /opt/keycloak/providers/

# Configure
bin/kc.sh start \
  --db-url=jdbc:aws-wrapper:postgresql://aurora-cluster-xyz.cluster-abc123.us-east-1.rds.amazonaws.com:5432/keycloak \
  --db-driver=software.amazon.jdbc.Driver
```

## Connection Pool Configuration

### Pool Size Settings

```bash
# Maximum pool size (default: 100)
--spi-connections-jpa--quarkus--max-pool-size=20

# Minimum pool size (default: unset)
--spi-connections-jpa--quarkus--min-pool-size=5

# Initial pool size
--db-pool-initial-size=10
```

### Pool Settings for Different Deployments

| Deployment | Max Pool Size | Min Pool Size |
|------------|---------------|---------------|
| Small (< 1000 users) | 20 | 5 |
| Medium (1000-10000 users) | 50 | 10 |
| Large (> 10000 users) | 100+ | 20 |

## Database Initialization and Migration

### Migration Strategies

```bash
# Manual migration (manual review of changes)
--spi-connections--jpa--quarkus-migration-strategy=manual

# Update (auto-migration)
--spi-connections--jpa--quarkus-migration-strategy=update

# Validate (check schema, no changes)
--spi-connections--jpa--quarkus-migration-strategy=validate
```

### Export SQL Schema

```bash
bin/kc.sh start \
  --spi-connections--jpa--quarkus-migration-strategy=manual \
  --spi-connections--jpa--quarkus-initialize-empty=false \
  --spi-connections--jpa--quarkus-migration-export=/path/to/schema.sql
```

## Cluster Database Locking

When running multiple nodes, Keycloak uses database locks during startup.

### Lock Timeout Configuration

```bash
# Default: 900 seconds
--spi-dblock--jpa--lock-wait-timeout=900
```

Increase this if nodes take longer to start concurrently.

## Unicode Support by Database

| Database | Unicode Support | Configuration Required |
|----------|----------------|------------------------|
| PostgreSQL | Full UTF-8 | Create database with UTF8 encoding |
| MySQL | utf8mb4 | Set characterEncoding=UTF-8 |
| Oracle | AL32UTF8 | Set oracle.jdbc.defaultNChar=true if needed |
| MSSQL | Special fields only | No special config |

## XA Transactions

For XA transaction support:

```bash
bin/kc.sh build \
  --db=postgres \
  --transaction-xa-enabled=true
```

**Note:** Not supported by Azure SQL, MariaDB Galera

## Performance Tuning

### Slow Query Logging

```bash
--db-log-slow-queries-threshold=10000
```

Logs queries slower than 10 seconds with `org.hibernate.SQL_SLOW`.

### Debug JPQL

```bash
--db-debug-jpql=true
```

Adds JPQL as comments in SQL statements.

## Database Schema

### Default Schema

Default schema name is `keycloak`. Change with:

```bash
--db-schema=my_custom_schema
```

### Custom JDBC Driver

```bash
--db-driver=my.CustomDriver
```

## Container Deployment

### Environment Variables

```yaml
# docker-compose.yml
environment:
  KC_DB: postgres
  KC_DB_URL_HOST: postgres
  KC_DB_DATABASE: keycloak
  KC_DB_USERNAME: keycloak
  KC_DB_PASSWORD: change_me
```

### Volume for Database Driver

```yaml
volumes:
  - ./providers/ojdbc17.jar:/opt/keycloak/providers/ojdbc17.jar
```

## Backup and Recovery

### Database Backup

```bash
# PostgreSQL
pg_dump -U keycloak keycloak > keycloak-backup.sql

# MySQL
mysqldump -u keycloak -p keycloak > keycloak-backup.sql

# MSSQL
sqlcmd -S localhost -U keycloak -Q "BACKUP DATABASE keycloak TO DISK='C:\backup.bak'"
```

### Keycloak Export (Alternative)

```bash
bin/kc.sh export --dir=/path/to/export --users different_files
```

## Troubleshooting

### Connection Issues

```bash
# Enable detailed logging
--log-level=debug,org.hibernate.SQL
--log-level=debug,org.hibernate.type.descriptor.sql.BasicBinder
```

### Pool Exhaustion

```bash
# Increase pool size
--spi-connections-jpa--quarkus--max-pool-size=50

# Decrease pool max wait time
--spi-connections-jpa--quarkus--connection-max-wait-time=30000
```

### Schema Validation Errors

```bash
# Use validate strategy to check schema
--spi-connections--jpa--quarkus-migration-strategy=validate
```

## Production Best Practices

1. **Use connection pooling** with appropriate sizes
2. **Enable SSL/TLS** for database connections
3. **Monitor slow queries** and optimize indexes
4. **Regular backups** of database
5. **Test migration strategy** before production deployment
6. **Use dedicated database user** with minimum required privileges
7. **Set appropriate timeouts** for connections
8. **Monitor connection pool metrics**

## Related Topics

- [[keycloak-caching-clustering]] - Distributed caches reduce DB load
- [[keycloak-server-configuration-guide]] - General configuration
- [[keycloak-security]] - Security considerations

## Additional Resources

- [Configuring the Database](https://www.keycloak.org/docs/latest/server/db)
