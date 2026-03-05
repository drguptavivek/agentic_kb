---
title: Keycloak Fine-Grained Admin Permissions v2 (FGAP v2) — Delegated Administration
type: reference
domain: Keycloak
tags:
  - keycloak
  - fgap
  - fgap-v2
  - fine-grained-admin-permissions
  - delegated-admin
  - authorization-services
  - admin-permissions
  - client-management
  - access-control
  - keycloak-26
status: approved
created: 2026-03-02
updated: 2026-03-02
related:
  - keycloak-delegated-admin-guard-spi.md
---

# Keycloak Fine-Grained Admin Permissions v2 (FGAP v2)

## Overview

Fine-Grained Admin Permissions v2 (FGAP v2) is Keycloak 26's mechanism for delegated realm administration. It allows you to grant partial administrative access (e.g. "manage only clients, not users") to non-admin users without giving them full realm admin rights.

**Key difference from FGAP v1:**
- FGAP v1 used the `/management/permissions` endpoint and per-object toggles in the UI. **This is deprecated and returns `501 Not Implemented` in Keycloak 26.**
- FGAP v2 is built entirely on top of Keycloak's Authorization Services, using a special system client called `admin-permissions`.

## Architecture

```
Realm (org-new-delhi)
└── admin-permissions  ← System client. Acts as the Authorization Server.
    ├── Scopes: manage, view, map-roles, map-roles-client-scope,
    │           map-roles-composite, map-role, map-role-client-scope,
    │           map-role-composite, impersonate, reset-password,
    │           manage-group-membership, manage-membership, manage-members,
    │           view-members, impersonate-members
    ├── Resources (auto-managed):
    │   ├── "Clients"  ← Global resource for ALL clients
    │   ├── "Groups"   ← Global resource for ALL groups
    │   ├── "Roles"    ← Global resource for ALL roles
    │   ├── "Users"    ← Global resource for ALL users
    │   └── "<client-uuid>"  ← Per-object resource (auto-created when first referenced)
    ├── Policies:
    │   ├── Role-based (POSITIVE logic) → allow access
    │   └── Role-based (NEGATIVE logic) → deny access
    └── Permissions (scope-based only):
        ├── Global permission (resourceType only, no resources list) → applies to ALL objects
        └── Scoped permission (resourceType + resources list) → applies to specific objects
```

## Key Source Reference

The authoritative source in the Keycloak 26.5.4 codebase is:

- `server-spi-private/src/main/java/org/keycloak/authorization/fgap/AdminPermissionsSchema.java`
- `tests/base/src/test/java/org/keycloak/tests/admin/authz/fgap/ClientResourceTypeEvaluationTest.java`
- `tests/base/src/test/java/org/keycloak/tests/admin/authz/fgap/ClientResourceTypePermissionTest.java`

## FGAP v2 Feature Flag

FGAP v2 requires both:
1. `ADMIN_FINE_GRAINED_AUTHZ_V2` feature enabled (default in Keycloak 26+)
2. `adminPermissionsEnabled = true` on the target realm

### Enable via API

```python
# Enable adminPermissionsEnabled on realm
url = f"{KC_URL}/admin/realms/{REALM}"
realm_rep = requests.get(url, headers=auth_headers).json()
realm_rep['adminPermissionsEnabled'] = True
realm_rep['sslRequired'] = 'none'  # for dev only
requests.put(url, headers=auth_headers, json=realm_rep)
```

When enabled, the `admin-permissions` client is **automatically created** by Keycloak. You do NOT need to create it manually.

## Resource Types and Scopes

From `AdminPermissionsSchema.java`:

| Resource Type (string) | Available Scopes |
|---|---|
| `"Clients"` | `manage`, `view`, `map-roles`, `map-roles-client-scope`, `map-roles-composite` |
| `"Groups"` | `manage`, `view`, `manage-membership`, `manage-members`, `view-members`, `impersonate-members` |
| `"Roles"` | `map-role`, `map-role-client-scope`, `map-role-composite` |
| `"Users"` | `manage`, `view`, `impersonate`, `map-roles`, `manage-group-membership`, `reset-password` |

