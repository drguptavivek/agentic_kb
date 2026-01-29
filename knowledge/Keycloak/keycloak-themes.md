---
title: Keycloak Theme Customization
type: reference
domain: Keycloak
tags:
  - keycloak
  - themes
  - customization
  - ui
  - freemarker
  - css
  - login
  - account
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Theme Customization

## Overview

Keycloak themes allow you to customize the appearance and branding of login pages, account console, and admin console. Themes use FreeMarker templates combined with CSS and JavaScript for maximum flexibility. <https://www.keycloak.org/ui-customization/themes>

## Theme Types

### Login Theme

**Purpose:** User-facing authentication pages

**Pages included:**
- Login page
- Registration page
- Forgot password
- OTP configuration
- WebAuthn/passkey setup
- Terms and conditions
- Error pages

### Account Theme

**Purpose:** User account management console

**Pages included:**
- Account overview
- Password management
- TOTP setup
- Sessions management
- Applications/authorized clients
- Log records

### Admin Console Theme

**Purpose:** Administration interface branding

**Customizable:**
- Logo and branding colors
- Login page
- Some UI elements

**Note:** Full admin console customization is limited.

### Email Theme

**Purpose:** Transactional email templates

**Templates included:**
- Email verification
- Password reset
- Identity provider linking
- Required actions
- Event notifications

## Theme Structure

### Directory Layout

```
theme/
└── my-theme/
    ├── login/
    │   ├── login.ftl
    │   ├── register.ftl
    │   ├── forgot-password.ftl
    │   ├── update-password.ftl
    │   ├── verify-email.ftl
    │   ├── terms.ftl
    │   ├── config-totp.ftl
    │   ├── webauthn-register.ftl
    │   ├── webauthn-register-passwordless.ftl
    │   ├── info.ftl
    │   ├── error.ftl
    │   ├── login.css
    │   ├── login.css.map
    │   ├── reset.css
    │   ├── common.css
    │   ├── script.js
    │   ├── keycloak.v2/
    │   │   └── components/
    │   │       ├── Button.component.css
    │   │       └── ...
    │   ├── resources/
    │   │   ├── img/
    │   │   │   └── logo.png
    │   │   ├── fonts/
    │   │   └── icons/
    │   └── messages/
    │       └── messages_en.properties
    ├── account/
    │   ├── account.ftl
    │   ├── password.ftl
    │   ├── totp.ftl
    │   ├── sessions.ftl
    │   ├── applications.ftl
    │   ├── log.ftl
    │   ├── account.css
    │   └── resources/
    └── email/
        ├── html/
        │   ├── verify-email.ftl
        │   └── execute-actions.ftl
        └── text/
            ├── verify-email.ftl
            └── execute-actions.ftl
```

## Creating a Custom Theme

### Step 1: Create Theme Directory

```bash
mkdir -p theme/my-theme/login/resources
mkdir -p theme/my-theme/account
mkdir -p theme/my-theme/email
```

### Step 2: Create Theme Properties

**File:** `theme/my-theme/theme.properties`

```properties
parent=keycloak
# Or specify another parent
# parent=base

# Theme information
name=My Theme
description=Custom theme for my organization

# Version
version=1.0.0

# Author
author=Your Name

# Variants (if supported)
variants=
```

### Step 3: Extend Base Theme

**Copy and modify templates from base theme:**

```bash
# Find Keycloak base themes
# Usually in: /opt/keycloak/themes/keycloak
cp -r /opt/keycloak/themes/keycloak/login/* \
  theme/my-theme/login/
```

### Step 4: Customize Login Page

**File:** `theme/my-theme/login/login.ftl`

