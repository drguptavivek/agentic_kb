---
title: Keycloak Authorization Concepts Overview - Attributes, Roles, Groups, Mappers, and Scopes
domain: Keycloak
type: reference
status: draft
tags: [keycloak, authorization, roles, groups, mappers, scopes, user-attributes, security]
created: 2026-01-29
related: [[keycloak-overview]], [[keycloak-concepts]], [[keycloak-roles-groups]], [[keycloak-protocol-mappers]], [[keycloak-user-consent-app-access]]
---

# Keycloak Authorization Concepts Overview

## Overview

Keycloak provides a comprehensive authorization framework built around several interconnected concepts. This guide provides an overarching discussion of how **User Attributes**, **Roles** (Realm and Client), **Groups**, **Protocol Mappers**, and **Scopes** (Client and Realm) work together to provide fine-grained access control.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Keycloak Realm                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐  │
│  │   Users      │◄────►│   Groups     │◄────►│  Attributes  │  │
│  │              │      │              │      │              │  │
│  └──────┬───────┘      └──────┬───────┘      └──────────────┘  │
│         │                     │                                  │
│         │ has                 │ has                              │
│         ▼                     ▼                                  │
│  ┌──────────────┐      ┌──────────────┐                          │
│  │Realm Roles   │      │Client Roles  │                          │
│  │              │      │              │                          │
│  └──────┬───────┘      └──────┬───────┘                          │
│         │                     │                                  │
│         │ mapped by           │ mapped by                        │
│         ▼                     ▼                                  │
│  ┌──────────────────────────────────────────┐                   │
│  │         Protocol Mappers                 │                   │
│  │  (transform attributes to claims)        │                   │
│  └────────────────────┬─────────────────────┘                   │
│                       │                                          │
│                       │ included in                              │
│                       ▼                                          │
│  ┌──────────────────────────────────────────┐                   │
│  │          Client Scopes                   │                   │
│  │  (collections of mappers and roles)      │                   │
│  └────────────────────┬─────────────────────┘                   │
│                       │                                          │
│                       │ requested as                             │
│                       ▼                                          │
│  ┌──────────────────────────────────────────┐                   │
│  │           Access Tokens                   │                   │
│  │    (with claims from mappers)            │                   │
│  └──────────────────────────────────────────┘                   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

## 1. User Attributes

### Definition

User attributes are key-value pairs that store additional information about users beyond the basic profile fields (username, email, first/last name).

### User Profile Configuration (Keycloak 24+)

Keycloak 24.0.0 introduced a comprehensive **User Profile** feature that provides:

- **Schema definition** for user attributes
- **Validation rules** using built-in or custom validators
- **Permission control** for viewing/editing attributes
- **Dynamic form rendering** based on attribute configuration
- **Attribute groups** for organizing related fields

#### Managed vs Unmanaged Attributes

| Type | Description | Use Case |
|------|-------------|----------|
| **Managed** | Explicitly defined in user profile configuration with validation | All user-facing attributes |
| **Unmanaged** | Not in schema, handling controlled by policy | Migration, legacy attributes |

#### Unmanaged Attribute Policies

```bash
# Realm settings → General → Unmanaged Attributes
DISABLED      # Default - unmanaged attributes ignored
ENABLED       # Allow from all contexts (not recommended)
ADMIN_VIEW    # Read-only for admins
ADMIN_EDIT    # Read/write for admins only
```

### Validators

Validators enforce rules on attribute values. **All user-editable attributes should have validators** for security.

#### Built-in Validators

| Validator | Purpose | Configuration |
|-----------|---------|---------------|
| `length` | String length constraints | `min`, `max`, `trim-disabled` |
| `integer` | Integer validation with range | `min`, `max` |
| `double` | Double/float validation | `min`, `max` |
| `email` | Email format validation | `max-local-length` |
| `pattern` | RegEx pattern matching | `pattern`, `error-message` |
| `uri` | URI format validation | None |
| `local-date` | Locale-aware date | None |
| `iso-date` | ISO 8601 date | None |
| `options` | Enum-like value restriction | `options` array |
| `multivalued` | Count of multi-value attributes | `min`, `max` |
| `person-name-prohibited-characters` | Security: prevents script injection | `error-message` |
| `username-prohibited-characters` | Username security validation | `error-message` |
| `up-username-not-idn-homograph` | IDN homograph attack prevention | `error-message` |