> ⚠️ **Critical**: These resource type strings are case-sensitive and must match exactly (`"Clients"` not `"clients"`).

## Permission Architecture: Global vs Scoped

### Global Permission (Resource Type only)

Applies to **all objects** of that type. Set `resourceType` but leave `resources` empty.

```json
{
  "name": "perm-view-all-clients",
  "type": "scope",
  "resourceType": "Clients",
  "scopes": ["<view-scope-id>", "<manage-scope-id>"],
  "policies": ["<policy-id>"],
  "resources": []
}
```

**Effect:** Any user with `policy-id`'s role can view/manage ALL clients.

### Scoped Permission (Resource Type + specific UUIDs)

Applies **only to the listed objects**. Provide the objects' internal UUIDs in `resources`.

```json
{
  "name": "perm-manage-specific-client",
  "type": "scope",
  "resourceType": "Clients",
  "scopes": ["<manage-scope-id>"],
  "policies": ["<policy-id>"],
  "resources": ["ecdff3bf-9027-4034-bbb8-8b6d34233cea"]
}
```

> ⚠️ **Do NOT pre-create the resource!** When you reference a client UUID in `resources`, Keycloak auto-creates the per-object resource in `admin-permissions`. Manually trying to POST to the resource endpoint returns `400 unknown_error`.

## NEGATIVE Policy Pattern (Deny + Allow Combination)

FGAP v2 evaluation rules (from `ClientResourceTypeEvaluationTest.java`):

1. Both global AND scoped permissions are evaluated for a given object.
2. If any permission **grants** a scope AND another **denies** the same scope for that specific object → **deny wins**.
3. This enables "allow all, deny specific" patterns.

### Design Pattern for Protected System Clients

```
POSITIVE policy (role=client-manager): "allow"
NEGATIVE policy (role=client-manager): "deny"  ← same role, Logic=NEGATIVE

Permission A: GLOBAL — all Clients — scopes:[manage,view] — policy: "allow"
Permission B: SCOPED — [broker-id, realm-mgmt-id, ...] — scopes:[manage] — policy: "deny"

Result:
  - client-manager can view all clients (global view)
  - client-manager can manage/create new clients (global manage)
  - client-manager CANNOT manage system clients (scoped deny overrides global allow)
```

## Complete Working Script

The following is a working, tested bootstrap script for delegated client administration:

### Setup: `scripts/step6_fgap_api_setup.py`

```python
# Key functions:

def enable_admin_permissions(keycloak_url, token, realm, env_mode):
    """Enable adminPermissionsEnabled on realm."""
    ...

def ensure_role_policy(keycloak_url, token, realm, mgmt_client_id,
                       policy_name, role_id, logic='POSITIVE'):
    """
    Create a role-based policy in admin-permissions.
    logic='POSITIVE' → allow
    logic='NEGATIVE' → deny
    """
    url = f"{keycloak_url}/admin/realms/{realm}/clients/{mgmt_client_id}/authz/resource-server/policy/role"
    payload = {
        "name": policy_name,
        "type": "role",
        "logic": logic,           # ← POSITIVE or NEGATIVE
        "decisionStrategy": "UNANIMOUS",
        "roles": [{"id": role_id, "required": True}]
    }
    ...

def ensure_scope_permission(keycloak_url, token, realm, mgmt_client_id,
                            perm_name, resource_type, scope_names,
                            policy_ids, resource_ids=None):
    """
    resource_ids=None → global (all objects of resource_type)
    resource_ids=[uuid1, uuid2] → scoped (only those objects)
    """
    url = f".../{mgmt_client_id}/authz/resource-server/permission/scope"
    payload = {
        "name": perm_name,
        "type": "scope",
        "resourceType": resource_type,   # ← "Clients", "Users", etc.
        "scopes": scope_ids,             # ← resolved from names to IDs
        "policies": policy_ids,
        "resources": resource_ids or []  # ← [] = global, [uuid...] = scoped
    }
    ...
```

### Bootstrap Flow