```freemarker
<#import "template.ftl" as layout>
<@layout.registrationLayout displayInfo=true; section>
    <#if section = "header">
        ${msg("loginTitle")}
    <#elseif section = "form">
        <div id="kc-form">
            <div id="kc-form-wrapper">
                <#if realm.password && social.providers??>
                    <div id="kc-social-providers">
                        <@layout.socialProviders; provider>
                            <a href="${provider.loginUrl}"
                               class="${provider.providerId}">
                                <span>${provider.displayName}</span>
                            </a>
                        </@layout.socialProviders>
                    </div>
                </#if>

                <form id="kc-form-login"
                      class="${properties.kcFormClass!}"
                      action="${url.loginAction}"
                      method="post">
                    <div class="${properties.kcFormGroupClass!}">
                        <label for="username"
                               class="${properties.kcLabelClass!}">
                            <#if !realm.loginWithEmailAllowed>
                                ${msg("username")}
                            <#elseif !realm.registrationEmailAsUsername>
                                ${msg("usernameOrEmail")}
                            <#else>
                                ${msg("email")}
                            </#if>
                        </label>

                        <input tabindex="1"
                               id="username"
                               class="${properties.kcInputClass!}"
                               name="username"
                               value="${login.username!}"
                               type="text"
                               autofocus
                               autocomplete="off"
                               aria-invalid="<#if messagesPerField.existsError('username','password')>true</#if>"
                        />

                        <#if messagesPerField.existsError('username','password')>
                            <span id="input-error"
                                  class="${properties.kcInputErrorMessageClass!}"
                                  aria-live="polite">
                                ${kcSanitize(messagesPerField.getFirstError('username','password'))?no_esc}
                            </span>
                        </#if>
                    </div>

                    <div class="${properties.kcFormGroupClass!}">
                        <label for="password"
                               class="${properties.kcLabelClass!}">
                            ${msg("password")}
                        </label>

                        <input tabindex="2"
                               id="password"
                               class="${properties.kcInputClass!}"
                               name="password"
                               type="password"
                               autocomplete="off"
                               aria-invalid="<#if messagesPerField.existsError('username','password')>true</#if>"
                        />

                        <#if usernameHidden?? && usernameHidden>
                            <input tabindex="1"
                                   id="username"
                                   name="username"
                                   type="hidden"
                                   value="${login.username!}"
                            />
                        </#if>
                    </div>

                    <div class="${properties.kcFormGroupClass!}">
                        <div id="kc-form-options">
                            <#if realm.rememberMe && !usernameHidden??>
                                <div class="checkbox">
                                    <label>
                                        <input tabindex="3"
                                               id="rememberMe"
                                               name="rememberMe"
                                               type="checkbox"
                                               ${login.rememberMe?string('checked', '')}
                                        />
                                        ${msg("rememberMe")}
                                    </label>
                                </div>
                            </#if>
                        </div>

                        <div id="kc-form-buttons"
                             class="${properties.kcFormButtonsClass!}">
                            <input tabindex="4"
                                   class="${properties.kcButtonClass!} ${properties.kcButtonPrimaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}"
                                   name="login"
                                   id="kc-login"
                                   type="submit"
                                   value="${msg("doLogIn")}"
                            />
                            <#if realm.resetPasswordAllowed>
                                <span class="${properties.kcFormButtonsWrapperClass!}">
                                    <a tabindex="5"
                                       href="${url.loginResetCredentialsUrl}"
                                       class="${properties.kcButtonClass!} ${properties.kcButtonSecondaryClass!} ${properties.kcButtonBlockClass!} ${properties.kcButtonLargeClass!}">
                                        ${msg("doForgotPassword")}
                                    </a>
                                </span>
                            </#if>
                        </div>
                    </div>
                </form>
            </div>
        </div>
        <#if realm.password && realm.registrationAllowed && !registrationDisabled??>
            <div id="kc-registration-container">
                <span id="kc-registration">
                    <a href="${url.registrationUrl}">
                        ${msg("noAccount")}
                        <a href="${url.registrationUrl}"
                           class="${properties.kcLinkClass!}">
                            ${msg("doRegister")}
                        </a>
                    </span>
                </span>
            </div>
        </#if>
    </#if>
</@layout.registrationLayout>
```

### Step 5: Add Custom CSS

**File:** `theme/my-theme/login/login.css`

