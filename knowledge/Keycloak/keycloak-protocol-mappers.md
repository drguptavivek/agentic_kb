---
title: Keycloak Protocol Mappers
type: reference
domain: Keycloak
tags:
  - keycloak
  - mappers
  - protocol-mappers
  - oidc
  - saml
  - claims
  - tokens
  - attributes
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Protocol Mappers

## Overview

Protocol mappers add claims and attributes to tokens issued by Keycloak. They map user attributes, roles, and other data to protocol-specific representations in OIDC ID tokens, access tokens, and SAML assertions.

## What is a Protocol Mapper?

**Purpose:** Transform internal data into external protocol format

**Internal data:**
- User attributes (username, email, custom)
- User roles
- Group memberships
- Client information
- Session data

**External format:**
- OIDC claims (JSON in JWT)
- SAML attributes (XML in assertion)

**Mapping flow:**
```
Internal Data → Protocol Mapper → Protocol Format → Token
    (User)       (Transform)        (JWT/SAML)    (Issued)
```

## Built-in Protocol Mappers

### OIDC Protocol Mappers

#### User Property Mapper

**Purpose:** Map standard user properties to claims

**Properties available:**
- `username` - User's username
- `email` - User's email
- `firstName` - User's first name
- `lastName` - User's last name
- `locale` - User's locale
- `zoneOffset` - User's timezone offset

**Configuration:**
- **Name:** Display name for mapper
- **User Property:** Property to map (username, email, etc.)
- **Token Claim Name:** Claim name in token (e.g., "preferred_username")
- **Claim JSON Type:** String, boolean, number, long
- **Add to ID token:** Include in ID token
- **Add to access token:** Include in access token
- **Add to userinfo:** Include in userinfo response
- **Add to ID token on refresh:** Include in refreshed ID token

**Example:**
```
Name: Username to preferred_username
User Property: username
Token Claim Name: preferred_username
Claim JSON Type: String
Add to ID token: ON
Add to access token: ON
```

**Result in ID token:**
```json
{
  "preferred_username": "john.doe",
  "email": "john.doe@example.com"
}
```

#### User Attribute Mapper

**Purpose:** Map custom user attributes to claims

**Configuration:**
- **Name:** Display name
- **User Attribute:** Custom attribute name
- **Token Claim Name:** Claim name in token
- **Claim JSON Type:** String, boolean, JSON, long
- **Add to token:** Same as User Property Mapper

**Example:**
```
Name: Department
User Attribute: department
Token Claim Name: department
Claim JSON Type: String
Add to ID token: ON
```

**Result:**
```json
{
  "department": "Engineering"
}
```

#### Group Membership Mapper

**Purpose:** Add user's group memberships to token

**Configuration:**
- **Name:** Display name
- **Token Claim Name:** Claim name (default: "groups")
- **Full group path:** Include full group path or just name
- **Add to ID token:** Include in ID token
- **Add to access token:** Include in access token
- **Add to userinfo:** Include in userinfo response

**Example:**
```
Name: Groups
Token Claim Name: groups
Full group path: OFF
Add to ID token: ON
```

**Result:**
```json
{
  "groups": [
    "Developers",
    "Backend-Team",
    "Managers"
  ]
}
```

#### Audience Mapper

**Purpose:** Add audience to access token

**Configuration:**
- **Name:** Display name
- **Included Client Audience:** Client ID to add as audience
- **Add to access token:** Always ON

**Use case:** Enable token exchange between clients

**Example:**
```
Name: Add API audience
Included Client Audience: my-api-service
```

**Result:**
```json
{
  "aud": [
    "my-app",
    "my-api-service"
  ]
}
```

#### Client IP Address Mapper

**Purpose:** Include client's IP address in token

**Configuration:**
- **Name:** Display name
- **Token Claim Name:** Claim name (default: "clientAddress")
- **Add to access token:** Always ON

**Use case:** IP-based access control in resource server

**Result:**
```json
{
  "clientAddress": "192.168.1.100"
}
```

#### Allowed Web Origins Mapper

**Purpose:** Add allowed web origins to token

**Use case:** CORS configuration in token itself

#### Time-Based OIDC Claims Mapper

**Purpose:** Add time-based claims (auth_time, updated_at)

**Configuration:**
- **Name:** Display name
- **Token Claim Name:** Claim name
- **Add to ID token:** Include in ID token
- **Add to access token:** Include in access token

**Available claims:**
- `auth_time` - When authentication occurred
- `updated_at` - When user was last updated

**Result:**
```json
{
  "auth_time": 1706524800,
  "updated_at": 1706524800
}
```

#### Access Token Context Mapper

**Purpose:** Set client session notes in access token

**Configuration:**
- **Name:** Display name
- **Client Session Note:** Note name (e.g., "customData")
- **Token Claim Name:** Claim name

**Use case:** Pass arbitrary data through authentication flow

#### Script Mapper

**Purpose:** Custom JavaScript-based mapping logic