```python
# Step 0: Enable FGAP v2
enable_admin_permissions(KC_URL, token, REALM, ENV)

# Step 1: Get admin-permissions client ID
mgmt_id = get_client_internal_id(KC_URL, token, REALM, 'admin-permissions')

# Step 2: Create client-manager realm role
role_id = ensure_client_manager_role(KC_URL, token, REALM)

# Step 3: Create POSITIVE policy (allow)
policy_allow_id = ensure_role_policy(..., policy_name='policy-client-manager-allow',
                                     role_id=role_id, logic='POSITIVE')

# Step 4: Create NEGATIVE policy (deny)
policy_deny_id = ensure_role_policy(..., policy_name='policy-client-manager-deny',
                                    role_id=role_id, logic='NEGATIVE')

# Step 5: Global view+manage permission on all Clients
ensure_scope_permission(...,
    perm_name='perm-client-manager-global',
    resource_type='Clients',
    scope_names=['view', 'manage'],
    policy_ids=[policy_allow_id],
    resource_ids=None)   # None = global

# Step 6: Deny manage on system clients (scoped to their UUIDs)
ensure_scope_permission(...,
    perm_name='perm-client-manager-deny-system',
    resource_type='Clients',
    scope_names=['manage'],
    policy_ids=[policy_deny_id],
    resource_ids=[broker_id, realm_mgmt_id, ...])  # system client UUIDs
```

## API Endpoints Reference

All endpoints are relative to `{KC_URL}/admin/realms/{realm}`.

### Policies

```
GET/POST  clients/{mgmt_id}/authz/resource-server/policy/role
PUT       clients/{mgmt_id}/authz/resource-server/policy/role/{policy_id}
```

### Permissions

```
GET/POST  clients/{mgmt_id}/authz/resource-server/permission/scope
PUT       clients/{mgmt_id}/authz/resource-server/permission/scope/{perm_id}
```

### Scopes (to resolve name → ID)

```
GET       clients/{mgmt_id}/authz/resource-server/scope
          ?name=manage
```

### Resources (read-only in FGAP v2 — DO NOT POST)

```
GET       clients/{mgmt_id}/authz/resource-server/resource
```

## Effective Behaviour Matrix

With FGAP v2 permissions + `delegated-admin-guard` SPI:

| Action | All Clients | System Clients (broker, realm-mgmt, etc.) | Own Created Clients | Client Scopes |
|---|---|---|---|---|
| **View/List** | ✅ Allowed | ✅ Allowed (view scope) | ✅ Allowed | ✅ Allowed (read-only) |
| **Create** | ✅ Allowed (manage on type) | N/A | N/A | ❌ 403 (guard SPI) |
| **Update/Configure** | ✅ Allowed | ❌ 403 (NEGATIVE deny) | ✅ Allowed | ❌ 403 (guard SPI) |
| **Deactivate (enable=false)** | ✅ Allowed | ❌ 403 (NEGATIVE deny) | ✅ Allowed | N/A |
| **Delete** | ❌ 403 (guard SPI) | ❌ 403 (NEGATIVE deny) | ❌ 403 (guard SPI) | ❌ 403 (guard SPI) |

> **FGAP v2 alone**: `manage` scope encompasses both update AND delete — there is no separate `delete` scope. The `delegated-admin-guard` SPI (event listener + `setRollbackOnly()`) is required to block delete on own clients and all client-scope mutations.

## Client Scopes Security Gap

**FGAP v2 has NO resource type for `ClientScopes`.**

The four resource types are: `Clients`, `Groups`, `Roles`, `Users`. Client Scopes are absent.

As a result, a user with global `manage` on the `Clients` resource type **has full, ungated access** to:
- `GET /admin/realms/{realm}/client-scopes` → 200 (list all)
- `POST /admin/realms/{realm}/client-scopes` → 201 (create)
- `PUT /admin/realms/{realm}/client-scopes/{id}` → 204 (update, including system scopes like `acr`, `profile`)
- `DELETE /admin/realms/{realm}/client-scopes/{id}` → 204 (**can delete system scopes!**)

