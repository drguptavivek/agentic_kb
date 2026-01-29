---
title: Keycloak Service Provider Interfaces (SPI)
type: reference
domain: Keycloak
tags:
  - keycloak
  - spi
  - service-provider
  - extension
  - customization
  - providers
  - development
  - plugins
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Service Provider Interfaces (SPI)

## Overview

Keycloak is built with extensibility in mind through **Service Provider Interfaces (SPIs)**. SPIs allow you to extend and customize Keycloak's capabilities by implementing custom providers for specific functionality. <https://www.keycloak.org/docs/latest/server_development/>

## What is an SPI?

A **Service Provider Interface (SPI)** is:
- A contract/interface for specific capability
- Implemented by provider classes
- Registered with Keycloak at build time
- Configured via CLI or environment variables

**Common SPI uses:**
- Custom authentication logic
- User storage integration
- Event listeners and logging
- Protocol mappers
- Theme customization
- Password hashing algorithms

## SPI Configuration Format

### Basic Configuration Option Format

```bash
spi-<spi-id>--<provider-id>--<property>=<value>
```

**Or** (if no ambiguity):

```bash
spi-<spi-id>-<provider-id>-<property>=<value>
```

**Components:**
- `<spi-id>` - SPI name (lowercase, dashes before uppercase)
- `<provider-id>` - Provider factory implementation ID
- `<property>` - Property name to set
- `<value>` - Property value

**Example:**
```bash
# HttpClient SPI: connectionsHttpClient, provider: default
spi-connections-http-client--default--connection-pool-size=10
```

**Naming conventions:**
- All lowercase
- Dashes before uppercase letters
- `myKeycloakProvider` → `my-keycloak-provider`

## Provider Configuration

### Setting Configuration Options

**Command line:**
```bash
bin/kc.sh start --spi-connections-http-client--default--connection-pool-size=10
```

**Environment variable:**
```bash
export SPI_CONNECTIONS_HTTP_CLIENT__DEFAULT__CONNECTION_POOL_SIZE=10
```

**Configuration file:**
```properties
spi-connections-http-client--default--connection-pool-size=10
```

### Build-Time Options

#### Single Provider Configuration

When only one provider should be active:

```bash
# Mark mycustomprovider as single provider for email-template SPI
bin/kc.sh build --spi-email-template--provider=mycustomprovider
```

#### Default Provider Configuration

Set the default provider (used if no specific provider requested):

```bash
# Set mycustomhash as default for password-hashing SPI
bin/kc.sh build --spi-password-hashing--provider-default=mycustomhash
```

**Default provider selection logic:**
1. Explicitly configured default provider
2. Provider with highest order (> 0)
3. Provider with id `default`

#### Enable/Disable Provider

```bash
# Enable provider
bin/kc.sh build --spi-email-template--mycustomprovider--enabled=true

# Disable provider
bin/kc.sh build --spi-email-template--mycustomprovider--enabled=false
```

**Note:** The `enabled` property is reserved for enabling/disabling providers.

## Installing and Uninstalling Providers

### Installing Custom Providers

1. **Package provider** in JAR file
2. **Copy JAR** to `providers/` directory:
   ```bash
   cp my-provider.jar /opt/keycloak/providers/
   ```
3. **Run build** command:
   ```bash
   bin/kc.sh build
   ```

**Why build?**
- Optimizes server runtime
- Registers providers ahead-of-time
- Avoids runtime discovery overhead

### Uninstalling Providers

1. **Remove JAR** from `providers/` directory:
   ```bash
   rm /opt/keycloak/providers/my-provider.jar
   ```
2. **Run build** command:
   ```bash
   bin/kc.sh build
   ```

### Using Third-Party Dependencies

If provider requires external dependencies:

1. **Copy dependencies** to `providers/` directory
2. **Run build** command
3. Dependencies available at runtime for providers that need them

```bash
cp my-dependency.jar /opt/keycloak/providers/
bin/kc.sh build
```

## Common SPIs

### 1. User Storage SPI

**Purpose:** Integrate with external user stores

**Use cases:**
- Custom database schema
- Legacy user systems
- Proprietary user stores
- Read-only user repositories

**Key interfaces:**
- `UserStorageProvider` - Core user storage
- `UserLookupProvider` - User lookup by ID/username
- `CredentialInputUpdater` - Credential updates
- `CredentialInputValidator` - Credential validation

**Example: Custom user storage**

