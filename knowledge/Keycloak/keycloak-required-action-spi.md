---
title: Keycloak Required Action SPI Walkthrough
domain: Keycloak
type: tutorial
status: draft
tags: [keycloak, spi, required-action, development, user-onboarding]
created: 2026-01-29
related: [[keycloak-authenticator-spi-walkthrough]], [[keycloak-registration-form]], [[keycloak-spi]]
---

# Keycloak Required Action SPI Walkthrough

## Overview

A **Required Action** in Keycloak is an action that a user must perform after authentication but before completing the login flow. Common examples include:
- Password reset
- Email verification
- Terms acceptance
- Profile completion
- 2FA setup

## Required Action vs Authenticator

| Aspect | Required Action | Authenticator |
|--------|----------------|--------------|
| **Timing** | After authentication | During authentication |
| **User State** | User exists | User may not exist |
| **Purpose** | Complete user setup | Validate credentials |
| **Frequency** | One-time per action | Every login |
| **Flow** | Part of authentication flow | Separate authentication step |

## Creating a Custom Required Action

### Step 1: Implement RequiredActionProvider

```java
package com.example.keycloak.requiredaction;

import org.keycloak.models.UserModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.provider.ProviderConfigProperty;
import org.keycloak.provider.ProviderConfigurationBuilder;
import org.keycloak.authentication.RequiredActionContext;
import org.keycloak.authentication.RequiredActionFactory;
import org.keycloak.authentication.RequiredActionProvider;

import javax.ws.rs.core.Response;
import java.util.List;

public class CustomRequiredActionProvider
        implements RequiredActionProvider {

    public static final String PROVIDER_ID = "custom-required-action";

    @Override
    public void evaluateRequiredActions(RequiredActionContext context) {
        // Check if action is already completed
        UserModel user = context.getUser();
        String attribute = user.getFirstAttribute("customActionCompleted");

        if ("true".equals(attribute)) {
            // Action already completed
            context.success();
            return;
        }

        // Show the required action form
        Response form = context.form()
            .createForm("custom-action.ftl");
        context.challenge(form);
    }

    @Override
    public void requiredActionChallenge(RequiredActionContext context) {
        // Render the challenge form
        Response form = context.form()
            .createForm("custom-action.ftl");
        context.challenge(form);
    }

    @Override
    public void processAction(RequiredActionContext context) {
        // Process form submission
        String inputValue = context.getHttpRequest()
            .getDecodedFormParameters()
            .getFirst("custom_input");

        if (isValid(inputValue)) {
            // Mark action as completed
            UserModel user = context.getUser();
            user.setSingleAttribute("customActionCompleted", "true");
            user.removeRequiredAction(PROVIDER_ID);

            context.success();
        } else {
            // Show error and re-challenge
            Response form = context.form()
                .setError("Invalid input")
                .createForm("custom-action.ftl");
            context.challenge(form);
        }
    }

    private boolean isValid(String value) {
        return value != null && !value.isEmpty() && value.length() >= 8;
    }

    @Override
    public void close() {
        // Cleanup if needed
    }

    @Override
    public RequiredActionProvider create(KeycloakSession session) {
        return this;
    }

    @Override
    public String getId() {
        return PROVIDER_ID;
    }

    @Override
    public String getDisplayText() {
        return "Custom Required Action";
    }

    @Override
    public boolean isOneTimeAction() {
        // If true, action is removed after completion
        // If false, user can be required to do it again
        return true;
    }

    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        // No configuration for this example
        return null;
    }

    @Override
    public void init(org.keycloak.provider.Config.Scope config) {
        // Initialization if needed
    }

    @Override
    public void postInit(org.keycloak.provider.Config.Scope config) {
        // Post-initialization if needed
    }
}
```

### Step 2: Create RequiredActionFactory

