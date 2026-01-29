---
title: Keycloak Authentication Flows
type: reference
domain: Keycloak
tags:
  - keycloak
  - authentication
  - flows
  - authenticators
  - required-actions
  - mfa
  - forms
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Authentication Flows

## Overview

Authentication flows in Keycloak define the sequence of steps a user must complete to authenticate. Flows are highly customizable and support multi-factor authentication, conditional logic, and complex workflows. <https://www.keycloak.org/docs/latest/server_admin/#configuring-authentication>

## Flow Concepts

### What is an Authentication Flow?

A **flow** is a container for:
- **Authenticators** - Validate credentials
- **Screens** - User interaction steps
- **Actions** - Required user actions
- **Execution requirements** - When to run

**Flow types:**
- **Basic flow** - Top-level flow
- **Form flow** - UI-based authentication
- **Client flow** - No UI, machine authentication

### Built-in Flows

**Browser Flow:**
- Used for browser-based applications
- Interactive authentication
- Default for most web apps

**Registration Flow:**
- User self-registration
- Profile creation
- Email verification

**Reset Credentials Flow:**
- Forgot password
- Reset via email
- Update credentials

**Direct Grant Flow:**
- Resource Owner Password Credentials
- Username/password exchange
- Not recommended (use alternatives)

**Http Challenge Client Flow:**
- SPNEGO/Kerberos
- Client certificate authentication
- No user interaction

**Registration Profile Form Flow:**
- Additional registration steps
- Profile completion
- Custom attributes

## Authentication Executions

### Execution Requirements

**Required:**
- Must complete successfully
- Blocks authentication if failed

**Alternative:**
- At least one must succeed
- Used for multiple options

**Disabled:**
- Not executed
- Temporarily turned off

**Conditional:**
- Executes based on condition
- User profile, role, client, etc.

### Authenticator Types

**Form Authenticators:**
- **Username Password Form** - Standard login
- **Registration Page** - User registration
- **Reset Credential** - Forgot password
- **WebAuthn Authenticator** - Passkey authentication
- **WebAuthn Passwordless** - Passwordless passkeys

**Non-Form Authenticators:**
- **Identity Provider Redirector** - Social login
- **SPNEGO** - Kerberos/SSO
- **X509/Client Certificate** - Certificate auth
- **Kerberos** - Windows integrated auth

**Script Authenticator:**
- Custom JavaScript logic
- Flexible validation
- Advanced use cases

### Built-in Authenticators

**Username Password Form:**
- Validates username/password
- Password policies enforced
- Brute force protection

**WebAuthn Authenticator:**
- Two-factor authentication
- Security key support
- Biometric support

**Recovery Authentication Codes:**
- Backup codes for 2FA
- Account recovery
- Prevents lockout

**Identity Provider Redirector:**
- Social login redirect
- Identity brokering
- SAML/SSO integration

**Conditional OTP Form:**
- Conditional 2FA
- Based on user, role, IP
- Risk-based authentication

## Required Actions

### What are Required Actions?

Actions a user **must** complete before accessing applications:

**Built-in Actions:**
- **UPDATE_PASSWORD** - Change password
- **CONFIGURE_TOTP** - Setup 2FA
- **UPDATE_PROFILE** - Update profile
- **VERIFY_EMAIL** - Verify email address
- **TERMS_AND_CONDITIONS** - Accept terms
- **UPDATE_USER_LOCALE** - Set language
- **mobile-delete-account** - Delete mobile account

### Configuring Required Actions

**Set for user:**
1. Users → Select user
2. **Required Actions** tab
3. Select actions from dropdown
4. Click **Add selected**

**Set as default:**
1. Authentication → Required Actions
2. Set default actions
3. Configure action priority

**Set in authentication flow:**
1. Authentication → Flows
2. Add "Conditional Flow" or "Conditional User Configured"
3. Configure action execution

### Custom Required Actions

**Create custom action:**
```java
public class CustomRequiredAction
    implements RequiredActionFactory<CustomRequiredActionProvider> {

    @Override
    public String getDisplayText() {
        return "Custom Action";
    }

    @Override
    public void evaluateTriggers(RequiredActionContext context) {
        // Determine if action is needed
        UserModel user = context.getUser();
        if (needsAction(user)) {
            context.getEvent().user(user)
                .detail("customAction", "triggered");
        }
    }
}
```

## Creating Custom Flows

### Flow Creation

**Admin Console:**
1. Authentication → Flows
2. Click **New flow**
3. Configure:
   - **Alias** - Internal flow name
   - **Description** - Flow description
   - **Flow Type** - Generic, Form, or Client
4. Click **Add**

### Adding Executions

**Add to flow:**
1. Select flow
2. **Add execution**
3. Choose authenticator
4. Set requirement:
   - **Required** - Must succeed
   - **Alternative** - One of alternatives
   - **Disabled** - Not active
   - **Conditional** - Based on condition
5. Click **Add**

**Add sub-flow:**
1. Select flow
2. **Add execution** → **Add flow**
3. Choose existing flow or create new
4. Set requirement
5. Click **Add**

### Conditional Executions

**Conditions:**
- **User configured** - User attribute set
- **Role** - User has role
- **Client** - Specific client
- **Client Scope** - Client scope mapping
- **User Property** - User attribute value
- **Time** - Date/time based
- **Group membership** - User in group
- **Script** - Custom JavaScript condition

**Example: Conditional 2FA for admin users**

1. Create flow: "Admin 2FA"
2. Add executions:
   - **Conditional Role** → `admin` role
   - **WebAuthn Authenticator** (required)
   - **Conditional OTP Form** (alternative)

