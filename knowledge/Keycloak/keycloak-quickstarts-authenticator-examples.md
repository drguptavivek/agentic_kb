---
title: Keycloak Quickstarts - Authenticator Examples from Official Repository
domain: Keycloak
type: tutorial
status: draft
tags: [keycloak, quickstarts, authenticator, spi, examples]
created: 2026-01-29
related: [[keycloak-authenticator-spi-walkthrough]], [[keycloak-required-action-spi]], [[keycloak-spi]]
---

# Keycloak Quickstarts - Authenticator Examples from Official Repository

## Overview

This guide covers the official Keycloak quickstarts for custom authenticators, providing real working examples you can reference when building your own authentication solutions.

## Official Quickstarts Repository

- **Repository:** [keycloak/keycloak-quickstarts](https://github.com/keycloak/keycloak-quickstarts)
- **Branch:** `main`
- **License:** Apache License 2.0

## Example 1: Secret Question Authenticator

**Level:** Beginner
**Summary:** Custom authenticator with cookie-based device memory
**Source:** `extension/authenticator`

### What It Does

This example implements a "secret question" authenticator that:
- Prompts users to answer a secret question when logging in from a new device
- Remembers devices using a cookie (30 days default)
- Integrates with Keycloak's credential provider SPI
- Includes a required action for question setup

### Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Authentication Flow                             │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  1. User logs in                                            │
│     │                                                        │
│     ▼                                                        │
│  2. Check for SECRET_QUESTION_ANSWERED cookie                 │
│     │                                                        │
│     ├─ Has cookie → Skip question, authenticate              │
│     │                                                        │
│     └─ No cookie → Show secret question form                 │
│                    │                                         │
│                    ▼                                         │
│  3. User answers question                                   │
│     │                                                        │
│     ├─ Correct → Set cookie, authenticate                   │
│     │                                                        │
│     └─ Incorrect → Show error, retry                         │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

#### 1. SecretQuestionAuthenticator.java

```java
public class SecretQuestionAuthenticator
        implements Authenticator, CredentialValidator<SecretQuestionCredentialProvider> {

    @Override
    public void authenticate(AuthenticationFlowContext context) {
        // Check if user already answered on this device
        if (hasCookie(context)) {
            context.success();
            return;
        }

        // Show secret question form
        Response challenge = context.form()
                .createForm("secret-question.ftl");
        context.challenge(challenge);
    }

    @Override
    public void action(AuthenticationFlowContext context) {
        // Validate the answer
        boolean validated = validateAnswer(context);
        if (!validated) {
            Response challenge = context.form()
                    .setError("badSecret")
                    .createForm("secret-question.ftl");
            context.failureChallenge(AuthenticationFlowError.INVALID_CREDENTIALS, challenge);
            return;
        }

        // Set remember cookie
        setCookie(context);
        context.success();
    }

    protected boolean hasCookie(AuthenticationFlowContext context) {
        Cookie cookie = context.getHttpRequest().getHttpHeaders()
            .getCookies().get("SECRET_QUESTION_ANSWERED");
        return cookie != null;
    }

    protected void setCookie(AuthenticationFlowContext context) {
        int maxCookieAge = 60 * 60 * 24 * 30; // 30 days
        URI uri = context.getUriInfo().getBaseUriBuilder()
            .path("realms")
            .path(context.getRealm().getName())
            .build();

        NewCookie newCookie = new NewCookie.Builder("SECRET_QUESTION_ANSWERED")
                .value("true")
                .path(uri.getRawPath())
                .maxAge(maxCookieAge)
                .secure(false)
                .build();
        context.getSession().getContext()
            .getHttpResponse()
            .setCookieIfAbsent(newCookie);
    }

    protected boolean validateAnswer(AuthenticationFlowContext context) {
        MultivaluedMap<String, String> formData =
            context.getHttpRequest().getDecodedFormParameters();
        String secret = formData.getFirst("secret_answer");

        // Use credential provider to validate
        UserCredentialModel input = new UserCredentialModel(
            credentialId,
            getType(context.getSession()),
            secret
        );
        return getCredentialProvider(context.getSession())
            .isValid(context.getRealm(), context.getUser(), input);
    }
}
```

#### 2. SecretQuestionAuthenticatorFactory.java

```java
public class SecretQuestionAuthenticatorFactory
        implements AuthenticatorFactory, ConfigurableAuthenticatorFactory {

    public static final String PROVIDER_ID = "secret-question-authenticator";
    private static final SecretQuestionAuthenticator SINGLETON =
        new SecretQuestionAuthenticator();

    @Override
    public String getId() {
        return PROVIDER_ID;
    }

    @Override
    public Authenticator create(KeycloakSession session) {
        return SINGLETON;
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
    public boolean isConfigurable() {
        return true;
    }

    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        return configProperties;
    }

    private static final List<ProviderConfigProperty> configProperties =
        new ArrayList<>();

    static {
        ProviderConfigProperty property = new ProviderConfigProperty();
        property.setName("cookie.max.age");
        property.setLabel("Cookie Max Age");
        property.setType(ProviderConfigProperty.STRING_TYPE);
        property.setHelpText("Max age in seconds of the SECRET_QUESTION_COOKIE.");
        configProperties.add(property);
    }

    @Override
    public String getHelpText() {
        return "A secret question that a user has to answer. i.e. What is your mother's maiden name.";
    }

    @Override
    public String getDisplayType() {
        return "Secret Question";
    }
}
```

### Key Implementation Details

#### Cookie-Based Device Memory

The example uses a simple cookie approach to remember devices:

```java
protected boolean hasCookie(AuthenticationFlowContext context) {
    Cookie cookie = context.getHttpRequest().getHttpHeaders()
        .getCookies().get("SECRET_QUESTION_ANSWERED");
    boolean result = cookie != null;
    if (result) {
        System.out.println("Bypassing secret question because cookie is set");
    }
    return result;
}
```

**Security Considerations:**
- Cookie not marked as `secure` (HTTP allowed)
- Cookie max age configurable
- Cookie path limited to realm

#### Credential Provider Integration

The authenticator implements `CredentialValidator` to integrate with Keycloak's credential system:

```java
@Override
public boolean configuredFor(KeycloakSession session,
                              RealmModel realm,
                              UserModel user) {
    return getCredentialProvider(session)
        .isConfiguredFor(realm, user, getType(session));
}

@Override
public void setRequiredActions(KeycloakSession session,
                                RealmModel realm,
                                UserModel user) {
    user.addRequiredAction(SecretQuestionRequiredAction.PROVIDER_ID);
}
```

### Build and Deploy

```bash
# Build the provider
mvn -Pextension clean install -DskipTests=true

# Copy to providers directory
cp target/authenticator-example.jar /opt/keycloak/providers/

# Build Keycloak with provider
/opt/keycloak/bin/kc.sh build

# Start Keycloak
/opt/keycloak/bin/kc.sh start-dev
```

### Configuration in Admin Console

1. **Create Custom Flow**
   - Authentication → Flows
   - Select `browser` flow
   - Action → Duplicate
   - Name: `Copy of browser`

2. **Add Authenticator**
   - In new flow, find `Copy of browser forms`
   - Click `+` → Add step
   - Search for `secret`
   - Select `Secret question`
   - Set requirement to `Required`

3. **Bind Flow**
   - Action → Bind flow
   - Binding type: `Browser flow`
   - Save

4. **Enable Required Action**
   - Authentication → Required actions
   - Enable `Secret Question`

## Example 2: External Application Authenticator

**Level:** Intermediate
**Summary:** Integration with external application using action tokens
**Source:** `extension/action-token-authenticator`

### What It Does

This example demonstrates:
1. **Authentication with external application**
   - Redirects user to external app during authentication
   - User performs action in external app
   - Returns to Keycloak with token

2. **Action Token Pattern**
   - Creates time-limited action token
   - Token encodes authentication session info
   - External app signs and returns token

3. **Claims Synchronization**
   - External app sets user attributes
   - Claims synchronized back to Keycloak

### Architecture Flow

```
┌──────────────────────────────────────────────────────────────┐
│         External Application Authentication Flow               │
├──────────────────────────────────────────────────────────────┤
│                                                                │
│  User                                                      Keycloak            External App              │
│   │                                                         │    │
│   │────────Login─────────────────────────────────────>      │    │
│   │                                                         │    │
│   │<─────────Action Token────────────────────────────────    │    │
│   │                                                         │    │
│   │────────────────Redirect to External App──────────────>    │    │
│   │                                                         │    │
│   │                                                  Fill Form   │
│   │                                                         │    │
│   │<────────────────Signed Token────────────────────────────    │    │
│   │                                                         │    │
│   └─────────────────Return to Keycloak───────────────>      │    │
│                  │                                         │    │
│                  ▼                                         │    │
│            Validate Token                                  │    │
│                  │                                         │    │
│                  ▼                                         │    │
│           Update User Attributes                              │    │
│                  │                                         │    │
│                  ▼                                         │    │
│            Authentication Complete                          │    │
│                                                                │
└──────────────────────────────────────────────────────────────┘
```

### Key Implementation Details

#### ExternalAppAuthenticator.java

```java
public class ExternalAppAuthenticator implements Authenticator {

    public static final String DEFAULT_EXTERNAL_APP_URL =
        "http://127.0.0.1:8080/action-token-responder-example/external-action.jsp?token={TOKEN}";

    public static final String DEFAULT_APPLICATION_ID = "application-id";

    @Override
    public void authenticate(AuthenticationFlowContext context) {
        String externalApplicationUrl = context.getAuthenticatorConfig()
            ?.getConfig()
            ?.get("externalAppUrl")
            ?: DEFAULT_EXTERNAL_APP_URL;

        String applicationId = context.getAuthenticatorConfig()
            ?.getConfig()
            ?.get("applicationId")
            ?: DEFAULT_APPLICATION_ID;

        // Create action token for returning to the flow
        AuthenticationSessionModel authSession = context.getAuthenticationSession();
        int validityInSecs = context.getRealm()
            .getActionTokenGeneratedByUserLifespan();
        int absoluteExpirationInSecs = Time.currentTime() + validityInSecs;

        String token = new ExternalApplicationNotificationActionToken(
            context.getUser().getId(),
            absoluteExpirationInSecs,
            authSession.getParentSession().getId(),
            applicationId
        ).serialize(context.getSession(), context.getRealm(), context.getUriInfo());

        // Build URL for external app to submit action token
        String submitActionTokenUrl = Urls
            .actionTokenBuilder(
                context.getUriInfo().getBaseUri(),
                token,
                authSession.getClient().getClientId(),
                authSession.getTabId(),
                ""
            )
            .queryParam(Constants.EXECUTION, context.getExecution().getId())
            .queryParam("{APP_TOKEN}", "{tokenParameterName}")
            .build(context.getRealm().getName(), "{APP_TOKEN}")
            .toString();

        // Redirect to external application
        try {
            Response challenge = Response
                .status(Status.FOUND)
                .header("Location",
                    externalApplicationUrl.replace("{TOKEN}",
                        URLEncoder.encode(submitActionTokenUrl, "UTF-8")))
                .build();
            context.challenge(challenge);
        } catch (UnsupportedEncodingException ex) {
            throw new RuntimeException(ex);
        }
    }

    @Override
    public void action(AuthenticationFlowContext context) {
        // Check if initiated by action token return
        AuthenticationSessionModel authSession = context.getAuthenticationSession();
        if (!Objects.equals(
            authSession.getAuthNote(
                ExternalApplicationNotificationActionTokenHandler
                    .INITIATED_BY_ACTION_TOKEN_EXT_APP),
            "true"
        )) {
            authenticate(context);
            return;
        }

        authSession.removeAuthNote(
            ExternalApplicationNotificationActionTokenHandler
                .INITIATED_BY_ACTION_TOKEN_EXT_APP);

        // Extract app token and update user attributes
        String appTokenString = context.getUriInfo()
            .getQueryParameters()
            .getFirst(QUERY_PARAM_APP_TOKEN);

        UserModel user = authSession.getAuthenticatedUser();
        String applicationId = context.getAuthenticatorConfig()
            ?.getConfig()
            ?.get("applicationId")
            ?: DEFAULT_APPLICATION_ID;

        try {
            JsonWebToken appToken = TokenVerifier
                .create(appTokenString, JsonWebToken.class)
                .getToken();

            // Set user attributes from app token claims
            appToken.getOtherClaims().forEach((key, value) ->
                user.setAttribute(applicationId + "." + key,
                    Collections.singletonList(String.valueOf(value)))
            );
        } catch (VerificationException ex) {
            logger.error("Error handling action token", ex);
            context.failure(AuthenticationFlowError.INTERNAL_ERROR,
                context.form()
                    .setError(Messages.INVALID_PARAMETER)
                    .createErrorPage(Status.INTERNAL_SERVER_ERROR));
        }

        context.success();
    }
}
```

### Action Token Structure

The action token encodes:
- **User ID:** The authenticating user
- **Expiration:** Token validity period
- **Parent Session ID:** For session continuity
- **Application ID:** Identifies the external app

### Build and Deploy

```bash
# Build the provider
mvn -Pextension clean install

# Deploy
cp target/action-token-example.jar /opt/keycloak/providers/

# Start with HMAC secret for action token verification
kc.sh start-dev --http-port=8180 \
  --spi-action-token-handler--external-app-notification--hmac-secret=aSqzP4reFgWR4j94BDT1r+81QYp/NYbY9SBwXtqV1ko=
```

### Configuration Options

| Config Property | Description | Default |
|-----------------|-------------|---------|
| `externalAppUrl` | URL of external application | `http://127.0.0.1:8080/...` |
| `applicationId` | Identifier for external app | `application-id` |

### Security Considerations

#### Action Token Security

1. **HMAC Secret:** Must be configured and kept secret
2. **Token Lifespan:** Limited by realm configuration
3. **Token Verification:** Signature verification required
4. **URL Encoding:** Tokens URL-encoded when passed

#### Production Recommendations

```bash
# Use secure configuration properties instead of command-line
# in production

# conf/keycloak.conf
spi-action-token-handler-external-app-notification-hmac-secret=${HC_SECRET}

# Or use Keycloak Vault for secrets
```

## Quickstart Comparison

| Aspect | Secret Question | External Application |
|---------|----------------|----------------------|
| **Level** | Beginner | Intermediate |
| **Use Case** | Device memory | External app integration |
| **Flow Type** | Inline authentication | Redirect to external |
| **State Management** | Cookie-based | Action token |
| **External Dependencies** | None | External app server |
| **Security** | Simple cookie | HMAC verification |

## Common Patterns

### Pattern 1: Cookie-Based Remember Device

```java
protected boolean hasCookie(AuthenticationFlowContext context) {
    Cookie cookie = context.getHttpRequest().getHttpHeaders()
        .getCookies().get("DEVICE_REMEMBERED");
    return cookie != null;
}

protected void setRememberCookie(AuthenticationFlowContext context) {
    NewCookie cookie = new NewCookie.Builder("DEVICE_REMEMBERED")
        .value(context.getUser().getId())
        .path("/realms/" + context.getRealm().getName())
        .maxAge(60 * 60 * 24 * 30)  // 30 days
        .httpOnly(true)
        .secure(context.getUriInfo().getBaseUri().getScheme().equals("https"))
        .build();
    context.getSession().getContext()
        .getHttpResponse()
        .setCookieIfAbsent(cookie);
}
```

### Pattern 2: External Redirect with Token

```java
// Generate action token
String token = new CustomActionToken(
    context.getUser().getId(),
    Time.currentTime() + validityInSecs,
    context.getAuthenticationSession().getParentSession().getId()
).serialize(context.getSession(), context.getRealm(), context.getUriInfo());

// Build return URL
String returnURL = Urls
    .actionTokenBuilder(baseUri, token, clientId, tabId, "")
    .queryParam(Constants.EXECUTION, executionId)
    .build(realm.getName(), reference)
    .toString();

// Redirect to external app
Response challenge = Response
    .status(Status.FOUND)
    .header("Location", externalAppUrl + "?token=" +
        URLEncoder.encode(returnURL, "UTF-8"))
    .build();
context.challenge(challenge);
```

### Pattern 3: Credential Provider Integration

```java
@Override
public boolean configuredFor(KeycloakSession session,
                              RealmModel realm,
                              UserModel user) {
    return getCredentialProvider(session)
        .isConfiguredFor(realm, user, getType(session));
}

protected boolean validateAnswer(AuthenticationFlowContext context) {
    String answer = context.getHttpRequest()
        .getDecodedFormParameters()
        .getFirst("secret_answer");

    UserCredentialModel input = new UserCredentialModel(
        credentialId,
        getType(context.getSession()),
        answer
    );

    return getCredentialProvider(context.getSession())
        .isValid(context.getRealm(), context.getUser(), input);
}
```

## Form Templates

### Secret Question Form (secret-question.ftl)

```html
<div class="pf-c-login__main-body">
    <h1>Secret Question Verification</h1>

    <p>Please answer your secret question to continue.</p>

    <#if message?has_content && message.type == 'error'>
        <div class="alert alert-error">
            <span class="pficon pficon-error-circle-o"></span>
            ${kcSanitize(message.summary)?no_esc}
        </div>
    </#if>

    <form id="kc-secret-question-form"
          action="${url.loginAction}"
          method="post">

        <div class="form-group">
            <label for="secret_answer">
                ${msg("secretQuestionAnswer")}
            </label>
            <input type="text"
                   id="secret_answer"
                   name="secret_answer"
                   class="form-control"
                   required
                   autofocus>
        </div>

        <div class="form-group">
            <button type="submit" class="btn btn-primary">
                ${msg("doSubmit")}
            </button>
        </div>
    </form>
</div>
```

## Building Your Own Authenticator

### Step 1: Choose Your Pattern

1. **Form-based inline authentication** (like Secret Question)
   - Simple user interaction
   - No external dependencies
   - Cookie or session-based state

2. **External redirect authentication** (like External App)
   - Integration with external systems
   - Complex user workflows
   - Action token pattern

3. **Conditional authentication**
   - Risk-based authentication
   - Step-up authentication
   - Context-aware flows

### Step 2: Extend the Right Interfaces

```java
// For simple form-based
public class MyAuthenticator implements Authenticator

// For credential integration
public class MyAuthenticator
    implements Authenticator, CredentialValidator<MyCredentialProvider>

// For conditional logic
public class MyConditionalAuthenticator
    implements ConditionalAuthenticator

// For external redirects
public class MyAuthenticator implements Authenticator {
    @Override
    public void authenticate(AuthenticationFlowContext context) {
        // Create action token and redirect
    }

    @Override
    public void action(AuthenticationFlowContext context) {
        // Handle return from external app
    }
}
```

### Step 3: Implement Required Methods

```java
@Override
public void authenticate(AuthenticationFlowContext context) {
    // Your authentication logic
    // - Check conditions
    // - Show challenge or succeed
    context.challenge(context.form().createForm("my-form.ftl"));
    // or
    context.success();
    // or
    context.failure(AuthenticationFlowError.INVALID_CREDENTIALS);
}

@Override
public void action(AuthenticationFlowContext context) {
    // Process form submission
    // Validate input
    // Update state
    context.success();
}

@Override
public boolean requiresUser() {
    return true;  // or false for registration
}

@Override
public boolean configuredFor(KeycloakSession session,
                              RealmModel realm,
                              UserModel user) {
    // Check if configured for this user
    return true;
}
```

### Step 4: Create Factory

```java
public class MyAuthenticatorFactory implements AuthenticatorFactory {

    public static final String PROVIDER_ID = "my-authenticator";

    @Override
    public String getId() {
        return PROVIDER_ID;
    }

    @Override
    public Authenticator create(KeycloakSession session) {
        return new MyAuthenticator();
    }

    @Override
    public String getDisplayType() {
        return "My Authenticator";
    }

    @Override
    public String getHelpText() {
        return "Description of what this authenticator does";
    }
}
```

### Step 5: Register Provider

Create `META-INF/services/org.keycloak.authentication.AuthenticatorFactory`:

```
com.example.MyAuthenticatorFactory
```

## Testing Your Authenticator

### Unit Test Structure

```java
public class MyAuthenticatorTest {

    @Test
    public void testSuccessfulAuthentication() {
        // Set up mock context
        AuthenticationFlowContext context = mockContext();

        // Execute
        myAuthenticator.authenticate(context);

        // Verify
        verify(context).challenge(any(Response.class));
    }

    @Test
    public void testSuccessfulAction() {
        // Set up context with form data
        AuthenticationFlowContext context = mockContextWithData();

        // Execute
        myAuthenticator.action(context);

        // Verify
        verify(context).success();
    }
}
```

### Integration Test Steps

1. Deploy provider to Keycloak
2. Configure authentication flow
3. Test in browser
4. Verify cookie/token behavior
5. Test error conditions

## Troubleshooting

### Authenticator Not Showing

```bash
# Check if provider is loaded
kcadm.sh get realms/REALM/authentication/registrations \
  -r REALM

# Check if factory is registered
kcadm.sh get authentication/registrations \
  -r REALM | grep PROVIDER_ID
```

### Cookie Not Being Set

```java
// Add logging
System.out.println("Setting cookie for realm: " +
    context.getRealm().getName());
System.out.println("Cookie path: " + uri.getRawPath());

// Verify cookie configuration
// - Is path correct?
// - Is secure flag appropriate?
// - Is domain correct?
```

### Action Token Verification Failing

```bash
# Verify HMAC secret matches
kcadm.sh get realms/REALM \
  -r REALM | grep hmac-secret

# Check action token handler logs
# Look for verification errors
```

## Related Topics

- [[keycloak-authenticator-spi-walkthrough]] - Complete SPI guide
- [[keycloak-required-action-spi]] - Required actions
- [[keycloak-spi]] - General SPI information

## Additional Resources

- [Keycloak Quickstarts Repository](https://github.com/keycloak/keycloak-quickstarts)
- [Secret Question Authenticator](https://github.com/keycloak/keycloak-quickstarts/tree/main/extension/authenticator)
- [External Application Authenticator](https://github.com/keycloak/keycloak-quickstarts/tree/main/extension/action-token-authenticator)
- [Server Developer Guide](https://www.keycloak.org/docs/latest/server_development)