```java
package com.example.keycloak.requiredaction;

import org.keycloak.authentication.RequiredActionFactory;
import org.keycloak.models.KeycloakSession;
import org.keycloak.provider.ProviderConfigProperty;
import org.keycloak.provider.ProviderConfigurationBuilder;
import org.keycloak.authentication.RequiredActionProvider;

import java.util.List;

public class CustomRequiredActionFactory
        implements RequiredActionFactory {

    @Override
    public String getId() {
        return CustomRequiredActionProvider.PROVIDER_ID;
    }

    @Override
    public String getDisplayText() {
        return "Custom Required Action";
    }

    @Override
    public String getHelpText() {
        return "A custom required action example that requires users to complete a specific task";
    }

    @Override
    public boolean isOneTimeAction() {
        return true;
    }

    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        // Add configuration if needed
        return ProviderConfigurationBuilder.create()
            .property()
                .name("minLength")
                .label("Minimum Length")
                .helpText("Minimum length for the input")
                .type(ProviderConfigProperty.STRING_TYPE)
                .defaultValue("8")
                .add()
            .build();
    }

    @Override
    public RequiredActionProvider create(KeycloakSession session) {
        return new CustomRequiredActionProvider();
    }

    @Override
    public void init(org.keycloak.provider.Config.Scope config) {
        // Initialize if needed
    }

    @Override
    public void postInit(org.keycloak.provider.Config.Scope config) {
        // Post-initialize if needed
    }

    @Override
    public void close() {
        // Cleanup if needed
    }
}
```

### Step 3: Register the Provider

Create `META-INF/services/org.keycloak.authentication.RequiredActionFactory`:

```
com.example.keycloak.requiredaction.CustomRequiredActionFactory
```

## Creating the Form Template

### Basic Form Template

Create `resources/theme-resources/custom-action.ftl`:

```html
<template name="custom-action.ftl">
    <div class="pf-c-login__main-body">
        <div class="pf-c-login__main-header">
            <h1>Complete Your Profile</h1>
            <p>Please complete the following required action</p>
        </div>

        <#if message?has_content && message.type == 'error'>
            <div class="alert alert-danger">
                <span class="pficon pficon-error-circle-o"></span>
                ${message.summary}
            </div>
        <#elseif message?has_content && message.type == 'success'>
            <div class="alert alert-success">
                <span class="pficon pficon-ok"></span>
                ${message.summary}
            </div>
        </#if>

        <form id="kc-custom-form" class="${properties.kcFormClass!''}"
              action="${url.loginAction}"
              method="post">

            <div class="form-group">
                <label for="custom_input" class="${properties.kcLabelClass!''}">
                    Enter Your Details
                </label>

                <input type="text"
                       id="custom_input"
                       name="custom_input"
                       class="form-control ${properties.kcInputClass!''}"
                       placeholder="Enter at least 8 characters"
                       required
                       autofocus
                       value="${custom_input?default_value!''}">

                <#if properties.inputHelpText??>
                    <p class="help-block">${properties.inputHelpText}</p>
                </#if>
            </div>

            <div class="form-group ${properties.kcFormButtonsClass!''}">
                <button type="submit"
                        class="${properties.kcButtonClass!''} ${properties.kcButtonPrimaryClass!''}">
                    Submit
                </button>

                <button type="submit"
                        name="cancel"
                        value="true"
                        class="${properties.kcButtonClass!''}">
                    Cancel
                </button>
            </div>
        </form>

        <script type="module">
            // Add custom JavaScript if needed
            const form = document.getElementById('kc-custom-form');
            form.addEventListener('submit', function(e) {
                const input = document.getElementById('custom_input');
                if (input.value.length < 8) {
                    e.preventDefault();
                    alert('Input must be at least 8 characters');
                }
            });
        </script>
    </div>
</template>
```

### Terms Acceptance Example

```html
<template name="terms-acceptance.ftl">
    <div class="pf-c-login__main-body">
        <h1>Terms and Conditions</h1>

        <div class="terms-content" style="max-height: 300px; overflow-y: auto; padding: 15px; border: 1px solid #ccc; margin-bottom: 15px;">
            <h2>Terms of Service</h2>
            <p>Lorem ipsum dolor sit amet, consectetur adipiscing elit.</p>
            <p>1. By using this service, you agree to our terms...</p>
            <p>2. You will not misuse the service...</p>
            <p>3. Your data will be handled according to our privacy policy...</p>
        </div>

        <form action="${url.loginAction}" method="post">
            <div class="form-group">
                <label class="checkbox-label">
                    <input type="checkbox"
                           name="terms_accepted"
                           value="true"
                           required>
                    I have read and agree to the Terms and Conditions
                </label>
            </div>

            <div class="form-group">
                <button type="submit" class="btn btn-primary">
                    Accept & Continue
                </button>

                <button type="submit"
                        name="cancel"
                        value="true"
                        class="btn btn-default">
                    Decline
                </button>
            </div>
        </form>
    </div>
</template>
```

## Built-in Required Actions

Keycloak includes several built-in required actions available out of the box:

| Provider ID | Display Name | Purpose | One-Time |
|------------|-------------|---------|---------|
| `UPDATE_PROFILE` | Update Profile | User must update profile information | No |
| `UPDATE_PASSWORD` | Update Password | User must change password | No |
| `VERIFY_EMAIL` | Verify Email | User must verify email address | Yes |
| `CONFIGURE_TOTP` | Configure TOTP | User must set up 2FA with authenticator app | No |
| `TERMS_AND_CONDITIONS` | Terms and Conditions | User must accept terms | No |
| `UPDATE_USER_LOCALE` | Update User Locale | User must set preferred language | No |
| `webauthn-register` | Register Webauthn | User must register a passkey | Yes |
| `webauthn-passwordless` | Passwordless Authentication | User registers for passwordless auth | Yes |
| `recovery-authentication-code` | Recovery Codes | User must save recovery codes | No |
| `delete_account` | Delete Account | User confirms account deletion | No |
| `update_email` | Update Email | User must update email address | No |

### Built-in Required Actions Details

#### UPDATE_PROFILE

**Provider ID:** `UPDATE_PROFILE`

Forces users to complete missing profile information. Works with User Profile feature to validate:
- Required attributes (must be populated)
- Attribute validation rules
- Context-based requirements (user/admin)

**Configuration:**
- Enabled by default for new users if required attributes exist
- Configured in Realm Settings → User Profile → Attributes

**When Triggered:**
- User has null or empty required attributes
- Authenticator calls `user.addRequiredAction("UPDATE_PROFILE")`
- Admin manually adds to user

**User Experience:**
- Shown profile update form with all required fields
- Validation happens on form submission
- User cannot bypass without completing

#### VERIFY_EMAIL

**Provider ID:** `VERIFY_EMAIL`

Ensures user has a verified email address before granting access.

**Configuration:**
- Requires email to be set on user
- Verification email sent with time-limited code
- Code validity period configurable per realm

**When Triggered:**
- User's email is not verified
- Authenticator requires verified email
- Admin adds to user manually

**API Configuration:**
```bash
# Verify email lifespan (default: 43200 seconds = 12 hours)
kcadm.sh update realms/REALM \
  -s 'userAction="VERIFY_EMAIL",userAction.lifespan=86400' \
  -r REALM
```

#### CONFIGURE_TOTP

**Provider ID:** `CONFIGURE_TOTP`

Sets up time-based one-time password for 2FA.

**Requirements:**
- Authenticator app on user's device
- Scan QR code or enter manual code
- Backup codes generated automatically

**When Triggered:**
- Realm requires 2FA
- Authenticator enforces OTP requirement
- User enables 2FA for account

**Related Flows:**
- Reset Credentials flow
- Browser flow
- Registration flow

#### UPDATE_PASSWORD

**Provider ID:** `UPDATE_PASSWORD`

Forces user to change password before continuing.

**Common Use Cases:**
- Password expiration policy
- Compromised password reset
- First-time login (temporary password)
- Periodic password rotation

**Password Requirements:**
- Enforces realm password policy
- Must meet complexity rules
- Cannot reuse recent passwords (if configured)

#### webauthn-register

**Provider ID:** `webauthn-register`

Registers a passkey (WebAuthn credential) for passwordless authentication.

**Requirements:**
- WebAuthn-supported browser
- Authenticator device (security key, biometric)
- User must authenticate with existing credential first

**When Triggered:**
- User opts into passwordless authentication
- Admin adds to user
- Part of step-up authentication strategy

#### Terms and Conditions

**Provider ID:** `TERMS_AND_CONDITIONS`

Requires user to accept terms of service before proceeding.

**Configuration:**
- Terms content can be localized
- Supports Markdown formatting
- Can require explicit acceptance per session

**Configuration in Realm:**
```bash
# Terms version
kcadm.sh update realms/REALM \
  -s 'userAction="TERMS_AND_CONDITIONS",userAction.content=terms_v1.md' \
  -r REALM
```

#### Recovery Codes

**Provider ID:** `recovery-authentication-code`

Generates backup recovery codes for account recovery (e.g., if 2FA lost).

**Configuration:**
- Number of codes: 16 (default)
- Code length: 8 characters (default)
- Generated when enabling 2FA

**User Experience:**
- Codes displayed one time only
- User must save codes securely
- Can be used to disable 2FA without authenticator

## Common Required Action Patterns

## Programmatic Usage

### Trigger Required Action from Authenticator

