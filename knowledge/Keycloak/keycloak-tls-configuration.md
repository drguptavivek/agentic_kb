---
title: Keycloak TLS and Truststore Configuration
domain: Keycloak
type: howto
status: draft
tags: [keycloak, tls, https, certificates, truststore, mtls]
created: 2026-01-29
related: [[keycloak-server-configuration-guide]], [[keycloak-security]], [[keycloak-outgoing-http]]
---

# Keycloak TLS and Truststore Configuration

## Overview

Keycloak requires TLS for secure communication. This guide covers:
- Inbound HTTPS (connections to Keycloak)
- Outgoing HTTPS (connections from Keycloak)
- Truststore configuration
- Mutual TLS (mTLS)
- Certificate validation

## Inbound HTTPS Configuration

### Using PEM Files

```bash
bin/kc.sh start \
  --https-certificate-file=/path/to/cert.pem \
  --https-certificate-key-file=/path/to/key.pem \
  --https-port=8443
```

### Using a KeyStore

```bash
bin/kc.sh start \
  --https-key-store-file=/path/to/keystore.p12 \
  --https-key-store-password=change_me \
  --https-key-store-type=PKCS12 \
  --https-port=8443
```

### KeyStore Types

| Type | Extension | Description |
|------|-----------|-------------|
| PKCS12 | `.p12`, `.pfx`, `.pkcs12` | Standard format, recommended |
| JKS | `.jks`, `.keystore` | Java KeyStore (legacy) |
| PEM | `.pem`, `.crt` | Privacy Enhanced Mail |

### Generating a KeyStore

```bash
# Generate self-signed certificate
keytool -genkeypair \
  -alias server \
  -keystore keystore.p12 \
  -storepass change_me \
  -storetype PKCS12 \
  -keyalg RSA \
  -keysize 2048 \
  -validity 365 \
  -dname "CN=keycloak.example.com" \
  -ext "SAN=DNS:keycloak.example.com,IP:127.0.0.1"
```

### Enable HTTP (Development Only)

```bash
bin/kc.sh start \
  --http-enabled=true \
  --http-port=8080
```

**Not recommended for production**

## Outgoing HTTPS Configuration

Keycloak makes outgoing requests to:
- Identity providers (brokers)
- External APIs
- Backend services

### System Truststore

Configure trusted certificates for outgoing connections:

```bash
bin/kc.sh start \
  --truststore-paths=/opt/truststore/ca.pem,/etc/certs
```

### Default Truststore Locations

- `conf/truststores/` - Default directory
- Scanned recursively for PEM and PKCS12 files
- PKCS12 files must be unencrypted (no password)

### Supported Truststore Formats

| Format | Extensions | Password |
|--------|-----------|----------|
| PEM | `.pem`, `.crt`, `.ca` | None (unencrypted) |
| PKCS12 | `.p12`, `.pfx`, `.pkcs12` | None (unencrypted) |

### Truststore Example Structure

```
conf/truststores/
├── internal-ca.pem
├── external/
│   ├── provider1.crt
│   └── provider2.pem
└── corporate.p12
```

## Hostname Verification

Control how hostnames are verified in TLS connections.

### Verification Policies

| Policy | Description | Use Case |
|--------|-------------|----------|
| `DEFAULT` | Wildcards with public suffix checking | Production |
| `ANY` | No verification | Development only |
| `STRICT` | Same-level wildcards only | Deprecated, use DEFAULT |
| `WILDCARD` | Multi-level wildcards | Deprecated, use DEFAULT |

### Configuration

```bash
bin/kc.sh start \
  --tls-hostname-verifier=DEFAULT
```