#### Example: Attribute with Validators

```json
{
  "name": "phoneNumber",
  "displayName": "${phoneNumber}",
  "validations": {
    "length": {
      "min": 10,
      "max": 15,
      "trim-disabled": false
    },
    "pattern": {
      "pattern": "^\\+?[1-9]\\d{1,14}$"
    }
  },
  "annotations": {
    "inputType": "html5-tel",
    "inputHelperTextAfter": "${phoneNumberHelp}"
  }
}
```

### Annotations

Annotations pass metadata to frontend themes to control rendering and behavior.

#### Built-in Annotations

| Annotation | Purpose | Example Values |
|------------|---------|----------------|
| `inputType` | HTML input field type | `text`, `textarea`, `select`, `html5-email`, `html5-date` |
| `inputHelperTextBefore` | Help text above field | "Enter your phone number" |
| `inputHelperTextAfter` | Help text below field | "${phoneHelp}" |
| `inputTypePlaceholder` | HTML placeholder | "john@example.com" |
| `inputTypeMaxLength` | Max length for client-side validation | `100` |
| `inputTypePattern` | Client-side RegEx | `"[0-9]*"` |
| `inputOptionLabels` | Labels for select options | `{"opt1": "Option 1"}` |
| `inputOptionLabelsI18nPrefix` | i18n prefix for options | `"userprofile.role"` |

#### Custom Annotations

Custom annotations with `kc` prefix load JavaScript modules:

```javascript
// In theme: resources/js/kcMyCustomValidation.js
import { registerElementAnnotatedBy } from "./userProfile.js";

registerElementAnnotatedBy({
  name: 'kcMyCustomValidation',
  onAdd(element) {
    var listener = (event) => {
      // Custom validation logic
    };
    element.addEventListener("keyup", listener);
    return () => element.removeEventListener("keyup", listener);
  }
});
```

### Attribute Groups

Attribute groups organize related attributes for form rendering:

```json
{
  "groups": [
    {
      "name": "personalInfo",
      "displayHeader": "Personal Information",
      "displayDescription": "Your basic personal details",
      "annotations": {
        "inputTypeCols": 50
      }
    }
  ]
}
```

**Best practices for attribute groups:**
- Group related fields (address fields, contact info, employment details)
- Keep attribute order sequential within groups
- Use display headers and descriptions for UX

### Attribute Permissions

Control who can view/edit attributes:

```json
{
  "permissions": {
    "view": ["admin"],      // Only admins can see
    "edit": ["user"]        // Only users can edit
  }
}
```

| Permission | Values | Effect |
|------------|--------|--------|
| `view` | `["admin"]`, `["user"]`, or both | Who sees the attribute |
| `edit` | `["admin"]`, `["user"]`, or both | Who can modify |

**Note:** When `edit` is granted, `view` is implicitly granted.

### Conditional Attributes

Enable attributes only when specific scopes are requested:

```json
{
  "name": "department",
  "enabled": {
    "scopes": ["hr"]
  }
}
```

## 2. Roles

### Role Types

Keycloak has two types of roles with different scopes:

| Aspect | Realm Roles | Client Roles |
|--------|-------------|--------------|
| **Scope** | Realm-wide, available to all clients | Specific to a single client |
| **Use Case** | Cross-application permissions | Application-specific permissions |
| **Best Practice** | User types (admin, user, developer) | App-specific functions (read, write, delete) |
| **Inheritance** | Can be composite of other roles | Cannot be composite |

### Role Hierarchy

```
                    ┌──────────────────┐
                    │   SUPER_ADMIN    │
                    │   (Realm Role)   │
                    └────────┬─────────┘
                             │ composite of
              ┌──────────────┴──────────────┐
              │                             │
              ▼                             ▼
    ┌──────────────────┐          ┌──────────────────┐
    │    ADMIN         │          │   BILLING_ADMIN   │
    │  (Realm Role)    │          │  (Realm Role)    │
    └────────┬─────────┘          └──────────────────┘
             │ composite of
             │
    ┌────────┴────────┐
    │                 │
    ▼                 ▼
┌─────────┐     ┌─────────┐
│  USER   │     │  AUDIT  │
│(Realm)  │     │(Realm)  │
└─────────┘     └─────────┘
```

