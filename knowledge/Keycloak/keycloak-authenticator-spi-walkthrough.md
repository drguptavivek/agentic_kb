---
title: Keycloak Authenticator SPI Walkthrough
domain: Keycloak
type: tutorial
status: draft
tags: [keycloak, spi, authenticator, development, custom-authentication]
created: 2026-01-29
related: [[keycloak-required-action-spi]], [[keycloak-registration-form]], [[keycloak-spi]]
---

# Keycloak Authenticator SPI Walkthrough

## Overview

The Authenticator SPI (Service Provider Interface) allows you to implement custom authentication logic in Keycloak. This walkthrough covers creating a custom authenticator from development to deployment.

## What is an Authenticator?

An authenticator in Keycloak:
- Validates user credentials
- Controls authentication flow
- Can require additional user actions
- Integrates with external systems
- Implements custom authentication protocols

## Authenticator Types

| Type | Description | Use Case |
|------|-------------|----------|
| **Form Authenticator** | Renders and processes forms | Username/password, OTP |
| **Conditional Authenticator** | Conditions for other authenticators | Risk-based auth, step-up |
| **Client Authenticator** | Client authentication | JWT assertion, client secret |

## Project Setup

### Maven Dependencies

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
         http://maven.apache.org/xsd/maven-4.0.0.xsd">
    <modelVersion>4.0.0</modelVersion>

    <groupId>com.example</groupId>
    <artifactId>custom-authenticator</artifactId>
    <version>1.0.0</version>

    <properties>
        <keycloak.version>26.5.0</keycloak.version>
        <maven.compiler.source>17</maven.compiler.source>
        <maven.compiler.target>17</maven.compiler.target>
        <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
    </properties>

    <dependencies>
        <!-- Keycloak SPI -->
        <dependency>
            <groupId>org.keycloak</groupId>
            <artifactId>keycloak-server-spi</artifactId>
            <version>${keycloak.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.keycloak</groupId>
            <artifactId>keycloak-server-spi-private</artifactId>
            <version>${keycloak.version}</version>
            <scope>provided</scope>
        </dependency>
        <dependency>
            <groupId>org.keycloak</groupId>
            <artifactId>keycloak-services</artifactId>
            <version>${keycloak.version}</version>
            <scope>provided</scope>
        </dependency>
    </dependencies>

    <build>
        <plugins>
            <plugin>
                <groupId>org.apache.maven.plugins</groupId>
                <artifactId>maven-shade-plugin</artifactId>
                <executions>
                    <execution>
                        <phase>package</phase>
                        <goals>
                            <goal>shade</goal>
                        </goals>
                        <configuration>
                            <artifactSet>
                                <includes>
                                    <include>*:*</include>
                                </includes>
                            </artifactSet>
                        </configuration>
                    </execution>
                </executions>
            </plugin>
        </plugins>
    </build>
</project>
```

## Creating a Simple Authenticator

### Step 1: Implement Authenticator Interface

```java
package com.example.keycloak.authenticator;

import org.keycloak.authentication.Authenticator;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;

public class CustomAuthenticator implements Authenticator {

    @Override
    public void authenticate(AuthenticationFlowContext context) {
        // Custom authentication logic here
        // For example, redirect to a custom form
        // Or validate against external system

        // If successful:
        context.success();

        // If failure:
        // context.failure(AuthenticationFlowError.INVALID_USER);
    }

    @Override
    public boolean requiresUser() {
        // Does this authenticator require an existing user?
        return true; // or false for new user registration
    }

    @Override
    public boolean configuredFor(KeycloakSession session,
                                  RealmModel realm,
                                  UserModel user) {
        // Is this authenticator configured for the user?
        return true;
    }

    @Override
    public void setRequiredActions(KeycloakSession session,
                                    RealmModel realm,
                                    UserModel user) {
        // Set required actions if needed
        // user.addRequiredAction("VERIFY_EMAIL");
    }

    @Override
    public void close() {
        // Cleanup resources if any
    }
}
```

### Step 2: Create Authenticator Factory

```java
package com.example.keycloak.authenticator;

import org.keycloak.authentication.Authenticator;
import org.keycloak.authentication.AuthenticatorFactory;
import org.keycloak.models.AuthenticationExecutionModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.provider.ProviderConfigProperty;
import org.keycloak.provider.ProviderConfigurationBuilder;

import java.util.List;

public class CustomAuthenticatorFactory implements AuthenticatorFactory {

    public static final String PROVIDER_ID = "custom-authenticator";
    public static final String DISPLAY_NAME = "Custom Authenticator";
    public static final String HELP_TEXT = "A custom authenticator example";

    @Override
    public String getDisplayType() {
        return DISPLAY_NAME;
    }

    @Override
    public String getReferenceCategory() {
        return "custom-auth";
    }

    @Override
    public boolean isConfigurable() {
        return false; // Set to true if you have configuration options
    }

    @Override
    public AuthenticationExecutionModel.Requirement[] getRequirementChoices() {
        return new AuthenticationExecutionModel.Requirement[]{
            AuthenticationExecutionModel.Requirement.REQUIRED,
            AuthenticationExecutionModel.Requirement.ALTERNATIVE,
            AuthenticationExecutionModel.Requirement.DISABLED
        };
    }

    @Override
    public boolean isUserSetupAllowed() {
        return false; // Can user set up this authenticator?
    }

    @Override
    public String getHelpText() {
        return HELP_TEXT;
    }

    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        if (!isConfigurable()) {
            return null;
        }
        return ProviderConfigurationBuilder.create()
            .property()
                .name("apiKey")
                .label("API Key")
                .helpText("API key for external validation service")
                .type(ProviderConfigProperty.STRING_TYPE)
                .required(true)
                .add()
            .build();
    }

    @Override
    public Authenticator create(KeycloakSession session) {
        return new CustomAuthenticator();
    }

    @Override
    public void init(org.keycloak.provider.Config.Scope config) {
        // Initialization if needed
    }

    @Override
    public void postInit(org.keycloak.provider.Config.Scope config) {
        // Post-initialization if needed
    }

    @Override
    public void close() {
        // Cleanup if needed
    }

    @Override
    public String getId() {
        return PROVIDER_ID;
    }
}
```

### Step 3: Register the Provider

Create `META-INF/services/org.keycloak.authentication.AuthenticatorFactory`:

```
com.example.keycloak.authenticator.CustomAuthenticatorFactory
```

## Form-Based Authenticator

### Rendering a Custom Form

```java
package com.example.keycloak.authenticator;

