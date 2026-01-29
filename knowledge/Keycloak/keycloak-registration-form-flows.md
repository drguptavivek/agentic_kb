---
title: Modifying Keycloak Registration Form and Forgot Password Flow
domain: Keycloak
type: tutorial
status: draft
tags: [keycloak, registration, forgot-password, credential-flow, customization]
created: 2026-01-29
related: [[keycloak-authenticator-spi-walkthrough]], [[keycloak-required-action-spi]], [[keycloak-spi]]
---

# Modifying Keycloak Registration Form and Credential Flows

## Overview

Keycloak allows customization of user-facing forms including:
- User registration
- Forgot password / credential reset
- Update profile information

This can be done through:
1. **Theme customization** (FreeMarker templates)
2. **Form providers** (Java-based)
3. **Authentication flow customization**
4. **SPI extensions**

## Registration Form Customization

### Method 1: FreeMarker Template Customization

#### Create Custom Theme Structure

```
my-theme/
├── account/
│   └── account.ftl
├── login/
│   ├── register.ftl
│   ├── register-user-profile.ftl
│   └── login.ftl
├── email/
│   └── ...
├── theme.properties
└── resources/
    ├── css/
    │   └── styles.css
    ├── js/
    │   └── scripts.js
    └── img/
        └── logo.png
```

#### theme.properties

```properties
parent=keycloak
locales=en,fr,de
css=resources/css/styles.css
```

#### Custom Registration Form (register.ftl)

```html
<template name="register.ftl">
    <div class="pf-c-login__main-body">
        <div class="pf-c-login__main-header">
            <h1>${msg("registerTitle")}</h1>
            <p>Create your account to get started</p>
        </div>

        <#if message?has_content && message.type == 'error'>
            <div class="alert alert-danger">
                <span class="pficon pficon-error-circle-o"></span>
                ${kcSanitize(message.summary)?no_esc}
            </div>
        </#if>

        <form id="kc-register-form" class="${properties.kcFormClass!''}"
              action="${url.registrationAction}"
              method="post">

            <@userProfileFormFields; section>

            <#if passwordRequired??>
                <div class="form-group">
                    <label for="password" class="${properties.kcLabelClass!''}">
                        ${msg("password")}
                    </label>

                    <input type="password"
                           id="password"
                           name="password"
                           class="form-control ${properties.kcInputClass!''}"
                           placeholder="${msg('passwordPlaceholder')}"
                           required
                           autofocus
                           autocomplete="new-password"
                           aria-invalid="<#if messagesPerField.exists('password')>true</#if>">

                    <#if messagesPerField.exists('password')>
                        <span class="pficon pficon-error-circle-o error-icon"></span>
                        <span class="error-text">
                            ${kcSanitize(messagesPerField.get('password'))?no_esc}
                        </span>
                    </#if>

                    <div class="password-strength-meter">
                        <div class="password-strength-bar" id="strength-bar"></div>
                        <span id="strength-text"></span>
                    </div>
                </div>

                <div class="form-group">
                    <label for="password-confirm" class="${properties.kcLabelClass!''}">
                        ${msg("passwordConfirm")}
                    </label>

                    <input type="password"
                           id="password-confirm"
                           name="password-confirm"
                           class="form-control ${properties.kcInputClass!''}"
                           placeholder="${msg('passwordConfirmPlaceholder')}"
                           required
                           autocomplete="new-password"
                           aria-invalid="<#if messagesPerField.exists('password-confirm')>true</#if>">

                    <#if messagesPerField.exists('password-confirm')>
                        <span class="pficon pficon-error-circle-o error-icon"></span>
                        <span class="error-text">
                            ${kcSanitize(messagesPerField.get('password-confirm'))?no_esc}
                        </span>
                    </#if>
                </div>
            </#if>

            <#if recaptchaRequired??>
                <div class="form-group">
                    <div class="g-recaptcha" data-sitekey="${recaptchaSiteKey}"></div>
                </div>
            </#if>

            <div class="form-group ${properties.kcFormButtonsClass!''}">
                <button type="submit"
                        class="${properties.kcButtonClass!''} ${properties.kcButtonPrimaryClass!''}"
                        id="kc-register">
                    ${msg("doRegister")}
                </button>
            </div>

        </form>

        <div class="login-prompt">
            <span>${msg("alreadyHaveAccount")}</span>
            <a href="${url.loginUrl}">${msg("backToLogin")}</a>
        </div>
    </div>

    <script type="module">
        // Password strength checker
        const passwordInput = document.getElementById('password');
        const strengthBar = document.getElementById('strength-bar');
        const strengthText = document.getElementById('strength-text');

        passwordInput.addEventListener('input', function() {
            const password = this.value;
            const strength = calculateStrength(password);
            updateStrengthMeter(strength);
        });

        function calculateStrength(password) {
            let score = 0;
            if (password.length >= 8) score++;
            if (password.length >= 12) score++;
            if (/[a-z]/.test(password)) score++;
            if (/[A-Z]/.test(password)) score++;
            if (/[0-9]/.test(password)) score++;
            if (/[^a-zA-Z0-9]/.test(password)) score++;
            return Math.min(score, 5);
        }

        function updateStrengthMeter(score) {
            const colors = ['#red', '#orange', '#yellow', '#yellow-green', '#green'];
            const texts = ['Very Weak', 'Weak', 'Fair', 'Good', 'Strong'];

            strengthBar.style.width = (score * 20) + '%';
            strengthBar.style.backgroundColor = colors[score];
            strengthText.textContent = texts[score];
        }
    </script>
</template>

<#macro userProfileFormFields>
    <div class="form-group">
        <label for="user.attributes.company" class="${properties.kcLabelClass!''}">
            Company
        </label>
        <input type="text"
               id="user.attributes.company"
               name="user.attributes.company"
               class="form-control ${properties.kcInputClass!''}"
               value="${(register.formData.formValue('user.attributes.company'))!''}"
               placeholder="Enter your company name">
    </div>

    <div class="form-group">
        <label for="user.attributes.phone" class="${properties.kcLabelClass!''}">
            Phone Number
        </label>
        <input type="tel"
               id="user.attributes.phone"
               name="user.attributes.phone"
               class="form-control ${properties.kcInputClass!''}"
               value="${(register.formData.formValue('user.attributes.phone'))!''}"
               placeholder="Enter your phone number">
    </div>

    <div class="form-group">
        <label>
            <input type="checkbox"
                   name="user.attributes.marketing_consent"
                   value="true"
                   <#if (register.formData.formValue('user.attributes.marketing_consent')!'') == 'true'>checked</#if>>
            I agree to receive marketing communications
        </label>
    </div>
</#macro>
```