```java
@Override
public void setRequiredActions(KeycloakSession session,
                                RealmModel realm,
                                UserModel user) {
    user.addRequiredAction("custom-required-action");
}

@Override
public void authenticate(AuthenticationFlowContext context) {
    UserModel user = context.getUser();

    // Check if required action is needed
    if (user.getRequiredActionsStream()
            .anyMatch("custom-required-action"::equals)) {
        // Will be redirected to required action
        context.forceChallenge(
            context.form()
                .setExecution(context.getExecution().getId())
        );
        return;
    }

    // Continue authentication
    context.success();
}
```

### Add Required Action via Admin API

```bash
# Add required action to user
curl -X PUT \
  http://localhost:8080/admin/realms/myrealm/users/$USER_ID/required-actions/custom-required-action \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

## Configuration in Admin Console

### Register Required Action

1. Navigate to **Authentication** → **Required Actions**
2. Click **New**
3. Select your custom required action
4. Set **Name** (default: factory display text)
5. Set as **Default** if needed

### Configure Flow

1. Go to **Authentication** → **Flows**
2. Edit or create a flow
3. Add execution with your required action
4. Set requirement level

## Testing

### Test via Admin Console

1. Create test user
2. Add required action to user
3. Login as test user
4. Complete required action
5. Verify action is removed

### Test via API

```bash
# Add required action
kcadm.sh update users/$USER_ID/required-actions/custom-required-action -r myrealm

# Check required actions
kcadm.sh get users/$USER_ID/required-actions -r myrealm

# Remove required action
kcadm.sh delete users/$USER_ID/required-actions/custom-required-action -r myrealm
```

## Best Practices

1. **User Experience**
   - Provide clear instructions
   - Show progress indicator
   - Allow users to save progress
   - Don't make actions too complex

2. **Error Handling**
   - Validate input thoroughly
   - Provide helpful error messages
   - Handle edge cases gracefully

3. **Security**
   - Validate all user input
   - Use CSRF tokens for forms
   - Sanitize output to prevent XSS
   - Log security-relevant events

4. **Accessibility**
   - Use semantic HTML
   - Provide proper labels
   - Support keyboard navigation
   - Ensure good contrast

5. **Testing**
   - Test with various user states
   - Test error conditions
   - Test accessibility
   - Test in different browsers

## Common Required Action Patterns

### Pattern 1: Attribute Validation

Validate that user has completed a specific task or attribute:

```java
public class AttributeValidationRequiredAction
        implements RequiredActionProvider {

    @Override
    public void evaluateRequiredActions(RequiredActionContext context) {
        UserModel user = context.getUser();
        String attribute = user.getFirstAttribute("agreementAccepted");

        if ("true".equals(attribute)) {
            context.success();
            return;
        }

        requiredActionChallenge(context);
    }

    @Override
    public void processAction(RequiredActionContext context) {
        MultivaluedMap<String, String> formData =
            context.getHttpRequest().getDecodedFormParameters();

        if ("true".equals(formData.getFirst("accept"))) {
            context.getUser().setSingleAttribute("agreementAccepted", "true");
            context.success();
        } else {
            context.challenge(context.form()
                .setError("You must accept to continue")
                .createForm("agreement.ftl"));
        }
    }
}
```

### Pattern 2: Time-Based Validation

Check if action was completed within a specific timeframe:

```java
public class TimeLimitedAction implements RequiredActionProvider {

    private static final String GRACE_PERIOD_DAYS_ATTR = "passwordChangedDays";

    @Override
    public void evaluateRequiredActions(RequiredActionContext context) {
        UserModel user = context.getUser();
        String daysAttr = user.getFirstAttribute(GRACE_PERIOD_DAYS_ATTR);

        if (daysAttr != null) {
            int daysSinceChange = Integer.parseInt(daysAttr);
            int gracePeriod = getGracePeriodDays(context);

            if (daysSinceChange < gracePeriod) {
                context.success();
                return;
            }
        }

        requiredActionChallenge(context);
    }

    @Override
    public void processAction(RequiredActionContext context) {
        // After password change, update the timestamp
        UserModel user = context.getUser();
        user.setSingleAttribute(GRACE_PERIOD_DAYS_ATTR, "0");
        context.success();
    }

    private int getGracePeriodDays(RequiredActionContext context) {
        return 90; // 90 days grace period
    }
}
```

### Pattern 3: External API Validation

Validate user against external service before allowing access:

```java
public class ExternalValidationAction implements RequiredActionProvider {

