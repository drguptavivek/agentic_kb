---
title: Keycloak Authorization Services
type: reference
domain: Keycloak
tags:
  - keycloak
  - authorization
  - uma
  - resource-based
  - permissions
  - policies
  - fine-grained
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Authorization Services

## Overview

Keycloak Authorization Services provides a comprehensive, centralized authorization solution based on the User-Managed Access (UMA) specification. It enables fine-grained, resource-based authorization for applications and services. <https://www.keycloak.org/docs/latest/authorization_services/>

## Key Concepts

### Authorization vs Authentication

| Aspect | Authentication | Authorization |
|--------|----------------|---------------|
| **Purpose** | Who are you? | What can you do? |
| **Protocol** | OIDC, SAML | UMA, XACML-like |
| **Output** | Access Token | RPT (Requesting Party Token) |
| **Keycloak** | Default behavior | Optional feature |

### Authorization Architecture

**Components:**
- **Resource Server** - Application hosting protected resources
- **Resource Owner** - Entity that owns the resource
- **Client** - Application requesting access
- **Authorization Server** - Keycloak (manages policies)
- **Requesting Party** - User on behalf of whom client requests access

## Enabling Authorization

### Per-Client Configuration

**Admin Console:**
1. Clients → Select client
2. **Authorization** tab
3. **Authorization Enabled** → ON
4. Click **Save**

**After enabling:**
- New Authorization tab appears
- Default authorization settings created
- Built-in client scopes added

## Authorization Building Blocks

### Resources

Resources represent the objects you want to protect.

**Resource properties:**
- **Name** - Unique identifier
- **Type** - Resource type (e.g., "Customer", "Order")
- **URIs** - Resource paths (optional)
- **Scopes** - Available actions on resource
- **Icon** - Visual representation (optional)
- **Owner** - Resource owner (optional, defaults to resource server)

**Creating resource:**
1. Client → Authorization → Resources
2. Click **Create resource**
3. Configure:
   - Name: `Customer Resource`
   - Type: `urn:myapp:resources:customer`
   - URIs: `/customers/*`
   - Scopes: `view`, `create`, `update`, `delete`
4. Click **Save**

**Resource types:**
- Group resources by type
- Apply policies to all resources of type
- Type example: `http://myapp.com/resources/orders`

### Scopes

Scopes represent the actions that can be performed on a resource.

**Scope properties:**
- **Name** - Scope name (e.g., "view", "edit")
- **Display name** - Human-readable name
- **Icon** - Visual representation

**Creating scope:**
1. Client → Authorization → Scopes
2. Click **Create scope**
3. Configure:
   - Name: `view`
   - Display name: `View Customer`
4. Click **Save**

**Best practices:**
- Use verb-based names (view, create, update, delete)
- Keep scopes simple and atomic
- Reuse scopes across resources
- Consider CRUD operations

### Permissions

Permissions connect policies to resources and scopes.

**Permission properties:**
- **Name** - Unique identifier
- **Type** - Permission type (resource, scope, token)
- **Description** - Purpose explanation
- **Policies** - Associated policies
- **Resources** - Associated resources
- **Scopes** - Associated scopes

**Permission types:**

**Resource-based Permission:**
- Grants access to specific resource
- Uses policies to evaluate
- Can include multiple scopes

**Scope-based Permission:**
- Grants specific scope across resources
- More granular than resource-based
- Useful for CRUD operations

**Creating permission:**
1. Client → Authorization → Permissions
2. Click **Create permission**
3. Select type (Resource or Scope)
4. Configure:
   - Name
   - Description
   - Resources/Scopes
   - Policies
5. Click **Save**

### Policies

Policies define rules for granting access.

**Policy types:**

**Role-based Policy:**
- Grants access based on user roles
- Most common policy type

**Creating role policy:**
1. Client → Authorization → Policies
2. Click **Create policy** → **Role**
3. Configure:
   - Name: `Only Admins`
   - Description: `Only admin role can access`
   - Roles: Select `admin` role
4. Click **Save**

**User-based Policy:**
- Grants access to specific users
- Useful for exceptions

**Time-based Policy:**
- Grants access during specific time periods
- Supports:
  - NotBeforeTime
  - NotAfterTime
  - DayMonth
  - Month
  - Year
  - Hour
  - Minute
  - DayOfWeek (1-7, 1=Monday)

**Client Policy (JavaScript):**
- Custom JavaScript logic
- Most flexible option
- Can access:
  - Attributes
  - Realm
  - Resources
  - Scopes