**Example:**
- `*.example.com` matches `api.example.com` but NOT `sub.api.example.com`
- Uses [Public Suffix List](https://publicsuffix.org/) for validation

## Mutual TLS (mTLS)

### Enabling mTLS

Configure Keycloak to validate client certificates:

```bash
bin/kc.sh start \
  --https-client-auth=request
```

### Client Authentication Modes

| Mode | Description |
|------|-------------|
| `none` | Default, no client certificate required |
| `request` | Request certificate, accept if missing |
| `required` | Require certificate, fail if missing |

### Dedicated Truststore for mTLS

```bash
bin/kc.sh start \
  --https-client-auth=required \
  --https-trust-store-file=/path/to/truststore.p12 \
  --https-trust-store-password=change_me \
  --https-trust-store-type=PKCS12
```

### Truststore File Recognition

| Extension | Type |
|-----------|------|
| `.p12`, `.pkcs12`, `.pfx` | PKCS12 |
| `.jks`, `.truststore` | JKS |
| `.ca`, `.crt`, `.pem` | PEM |

**Note:** mTLS configuration is shared across all realms.

### Management Interface mTLS

Override mTLS for management interface:

```bash
bin/kc.sh start \
  --https-client-auth=request \
  --https-management-client-auth=none
```

## Outgoing HTTP Requests with mTLS

When Keycloak acts as client (e.g., brokered IdP with mTLS):

```bash
bin/kc.sh start \
  --spi-connections-http-client--default--client-keystore=/path/to/client.p12 \
  --spi-connections-http-client--default--client-keystore-password=change_me \
  --spi-connections-http-client--default--client-key-password=keypass
```

### HTTP Client Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `establish-connection-timeout-millis` | Connection timeout | Not set |
| `socket-timeout-millis` | Inactivity timeout | 5000ms |
| `connection-pool-size` | Pool size | 128 |
| `max-pooled-per-route` | Per-host pool size | 64 |
| `connection-ttl-millis` | Connection TTL | Not set |
| `max-connection-idle-time-millis` | Idle connection timeout | 900000 |
| `disable-cookies` | Disable cookie caching | true |
| `disable-trust-manager` | Disable cert verification | false (never use in production) |

### Example: Configure HTTP Client

```bash
bin/kc.sh start \
  --spi-connections-http-client--default--connection-pool-size=50 \
  --spi-connections-http-client--default--socket-timeout-millis=10000 \
  --spi-connections-http-client--default--max-connection-idle-time-millis=60000
```

## Proxy Configuration for Outgoing Requests

### Environment Variables

```bash
export HTTPS_PROXY=https://proxy.example.com:8080
export NO_PROXY=google.com,facebook.com
```

### Proxy Mappings

```bash
bin/kc.sh start \
  --spi-connections-http-client--default--proxy-mappings='.*\\.google\\.com;http://proxy.example.com:8080'
```

### Proxy with Authentication

```bash
.*\\.example\\.com;http://user:password@proxy.example.com:8080
```

### Special Proxy Values

```
# All requests to Google APIs use proxy
.*\\.(google|googleapis)\\.com;http://proxy:8080

# Internal systems bypass proxy
.*\\.acme\\.com;NO_PROXY

# Catch-all default proxy
.*;http://fallback:8080
```

## Certificate Management

### Import Certificate into Truststore

```bash
# For JKS
keytool -importcert \
  -alias my-ca \
  -file ca.crt \
  -keystore truststore.jks \
  -storepass change_me

# For PKCS12
keytool -importcert \
  -alias my-ca \
  -file ca.crt \
  -keystore truststore.p12 \
  -storetype PKCS12 \
  -storepass change_me
```

### List Truststore Contents

```bash
keytool -list \
  -keystore truststore.p12 \
  -storetype PKCS12 \
  -storepass change_me \
  -v
```

### Export Certificate

```bash
keytool -exportcert \
  -alias my-ca \
  -keystore truststore.p12 \
  -storetype PKCS12 \
  -storepass change_me \
  -file ca.crt
```

## Production Best Practices

### Certificate Requirements

- [ ] Use certificates from trusted CA
- [ ] Include all required domains in SAN
- [ ] Set appropriate expiration dates
- [ ] Use strong private keys (2048+ bit RSA or ECC)
- [ ] Monitor certificate expiration

### TLS Configuration

- [ ] Enable HTTPS only
- [ ] Use TLS 1.3 or TLS 1.2
- [ ] Disable weak ciphers
- [ ] Enable hostname verification
- [ ] Configure truststore properly

### mTLS Configuration

- [ ] Use dedicated truststore for client certs
- [ ] Implement proper certificate revocation
- [ ] Monitor certificate validation failures
- [ ] Secure truststore files
- [ ] Rotate certificates regularly

### Security Considerations

- [ ] Never use `disable-trust-manager=true` in production
- [ ] Protect keystore passwords
- [ ] Use `tls-hostname-verifier=DEFAULT`
- [ ] Restrict truststore file permissions
- [ ] Audit certificate usage

## Troubleshooting

### Enable TLS Debug

```bash
export JAVA_OPTS_APPEND="-Djavax.net.debug=ssl,handshake"
bin/kc.sh start
```

### Common Certificate Errors

**PKIX path building failed:**
```
Cause: Certificate not in truststore
Solution: Add CA cert to truststore-paths
```

**No subject alternative DNS name:**
```
Cause: Certificate missing SAN entry
Solution: Re-generate certificate with proper SAN
```

**Certificate expired:**
```
Cause: Certificate past expiration date
Solution: Renew certificate
```

### Verification Commands

```bash
# Check certificate details
openssl x509 -in cert.pem -text -noout

# Verify certificate chain
openssl s_client -connect keycloak.example.com:8443 -showcerts

# Check truststore
keytool -list -v -keystore truststore.p12
```

## Related Topics

- [[keycloak-outgoing-http]] - Outgoing HTTP client configuration
- [[keycloak-security]] - Security best practices
- [[keycloak-server-configuration-guide]] - Server configuration
- [[keycloak-reverse-proxy]] - Proxy configuration

## Additional Resources

- [Configuring Trusted Certificates](https://www.keycloak.org/docs/latest/server/keycloak-truststore)
- [Configuring mTLS](https://www.keycloak.org/docs/latest/server/mutual-tls)
- [Outgoing HTTP Requests](https://www.keycloak.org/docs/latest/server/outgoinghttp)