    private static final String EXTERNAL_API_URL =
        "https://api.example.com/validate/";

    @Override
    public void evaluateRequiredActions(RequiredActionContext context) {
        UserModel user = context.getUser();
        String validationStatus = user.getFirstAttribute("externalValidation");

        if ("valid".equals(validationStatus)) {
            context.success();
            return;
        }

        requiredActionChallenge(context);
    }

    @Override
    public void processAction(RequiredActionContext context) {
        UserModel user = context.getUser();
        String token = generateValidationToken(user);

        // Make API call to external service
        try {
            HttpResponse response = context.getSession().getProvider(HttpClient.class)
                .target(EXTERNAL_API_URL + "?token=" + token)
                .request();

            int status = response.getStatus();

            if (status == 200) {
                user.setSingleAttribute("externalValidation", "valid");
                context.success();
            } else {
                context.challenge(context.form()
                    .setError("Validation failed")
                    .createForm("external-validation.ftl"));
            }
        } catch (Exception e) {
            context.challenge(context.form()
                .setError("Unable to validate")
                .createForm("external-validation.ftl"));
        }
    }

    private String generateValidationToken(UserModel user) {
        // Generate time-limited validation token
        return JWT.create()
            .subject(user.getId())
            .claim("email", user.getEmail())
            .expiresAt(Date.from(Instant.now().plus(1, ChronoUnit.HOURS))
            .signWith(key);
    }
}
```

### Pattern 4: Multi-Step Wizard

Create a multi-step required action with progress tracking:

```java
public class MultiStepWizardAction implements RequiredActionProvider {

    private static final String CURRENT_STEP_ATTR = "wizardCurrentStep";
    private static final int TOTAL_STEPS = 3;

    @Override
    public void evaluateRequiredActions(RequiredActionContext context) {
        String stepStr = context.getUser()
            .getFirstAttribute(CURRENT_STEP_ATTR);

        if (stepStr != null) {
            int currentStep = Integer.parseInt(stepStr);
            if (currentStep > TOTAL_STEPS) {
                context.success();
                return;
            }
        }

        showStep(context, 1);
    }

    @Override
    public void processAction(RequiredActionContext context) {
        String stepStr = context.getUser()
            .getFirstAttribute(CURRENT_STEP_ATTR, "1");

        int currentStep = Integer.parseInt(stepStr);
        String action = context.getHttpRequest()
            .getDecodedFormParameters()
            .getFirst("action");

        if ("cancel".equals(action)) {
            // Cancel wizard - remove progress
            context.getUser().removeAttribute(CURRENT_STEP_ATTR);
            context.failureChallenge(context.form()
                .setError("Wizard cancelled")
                .createForm("wizard-intro.ftl"));
            return;
        }

        switch (currentStep) {
            case 1:
                handleStep1(context);
                break;
            case 2:
                handleStep2(context);
                break;
            case 3:
                handleStep3(context);
                break;
        }
    }

    private void showStep(RequiredActionContext context, int step) {
        context.getUser().setSingleAttribute(CURRENT_STEP_ATTR, String.valueOf(step));

        Response form = context.form()
            .setAttribute("currentStep", step)
            .setAttribute("totalSteps", TOTAL_STEPS)
            .createForm("wizard-step-" + step + ".ftl");
        context.challenge(form);
    }

    private void handleStep1(RequiredActionContext context) {
        // Validate step 1 data
        String value = context.getHttpRequest()
            .getDecodedFormParameters()
            .getFirst("step1_value");

        if (isValidStep1(value)) {
            context.getUser().setSingleAttribute("step1Data", value);
            showStep(context, 2);  // Move to step 2
        } else {
            context.challenge(context.form()
                .setError("Invalid input")
                .setAttribute("currentStep", 1)
                .createForm("wizard-step-1.ftl"));
        }
    }

    private void handleStep2(RequiredActionContext context) {
        String value = context.getHttpRequest()
            .getDecodedFormParameters()
            .getFirst("step2_value");

        if (isValidStep2(value)) {
            context.getUser().setSingleAttribute("step2Data", value);
            showStep(context, 3);  // Move to final step
        } else {
            context.challenge(context.form()
                .setError("Invalid input")
                .setAttribute("currentStep", 2)
                .createForm("wizard-step-2.ftl"));
        }
    }

