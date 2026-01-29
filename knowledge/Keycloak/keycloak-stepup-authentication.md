---
title: Keycloak Step-Up Authentication
type: reference
domain: Keycloak
tags:
  - keycloak
  - step-up-auth
  - adaptive-authentication
  - mfa
  - risk-based
  - conditional
  - security
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Step-Up Authentication

## Overview

Step-up authentication (also known as adaptive or risk-based authentication) dynamically adjusts authentication requirements based on context, risk level, or requested resource. Instead of static authentication flows, Keycloak can require additional verification for sensitive operations or high-risk scenarios. <https://www.keycloak.org/docs/latest/server_admin/#configuring-authentication>

## What is Step-Up Authentication?

**Definition:** Progressive authentication that adapts based on:

**Context factors:**
- User roles and groups
- Client/application being accessed
- Resource sensitivity
- User's current session strength
- Network location/IP address
- Time of access

**Risk-based decisions:**
- Standard access: username/password only
- Sensitive access: + MFA required
- High-risk access: + additional verification
- Admin functions: + multiple factors

**Benefits:**
- Better security without sacrificing UX
- Progressive authentication (step-up when needed)
- Context-aware access control
- Reduced user friction for low-risk scenarios

## Step-Up Use Cases

### Use Case 1: Role-Based Step-Up

**Scenario:** Admin users require MFA, regular users don't

**Implementation:**
```
Browser Flow:
1. Username Password Form (required)
2. Conditional Role: admin (conditional)
   Condition: User has role 'admin'
   Executions:
   └─ WebAuthn Authenticator (required)
```

**Behavior:**
- Regular users: Password only
- Admin users: Password + WebAuthn

### Use Case 2: Resource-Based Step-Up

**Scenario:** Accessing sensitive resources requires stronger auth

**Implementation:**
```
Browser Flow:
1. Username Password Form (required)
2. Conditional User Configured: requiresMFA (conditional)
   Condition: User attribute 'requiresMFA' is set
   Executions:
   ├─ WebAuthn Authenticator (alternative)
   ├─ TOTP Form (alternative)
   └─ Recovery Codes (alternative)
```

**Workflow:**
1. User logs in with password
2. Keycloak checks user attributes
3. If `requiresMFA=true`, prompts for MFA
4. User completes MFA, access granted

### Use Case 3: Client-Based Step-Up

**Scenario:** Admin console requires stronger authentication

**Implementation:**
```
Browser Flow (bound to admin-console client):
1. Username Password Form (required)
2. Conditional Client: admin-console (conditional)
   Condition: Client ID is 'admin-console'
   Executions:
   ├─ WebAuthn Authenticator (required)
   └─ Script Authenticator (check session)
```

**Bind flow to client:**
1. Clients → admin-console
2. **Authentication** tab → **Browser flow**
3. Select "Admin Step-Up" flow

### Use Case 4: Time-Based Step-Up

**Scenario:** Banking requires MFA during business hours

**Implementation:**
```
Browser Flow:
1. Username Password Form (required)
2. Conditional Time: business-hours (conditional)
   Condition: Time between 09:00-17:00, Mon-Fri
   Executions:
   └─ TOTP Form (required)
```

### Use Case 5: IP-Based Step-Up

**Scenario:** External network requires additional verification

**Implementation:**
```
Browser Flow:
1. Username Password Form (required)
2. Conditional Script: internal-network (conditional)
   Condition: Script checks IP address
   Executions:
   └─ WebAuthn Authenticator (alternative)
```

**Script:**
```javascript
// Network-based authentication
var remoteAddr = httpRequest.getRemoteAddr();
var internalNetworks = ["192.168.1.0/24", "10.0.0.0/8"];
var isInternal = false;

for each (var network in internalNetworks) {
  if (isInNetwork(remoteAddr, network)) {
    isInternal = true;
    break;
  }
}

if (!isInternal) {
  // Require MFA for external access
  outcome = "challenged";
} else {
  outcome = "authenticated";
}
```

## Implementation Patterns

### Pattern 1: Conditional Execution

**Using built-in conditions:**

**Role-based:**
```
1. Authentication → Flows → Browser Flow
2. Add execution → Conditional Role
3. Configure:
   - Role: admin
   - On success: challenge (require MFA)
   - On failure: skip (no MFA)
4. Add MFA execution as conditional child
```

**Group-based:**
```
1. Add execution → Conditional Group
2. Configure:
   - Group: High-Security-Users
   - On success: require MFA
   - On failure: allow
```

**User attribute-based:**
```
1. Add execution → Conditional User Configured
2. Configure:
   - User attribute: securityLevel
   - Expected value: high
   - On match: require MFA
```

**Client-based:**
```
1. Add execution → Conditional Client
2. Configure:
   - Client ID: admin-console
   - On match: require MFA
```

### Pattern 2: Script Authenticator

**Custom conditional logic:**