import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.forms.login.LoginFormsProvider;
import org.keycloak.models.UserModel;
import javax.ws.rs.core.MultivaluedMap;
import javax.ws.rs.core.Response;

public class FormAuthenticator implements Authenticator {

    @Override
    public void authenticate(AuthenticationFlowContext context) {
        // Render custom form
        LoginFormsProvider forms = context.form();

        Response form = forms.createForm("custom-form.ftl")
            .setAttribute("customData", "Hello from custom authenticator")
            .createForm();

        context.challenge(form);
    }

    @Override
    public void action(AuthenticationFlowContext context) {
        // Process form submission
        MultivaluedMap<String, String> formData = context.getHttpRequest()
            .getDecodedFormParameters();

        String customField = formData.getFirst("custom_field");

        // Validate input
        if (isValid(customField, context)) {
            context.success();
        } else {
            Response form = context.form()
                .setError("Invalid input")
                .createForm("custom-form.ftl");
            context.challenge(form);
        }
    }

    private boolean isValid(String value, AuthenticationFlowContext context) {
        // Custom validation logic
        return value != null && !value.isEmpty();
    }

    // ... other interface methods
}
```

### Custom FreeMarker Template

Create `resources/theme-resources/custom-form.ftl`:

```html
<template name="custom-form.ftl">
    <div class="pf-c-login__main-body">
        <h1>Custom Authentication</h1>

        <#if message?has_content>
            <div class="alert alert-danger">${message.summary}</div>
        </#if>

        <form method="post" action="${url.loginAction}">
            <div class="form-group">
                <label for="custom_field">Custom Field</label>
                <input type="text"
                       id="custom_field"
                       name="custom_field"
                       class="form-control"
                       value="${customData!''}"
                       required>
            </div>

            <div class="form-group">
                <button type="submit" class="btn btn-primary">
                    Submit
                </button>
            </div>
        </form>
    </div>
</template>
```

## Conditional Authenticator

A conditional authenticator controls whether other authenticators execute based on conditions.

```java
package com.example.keycloak.authenticator;

import org.keycloak.authentication.Authenticator;
import org.keycloak.authentication.authenticators.conditional.ConditionalAuthenticator;
import org.keycloak.authentication.AuthenticatorFactory;
import org.keycloak.models.*;
import java.util.Map;

public class ConditionalAuthenticator implements ConditionalAuthenticator {

    @Override
    public boolean matchCondition(AuthenticatorFlowContext context) {
        UserModel user = context.getUser();
        RealmModel realm = context.getRealm();

        // Condition: only for users with specific role
        return user != null && user.hasRealmRole("premium-user");
    }

    @Override
    public void action(AuthenticatorFlowContext context) {
        context.success();
    }

    @Override
    public boolean requiresUser() {
        return true;
    }

    @Override
    public void close() {
        // Cleanup
    }