### Composite Roles

A role that contains other roles:

```bash
# Create composite role
kcadm.sh create roles/ADMIN/composites -r myrealm \
  -s realmRoles=["USER","AUDIT"]

# Add client role to composite
kcadm.sh create roles/ADMIN/composites/clients/myapp -r myrealm \
  -s clientRoles=["read","write"]
```

### Role Mappings

Roles can be assigned to:
- **Users directly** (not recommended for large organizations)
- **Groups** (recommended for maintainability)

```bash
# Assign role to user
kcadm.sh create users/$USER_ID/role-mappings/realm -r myrealm \
  -s roles=[{"id": "$ROLE_ID", "name": "USER"}]

# Assign role to group (preferred)
kcadm.sh create groups/$GROUP_ID/role-mappings/realm -r myrealm \
  -s roles=[{"id": "$ROLE_ID", "name": "DEVELOPER"}]
```

## 3. Groups

### Purpose

Groups organize users for:
- **Role assignment** (assign roles once, apply to all group members)
- **Attribute inheritance** (group-level attributes)
- **User management** (bulk operations, lifecycle management)

### Group Hierarchy

```
┌─────────────────────────────────────┐
│           ORGANIZATION              │
│  ┌───────────────────────────────┐  │
│  │      DEPARTMENT               │  │
│  │  ┌──────────┐  ┌──────────┐   │  │
│  │  │   TEAM   │  │   TEAM   │   │  │
│  │  │          │  │          │   │  │
│  │  └──────────┘  └──────────┘   │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### Group Attributes

Groups can have attributes that are inherited by members:

```bash
# Set group attribute
kcadm.sh update groups/$GROUP_ID -r myrealm \
  -s 'attributes.department=Engineering' \
  -s 'attributes.costCenter=["12345"]'

# These can be mapped to tokens via protocol mappers
```

**Important:** Group attributes are NOT the same as user attributes. They are set on the group object and can be accessed via protocol mappers with group context.

### Groups vs Roles

| Aspect | Groups | Roles |
|--------|--------|-------|
| **Primary Purpose** | User organization | Permission definition |
| **Contains** | Users and subgroups | Permissions (can contain other roles) |
| **Best Practice** | Assign roles to groups, users to groups | Define what actions are possible |
| **Inheritance** | Hierarchical (parent groups) | Composite roles |
| **Attributes** | Can have group attributes | No attributes |

## 4. Protocol Mappers

### Purpose

Protocol mappers transform Keycloak internal data (user attributes, roles, group memberships) into protocol-specific claims in tokens (ID tokens, access tokens, UserInfo).

### Mapper Types

| Mapper Type | Purpose | Example Claim |
|-------------|---------|---------------|
| `oidc-usermodel-attribute-mapper` | User attribute → claim | `email`, `phone_number` |
| `oidc-usermodel-property-mapper` | User property → claim | `username`, `email_verified` |
| `oidc-usermodel-realm-role-mapper` | Realm roles → claim | `roles: ["admin", "user"]` |
| `oidc-usermodel-client-role-mapper` | Client roles → claim | `resource_access: {client: {roles: []}}` |
| `oidc-group-membership-mapper` | Group membership → claim | `groups: ["developers"]` |
| `oidc-sha256-pairwise-sub-mapper` | Pairwise subject identifier | `sub` (sector-specific) |
| `oidc-audience-mapper` | Add audience claim | `aud: ["api-service"]` |

### Mapper Configuration

```json
{
  "name": "department",
  "protocol": "openid-connect",
  "protocolMapper": "oidc-usermodel-attribute-mapper",
  "consentRequired": false,
  "consentText": "${department}",
  "config": {
    "userinfo.token.claim": "true",
    "id.token.claim": "true",
    "access.token.claim": "true",
    "claim.name": "department",
    "jsonType.label": "String",
    "user.attribute": "department"
  }
}
```

### Where to Define Mappers

| Location | Scope | Use Case |
|----------|-------|----------|
| **Client** | Single client | Client-specific claims |
| **Client Scope** | Multiple clients | Reusable claim definitions |
| **Protocol** | All clients in realm | Standard OIDC claims |

### Claim Types

```json
// String (default)
"department": "Engineering"