**Configuration:**
- **Name:** Display name
- **Script:** JavaScript code
- **Add to token:** Select which tokens

**Example script:**
```javascript
// Transform user attribute
var userAttribute = user.getAttribute("customAttribute");
if (userAttribute != null && userAttribute.size() > 0) {
    exports.transformedValue = userAttribute.get(0);
} else {
    exports.transformedValue = "default";
}
```

**Access context:**
- `user` - UserModel
- `realm` - RealmModel
- `token` - Token representation
- `session` - UserSessionModel
- `clientSession` - ClientSessionModel
- `mappedAssertion` - Current assertion (SAML)

### SAML Protocol Mappers

#### SAML Role List Mapper

**Purpose:** Map user roles to SAML Role attributes

**Configuration:**
- **Name:** Display name
- **SAML Attribute Name:** Attribute name (default: "Role")
- **Friendly Name:** Friendly name for attribute
- **Single Role Attribute:** Single vs multiple values

**Result:**
```xml
<saml:Attribute NameFormat="urn:oasis:names:tc:SAML:2.0:attrname-format:basic"
                 Name="Role"
                 FriendlyName="role">
  <saml:AttributeValue>admin</saml:AttributeValue>
  <saml:AttributeValue>user</saml:AttributeValue>
</saml:Attribute>
```

#### SAML Group List Mapper

**Purpose:** Map user groups to SAML attributes

**Configuration:**
- **Name:** Display name
- **SAML Attribute Name:** Attribute name (default: "group")
- **Friendly Name:** Friendly name
- **Full Group Path:** Include full path

#### User Attribute Mapper (SAML)

**Purpose:** Map user attributes to SAML attributes

**Configuration:**
- **Name:** Display name
- **SAML Attribute Name:** SAML attribute name
- **Friendly Name:** Friendly name
- **User Attribute:** User attribute name
- **Attribute Value:** Custom value or use user attribute

## Client Scope Mappers

### What are Client Scopes?

Reusable collections of protocol mappers.

**Built-in client scopes:**
- **profile** - Basic profile claims
- **email** - Email address and verification
- **address** - Postal address
- **phone** - Phone number
- **offline_access** - Refresh token support
- **roles** - User roles
- **microprofile-jwt** - MicroProfile JWT claims

### Adding Mapper to Client Scope

**Admin Console:**
1. Client Scopes → Select scope (e.g., "profile")
2. **Add mapper** → Choose mapper type
3. Configure mapper
4. **Save**

### Creating Custom Client Scope

1. Client Scopes → Create client scope
2. Name: `my-custom-scope`
3. Protocol: `openid-connect` or `saml`
4. **Save**
5. Add mappers as needed

### Assigning Client Scope to Client

**Admin Console:**
1. Clients → Select client
2. **Client scopes** tab
3. **Add client scope** → Select scope
4. Set as:
   - **Default** - Automatically included
   - **Optional** - User must request

**Scope types:**
- **Default scope** - Always included in tokens
- **Optional scope** - User explicitly requests

## Advanced Mapper Patterns

### Conditional Claims

**Include claim based on condition:**

**Example: Only include department if user is employee**

1. **Use Script Mapper:**
```javascript
var userGroups = user.getGroups();
var isEmployee = false;

for each (var group in userGroups) {
  if (group.getName().equals("Employees")) {
    isEmployee = true;
    break;
  }
}

if (isEmployee) {
  exports.transformedValue = user.getAttribute("department").get(0);
} else {
  exports.transformedValue = null;
}
```

### Complex JSON Claims

**Nested JSON structures:**

**Example: Organization info**
```javascript
var orgName = user.getFirstAttribute("organization");
var dept = user.getFirstAttribute("department");
var location = user.getFirstAttribute("location");

var orgInfo = {
  name: orgName,
  department: dept,
  location: location
};

exports.transformedValue = JSON.stringify(orgInfo);
```

**Result in token:**
```json
{
  "organization_info": {
    "name": "Acme Corp",
    "department": "Engineering",
    "location": "San Francisco"
  }
}
```

### Role-Based Claims

**Map roles to custom claim structure:**

**Example: Flatten roles**
```javascript
var realmRoles = user.getRealmRoleMappings();
var clientRoles = user.getClientRoleMappings(clientId);

var roles = [];

// Add realm roles
for each (var role in realmRoles) {
  roles.push("realm:" + role.getName());
}

// Add client roles
for each (var role in clientRoles) {
  roles.push("client:" + role.getClientId() + ":" + role.getName());
}

exports.transformedValue = JSON.stringify(roles);
```

**Result:**
```json
{
  "roles": [
    "realm:admin",
    "realm:user",
    "client:myapp:editor"
  ]
}
```

## Mapper Configuration in Practice

### Example 1: Custom Claims for API

**Scenario:** API needs user's department and manager

**Solution:**
1. **Create User Attribute Mappers:**
   - Mapper 1: `department` attribute → `department` claim
   - Mapper 2: `manager` attribute → `manager` claim