### Method 2: Dynamic User Profile Attributes

#### Configure User Profile in Admin Console

1. Go to **Realm Settings** → **User Profile**
2. Add custom attributes:
   - **company** (text, required)
   - **phone** (text, optional)
   - **marketing_consent** (boolean, optional)

#### Attribute Validation

```json
{
  "name": "company",
  "displayName": "${company}",
  "validations": {
    "length": {
      "min": 2,
      "max": 100
    }
  },
  "required": {
    "roles": ["user"]
  }
}
```

## Forgot Password / Credential Flow Customization

### Understanding the Flow

```
┌──────────────────┐
│ User clicks      │
│ "Forgot Password"│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Enter username   │
│ or email         │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Keycloak sends   │
│ reset email      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ User clicks link │
│ in email         │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Enter new        │
│ password         │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Password updated │
│ Login enabled    │
└──────────────────┘
```

### Custom Forgot Password Form

#### Custom reset-password.ftl

```html
<template name="reset-password.ftl">
    <div class="pf-c-login__main-body">
        <div class="pf-c-login__main-header">
            <h1>Reset Your Password</h1>
            <p>Enter your email address and we'll send you instructions to reset your password.</p>
        </div>

        <#if message?has_content>
            <div class="alert alert-${message.type}">
                <span class="pficon pficon-${message.type == 'error' ? 'error-circle-o' : 'ok'}"></span>
                ${kcSanitize(message.summary)?no_esc}
            </div>
        </#if>

        <form id="kc-reset-password-form" class="${properties.kcFormClass!''}"
              action="${url.loginAction}"
              method="post">

            <div class="form-group">
                <label for="username" class="${properties.kcLabelClass!''}">
                    <#if login.rememberMe?>
                        ${msg("emailOrUsername")}
                    <#else>
                        ${msg("username")}
                    </#if>
                </label>

                <input type="text"
                       id="username"
                       name="username"
                       class="form-control ${properties.kcInputClass!''}"
                       placeholder="Enter your email or username"
                       required
                       autofocus
                       value="${(login.lastUsername!'')}"
                       aria-invalid="<#if messagesPerField.exists('username')>true</#if>">

                <#if messagesPerField.exists('username')>
                    <span class="pficon pficon-error-circle-o error-icon"></span>
                    <span class="error-text">
                        ${kcSanitize(messagesPerField.get('username'))?no_esc}
                    </span>
                </#if>
            </div>

            <#if recaptchaRequired??>
                <div class="form-group">
                    <div class="g-recaptcha" data-sitekey="${recaptchaSiteKey}"></div>
                </div>
            </#if>

            <div class="form-group ${properties.kcFormButtonsClass!''}">
                <button type="submit"
                        class="${properties.kcButtonClass!''} ${properties.kcButtonPrimaryClass!''}"
                        id="kc-reset-password">
                    ${msg("doSubmit")}
                </button>

                <button type="submit"
                        name="cancel"
                        value="true"
                        class="${properties.kcButtonClass!''}">
                    ${msg("doCancel")}
                </button>
            </div>

        </form>

        <div class="login-prompt">
            <span>${msg("backToLogin")}</span>
            <a href="${url.loginUrl}">${msg("backToLoginPage")}</a>
        </div>
    </div>
</template>
```