// JSON Object
"address": {
  "street": "123 Main St",
  "city": "San Francisco"
}

// JSON Array
"groups": ["admin", "developer"]

// Long (for timestamps)
"updated_at": 1643723400000
```

## 5. Client Scopes

### Purpose

Client scopes are reusable collections of protocol mappers and role scope mappings that define:
- **What claims** are included in tokens
- **What roles** are available to a client
- **Consent behavior** for each scope

### Scope Types

| Type | Description | Behavior |
|------|-------------|----------|
| **Default** | Always included in tokens | No consent needed |
| **Optional** | User can choose to grant | Shown in consent screen |
| **Required** | Must be granted for access | Forced consent if not granted |

### Client Scope Evaluation

```
┌────────────────────────────────────────────────────────────────┐
│                    Token Request                               │
│                  scope=profile email department                │
└────────────────────────────┬───────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────────┐
│              Client Scope Resolution                           │
│  1. Evaluate Default Client Scopes (always added)              │
│  2. Evaluate Optional Client Scopes (if requested)             │
│  3. Check consent requirements                                 │
│  4. Resolve protocol mappers for each scope                    │
└────────────────────────────┬───────────────────────────────────┘
                             │
                             ▼
┌────────────────────────────────────────────────────────────────┐
│              Token Construction                                │
│  - Apply protocol mappers                                      │
│  - Add role mappings                                           │
│  - Include consented claims                                    │
└────────────────────────────────────────────────────────────────┘
```

### Predefined Client Scopes

Keycloak provides these built-in scopes:

| Scope | Protocol | Purpose |
|-------|----------|---------|
| `profile` | OIDC | Basic profile information (name, family_name, etc.) |
| `email` | OIDC | Email and email_verified |
| `address` | OIDC | Postal address |
| `phone` | OIDC | Phone number |
| `offline_access` | OIDC | Refresh tokens without user session |
| `roles` | OIDC | Include roles in token |
| `web-origins` | OIDC | Allowed web origins for CORS |

### Creating Custom Client Scopes

```bash
# Create client scope
kcadm.sh create client-scopes -r myrealm \
  -s 'name=hr' \
  -s 'protocol=openid-connect' \
  -s 'attributes.displayOnConsentScreen=true' \
  -s 'attributes.includeInTokenScope=true'

# Add mapper to scope
kcadm.sh create client-scopes/hr/protocol-mappers/models -r myrealm \
  -s 'name=department_mapper' \
  -s 'protocol=openid-connect' \
  -s 'protocolMapper=oidc-usermodel-attribute-mapper' \
  -s 'consentRequired=true' \
  -s 'config.user.attribute=department' \
  -s 'config.claim.name=department' \
  -s 'config.jsonType.label=String' \
  -s 'config.access.token.claim=true'
```

### Linking Scopes to Clients

```bash
# Add as optional scope
kcadm.sh create clients/$CLIENT_ID/optional-client-scopes -r myrealm \
  -s 'id=hr-scope-id'

# Add as default scope
kcadm.sh create clients/$CLIENT_ID/default-client-scopes -r myrealm \
  -s 'id=profile-scope-id'