```css
:root {
    --kc-primary-color: #007bff;
    --kc-secondary-color: #6c757d;
    --kc-background-color: #f8f9fa;
    --kc-text-color: #212529;
    --kc-border-color: #dee2e6;
}

body {
    background-color: var(--kc-background-color);
    color: var(--kc-text-color);
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI",
                 Roboto, "Helvetica Neue", Arial, sans-serif;
}

#kc-header {
    background-color: var(--kc-primary-color);
    padding: 20px;
    text-align: center;
}

#kc-logo {
    max-width: 200px;
    max-height: 60px;
}

#kc-form-wrapper {
    background: white;
    border-radius: 8px;
    padding: 30px;
    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
    max-width: 400px;
    margin: 0 auto;
}

.kc-button-primary {
    background-color: var(--kc-primary-color);
    border-color: var(--kc-primary-color);
    color: white;
    padding: 10px 20px;
    border-radius: 4px;
    font-weight: 500;
}

.kc-button-primary:hover {
    background-color: #0056b3;
    border-color: #0056b3;
}

.kc-input {
    width: 100%;
    padding: 10px;
    border: 1px solid var(--kc-border-color);
    border-radius: 4px;
    margin-bottom: 15px;
}

.kc-input:focus {
    border-color: var(--kc-primary-color);
    outline: none;
    box-shadow: 0 0 0 0.2rem rgba(0,123,255,0.25);
}

/* Social providers */
.kc-social-provider {
    display: block;
    width: 100%;
    margin-bottom: 10px;
    padding: 10px;
    border: 1px solid var(--kc-border-color);
    border-radius: 4px;
    background: white;
    text-align: center;
}

/* Responsive */
@media (max-width: 768px) {
    #kc-form-wrapper {
        margin: 10px;
        padding: 20px;
    }
}
```

### Step 6: Add Custom Resources

**Logo:**
```
theme/my-theme/login/resources/img/logo.png
```

**Icons:**
```
theme/my-theme/login/resources/icons/
```

**Fonts:**
```
theme/my-theme/login/resources/fonts/
```

## Theme Messages

### Message Bundles

**File:** `theme/my-theme/login/messages/messages_en.properties`

```properties
# Custom messages
customTitle=Welcome to Our App
customSubtitle=Please sign in to continue

# Override default messages
loginTitle=Sign In
doLogIn=Login
doRegister=Create Account
doForgotPassword=Forgot Password?

# Error messages
invalidUserMessage=Please check your username and try again
```

**Other languages:**
```
messages_es.properties - Spanish
messages_fr.properties - French
messages_de.properties - German
```

## Installing a Theme

### Method 1: Copy to Themes Directory

```bash
# Copy theme to Keycloak
sudo cp -r theme/my-theme /opt/keycloak/themes/

# Set permissions
sudo chown -R keycloak:keycloak /opt/keycloak/themes/my-theme
sudo chmod -R 755 /opt/keycloak/themes/my-theme
```

### Method 2: Create JAR Package

**For distribution:**
```bash
# Create JAR
jar cvf my-theme.jar -C theme my-theme

# Copy to providers
cp my-theme.jar /opt/keycloak/providers/

# Build Keycloak
bin/kc.sh build
```

### Method 3: Docker Volume

```yaml
# docker-compose.yml
version: '3'
services:
  keycloak:
    image: quay.io/keycloak/keycloak:26.5.0
    volumes:
      - ./themes:/opt/keycloak/themes/my-theme:ro
    environment:
      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: admin
    command: start-dev
```

## Configuring Theme

### Set Theme for Realm

**Admin Console:**
1. Realm Settings → Themes
2. Select theme for each type:
   - **Login Theme** - `my-theme`
   - **Account Theme** - `my-theme`
   - **Admin Console Theme** - `keycloak` or `my-theme`
   - **Email Theme** - `my-theme`
3. Click **Save**

### Set Theme per Client

**Admin Console:**
1. Clients → Select client
2. **Settings** tab
3. **Theme** dropdown
4. Select `my-theme`
5. Click **Save`

## Theme Properties Reference

### Common Properties

**Login theme properties:**
```properties
# Logo
logo=resources/img/logo.png
logoWidth=200px
logoHeight=60px

# Colors
kcPrimaryColor=#007bff
kcSecondaryColor=#6c757d

# CSS classes
kcFormClass=login-form
kcInputClass=form-control
kcButtonClass=btn
kcButtonPrimaryClass=btn-primary
kcButtonLargeClass=btn-lg
kcButtonBlockClass=btn-block

# Social providers
kcSocialDisplay=icons
kcSocialProviderListPosition=top

# Internationalization
kcLocaleSupported=en,es,fr,de
kcLocaleDropDownEnabled=true
```

## Advanced Customization

### Custom JavaScript

**File:** `theme/my-theme/login/script.js`

```javascript
// Custom initialization
document.addEventListener('DOMContentLoaded', function() {
    // Add custom validation
    const usernameInput = document.getElementById('username');
    usernameInput.addEventListener('input', function(e) {
        // Custom validation logic
    });

    // Add custom features
    addPasswordToggle();
    addRememberMeTooltip();
});