2. **Add to client scope or directly to client**

**Result:**
```json
{
  "sub": "12345678-1234-1234-1234-123456789abc",
  "department": "Engineering",
  "manager": "john.smith@example.com"
}
```

### Example 2: Group-Based Authorization

**Scenario:** Application needs user's groups for authorization

**Solution:**
1. **Group Membership Mapper**
2. **Configuration:**
   - Token Claim Name: `groups`
   - Full Group Path: OFF
   - Add to access token: ON

**Result:**
```json
{
  "groups": [
    "Developers",
    "Backend-Team"
  ]
}
```

**Application usage:**
```javascript
// Check if user is in Developers group
const hasAccess = token.groups.includes("Developers");
```

### Example 3: Multi-Tenant Application

**Scenario:** API needs to know which organizations user can access

**Solution:**
1. **User Attribute:** `organizations` (comma-separated)
2. **Script Mapper:**
```javascript
var orgsAttr = user.getAttribute("organizations");
var orgs = [];

if (orgsAttr != null && orgsAttr.size() > 0) {
  var orgsStr = orgsAttr.get(0);
  orgs = orgsStr.split(",");
}

exports.transformedValue = JSON.stringify(orgs);
```

**Result:**
```json
{
  "organizations": [
    "acme-corp",
    "partner-xyz"
  ]
}
```

## Best Practices

### Mapper Design

**✅ DO:**
- Use descriptive claim names
- Follow naming conventions
- Document mapper purpose
- Use client scopes for reusability
- Test mapper output
- Validate claim values
- Consider token size
- Use standard claim names when possible

**❌ DON'T:**
- Create duplicate mappers
- Use vague claim names
- Skip documentation
- Add too many mappers (token bloat)
- Include sensitive data unnecessarily
- Use inconsistent naming
- Forget about privacy
- Overcomplicate simple mappings

### Claim Naming

**Follow standards:**

**OIDC standard claims:**
- `sub` - Subject (user ID)
- `name` - Full name
- `given_name` - First name
- `family_name` - Last name
- `preferred_username` - Username
- `email` - Email address
- `picture` - Profile picture URL

**Custom claims:**
- Use namespaces or prefixes
- Example: `app_department`, `app_manager`
- Example: `https://example.com/claims/department`

**Avoid:**
- Common names: `role`, `group`, `user` (conflicts)
- Cryptic names: `d`, `m`, `u`
- Inconsistent prefixes

### Token Size

**Considerations:**
- More claims = larger token
- HTTP header limits
- Browser cookie limits
- Database storage size

**Recommendations:**
- Limit mappers to <20 per client
- Keep claim values concise
- Use references instead of full data
- Compress when necessary

**Example:**
```
❌ Bad - Include full user profile
"profile": {
  "name": "John Doe",
  "email": "john@example.com",
  "phone": "+1-555-0123",
  "address": { ... },
  "preferences": { ... }
}

✅ Good - Include reference
"profile_id": "12345",
"profile_url": "https://api.example.com/users/12345"
```

## Performance Considerations

### Mapper Execution

**Order of execution:**
1. Built-in mappers (fast)
2. Script mappers (slower)
3. External mappers (slowest)

**Optimization:**
- Use built-in mappers when possible
- Cache expensive operations in script mappers
- Limit script mapper complexity
- Profile mapper performance

### Database Queries

**Avoid N+1 queries:**
```javascript
// ❌ Bad - Queries for each user
var roles = user.getRoleMappings();  // DB query
var groups = user.getGroups();        // Another DB query

// ✅ Good - Use available data
var roles = user.getRealmRoleMappingsStream()
               .collect(Collectors.toList());
```

## Troubleshooting

### Claim Not Appearing in Token

**Debug steps:**
1. Check mapper enabled
2. Verify "Add to token" selected
3. Check client scope assigned
4. Verify scope requested
5. Check user has data
6. Review logs

**CLI inspection:**
```bash
# Decode access token
echo $ACCESS_TOKEN | jq .

# Check client scopes
kcadm.sh get clients/myapp/client-scopes -r myrealm

# Get client mappers
kcadm.sh get clients/myapp/protocol-mappers/oidc -r myrealm
```

### Script Mapper Errors

**Common issues:**
- Syntax errors in JavaScript
- Missing null checks
- Type conversion errors
- API version issues

**Debugging:**
```javascript
// Add logging
System.out.println("User: " + user.getUsername());

// Check for null
if (userAttribute != null) {
  // Process attribute
} else {
  // Handle null case
  System.out.println("Attribute is null");
}

// Print output
System.out.println("Transformed value: " + exports.transformedValue);
```

## References

- <https://www.keycloak.org/docs/latest/server_admin/#protocol-mappers>
- OIDC Claims Specification
- SAML 2.0 Specification

## Related

- [[keycloak-server-administration]]
- [[keycloak-securing-apps-oidc]]
- [[keycloak-client-scopes]]