```

### Fine-Grained Consent

Users can:
1. **Grant required scopes** (must grant to continue)
2. **Optionally add optional scopes** (can be granted or denied)
3. **Revoke optional scopes** later from Account Console

This enables GDPR-compliant granular consent.

## 6. Realm Scopes

### Concept

"Realm scopes" is not a formal Keycloak term, but refers to **client scopes that are available realm-wide** and can be shared across all clients.

### Realm Default Client Scopes

When you create a client, Keycloak automatically assigns these realm-wide defaults:
- `profile` (if enabled)
- `email` (if enabled)
- `roles` (if enabled)

You can configure realm defaults at:
```
Realm Settings → Client Scopes → Realm Default Client Scopes
```

### Best Practices for Realm Scopes

| Practice | Description |
|----------|-------------|
| **Standardize common claims** | Create reusable scopes for profile, email, phone |
| **Department-specific scopes** | Create scopes like `hr`, `finance` for department-specific data |
| **Application-type scopes** | `mobile-app`, `web-app` for different client types |
| **Consent grouping** | Group related claims under logical scopes |

## Putting It All Together

### Example: HR Application with Comprehensive Authorization

```
1. User Attributes:
   - department (validated, required)
   - employeeId (validated, required)
   - managerEmail (validated, optional)

2. Groups:
   - Organization > Department > Team
   - Each group has attributes: costCenter, location

3. Realm Roles:
   - EMPLOYEE (base role)
   - HR_ADMIN (composite: EMPLOYEE + HR_READ)
   - MANAGER (composite: EMPLOYEE + TEAM_VIEW)

4. Client Roles (hr-app):
   - READ_SELF
   - READ_TEAM
   - READ_DEPARTMENT
   - APPROVE_LEAVE

5. Protocol Mappers:
   - employeeId → employee_id claim
   - department → department claim
   - groups → groups claim
   - realm roles → realm_access.roles
   - client roles → resource_access.hr-app.roles

6. Client Scopes:
   - hr_basic (default): profile, email, employeeId
   - hr_team (optional): team members, department info
   - hr_admin (required): all employee data

7. Token Result:
{
  "sub": "user-id",
  "email": "user@example.com",
  "employee_id": "12345",
  "department": "Engineering",
  "groups": ["engineering", "platform-team"],
  "realm_access": {
    "roles": ["EMPLOYEE"]
  },
  "resource_access": {
    "hr-app": {
      "roles": ["READ_SELF", "READ_TEAM"]
    }
  }
}
```

## Decision Framework

### When to Use Each Concept

| Scenario | Use | Configuration |
|----------|-----|---------------|
| Store user-specific data | **User Attributes** | User Profile → Attributes |
| Validate user input | **Validators** | Attribute → Validations |
| Control form rendering | **Annotations** | Attribute → Annotations |
| Organize related fields | **Attribute Groups** | User Profile → Attribute Groups |
| Define permissions | **Roles** | Roles → Create (Realm/Client) |
| Organize users for management | **Groups** | Groups → Create hierarchy |
| Assign permissions efficiently | **Group + Role** | Groups → Role Mappings |
| Include data in tokens | **Protocol Mappers** | Client Scope → Protocol Mappers |
| Control token content | **Client Scopes** | Client Scopes → Create |
| Request specific claims | **Scope Parameter** | OAuth2/OIDC `scope` parameter |

### Best Practices Summary

1. **Use Groups over direct role assignments** for maintainability
2. **Define user attributes in User Profile** with proper validation
3. **Create reusable client scopes** for common claim combinations
4. **Use realm roles** for cross-application permissions
5. **Use client roles** for application-specific permissions
6. **Make composite roles** for role hierarchies
7. **Use protocol mappers in client scopes** (not directly on clients)
8. **Set appropriate consent requirements** for each scope
9. **Leverage attribute groups** for better UX
10. **Use annotations** for consistent UI rendering

## Related Topics

- [[keycloak-overview]]: Keycloak architecture
- [[keycloak-concepts]]: Core concepts (realms, clients, users)
- [[keycloak-roles-groups]]: Detailed roles and groups guide
- [[keycloak-protocol-mappers]]: Protocol mappers deep dive
- [[keycloak-user-consent-app-access]]: User consent management
- [[keycloak-security]]: Security best practices

## Additional Resources

- [User Profile Documentation](https://www.keycloak.org/docs/latest/server_admin/index.html#user-profile)
- [Server Administration Guide - Client Scopes](https://www.keycloak.org/docs/latest/server_admin/index.html#client-scopes)
- [Protocol Mappers](https://www.keycloak.org/docs/latest/server_admin/index.html#protocol-mappers)
- [Roles and Groups](https://www.keycloak.org/docs/latest/server_admin/index.html#roles-and-groups)