function addPasswordToggle() {
    const passwordInput = document.getElementById('password');
    const toggleButton = document.createElement('button');
    toggleButton.textContent = 'Show';
    toggleButton.type = 'button';
    toggleButton.onclick = function() {
        if (passwordInput.type === 'password') {
            passwordInput.type = 'text';
            toggleButton.textContent = 'Hide';
        } else {
            passwordInput.type = 'password';
            toggleButton.textContent = 'Show';
        }
    };
    passwordInput.parentNode.appendChild(toggleButton);
}

function addRememberMeTooltip() {
    const rememberMe = document.getElementById('rememberMe');
    if (rememberMe) {
        rememberMe.title = 'Keep me signed in on this device';
    }
}
```

### Include JavaScript in Template

```freemarker
<#import "template.ftl" as layout>
<@layout.registrationLayout; section>
    <#if section = "scripts">
        <script type="module">
            // Your module script
        </script>
        <script nomodule src="${url.resourcesPath}/js/script.js"></script>
    </#if>
</@layout.registrationLayout>
```

## Keycloak v2 Theme Framework

### Component-Based Approach

**Keycloak 26.x uses a component framework:**

**Components:**
```
theme/my-theme/login/keycloak.v2/components/
├── Button/
│   └── Button.component.css
├── Input/
│   └── Input.component.css
└── Card/
    └── Card.component.css
```

**Benefits:**
- Consistent styling
- Reusable components
- Easier maintenance
- Better performance

### Using v2 Components

**Extend v2 components:**
```css
/* theme/my-theme/login/keycloak.v2/components/Button/Button.component.css */
.my-button {
    /* Custom button styles */
    composes: kc-button;
}
```

## Theme Best Practices

### ✅ DO

- Extend base theme when possible
- Use CSS variables for colors
- Support responsive design
- Test on all page types
- Include error pages
- Support accessibility (WCAG 2.1)
- Use semantic HTML
- Test in multiple browsers
- Internationalize messages
- Document customizations

### ❌ DON'T

- Copy entire base theme
- Use inline styles
- Hardcode URLs
- Ignore mobile devices
- Skip error pages
- Break accessibility
- Use deprecated features
- Test only one browser
- Hardcode text (use messages)
- Create undocumented changes

## Accessibility

### WCAG 2.1 Compliance

**Include:**
- Proper ARIA labels
- Keyboard navigation
- Focus indicators
- Screen reader support
- Color contrast (4.5:1 minimum)
- Text alternatives for images
- Skip navigation links

**Example:**
```html
<input type="text"
       id="username"
       name="username"
       aria-label="Username"
       aria-invalid="false"
       aria-describedby="username-error"
       required />

<span id="username-error" role="alert">
    Username is required
</span>
```

## Theme Testing

### Cross-Browser Testing

**Test in:**
- Chrome/Edge (Chromium)
- Firefox
- Safari
- Mobile browsers (iOS Safari, Chrome Mobile)

### Responsive Testing

**Test at:**
- 320px (mobile small)
- 375px (mobile)
- 768px (tablet)
- 1024px (desktop)
- 1920px (large desktop)

### Page Testing

**Test all pages:**
- Login
- Registration
- Forgot password
- Update password
- Verify email
- TOTP setup
- WebAuthn
- Terms and conditions
- Error pages

## Troubleshooting

### Theme Not Loading

**Check:**
1. Theme directory exists in `/opt/keycloak/themes/`
2. `theme.properties` file exists
3. Realm uses correct theme
4. File permissions correct
5. No syntax errors in templates

### CSS Not Applied

**Check:**
1. CSS file path correct
2. CSS file linked in template
3. No CSS errors (check browser console)
4. Cache cleared (hard refresh)

### Templates Not Rendering

**Check:**
1. FreeMarker syntax correct
2. Template imports correct
3. Variables available in context
4. No server-side errors (check logs)

## References

- <https://www.keycloak.org/ui-customization/themes>
- <https://www.keycloak.org/ui-customization/>
- FreeMarker Template Language Documentation
- WCAG 2.1 Guidelines

## Related

- [[keycloak-server-administration]]
- [[keycloak-authentication-flows]]
- [[keycloak-ui-customization]]