```java
public class CustomUserStorageProvider
    implements UserStorageProvider,
               UserLookupProvider,
               CredentialInputUpdater,
               CredentialInputValidator {

    private final KeycloakSession session;
    private final ComponentModel model;

    public CustomUserStorageProvider(KeycloakSession session,
                                     ComponentModel model) {
        this.session = session;
        this.model = model;
    }

    @Override
    public UserModel getUserById(RealmModel realm, String id) {
        // Lookup user by ID from external system
    }

    @Override
    public UserModel getUserByUsername(RealmModel realm,
                                       String username) {
        // Lookup user by username
    }

    @Override
    public boolean isValid(RealmModel realm, UserModel user,
                          CredentialInput input) {
        // Validate credentials
    }
}
```

**Configuration:**
```java
public class CustomUserStorageProviderFactory
    implements UserStorageProviderFactory<CustomUserStorageProvider> {

    @Override
    public String getId() {
        return "custom-user-storage";
    }

    @Override
    public CustomUserStorageProvider create(KeycloakSession session,
                                           ComponentModel model) {
        return new CustomUserStorageProvider(session, model);
    }
}
```

### 2. Authentication SPI

**Purpose:** Implement custom authentication logic

**Use cases:**
- Custom authentication flows
- Multi-factor authentication
- Conditional authentication
- Risk-based authentication

**Key interfaces:**
- `Authenticator` - Authentication logic
- `AuthenticatorFactory` - Creates authenticators
- `RequiredActionFactory` - Required actions
- `FormAuthenticatorFactory` - Form-based auth

**Example: Custom authenticator**

```java
public class CustomAuthenticator implements Authenticator {

    public static final CustomAuthenticator INSTANCE =
        new CustomAuthenticator();

    @Override
    public void authenticate(AuthenticationFlowContext context) {
        // Custom authentication logic
        HttpResponse response = context.getHttpRequest()
                                       .getHttpResponse();

        // Check custom condition
        if (customConditionMet(context)) {
            context.success();
        } else {
            context.failure(AuthenticationFlowError.INVALID_CREDENTIALS);
        }
    }

    @Override
    public boolean requiresUser() {
        return false;
    }

    @Override
    public boolean configuredFor(KeycloakSession session,
                                 RealmModel realm,
                                 UserModel user) {
        return true;
    }
}
```

### 3. Event Listener SPI

**Purpose:** Listen to and react to Keycloak events

**Use cases:**
- Custom logging
- Audit trails
- Webhook notifications
- Database synchronization
- Analytics integration

**Events:**
- **Admin Events:**
  - CREATE - Resource creation
  - UPDATE - Resource updates
  - DELETE - Resource deletion
  - ACTION - Administrative actions

- **User Events:**
  - LOGIN - Successful login
  - LOGIN_ERROR - Failed login
  - LOGOUT - User logout
  - REGISTER - User registration
  - UPDATE_PASSWORD - Password change
  - UPDATE_TOTP - TOTP changes
  - REMOVE_TOTP - TOTP removal
  - SEND_VERIFY_EMAIL - Email verification

**Key interfaces:**
- `EventListenerProvider` - Event handling logic
- `EventListenerProviderFactory` - Creates provider
- `EventListenerProvider` - Event types

**Example: Custom event listener**

```java
public class CustomEventListenerProvider
    implements EventListenerProvider {

    private final KeycloakSession session;
    private final RealmModel realm;

    public CustomEventListenerProvider(KeycloakSession session,
                                       RealmModel realm) {
        this.session = session;
        this.realm = realm;
    }

    @Override
    public void onEvent(Event event) {
        // Handle admin event
        if (event.getType() instanceof EventType) {
            EventType type = (EventType) event.getType();

            switch (type) {
                case CREATE:
                    logCreate(event);
                    break;
                case UPDATE:
                    logUpdate(event);
                    break;
                case DELETE:
                    logDelete(event);
                    break;
            }
        }
    }

    @Override
    public void onEvent(AdminEvent event, boolean includeRepresentation) {
        // Handle admin event with representation
        logAdminEvent(event, includeRepresentation);
    }

    @Override
    public void close() {
        // Cleanup resources
    }
}
```

**Configuration:**
```bash
# Enable custom event listener
bin/kc.sh start \
  --spi-events-listener--custom--enabled=true \
  --spi-events-listener--custom--exclude-events=LOGIN_ERROR,REFRESH_TOKEN
```

**Available configuration options:**
- `enabled` - Enable/disable listener
- `include-representation` - Include full representation
- `exclude-events` - Comma-separated list of events to exclude

### 4. Protocol Mapper SPI

**Purpose:** Add custom claims to tokens

**Use cases:**
- Custom user attributes in tokens
- External system integration
- Custom claim values
- Dynamic claim generation

**Key interfaces:**
- `ProtocolMapper` - Mapper logic
- `ProtocolMapperFactory` - Creates mappers
- `OIDCAccessTokenMapper` - OIDC access token
- `OIDCIDTokenMapper` - OIDC ID token
- `SAMLAttributeMapper` - SAML attributes