    private void handleStep3(RequiredActionContext context) {
        // Validate final step and complete
        if (validateAllSteps(context)) {
            context.getUser().removeAttribute(CURRENT_STEP_ATTR);
            // Clean up step data
            context.getUser().removeAttribute("step1Data");
            context.getUser().removeAttribute("step2Data");
            context.success();
        } else {
            context.challenge(context.form()
                .setError("Validation failed")
                .setAttribute("currentStep", 1)
                .createForm("wizard-intro.ftl"));
        }
    }

    private boolean isValidStep1(String value) {
        return value != null && !value.isEmpty();
    }

    private boolean isValidStep2(String value) {
        return value != null && !value.isEmpty();
    }

    private boolean validateAllSteps(RequiredActionContext context) {
        return context.getUser().getFirstAttribute("step1Data") != null
            && context.getUser().getFirstAttribute("step2Data") != null;
    }
}
```

### Pattern 5: Conditional Required Action

Different actions based on user attributes or context:

```java
public class ConditionalRequiredAction implements RequiredActionProvider {

    @Override
    public void evaluateRequiredActions(RequiredActionContext context) {
        UserModel user = context.getUser();

        // Different requirements based on user type
        if (user.hasRealmRole("admin")) {
            // Admins must accept admin policies
            showPolicyAcceptance(context);
        } else if (user.hasRealmRole("premium")) {
            // Premium users must accept EULA
            showEULAAcceptance(context);
        } else {
            // Regular users must accept basic terms
            showTermsAcceptance(context);
        }
    }

    @Override
    public void processAction(RequiredActionContext context) {
        // Process based on which form was shown
        String action = context.getHttpRequest()
            .getDecodedFormParameters()
            .getFirst("action");

        if ("accept".equals(action)) {
            // Set appropriate attribute based on user type
            String acceptanceType = getAcceptanceType(context.getUser());
            context.getUser().setSingleAttribute(acceptanceType + "Accepted", "true");
            context.success();
        } else {
            context.challenge(context.form()
                .setError("Must accept to continue")
                .createForm("terms.ftl"));
        }
    }

    private void showPolicyAcceptance(RequiredActionContext context) {
        context.form()
            .setAttribute("termsType", "admin-policies")
            .createForm("policy-acceptance.ftl");
    }

    private void showEULAAcceptance(RequiredActionContext context) {
        context.form()
            .setAttribute("termsType", "premium-eula")
            .createForm("eula-acceptance.ftl");
    }

    private void showTermsAcceptance(RequiredActionContext context) {
        context.form()
            .setAttribute("termsType", "basic-terms")
            .createForm("terms-acceptance.ftl");
    }

    private String getAcceptanceType(UserModel user) {
        if (user.hasRealmRole("admin")) return "adminPolicies";
        if (user.hasRealmRole("premium")) return "premiumEula";
        return "basicTerms";
    }
}
```

### Pattern 6: Group-Based Required Action

Check group membership before requiring action:

```java
public class GroupBasedRequiredAction implements RequiredActionProvider {

    private static final String REQUIRED_GROUP = "high-security-users";

    @Override
    public void evaluateRequiredActions(RequiredActionContext context) {
        UserModel user = context.getUser();

        // Check if user is in high-security group
        if (!isMemberOfGroup(user, REQUIRED_GROUP)) {
            context.success();
            return;
        }

        // High-security users must complete additional verification
        String lastVerification = user.getFirstAttribute("lastVerification");
        if (lastVerification != null) {
            long lastVerified = Long.parseLong(lastVerification);
            long daysSinceVerification = (System.currentTimeMillis() - lastVerified) / (1000 * 60 * 60 * 24);

            if (daysSinceVerification < 30) {
                context.success();
                return;
            }
        }

        requiredActionChallenge(context);
    }

    @Override
    public void processAction(RequiredActionContext context) {
        // Perform additional verification (e.g., security quiz)
        String answer = context.getHttpRequest()
            .getDecodedFormParameters()
            .getFirst("securityAnswer");

        if (isValidSecurityAnswer(answer, context.getUser())) {
            context.getUser().setSingleAttribute("lastVerification",
                String.valueOf(System.currentTimeMillis()));
            context.success();
        } else {
            context.challenge(context.form()
                .setError("Incorrect answer")
                .createForm("security-verification.ftl"));
        }
    }

    private boolean isMemberOfGroup(UserModel user, String groupName) {
        return user.getGroupsStream()
            .anyMatch(group -> groupName.equals(group.getName()));
    }