```javascript
// Complex step-up logic
// Script authenticator in authentication flow

// Get user context
var user = authenticationSession.getAuthenticatedUser();
var client = session.getContext().getClient();
var realm = session.getContext().getRealm();
var httpRequest = session.getContext().getHttpRequest();

// Check multiple conditions
var requiresStepUp = false;
var reason = "";

// 1. Check user role
if (user.hasRealmRole("admin")) {
  requiresStepUp = true;
  reason = "admin_role";
}

// 2. Check client
if (client.getClientId().equals("admin-console")) {
  requiresStepUp = true;
  reason = "admin_console";
}

// 3. Check IP address
var remoteAddr = httpRequest.getRemoteAddr();
if (!isInternalNetwork(remoteAddr)) {
  requiresStepUp = true;
  reason = "external_network";
}

// 4. Check time
var hour = new java.util.Date().getHours();
if (hour >= 17 || hour < 9) {
  requiresStepUp = true;
  reason = "outside_hours";
}

// Make decision
if (requiresStepUp) {
  // Require MFA
  outcome = "challenge";
  // Store reason for logging
  authenticationSession.setUserSessionNote("stepup_reason", reason);
} else {
  // Allow login
  outcome = "authenticated";
}
```

### Pattern 3: Sub-Flow Execution

**Create reusable step-up flow:**

**Main flow (Browser):**
```
1. Username Password Form (required)
2. Conditional Script: needs-step-up (conditional)
   └─ Executions: Step-Up Sub-Flow (sub-flow)
```

**Sub-Flow (Step-Up Sub-Flow):**
```
1. WebAuthn Authenticator (alternative)
2. TOTP Form (alternative)
3. OTP Form via Email (alternative)
```

**Benefit:** Reusable step-up flow

### Pattern 4: Client Session Notes

**Store authentication context:**

```javascript
// Set authentication strength
authenticationSession.setUserSessionNote("auth_strength", "high");

// Store step-up reason
authenticationSession.setUserSessionNote("stepup_reason", "admin_access");

// Store timestamp
authenticationSession.setUserSessionNote("stepup_time", new java.util.Date().toString());
```

**Read in later authenticators:**
```javascript
var authStrength = authenticationSession.getUserSessionNote("auth_strength");
var stepupReason = authenticationSession.getUserSessionNote("stepup_reason");

if (authStrength.equals("high")) {
  // Already stepped up, skip
  outcome = "authenticated";
} else {
  // Need step-up
  outcome = "challenge";
}
```

## Configuring Step-Up

### Step 1: Create Authentication Flow

**Admin Console:**
1. Authentication → Flows
2. Click **New flow**
3. Name: `Step-Up Login`
4. Flow Type: **Generic**
5. Click **Create**

### Step 2: Add Required Authentication

**Add username/password:**
1. Select `Step-Up Login` flow
2. **Add execution**
3. Select: **Username Password Form**
4. Requirement: **Required**
5. Click **Add**

### Step 3: Add Conditional Step-Up

**Add conditional logic:**
1. **Add execution** → **Conditional Role**
2. Configure:
   - **Alias:** `admin-step-up`
   - **Condition:** User has role `admin`
   - **On success:** `challenge`
   - **On fail:** `skip`
3. Click **Add**

### Step 4: Add MFA Execution

**Add under conditional:**
1. Select conditional execution
2. **Add execution** → **WebAuthn Authenticator**
3. Requirement: **Required**
4. Click **Add**

### Step 5: Test Flow

**Test with admin user:**
1. Login as admin user
2. Should prompt for WebAuthn
3. Verify MFA required

**Test with regular user:**
1. Login as regular user
2. Should NOT prompt for MFA
3. Should login directly

## Advanced Step-Up Scenarios

### Scenario 1: Progressive Step-Up

**Multiple levels of authentication:**

```
Browser Flow:
1. Username Password Form (required)
2. Conditional Script: sensitivity-check (conditional)
   └─ Executions:
      ├─ Low sensitivity (skip)
      ├─ Medium sensitivity → Conditional Sub-Flow
      │  └─ Executions:
      │     ├─ WebAuthn Authenticator (alternative)
      │     └─ TOTP Form (alternative)
      └─ High sensitivity → Conditional Sub-Flow
         └─ Executions:
            ├─ WebAuthn Authenticator (required)
            ├─ TOTP Form (required)
            └─ OTP Email (required)
```

**Script for sensitivity check:**
```javascript
var requestedResource = session.getAttribute("requested_resource");
var userRole = user.getRealmRoleMappingsStream()
                         .map(Role::getName)
                         .collect(Collectors.toList());

var sensitivity = "low";

// Check resource
if (requestedResource != null && requestedResource.equals("/admin")) {
  sensitivity = "high";
}

// Check user role
if (userRole.contains("super_admin")) {
  sensitivity = "high";
}

authenticationSession.setUserSessionNote("sensitivity", sensitivity);
```

### Scenario 2: Session Revocation

**Revoke step-up after time:**

```javascript
// In authenticator
var stepupTime = authenticationSession.getUserSessionNote("stepup_time");
if (stepupTime != null) {
  var stepupDate = new java.util.Date(stepupTime);
  var now = new java.util.Date();
  var diff = now.getTime() - stepupDate.getTime();
  var hours = diff / (1000 * 60 * 60);

  // Step-up expires after 8 hours
  if (hours > 8) {
    // Require step-up again
    outcome = "challenge";
  } else {
    // Use existing step-up
    outcome = "authenticated";
  }
}
```