This was verified empirically — a user with only `client-manager` role and FGAP v2 permissions could **delete the `acr` system scope** without restriction.

The `delegated-admin-guard` EventListener SPI addresses this via `setRollbackOnly()`. See `keycloak-delegated-admin-guard-spi.md` for details.

## Important Gotchas

### ❌ Do NOT manually create resources for clients

The following will fail with `400 unknown_error`:
```python
# WRONG — do not do this
requests.post(
    f".../{mgmt_id}/authz/resource-server/resource",
    json={"name": "client.resource.abc123", "type": "Client", ...}
)
```

Instead, just reference the client UUID in the permission's `resources` field and let Keycloak create the resource lazily.

### ❌ FGAP v1 `/management/permissions` endpoint is dead

```python
# WRONG — deprecated, returns 501 in Keycloak 26
requests.put(
    f".../clients/{client_id}/management/permissions",
    json={"enabled": True}
)
# Returns: 501 Not Implemented
```

### ✅ Resource type string must match exactly

The `resourceType` field in permissions must be exactly one of:
- `"Clients"` (capital C)
- `"Groups"`
- `"Roles"`
- `"Users"`

Any other string causes a validation error.

### ✅ Scope IDs, not names, in permission payload

The `scopes` field in permission payloads needs the **scope UUID**, not the scope name string. Always resolve names to IDs first:

```python
scopes_res = requests.get(f".../{mgmt_id}/authz/resource-server/scope", ...)
scope_map = {s['name']: s['id'] for s in scopes_res.json()}
scope_ids = [scope_map['manage'], scope_map['view']]
```

### ✅ Scope resolution for `create` clients

In FGAP v2, creating new clients requires the **global `manage` scope on the `Clients` resource type** (not just a scoped permission). There is no separate `create` scope.

## Testing Pattern

```python
# test_04: Verify system clients are protected
for system_client_name in ['broker', 'realm-management', 'security-admin-console']:
    system_id = get_client_id(system_client_name)
    res = session.put(
        f"{url}/admin/realms/{realm}/clients/{system_id}",
        json={"description": "tampered"},
        headers=delegated_user_headers
    )
    assert res.status_code == 403, f"System client {system_client_name} must be protected!"

# test_05: Verify system clients cannot be deleted
for system_client_name in ['broker', 'realm-management', 'security-admin-console']:
    system_id = get_client_id(system_client_name)
    res = session.delete(
        f"{url}/admin/realms/{realm}/clients/{system_id}",
        headers=delegated_user_headers
    )
    assert res.status_code == 403

# test_06: Verify own clients can be deactivated
res = session.put(
    f"{url}/admin/realms/{realm}/clients/{own_client_id}",
    json={"clientId": client_id_name, "enabled": False},
    headers=delegated_user_headers
)
assert res.status_code == 204  # disabled successfully
```

## When admin-permissions Client Was Created

The `admin-permissions` client is auto-created by Keycloak the first time `adminPermissionsEnabled` is set to `true` on a realm. In the `org-new-delhi` realm, this was present in the pre-upgrade backup from 2026-02-25, indicating it was created during or after the Keycloak 26 upgrade.

## Related Files in This Project

| File | Purpose |
|---|---|
| `scripts/step6_fgap_api_setup.py` | FGAP v2 bootstrap + event listener registration |
| `scripts/test_step6_delegation.py` | 7-test delegation behaviour suite |
| `custom-delegated-admin-guard-spi/` | Guard SPI JAR source |
| `scripts/list_authz_resources.py` | Inspect admin-permissions resources |
| `scripts/list_authz_scopes.py` | Inspect admin-permissions scopes |
| `docker-compose.yml` | `step6-fgap-init` service definition |

## Related KB Articles

- **`keycloak-delegated-admin-guard-spi.md`** — Guard SPI: blocking deletes + client-scope mutations
- `keycloak-authorization-services.md` — General Authorization Services concepts
- `keycloak-roles-groups.md` — Role and group management
- `keycloak-spi.md` — Custom SPI development patterns