    private boolean isValidSecurityAnswer(String answer, UserModel user) {
        // Validate against security questions stored in user attributes
        String storedAnswer = user.getFirstAttribute("securityAnswer");
        return answer != null && answer.equals(storedAnswer);
    }
}
```

### Pattern 7: Device Registration

Register current device and require authentication from new devices:

```java
public class DeviceRegistrationAction implements RequiredActionProvider {

    @Override
    public void evaluateRequiredActions(RequiredActionContext context) {
        UserModel user = context.getUser();
        String deviceId = getDeviceId(context);

        if (isDeviceRegistered(user, deviceId)) {
            context.success();
            return;
        }

        // Require device registration
        requiredActionChallenge(context);
    }

    @Override
    public void processAction(RequiredActionContext context) {
        String deviceName = context.getHttpRequest()
            .getDecodedFormParameters()
            .getFirst("deviceName");

        if (deviceName != null && !deviceName.isEmpty()) {
            // Register this device
            String deviceId = getDeviceId(context);
            registerDevice(context.getUser(), deviceId, deviceName);

            context.success();
        } else {
            context.challenge(context.form()
                .setError("Device name is required")
                .createForm("device-registration.ftl"));
        }
    }

    @Override
    public boolean isOneTimeAction() {
        return false; // Device can be re-registered
    }

    private String getDeviceId(RequiredActionContext context) {
        // Generate unique device ID based on user agent and IP
        String userAgent = context.getHttpRequest()
            .getHttpHeaders().getHeaderString("User-Agent");

        // Extract browser/os identifier
        String browserId = extractBrowserId(userAgent);
        String ip = context.getConnection().getRemoteAddr();

        return DigestUtils.md5Hex(browserId + "-" + ip);
    }

    private boolean isDeviceRegistered(UserModel user, String deviceId) {
        String registeredDevices = user.getFirstAttribute("registeredDevices");
        if (registeredDevices == null) return false;

        return Arrays.stream(registeredDevices.split(","))
            .anyMatch(deviceId::equals);
    }

    private void registerDevice(UserModel user, String deviceId,
                               String deviceName) {
        String current = user.getFirstAttribute("registeredDevices", "");
        String updated = current.isEmpty()
            ? deviceId
            : current + "," + deviceId;

        user.setSingleAttribute("registeredDevices", updated);
        user.setSingleAttribute("deviceName_" + deviceId, deviceName);
    }
}
```

### Pattern 8: Consent Management

Manage user consent for data processing:

```java
public class DataConsentAction implements RequiredActionProvider {

    private static final String CONSENT_PURPOSE = "data-processing";

    @Override
    public void evaluateRequiredActions(RequiredActionContext context) {
        UserModel user = context.getUser();
        String consent = user.getFirstAttribute(CONSENT_PURPOSE + "Consent");

        if ("granted".equals(consent)) {
            context.success();
            return;
        }

        // Check if user previously declined
        if ("declined".equals(consent)) {
            // Show declined message with option to grant
            context.challenge(context.form()
                .setAttribute("showGrantOption", true)
                .createForm("data-consent.ftl"));
            return;
        }

        // First time requesting consent
        requiredActionChallenge(context);
    }

    @Override
    public void processAction(RequiredActionContext context) {
        String action = context.getHttpRequest()
            .getDecodedFormParameters()
            .getFirst("action");

        UserModel user = context.getUser();

        switch (action) {
            case "grant":
                user.setSingleAttribute(CONSENT_PURPOSE + "Consent", "granted");
                user.setSingleAttribute(CONSENT_PURPOSE + "Timestamp",
                    String.valueOf(System.currentTimeMillis()));
                context.success();
                break;

            case "decline":
                user.setSingleAttribute(CONSENT_PURPOSE + "Consent", "declined");
                // Option 1: Deny access
                // context.failure(AuthenticationFlowError.CONSENT_DENIED);
                // Option 2: Allow limited access
                context.success();
                break;

            default:
                // First time showing consent
                requiredActionChallenge(context);
        }
    }

    @Override
    public boolean isOneTimeAction() {
        return false; // User can change consent anytime
    }
}
```

### Pattern 9: Progressive Profiling

Collect user information over multiple sessions:

```java
public class ProgressiveProfilingAction implements RequiredActionProvider {

    @Override
    public void evaluateRequiredActions(RequiredActionContext context) {
        UserProfile profile = getUserProfile(context.getUser());
        int completedFields = countCompletedFields(profile);

        if (completedFields == profile.getTotalFields()) {
            context.success();
            return;
        }

        // Show next incomplete field
        showNextField(context, profile);
    }