    public static class Factory
            implements AuthenticatorFactory {

        public static final String PROVIDER_ID = "conditional-premium";

        // ... factory methods
    }
}
```

## Configuration Options

### Adding Configurable Properties

```java
@Override
public List<ProviderConfigProperty> getConfigProperties() {
    return ProviderConfigurationBuilder.create()
        .property()
            .name("validationEndpoint")
            .label("Validation Endpoint")
            .helpText("URL of the external validation service")
            .type(ProviderConfigProperty.STRING_TYPE)
            .defaultValue("https://api.example.com/validate")
            .add()
        .property()
            .name("timeout")
            .label("Timeout (ms)")
            .helpText("Request timeout")
            .type(ProviderConfigProperty.STRING_TYPE)
            .defaultValue("5000")
            .add()
        .build();
}
```

### Accessing Configuration

```java
@Override
public void authenticate(AuthenticationFlowContext context) {
    AuthenticatorModel config = context.getAuthenticatorConfig();

    String endpoint = config.getConfig()
        .get("validationEndpoint");

    String timeout = config.getConfig()
        .get("timeout");

    // Use configuration
}
```

## Required Actions

Trigger required actions from authenticator:

```java
@Override
public void setRequiredActions(KeycloakSession session,
                                RealmModel realm,
                                UserModel user) {
    // Require user to update profile
    user.addRequiredAction("UPDATE_PROFILE");

    // Or require custom required action
    user.addRequiredAction("custom-required-action");
}

@Override
public void action(AuthenticationFlowContext context) {
    UserModel user = context.getUser();

    if (user.getRequiredActionsStream()
            .anyMatch("UPDATE_PASSWORD"::equals)) {
        // User needs to update password
        context.forceChallenge(
            context.form()
                .setExecution(context.getExecution().getId())
                .createPasswordReset()
        );
    }
}
```

## Building and Deployment

### Build the JAR

```bash
mvn clean package
```

Result: `target/custom-authenticator-1.0.0.jar`

### Deploy to Keycloak

**Option 1: Direct Deployment**

```bash
# Copy to providers directory
cp target/custom-authenticator-1.0.0.jar \
   /opt/keycloak/providers/

# Build Keycloak with provider
/opt/keycloak/bin/kc.sh build
```

**Option 2: Container Deployment**

```dockerfile
FROM quay.io/keycloak/keycloak:latest AS builder

# Copy provider
COPY target/custom-authenticator-1.0.0.jar \
     /opt/keycloak/providers/

# Build with provider
RUN /opt/keycloak/bin/kc.sh build

# Final image
FROM quay.io/keycloak/keycloak:latest
COPY --from=builder /opt/keycloak/ /opt/keycloak/
```

## Configuration in Admin Console

### 1. Register Authenticator

1. Navigate to **Authentication** → **Required Actions** (for required actions)
2. Or **Authentication** → **Flows** (for authenticators)
3. Click **New** to register

### 2. Configure Authentication Flow

1. Navigate to **Authentication** → **Flows**
2. Create new flow or edit existing
3. Add **Execution** with your authenticator
4. Set requirement (REQUIRED, ALTERNATIVE, DISABLED)

### 3. Bind Flow to Browser Flow

1. Go to **Authentication** → **Bindings**
2. Set **Browser Flow** to your custom flow
3. Click **Save**

## Testing

### Unit Testing

```java
import org.junit.Test;
import org.keycloak.models.KeycloakSession;
import static org.mockito.Mockito.*;

public class CustomAuthenticatorTest {

    @Test
    public void testAuthenticate() {
        KeycloakSession session = mock(KeycloakSession.class);
        CustomAuthenticator authenticator = new CustomAuthenticator();

        // Test logic
    }
}
```

### Integration Testing

1. Deploy to development Keycloak
2. Test via Admin Console
3. Create test user
4. Attempt login
5. Verify behavior

## Best Practices

1. **Error Handling**
   - Always handle exceptions
   - Provide user-friendly error messages
   - Log errors appropriately

2. **Security**
   - Validate all input
   - Sanitize data before display
   - Use secure connections for external calls
   - Don't log sensitive data

3. **Performance**
   - Cache external data when appropriate
   - Use connection pooling for external services
   - Set appropriate timeouts

4. **Testing**
   - Write unit tests
   - Test in development environment
   - Consider edge cases

5. **Documentation**
   - Document configuration options
   - Provide usage examples
   - Document error conditions

## Related Topics

- [[keycloak-required-action-spi]] - Required actions
- [[keycloak-registration-form]] - Registration customization
- [[keycloak-spi]] - General SPI information

## Additional Resources

- [Server Developer Guide](https://www.keycloak.org/docs/latest/server_development)
- [Understanding Keycloak SPIs](https://medium.com/@jaging4you/understanding-keycloak-spis)
- [Authenticator SPI Documentation](https://www.keycloak.org/docs/latest/server_development/#auth_spi_walkthrough)