## Authentication Flow Examples

### Standard Login Flow

**Browser Flow (default):**
```
1. Cookie Reset (alternative)
2. Auth Forms (conditional)
   └─ Username Password Form (required)
3. WebAuthn Browser (conditional)
   ├─ WebAuthn Authenticator (alternative)
   ├─ WebAuthn Passwordless (alternative)
   └─ Password Form (alternative)
```

### Multi-Factor Authentication Flow

**Custom "MFA Login" Flow:**
```
1. Username Password Form (required)
2. Conditional 2FA (conditional)
   Condition: User in "2FA Users" group
   Executions:
   ├─ WebAuthn Authenticator (alternative)
   ├─ TOTP Form (alternative)
   └─ Recovery Codes (alternative)
```

### Step-up Authentication Flow

**Custom "High Security" Flow:**
```
1. Username Password Form (required)
2. Device Trust (conditional)
   Condition: Client is "high-security-app"
   Executions:
   ├─ WebAuthn Authenticator (required)
   ├─ X509 Validate (alternative)
   └─ Device Script (alternative)
```

### Registration with Verification

**Registration Flow (customized):**
```
1. Registration Page (required)
2. Registration Profile (required)
3. Verify Email (conditional)
   Condition: Email not verified
   Executions:
   └─ Verify Email (required)
4. Terms and Conditions (required)
5. Mobile 2FA (conditional)
   Condition: User uses mobile client
   Executions:
   └─ Configure Mobile OTP (alternative)
```

## Configuring Flows for Clients

### Bind Flow to Client

**Admin Console:**
1. Clients → Select client
2. **Authentication** tab
3. **Flow Override**
4. Select flow for binding:
   - Browser flow
   - Registration flow
   - Direct grant flow
   - Reset credentials flow
5. Click **Save**

**Example:** Require WebAuthn for admin client
1. Create "Admin Login" flow with WebAuthn required
2. Bind admin console client to "Admin Login" flow

## Flow Ordering

### Execution Order

**Top-down execution:**
1. First execution runs
2. If required and fails → authentication fails
3. If alternative and fails → next alternative runs
4. Continue until all required succeed

**Sub-flow execution:**
1. Parent flow execution reaches sub-flow
2. Sub-flow executes completely
3. Parent flow continues after sub-flow completes

### Best Practices

**✅ DO:**
- Start with built-in flows
- Test custom flows thoroughly
- Use alternatives for multiple options
- Document custom flow logic
- Use conditional executions for flexibility
- Monitor flow execution in logs

**❌ DON'T:**
- Modify built-in flows (create copy)
- Create overly complex flows
- Ignore error handling
- Forget about user experience
- Skip testing edge cases

## Troubleshooting Flows

### Common Issues

**Flow not executing:**
- Verify flow bound to client
- Check execution requirements
- Review authentication logs
- Test with different user

**Alternative not working:**
- Verify requirement set to "Alternative"
- Check for execution errors
- Review condition configuration
- Test each alternative individually

**Required action not shown:**
- Check action enabled
- Verify user needs action
- Review flow configuration
- Check browser console for errors

### Debug Logging

**Enable authentication logging:**
```bash
bin/kc.sh start-dev \
  --log-level=org.keycloak.authentication:DEBUG \
  --log-level=org.keycloak.services:DEBUG
```

**Monitor flow execution:**
```
Realm Settings → Events → Save events
View authentication events and errors
```

## Advanced Features

### Passwordless Authentication

**WebAuthn Passwordless:**
- No password required
- Biometric or security key
- Phishing-resistant

**Setup:**
1. Enable WebAuthn passwordless
2. Add to authentication flow
3. Configure authenticator settings

### Conditional Authentication

**Risk-based authentication:**
- High-value actions require MFA
- Unknown devices require verification
- Suspicious locations trigger additional checks

**Implementation:**
- Use conditional executions
- Script authenticator for custom logic
- User profile conditions

### Social Login Integration

**Identity Provider Redirector:**
1. Add to flow
2. Configure provider
3. Set alias
4. Configure display order

**Multiple IdPs:**
```
1. Cookie Reset (alternative)
2. Identity Provider Redirector (alternative)
   Provider: google
3. Identity Provider Redirector (alternative)
   Provider: github
4. Username Password Form (alternative)
```

## Flow Best Practices

### Security

**✅ DO:**
- Require MFA for sensitive operations
- Use conditional authentication
- Enable brute force protection
- Monitor authentication events
- Use short-lived sessions

**❌ DON'T:**
- Allow username/password only for sensitive apps
- Ignore failed authentication attempts
- Use resource owner password grant
- Disable required actions
- Skip MFA for admin accounts

### User Experience

**✅ DO:**
- Provide clear error messages
- Support progressive enrollment
- Offer alternative methods
- Remember user preferences
- Allow account recovery

**❌ DON'T:**
- Force too many steps
- Make flows overly complex
- Hide authentication requirements
- Prevent logout
- Lose user state

### Performance

**✅ DO:**
- Cache authentication decisions
- Use efficient conditions
- Minimize database queries
- Monitor flow execution time
- Test under load

**❌ DON'T:**
- Create deep nesting
- Use expensive scripts
- Ignore caching
- Block indefinitely
- Skip performance testing

## References

- <https://www.keycloak.org/docs/latest/server_admin/#configuring-authentication>
- Authentication flows documentation
- Authenticator SPI documentation

## Related

- [[keycloak-server-administration]]
- [[keycloak-security]]
- [[keycloak-spi]]
- [[keycloak-sessions]]