**Aggregated Policy:**
- Combines multiple policies
- Logic: AND (all must grant) or OR (any must grant)

**Group-based Policy:**
- Grants access based on group membership

**Creating group policy:**
1. Client → Authorization → Policies
2. Click **Create policy** → **Group**
3. Configure:
   - Name: `Managers Only`
   - Groups: Select `managers` group
4. Click **Save**

## Authorization Flow

### Standard Authorization Flow

1. **Authentication** - User authenticates via OIDC
2. **Access Request** - Client requests resource with Access Token
3. **Policy Evaluation** - Keycloak evaluates policies
4. **RPT Issuance** - Keycloak issues RPT with permissions
5. **Resource Access** - Client accesses resource with RPT

### Sequence Diagram

```
Client → Resource Server: Request resource
Resource Server → Keycloak: Request permissions (with access token)
Keycloak: Evaluate policies
Keycloak → Resource Server: RPT (with permissions)
Resource Server: Validate RPT
Resource Server → Client: Protected resource
```

## Obtaining Permissions

### UMA Authorization Flow

**Endpoint:**
```
POST /realms/{realm}/protocol/openid-connect/token
Content-Type: application/x-www-form-urlencoded

grant_type=urn:ietf:params:oauth:grant-type:uma-ticket&
audience={client_id}&
permission=Customer Resource#view
```

**Response:**
```json
{
  "access_token": "eyJhbG...",
  "expires_in": 300,
  "refresh_expires_in": 1800,
  "token_type": "Bearer",
  "permissions": [
    {
      "rsid": "Customer Resource",
      "rsname": "Customer Resource",
      "scopes": ["view"]
    }
  ]
}
```

### Authorization Request via Parameters

**Single permission:**
```
permission=Resource#scope
```

**Multiple permissions:**
```
permission=Resource1#scope1&permission=Resource2#scope2
```

**All permissions for resource:**
```
permission=Resource
```

**All permissions for user:**
```
permission=
```

### Using RPT in Resource Server

**Introspect RPT:**
```bash
POST /realms/{realm}/protocol/openid-connect/token/introspect
Content-Type: application/x-www-form-urlencoded

token=<rpt_token>&
client_id=<client_id>&
client_secret=<client_secret>
```

**Response:**
```json
{
  "active": true,
  "permissions": [
    {
      "rsid": "Customer Resource",
      "scopes": ["view", "create"]
    }
  ]
}
```

## Policy Evaluation

### Evaluation Logic

**AND Logic (Aggregated Policy):**
- All policies must grant
- Used for restrictive access
- Example: User AND valid time AND specific group

**OR Logic (Default):**
- Any policy can grant
- Used for permissive access
- Example: Admin role OR manager group

### Policy Priority

When multiple policies apply:
1. Deny always takes precedence
2. Specific policies before generic
3. Explicit permissions before implicit

## Administration Console

### Authorization Tab

**After enabling authorization for a client:**

**Resources:**
- Create, view, edit resources
- Define resource types
- Set resource ownership

**Scopes:**
- Create, view, edit scopes
- Define scope icons

**Permissions:**
- Create resource-based permissions
- Create scope-based permissions
- Link policies to permissions

**Policies:**
- Create various policy types
- Configure policy logic
- Test policy evaluation

**Evaluate:**
- Test permissions for users
- Debug policy evaluation
- View effective permissions

**Settings:**
- Default resource configuration
- Remote resource management
- Policy enforcement mode

**Providers:**
- Configure policy providers
- Import/export authorization data

### Export/Import Authorization Data

**Export:**
```bash
Client → Authorization → Providers → Export
```

**Import:**
```bash
Client → Authorization → Providers → Import
```

**JSON format:**
- Resources
- Scopes
- Policies
- Permissions
- Complete configuration

## Protection API

Keycloak provides Protection API for resource servers.

### Create Resource

```bash
POST /realms/{realm}/authz/protection/resource_set
Content-Type: application/json
Authorization: Bearer <pat>

{
  "name": "Customer Resource",
  "type": "urn:myapp:resources:customer",
  "uris": ["/customers/*"],
  "scopes": ["view", "create", "update", "delete"]
}
```

### Create Permission

```bash
POST /realms/{realm}/authz/protection/permission
Content-Type: application/json
Authorization: Bearer <pat>

{
  "name": "View Customer Permission",
  "resourceType": "urn:myapp:resources:customer",
  "scopes": ["view"],
  "policies": ["Only Admins"]
}
```