### Custom Update Password Form

#### Custom update-password.ftl

```html
<template name="update-password.ftl">
    <div class="pf-c-login__main-body">
        <div class="pf-c-login__main-header">
            <h1>Update Password</h1>
            <p>Enter your new password below.</p>
        </div>

        <#if message?has_content && message.type == 'error'>
            <div class="alert alert-danger">
                <span class="pficon pficon-error-circle-o"></span>
                ${kcSanitize(message.summary)?no_esc}
            </div>
        </#if>

        <form id="kc-update-password-form" class="${properties.kcFormClass!''}"
              action="${url.loginAction}"
              method="post">

            <div class="form-group">
                <label for="password-new" class="${properties.kcLabelClass!''}">
                    ${msg("passwordNew")}
                </label>

                <input type="password"
                       id="password-new"
                       name="password-new"
                       class="form-control ${properties.kcInputClass!''}"
                       placeholder="${msg('passwordNewPlaceholder')}"
                       required
                       autofocus
                       autocomplete="new-password"
                       pattern="(?=.*\d)(?=.*[a-z])(?=.*[A-Z]).{8,}"
                       aria-invalid="<#if messagesPerField.exists('password-new')>true</#if>">

                <div class="password-requirements">
                    <p>Password must contain:</p>
                    <ul>
                        <li id="length-check" class="invalid">At least 8 characters</li>
                        <li id="uppercase-check" class="invalid">One uppercase letter</li>
                        <li id="lowercase-check" class="invalid">One lowercase letter</li>
                        <li id="number-check" class="invalid">One number</li>
                    </ul>
                </div>

                <#if messagesPerField.exists('password-new')>
                    <span class="error-text">
                        ${kcSanitize(messagesPerField.get('password-new'))?no_esc}
                    </span>
                </#if>
            </div>

            <div class="form-group">
                <label for="password-confirm" class="${properties.kcLabelClass!''}">
                    ${msg("passwordConfirm")}
                </label>

                <input type="password"
                       id="password-confirm"
                       name="password-confirm"
                       class="form-control ${properties.kcInputClass!''}"
                       placeholder="${msg('passwordConfirmPlaceholder')}"
                       required
                       autocomplete="new-password"
                       aria-invalid="<#if messagesPerField.exists('password-confirm')>true</#if>">

                <#if messagesPerField.exists('password-confirm')>
                    <span class="error-text">
                        ${kcSanitize(messagesPerField.get('password-confirm'))?no_esc}
                    </span>
                </#if>
            </div>

            <div class="form-group ${properties.kcFormButtonsClass!''}">
                <button type="submit"
                        class="${properties.kcButtonClass!''} ${properties.kcButtonPrimaryClass!''}">
                    ${msg("doSubmit")}
                </button>

                <button type="submit"
                        name="cancel"
                        value="true"
                        class="${properties.kcButtonClass!''}">
                    ${msg("doCancel")}
                </button>
            </div>

        </form>

        <script type="module">
            const password = document.getElementById('password-new');
            const confirm = document.getElementById('password-confirm');

            password.addEventListener('input', function() {
                validatePassword(this.value);
            });

            function validatePassword(value) {
                document.getElementById('length-check').className =
                    value.length >= 8 ? 'valid' : 'invalid';
                document.getElementById('uppercase-check').className =
                    /[A-Z]/.test(value) ? 'valid' : 'invalid';
                document.getElementById('lowercase-check').className =
                    /[a-z]/.test(value) ? 'valid' : 'invalid';
                document.getElementById('number-check').className =
                    /\d/.test(value) ? 'valid' : 'invalid';
            }
        </script>
    </div>
</template>
```

## Programmatic Form Provider

### Implementing FormActionFactory

For more complex form logic:

```java
package com.example.keycloak.forms;

import org.keycloak.forms.login.LoginFormsProvider;
import org.keycloak.forms.login.freemarker.FreeMarkerLoginFormsProvider;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;
import org.keycloak.services.validation.Validation;
import org.keycloak.authentication.FormAction;
import org.keycloak.authentication.FormActionFactory;
import org.keycloak.authentication.FormContext;
import org.keycloak.models.KeycloakSession;
import javax.ws.rs.core.MultivaluedMap;
import java.util.List;
import java.util.Map;

public class RegistrationProfile implements FormAction, FormActionFactory {

    public static final String PROVIDER_ID = "registration-profile-action";

    @Override
    public String getHelpText() {
        return "Validates custom registration fields";
    }

    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        return null;
    }

    @Override
    public void buildPage(FormContext context, LoginFormsProvider form) {
        // Add custom form fields to registration page
        form.setAttribute("customFields", getCustomFields(context));
    }

    @Override
    public void validate(FormContext context) {
        MultivaluedMap<String, String> formData =
            context.getHttpRequest().getDecodedFormParameters();

        // Validate company field
        String company = formData.getFirst("user.attributes.company");
        if (company == null || company.trim().isEmpty()) {
            context.error("Company is required");
            return;
        }

        // Validate phone format
        String phone = formData.getFirst("user.attributes.phone");
        if (phone != null && !phone.isEmpty() && !isValidPhone(phone)) {
            context.error("Invalid phone number format");
            return;
        }
    }

    @Override
    public boolean success(FormContext context) {
        UserModel user = context.getUser();
        MultivaluedMap<String, String> formData =
            context.getHttpRequest().getDecodedFormParameters();

        // Store custom attributes
        String company = formData.getFirst("user.attributes.company");
        user.setSingleAttribute("company", company);

        String phone = formData.getFirst("user.attributes.phone");
        if (phone != null && !phone.isEmpty()) {
            user.setSingleAttribute("phone", phone);
        }

        String marketingConsent = formData.getFirst("user.attributes.marketing_consent");
        user.setSingleAttribute("marketing_consent",
            marketingConsent != null ? "true" : "false");

        return true;
    }

    private boolean isValidPhone(String phone) {
        return phone.matches("^[+]?[0-9]{10,15}$");
    }

    private Map<String, Object> getCustomFields(FormContext context) {
        Map<String, Object> fields = new HashMap<>();
        fields.put("company", "");
        fields.put("phone", "");
        fields.put("marketing_consent", false);
        return fields;
    }

    @Override
    public boolean requiresUser() {
        return false; // This is for registration, no user exists yet
    }

    @Override
    public boolean configuredFor(KeycloakSession session,
                                  RealmModel realm,
                                  UserModel user) {
        return true;
    }

    @Override
    public void close() {
    }

    // FormActionFactory methods
    @Override
    public String getId() {
        return PROVIDER_ID;
    }

    @Override
    public FormAction create(KeycloakSession session) {
        return this;
    }

    @Override
    public void init(Config.Scope config) {
    }

    @Override
    public void postInit(Config.Scope config) {
    }
}
```

### Register Form Action Provider

Create `META-INF/services/org.keycloak.authentication.FormActionFactory`:

```
com.example.keycloak.forms.RegistrationProfile
```

## Authentication Flow Configuration

### Configure Custom Flow in Admin Console

1. Navigate to **Authentication** → **Flows**
2. Click **New** to create flow
3. Add form action to registration execution
4. Configure as required

### Flow Example

```
Registration Flow
├── Screen - Registration Profile
├── Screen - Registration Password
├── Screen - Registration Recaptcha
└── Screen - Registration User Creation
```

## Deployment

### Package and Deploy

```bash
# Build JAR
mvn clean package

# Deploy to Keycloak
cp target/custom-forms-1.0.0.jar /opt/keycloak/providers/

# Build Keycloak
/opt/keycloak/bin/kc.sh build
```

### Enable in Realm

1. Restart Keycloak
2. Navigate to **Authentication** → **Flows**
3. Edit Registration flow
4. Add your custom form action
5. Set requirement level

## Best Practices

### User Experience

- [ ] Clear instructions and labels
- [ ] Inline validation feedback
- [ ] Password strength indicators
- [ ] Helpful error messages
- [ ] Mobile-responsive design

### Security

- [ ] Validate all input
- [ ] Use CSRF protection
- [ ] Sanitize output
- [ ] Secure password handling
- [ ] Rate limiting

### Accessibility

- [ ] Semantic HTML
- [ ] Proper ARIA labels
- [ ] Keyboard navigation
- [ ] Screen reader support
- [ ] Color contrast

### Testing

- [ ] Test with valid data
- [ ] Test with invalid data
- [ ] Test accessibility
- [ ] Test cross-browser
- [ ] Test mobile devices

## Related Topics

- [[keycloak-authenticator-spi-walkthrough]] - Authenticator development
- [[keycloak-required-action-spi]] - Required actions
- [[keycloak-spi]] - General SPI information

## Additional Resources

- [Server Developer Guide](https://www.keycloak.org/docs/latest/server_development)
- [Modifying Forgot Password/Credential Flow](https://www.keycloak.org/docs/latest/server_development/#modifying-forgot-passwordcredential-flow)
- [Modifying Registration Form](https://www.keycloak.org/docs/latest/server_development/#modifying-or-extending-the-registration-form)