    @Override
    public void processAction(RequiredActionContext context) {
        MultivaluedMap<String, String> formData =
            context.getHttpRequest().getDecodedFormParameters();

        String fieldName = context.getUser()
            .getFirstAttribute("nextFieldToComplete");

        // Save the field value
        saveFieldValue(context.getUser(), fieldName, formData.getFirst(fieldName));

        // Check if all fields are complete
        if (isProfileComplete(context.getUser())) {
            context.success();
        } else {
            evaluateRequiredActions(context);
        }
    }

    private void showNextField(RequiredActionContext context, UserProfile profile) {
        UserProfileField nextField = profile.getNextIncompleteField();

        context.getUser().setSingleAttribute("nextFieldToComplete", nextField.getName());

        context.form()
            .setAttribute("fieldLabel", nextField.getLabel())
            .setAttribute("fieldType", nextField.getType())
            .setAttribute("isRequired", nextField.isRequired())
            .setAttribute("fieldOptions", nextField.getOptions())
            .createForm("progressive-profile.ftl");
    }

    private int countCompletedFields(UserProfile profile) {
        return (int) profile.getFields().stream()
            .filter(field -> field.isComplete())
            .count();
    }
}
```

### Pattern 10: Risk-Based Challenge

Show different challenge based on risk assessment:

```java
public class RiskBasedRequiredAction implements RequiredActionProvider {

    @Override
    public void evaluateRequiredActions(RequiredActionContext context) {
        RiskLevel risk = assessRisk(context);

        switch (risk) {
            case LOW:
                // No additional challenge needed
                context.success();
                break;

            case MEDIUM:
                // Show simple verification
                context.challenge(context.form()
                    .createForm("simple-verification.ftl"));
                break;

            case HIGH:
                // Show strict authentication
                context.challenge(context.form()
                    .createForm("strict-authentication.ftl"));
                break;

            case CRITICAL:
                // Deny access, require admin intervention
                context.failure(AuthenticationFlowError.RISK_DETECTED);
                break;
        }
    }

    private enum RiskLevel {
        LOW, MEDIUM, HIGH, CRITICAL
    }

    private RiskLevel assessRisk(RequiredActionContext context) {
        int score = 0;

        // Check login attempts
        score += getFailedLoginCount(context.getUser()) * 10;

        // Check if logging from new location
        score += isNewLocation(context) ? 20 : 0;

        // Check if logging from new device
        score += isNewDevice(context) ? 15 : 0;

        // Check time-based risk (unusual hours)
        score += isUnusualTime(context) ? 10 : 0;

        if (score < 30) return RiskLevel.LOW;
        if (score < 60) return RiskLevel.MEDIUM;
        if (score < 80) return RiskLevel.HIGH;
        return RiskLevel.CRITICAL;
    }

    private int getFailedLoginCount(UserModel user) {
        String count = user.getFirstAttribute("failedLoginCount");
        return count != null ? Integer.parseInt(count) : 0;
    }

    private boolean isNewLocation(RequiredActionContext context) {
        String lastLocation = context.getUser()
            .getFirstAttribute("lastLoginLocation");

        String currentLocation = context.getConnection().getRemoteAddr();
        return !currentLocation.equals(lastLocation);
    }

    private boolean isNewDevice(RequiredActionContext context) {
        String lastDevice = context.getUser()
            .getFirstAttribute("lastLoginDevice");

        String currentDevice = context.getHttpRequest()
            .getHttpHeaders()
            .getHeaderString("User-Agent");

        return !currentDevice.equals(lastDevice);
    }

    private boolean isUnusualTime(RequiredActionContext context) {
        LocalTime time = LocalTime.now();
        int hour = time.getHour();

        // Consider 11 PM - 5 AM as unusual
        return hour >= 23 || hour <= 5;
    }
}
```

## Related Topics

- [[keycloak-authenticator-spi-walkthrough]] - Authenticator development
- [[keycloak-registration-form-flows]] - Registration customization
- [[keycloak-spi]] - General SPI information

## Additional Resources

- [Server Developer Guide](https://www.keycloak.org/docs/latest/server_development)
- [Required Action Walkthrough](https://www.keycloak.org/docs/latest/server_development/#required-action-walkthrough)
- [Quickstarts - Authenticator Example](https://github.com/keycloak/keycloak-quickstarts/tree/main/extension/authenticator)