## Best Practices

### Resource Design

**DO:**
- Use hierarchical resource structure
- Group by resource type
- Use consistent naming conventions
- Keep resources focused

**DON'T:**
- Create too many fine-grained resources
- Mix resource types
- Use overly generic names
- Create resources without clear ownership

### Scope Design

**DO:**
- Use CRUD operations (create, read, update, delete)
- Keep scopes atomic
- Reuse scopes across resources
- Use verb-based naming

**DON'T:**
- Create compound scopes
- Mix multiple actions in one scope
- Use noun-based naming
- Create too many scopes

### Policy Design

**DO:**
- Use role-based policies for most cases
- Create reusable policies
- Use aggregated policies for complex logic
- Test policies thoroughly

**DON'T:**
- Create one-off policies excessively
- Make policies too complex
- Duplicate policy logic
- Forget about edge cases

### Permission Design

**DO:**
- Link to policies (not users/roles directly)
- Use scope-based for CRUD
- Use resource-based for entity-level
- Document permission purpose

**DON'T:**
- Create permissions without policies
- Duplicate permission logic
- Mix resource and scope permissions confusingly
- Skip documentation

## Common Patterns

### CRUD Permissions

**Scenario:** Full CRUD on resources

**Approach 1: Resource-based**
- 1 resource: `Customer Resource`
- 1 scope: `all`
- 4 permissions: view, create, update, delete
- 4 policies linking to roles

**Approach 2: Scope-based (Recommended)**
- 1 resource: `Customer Resource`
- 4 scopes: view, create, update, delete
- 4 scope permissions
- Role-based policies per scope

**Benefits of scope-based:**
- More granular control
- Easier to manage
- Clearer intent

### Owner-Based Authorization

**Scenario:** Users can only access their own resources

**Approach:**
1. Set resource owner to user
2. Create JavaScript policy:
```javascript
var context = $evaluation.getContext();
var identity = context.getIdentity();
var resource = $evaluation.getResource();
var owner = resource.getOwner();

if (owner.getId() === identity.getId()) {
    $evaluation.grant();
}
```

### Time-Based Access

**Scenario:** Access only during business hours

**Policy:**
- Type: Time-based
- **NotBeforeTime**: 09:00
- **NotAfterTime**: 17:00
- **DayOfWeek**: 1,2,3,4,5 (Mon-Fri)

### Hierarchical Resources

**Scenario:** Department → Team → User hierarchy

**Approach:**
- Resources have parent relationships
- Policies check parent access
- Aggregate policies for inheritance

## Performance Considerations

### Policy Evaluation Caching

**Keycloak caches:**
- Policy evaluation results
- Permission decisions
- User permissions

**Tuning:**
```bash
--spi-policy-jpa-cache-max-size=10000
--spi-policy-jpa-cache-lifespan=60000
```

### Remote Resource Management

**Disable for performance:**
1. Client → Authorization → Settings
2. **Remote Resource Management** → OFF
3. Manage resources directly in Keycloak

**Enable for distributed:**
- Resource servers can register resources
- Dynamic resource creation
- More complex setup

## Troubleshooting

### Common Issues

**Permission not working:**
1. Check policy evaluation in Admin Console
2. Verify user has required roles/groups
3. Check resource and scope configuration
4. Verify permission links to policies
5. Check policy logic (AND vs OR)

**RPT not issued:**
1. Verify access token is valid
2. Check audience matches client_id
3. Verify client has authorization enabled
4. Check permission format in request

**Policy evaluation fails:**
1. Check JavaScript policy syntax
2. Verify attribute names
3. Check time-based policy configuration
4. Review logs for errors

### Debug Mode

**Enable debug logging:**
```bash
./kc.sh start-dev \
  --log-level=org.keycloak.authorization:DEBUG
```

### Testing Permissions

**Admin Console:**
1. Client → Authorization → Evaluate
2. Select user
3. Select resource
4. Select scope
5. Click **Evaluate**
6. View result and details

## References

- <https://www.keycloak.org/docs/latest/authorization_services/>
- User-Managed Access (UMA) 2.0 Specification
- OAuth 2.0 Resource Indicators (RFC 8707)

## Related

- [[keycloak-overview]]
- [[keycloak-server-administration]]
- [[keycloak-security]]
- [[keycloak-securing-apps-oidc]]