### Scenario 3: Device Trust

**Remember trusted devices:**

```javascript
// Check device trust
var deviceId = httpRequest.getCookie("device_id");
var trustedDevices = user.getAttribute("trusted_devices");

if (trustedDevices != null && trustedDevices.contains(deviceId)) {
  // Trusted device, skip MFA
  outcome = "authenticated";
} else {
  // New or untrusted device, require MFA
  outcome = "challenge";
}
```

**Store device after MFA:**
```javascript
// After successful MFA
var deviceId = generateDeviceId();
var trustedDevices = user.getAttribute("trusted_devices") || [];
trustedDevices.add(deviceId);
user.setAttribute("trusted_devices", trustedDevices);
```

## Best Practices

### Step-Up Design

**✅ DO:**
- Start simple, add complexity gradually
- Use built-in conditions when possible
- Document step-up logic
- Test with different user types
- Monitor step-up success rates
- Provide user feedback
- Consider user experience
- Log step-up events

**❌ DON'T:**
- Over-complicate flows
- Step-up for every action
- Skip user communication
- Ignore performance impact
- Forget mobile experience
- Create deep nesting
- Hardcode conditions
- Skip testing

### User Experience

**✅ DO:**
- Explain why step-up is needed
- Show what's required
- Provide alternatives
- Remember trusted devices
- Allow step-down
- Clear error messages
- Fast verification

**❌ DON'T:**
- Surprise users with MFA
- Make step-up permanent
- Provide no alternatives
- Forget about context
- Slow down verification
- Confusing errors
- Too many steps

### Security

**✅ DO:**
- Use multiple factors for high security
- Verify device trust
- Check session freshness
- Validate context data
- Log step-up events
- Monitor for anomalies
- Regular review of rules

**❌ DON'T:**
- Rely on single factor
- Trust devices blindly
- Ignore session age
- Skip validation
- Forget logging
- Ignore anomalies
- Never review rules

## Performance Considerations

### Efficient Conditions

**Use efficient checks:**
- Role/group checks (fast)
- Client checks (fast)
- User attribute checks (fast)
- Script checks (slower)

**Avoid:**
- Database queries in scripts
- External API calls
- Complex computations
- Loops over large datasets

**Example:**
```javascript
// ✅ Fast - Role check
if (user.hasRealmRole("admin")) {
  outcome = "challenge";
}

// ❌ Slow - External API
var response = httpClient.get("https://api.example.com/check");
var isRisky = JSON.parse(response).risk;
```

### Caching

**Cache context data:**
```javascript
// Cache user roles in session note
var userRoles = authenticationSession.getUserSessionNote("cached_roles");

if (userRoles == null) {
  // Cache miss - compute and cache
  userRoles = user.getRealmRoleMappingsStream()
                   .map(Role::getName)
                   .collect(Collectors.toList());

  authenticationSession.setUserSessionNote("cached_roles", userRoles);
}

// Use cached data
if (userRoles.contains("admin")) {
  outcome = "challenge";
}
```

## Troubleshooting

### Step-Up Not Triggering

**Debug steps:**
1. Verify conditional execution configured correctly
2. Check user has required role/group
3. Verify client matches condition
4. Check user attribute set correctly
5. Review authentication logs

**Debug logging:**
```bash
bin/kc.sh start-dev \
  --log-level=org.keycloak.authentication:DEBUG \
  --log-level=org.keycloak.models:DEBUG
```

### Always Requiring MFA

**Problem:** Conditional always executes

**Check:**
- Condition is not mutually exclusive
- "On success" should be "challenge"
- "On fail" should be "skip"

**Fix:**
```
Conditional Role: admin
├─ On success: challenge  ✅ (requires MFA)
└─ On fail: skip        ✅ (allows without MFA)
```

### Flow Not Binding to Client

**Problem:** Step-up flow not used for client

**Check:**
1. Client → Authentication → Browser flow
2. Verify correct flow selected
3. Check for flow override

**Fix:**
1. Select correct flow in client settings
2. Or leave empty for realm default

## Monitoring Step-Up

### Events to Monitor

**Enable event logging:**
```
Realm Settings → Events → Save events
```

**Key events:**
- `LOGIN` - Successful login
- `LOGIN_ERROR` - Failed login
- `CODE_TO_TOKEN` - Token exchange
- `CUSTOM_REQUIRED_ACTION` - Required action executed

**Check step-up events:**
1. Realm Settings → Events
2. Filter by user
3. Review authentication flow
4. Check for MFA events

### Metrics

**Monitor:**
- Step-up success rate
- MFA failure rate
- Average login time with step-up
- User complaints/issues

## References

- <https://www.keycloak.org/docs/latest/server_admin/#configuring-authentication>
- Authentication flows documentation
- Conditional authentication guide

## Related

- [[keycloak-authentication-flows]]
- [[keycloak-security]]
- [[keycloak-webauthn]]
- [[keycloak-passkeys-webauthn]]