**Example: Custom OIDC protocol mapper**

```java
public class CustomProtocolMapper
    extends AbstractOIDCProtocolMapper
    implements OIDCAccessTokenMapper,
               OIDCIDTokenMapper {

    @Override
    protected ProtocolMapperModel createMapperModel(String name,
                                                    String consentText,
                                                    String consentTooltipText,
                                                    boolean addToToken,
                                                    boolean addToIdToken) {
        return new ProtocolMapperModel();
    }

    @Override
    protected void setClaim(AccessTokenResponse token,
                           ProtocolMapperModel mappingModel,
                           UserSessionModel userSession,
                           KeycloakSession keycloakSession,
                           RootAuthenticationSessionModel rootSession,
                           UserModel user) {
        String customValue = getCustomValue(user);
        token.getOtherClaims().put("custom_claim", customValue);
    }

    private String getCustomValue(UserModel user) {
        // Custom logic to generate claim value
        return user.getFirstAttribute("customAttribute");
    }
}
```

### 5. Password Hashing SPI

**Purpose:** Custom password hashing algorithms

**Use cases:**
- Legacy password migration
- Custom hashing algorithms
- Industry-specific requirements
- FIPS-compliant hashing

**Key interfaces:**
- `PasswordHashProvider` - Hashing logic
- `PasswordHashProviderFactory` - Creates provider

**Example: Custom password hasher**

```java
public class CustomPasswordHashProvider
    implements PasswordHashProvider {

    private final int defaultIterations;

    public CustomPasswordHashProvider(int defaultIterations) {
        this.defaultIterations = defaultIterations;
    }

    @Override
    public boolean policyCheck(RealmModel realm,
                              UserModel user,
                              String password) {
        // Check password policy
        return password != null && password.length() >= 12;
    }

    @Override
    public String encode(String rawPassword,
                        int iterations) {
        // Custom hashing logic
        return customHash(rawPassword, iterations);
    }

    @Override
    public boolean verify(String rawPassword,
                         String encodedPassword) {
        return encode(rawPassword, defaultIterations)
                   .equals(encodedPassword);
    }

    @Override
    public void close() {
        // Cleanup
    }
}
```

### 6. Theme SPI

**Purpose:** Customize Keycloak UI appearance

**Types:**
- **Login Theme** - Login pages
- **Account Theme** - User account console
- **Admin Console Theme** - Administration interface
- **Email Theme** - Email templates

**Theme structure:**
```
theme/
├── my-theme/
│   ├── login/
│   │   ├── login.ftl
│   │   ├── login.css
│   │   └── resources/
│   ├── account/
│   │   ├── account.ftl
│   │   └── account.css
│   └── email/
│       ├── html/
│       └── text/
```

### 7. Client Registration SPI

**Purpose:** Dynamic client registration policies

**Use cases:**
- Approval workflows
- Policy enforcement
- Custom validation
- Rate limiting

### 8. HttpClient SPI

**Purpose:** Customize HTTP client behavior

**Use cases:**
- Custom connection pooling
- TLS configuration
- Proxy settings
- Timeouts

**Configuration:**
```bash
# Default HTTP client configuration
spi-connections-http-client--default--connection-pool-size=10
spi-connections-http-client--default--connection-pool-max-size=20
spi-connections-http-client--default--connection-pool-max-queued=50
spi-connections-http-client--default--connection-timeout-millis=5000
spi-connections-http-client--default--socket-timeout-millis=30000
```

### 9. Infinispan Cache SPI

**Purpose:** Customize caching behavior

**Configuration:**
```bash
spi-infinispan-connection-provider--default--client-intelligence=BASIC
spi-infinispan-connection-provider--default--cluster-name=keycloak
```

### 10. JPA Entity SPI

**Purpose:** Customize database entities and persistence

**Use cases:**
- Custom database mappings
- Additional entity properties
- Custom queries

## Provider Development

### Project Setup

**Maven dependencies:**
```xml
<dependency>
    <groupId>org.keycloak</groupId>
    <artifactId>keycloak-core</artifactId>
    <version>26.5.0</version>
    <scope>provided</scope>
</dependency>
<dependency>
    <groupId>org.keycloak</groupId>
    <artifactId>keycloak-server-spi</artifactId>
    <version>26.5.0</version>
    <scope>provided</scope>
</dependency>
<dependency>
    <groupId>org.keycloak</groupId>
    <artifactId>keycloak-services</artifactId>
    <version>26.5.0</version>
    <scope>provided</scope>
</dependency>
```

### Provider Factory Pattern

Every provider needs a factory:

```java
public class CustomProviderFactory
    implements CustomProviderFactory,
               ProviderFactory<CustomProvider> {

    private volatile CustomProvider provider;

    @Override
    public String getId() {
        return "custom-provider";
    }

    @Override
    public void init(Config.Scope config) {
        // Initialization
    }

    @Override
    public CustomProvider create(KeycloakSession session) {
        if (provider == null) {
            synchronized (this) {
                if (provider == null) {
                    provider = new CustomProvider(session);
                }
            }
        }
        return provider;
    }

    @Override
    public void close() {
        if (provider != null) {
            provider.close();
            provider = null;
        }
    }
}
```

### Service Provider Registration

Register factory in `META-INF/services/`:

**File:** `META-INF/services/org.keycloak.provider.ProviderFactory`

```
com.example.CustomProviderFactory
com.example.CustomUserStorageProviderFactory
```

### Building and Packaging

**Maven build:**
```bash
mvn clean package
```

**Result:** JAR file in `target/` directory

## Testing Providers

### Unit Testing

```java
@Test
public void testCustomProvider() {
    KeycloakSession session = createKeycloakSession();
    CustomProvider provider = new CustomProvider(session);

    assertNotNull(provider);
    // Test provider logic
}
```

### Integration Testing

**Keycloak test framework:**
```java
@RunWith(Arquillian.class)
public class CustomProviderIT {

    @Inject
    private KeycloakSession session;

    @Test
    public void testProviderIntegration() {
        CustomProvider provider = session.getProvider(CustomProvider.class);
        assertNotNull(provider);
        // Integration tests
    }
}
```

## Best Practices

### 1. Provider Design

**DO:**
- Implement interfaces correctly
- Handle null values gracefully
- Use dependency injection
- Follow single responsibility principle
- Document provider behavior
- Handle errors appropriately

**DON'T:**
- Block threads indefinitely
- Hold onto resources
- Ignore configuration
- Hardcode values
- Assume all realms are the same

### 2. Performance

**Considerations:**
- Lazy initialization
- Connection pooling
- Caching when appropriate
- Async operations for I/O
- Resource cleanup

**Example:**
```java
public class CachedCustomProvider {
    private final Cache<String, User> cache;

    public UserModel getUser(String username) {
        return cache.computeIfAbsent(username,
            key -> loadFromDatabase(key));
    }
}
```

### 3. Security

**Best practices:**
- Validate all inputs
- Sanitize data from external sources
- Use prepared statements
- Follow principle of least privilege
- Log security-relevant events
- Handle secrets properly

### 4. Error Handling

**Approaches:**
- Return meaningful error messages
- Log errors appropriately
- Don't expose sensitive information
- Graceful degradation
- Retry logic for transient failures

### 5. Configuration

**Best practices:**
- Provide sensible defaults
- Validate configuration
- Document all options
- Support runtime configuration
- Use consistent naming

## Debugging SPIs

### Enable Debug Logging

```bash
bin/kc.sh start-dev \
  --log-level=org.keycloak.provider:DEBUG \
  --log-level=com.example:DEBUG
```

### Check Provider Registration

**Admin Console:**
1. Server Info → Providers
2. Check if provider is listed
3. Verify configuration

**Server startup logs:**
```
INFO  [org.keycloak.provider.ProviderManager]
  Loaded provider custom-user-storage from
  file:/opt/keycloak/providers/custom-provider.jar
```

### Common Issues

**Provider not found:**
- Verify JAR in `providers/` directory
- Run `kc.sh build`
- Check service registration
- Verify factory class name

**Configuration not applied:**
- Check configuration format
- Verify SPI and provider IDs
- Check property names
- Check for typos

**Provider not active:**
- Verify `enabled=true`
- Check provider order
- Verify default provider setting

## Examples and Demos

**GitHub repositories:**
- [keycloak-extensions-demo](https://github.com/dasniko/keycloak-extensions-demo) - Various SPI examples
- [keycloak-spi-azurekeyvault](https://github.com/amd989/keycloak-spi-azurekeyvault) - Azure Key Vault integration
- [keycloak-event-listener-sysout](https://github.com/keycloak/keycloak/tree/main/examples/event-listener-sysout) - Event listener example

## All Provider Configuration

**Reference:** <https://www.keycloak.org/server/all-provider-config>

Complete list of all SPIs and their configuration options.

## References

- <https://www.keycloak.org/docs/latest/server_development/>
- <https://www.keycloak.org/server/configuration-provider>
- <https://www.keycloak.org/server/all-provider-config>
- Keycloak GitHub: examples/event-listener-sysout

## Related

- [[keycloak-overview]]
- [[keycloak-server-administration]]
- [[keycloak-events]]
