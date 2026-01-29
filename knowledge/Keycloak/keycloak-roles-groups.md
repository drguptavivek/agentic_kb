---
title: Keycloak Roles and Groups - Complete Guide
type: reference
domain: Keycloak
tags:
  - keycloak
  - roles
  - groups
  - permissions
  - rbac
  - access-control
  - organization
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Roles and Groups - Complete Guide

## Overview

Roles and Groups are Keycloak's primary mechanisms for organizing users and controlling access. Understanding when and how to use each is essential for effective identity and access management.

## Roles vs Groups

### Fundamental Differences

| Aspect | Roles | Groups |
|--------|-------|--------|
| **Purpose** | Define permissions | Organize users |
| **Scope** | Functional capabilities | Organizational structure |
| **Hierarchy** | Composite roles (inheritance) | Nested groups (parent-child) |
| **Attributes** | No (just name/description) | Yes (custom key-value pairs) |
| **Best For** | Permission assignment | User management |
| **Example** | `admin`, `user`, `editor` | `Engineering`, `Sales`, `Managers` |

### Key Principle

**Roles answer:** "What can you do?"
**Groups answer:** "Who are you?"

**Best practice:** Assign roles to groups, then add users to groups.

## Roles

### Role Types

### Realm Roles

**Scope:** Available across entire realm

**Use cases:**
- Global permissions
- Cross-client permissions
- Broad functional categories

**Examples:**
```java
// Common realm roles
ADMIN          // Full administration
USER           // Basic user access
MANAGER        // Management permissions
DEVELOPER      // Development access
ANALYST        // Analytics access
```

**Creating realm roles:**
1. **Admin Console:** Realm roles → Add role
2. **Name:** `admin` (required)
3. **Description:** Full administration access (optional)
4. **Click:** Save

### Client Roles

**Scope:** Specific to a client/application

**Use cases:**
- Application-specific permissions
- API access control
- Resource-specific permissions

**Examples:**
```java
// Client: hr-app
hr-app:EMPLOYEE_READ    // Read employee data
hr-app:EMPLOYEE_WRITE   // Modify employee data
hr-app:PAYROLL_ADMIN    // Payroll administration
hr-app:RECRUITER        // Recruitment permissions

// Client: finance-app
finance-app:INVOICE_VIEW
finance-app:INVOICE_CREATE
finance-app:RECONCILE
```

**Creating client roles:**
1. Clients → Select client
2. Roles tab → Add role
3. Name: `invoice-view`
4. Description: View invoices (optional)
5. Click: Save

### Composite Roles

**Definition:** Roles that contain other roles

**Benefits:**
- Role inheritance
- Reusable permission sets
- Hierarchical organization
- Simplified management

**Example hierarchy:**
```
ADMIN (composite)
├── USER_MANAGER
│   ├── USER_READ
│   └── USER_WRITE
├── CLIENT_MANAGER
│   ├── CLIENT_READ
│   └── CLIENT_WRITE
└── GROUP_MANAGER
    ├── GROUP_READ
    └── GROUP_WRITE
```

**Creating composite role:**
1. Realm roles → Select role (e.g., `admin`)
2. **Composite** tab
3. **Add composite roles**
4. Select roles to include
5. **Add selected**

**Effective permissions:** Union of all composite roles

### Default Roles

**Role assigned automatically to new users:**

**Configure:**
1. Realm Settings → User profile
2. **Default roles** setting
3. Add roles (e.g., `USER`)

**Use case:** Ensure baseline permissions for all users

## Groups

### Group Purpose

**Groups organize users for:**
- Easier management
- Bulk role assignment
- Organizational structure
- Attribute-based access control
- Hierarchical permissions

### Group Hierarchy

**Nested group structure:**
```
Organization (root)
├── Engineering (parent)
│   ├── Frontend Team (child)
│   │   ├── React Developers (sub-child)
│   │   └── Vue Developers (sub-child)
│   └── Backend Team (child)
│       ├── Java Developers (sub-child)
│       └── Python Developers (sub-child)
├── Sales (parent)
│   ├── North America (child)
│   └── Europe (child)
└── Operations (parent)
    └── Support (child)
```

**Inheritance:**
- Child groups inherit parent group roles
- Attributes don't inherit (only roles)
- User belongs to entire hierarchy path

**Creating nested groups:**
1. Groups → Select parent group
2. **Create sub-group**
3. Name: `Backend Team`
4. Click: Create

### Group Attributes

**Custom attributes on groups:**
```properties
department=Engineering
cost-center=12345
location=San Francisco
manager=john.doe
team-lead=jane.smith
```

**Use cases:**
- Attribute-based access control (ABAC)
- Organizational metadata
- Cost allocation tracking
- Dynamic authorization policies

**Adding attributes:**
1. Groups → Select group
2. **Attributes** tab
3. Add key-value pairs
4. Click: Add

## Role Assignment Patterns

### Pattern 1: Direct Assignment

**Assign role directly to user:**

**Pros:**
- Simple for single-user exceptions
- Quick one-offs

**Cons:**
- Difficult to manage at scale
- No consistency
- Hard to audit

**When to use:**
- Individual exceptions
- Temporary access
- Testing

**Admin Console:**
1. Users → Select user
2. **Role mapping** tab
3. **Assign role**
4. Select role (realm or client)
5. **Add selected**

### Pattern 2: Group-Based Assignment (Recommended)

**Assign roles to groups, users to groups:**

**Pros:**
- Consistent permissions
- Easy to manage
- Clear audit trail
- Scalable

**Cons:**
- Requires planning
- More initial setup

**When to use:**
- Production environments
- Multiple users
- Regular access needs

**Setup:**
1. Create group: `Developers`
2. Assign roles: `DEVELOPER`, `USER_READ`
3. Add users to group
4. All users inherit group roles

**Admin Console - Assign roles to group:**
1. Groups → Select group
2. **Role mapping** tab
3. **Assign role**
4. Select roles
5. **Add selected**

### Pattern 3: Mixed Approach

**Combine both patterns:**

**Use groups for:**
- Standard, repeatable permissions
- Organizational roles
- Team access

**Use direct assignment for:**
- Exceptions
- Temporary access
- Individual permissions

**Example:**
```
Groups:
├── Developers (has: DEVELOPER, READ_ALL)
├── Managers (has: MANAGER, APPROVE_REQUESTS)
└── Contractors (has: LIMITED_ACCESS)

Direct assignments:
├── john.doe (extra: ADMIN - temporary project access)
└── jane.smith (extra: REPORT_VIEWER - one-off need)
```

## Common Role Patterns

### RBAC (Role-Based Access Control)

**Standard permission model:**

```
Roles:
├── READ_ONLY
│   └── Permissions: View resources
├── OPERATOR
│   └── Permissions: View + Create
├── ADMIN
│   └── Permissions: Full CRUD
└── SUPER_ADMIN
    └── Permissions: All permissions + user management
```

**Implementation:**
1. Create roles with clear hierarchy
2. Assign to groups based on job function
3. Add users to appropriate groups

### Functional Roles

**Organized by capability:**

```
Roles:
├── USER_MANAGER
│   ├── CREATE_USER
│   ├── UPDATE_USER
│   └── DELETE_USER
├── CONTENT_MANAGER
│   ├── CREATE_CONTENT
│   ├── EDIT_CONTENT
│   └── PUBLISH_CONTENT
└── REPORT_VIEWER
    └── VIEW_REPORTS
```

### Data-Level Roles

**For fine-grained data access:**

```
Roles:
├── EMPLOYEE_READ_ALL
├── EMPLOYEE_READ_DEPARTMENT
├── EMPLOYEE_READ_SELF
├── SALARY_VIEW_ALL
├── SALARY_VIEW_DEPARTMENT
└── SALARY_VIEW_NONE
```

**Combine with groups:**
```
Groups:
├── HR (has: EMPLOYEE_READ_ALL, SALARY_VIEW_DEPARTMENT)
├── Managers (has: EMPLOYEE_READ_DEPARTMENT)
└── Employees (has: EMPLOYEE_READ_SELF)
```

## Common Group Patterns

### Organizational Groups

**Mirror company structure:**

```
Groups:
├── Executive
├── Engineering
│   ├── Frontend
│   ├── Backend
│   └── DevOps
├── Sales
│   ├── Inside Sales
│   └── Field Sales
└── Operations
    ├── Support
    └── Facilities
```

### Cross-Functional Groups

**Project-based or initiative-based:**

```
Groups:
├── Project-Alpha-Team
├── Product-Launch-Committee
├── Security-Review-Board
└── Migration-Task-Force
```

### Location-Based Groups

**Geographic organization:**

```
Groups:
├── North-America
│   ├── US-East
│   ├── US-West
│   └── Canada
├── Europe
│   ├── UK
│   ├── Germany
│   └── France
└── Asia-Pacific
    ├── Japan
    └── Australia
```

### Environment-Based Groups

**Development lifecycle:**

```
Groups:
├── Dev-Access
├── Test-Access
├── Staging-Access
└── Prod-Access
```

**Use case:** Different access levels per environment

## Best Practices

### Role Design

**✅ DO:**
- Use clear, descriptive names
- Keep roles focused and atomic
- Document role purpose
- Use composite roles for hierarchy
- Limit number of roles (avoid explosion)
- Review and clean up unused roles
- Use naming conventions
- Consider permission model

**❌ DON'T:**
- Create duplicate roles
- Use vague names (access1, role2)
- Mix responsibilities in one role
- Create overly granular roles
- Skip documentation
- Forget to review periodically

**Role naming conventions:**
```
Good:
├── user:read
├── user:write
├── user:delete
├── invoice:view
├── invoice:create
└── invoice:approve

Bad:
├── role1
├── access_user
├── can_do_stuff
├── general_permission
└── everything_admin
```

### Group Design

**✅ DO:**
- Mirror organizational structure
- Use nested groups for hierarchy
- Add descriptive attributes
- Keep group structure flat where possible
- Document group purpose
- Review membership regularly
- Use group-based permissions (not direct)
- Consider team-based organization

**❌ DON'T:**
- Create overly deep hierarchies (>5 levels)
- Mix organizational and functional groups
- Forget to maintain membership
- Create duplicate groups
- Use groups as roles
- Ignore group attributes
- Create orphan groups

### Permission Assignment

**✅ DO:**
- Assign roles to groups (not users)
- Use groups for user organization
- Keep assignments consistent
- Document permission logic
- Review access regularly
- Use principle of least privilege
- Implement approval workflows for access

**❌ DON'T:**
- Assign everything to everyone
- Use direct assignment as default
- Forget to revoke access
- Ignore privilege creep
- Skip documentation
- Give admin access lightly
- Forget about separation of duties

## Advanced Scenarios

### Scenario 1: Multi-Tenant Application

**Challenge:** Different organizations, different permissions

**Solution:**
```
Groups (per organization):
├── org1:admins
├── org1:users
├── org2:admins
└── org2:users

Client Roles:
├── app:read
├── app:write
└── app:admin

Group → Role mapping:
├── org1:admins → app:admin (org1 only)
├── org1:users → app:read (org1 only)
├── org2:admins → app:admin (org2 only)
└── org2:users → app:read (org2 only)
```

### Scenario 2: Time-Based Access

**Challenge:** Temporary elevated access

**Solution:**
```
Groups:
├── Permanent-Developers (has: DEVELOPER)
└── Temporary-Admin (has: ADMIN, expires: 30 days)

Process:
1. Add user to Temporary-Admin
2. Set reminder for 30 days
3. Remove user after expiration
```

**Better:** Use automated expiration:
- Event listener
- Custom SPI
- External IDM integration

### Scenario 3: Delegated Administration

**Challenge:** Let managers manage their team's access

**Solution:**
```
Groups:
├── Department-Managers
│   ├── HR-Manager (has: USER_MANAGE_HR)
│   ├── IT-Manager (has: USER_MANAGE_IT)
│   └── Sales-Manager (has: USER_MANAGE_SALES)
└── Employees
    ├── HR-Employees
    ├── IT-Employees
    └── Sales-Employees

Permissions:
- HR-Manager can manage HR-Employees only
- IT-Manager can manage IT-Employees only
- etc.
```

**Implementation:**
- Use Fine-Grained Admin Permissions (FGAP)
- Create client-scoped admin roles
- Set up group-based permissions

### Scenario 4: Dynamic Group Membership

**Challenge:** Automatically add users to groups

**Solutions:**

**Option 1: User federation (LDAP)**
- Groups sync from LDAP/AD
- Automatic updates

**Option 2: Event listener SPI**
- Listen for user events
- Add/remove groups based on attributes

**Option 3: External IDM**
- Synchronize groups from external system
- Real-time updates

**Example:**
```java
// Event listener that adds users to groups
public class AutoGroupListener implements EventListenerProvider {

    @Override
    public void onEvent(Event event) {
        if (event.getType() == EventType.REGISTER) {
            UserModel user = ((UserEvent) event).getUser();

            // Add to default users group
            RealmModel realm = session.realms().getRealm(event.getRealmId());
            GroupModel usersGroup = realm.getGroupByName("Users");

            if (usersGroup != null) {
                user.joinGroup(usersGroup);
            }
        }
    }
}
```

## Management Operations

### Creating Roles

**CLI:**
```bash
# Create realm role
kcadm.sh create roles/clients/app/roles \
  -r myrealm \
  -s name=invoice-view \
  -s description="View invoices"

# Create composite role
kcadm.sh create roles/clients/app/roles/composite \
  -r myrealm \
  -s name=admin-composite \
  -s composite=["invoice-view","invoice-create","invoice-delete"]
```

### Creating Groups

**CLI:**
```bash
# Create group
kcadm.sh create groups \
  -r myrealm \
  -s name=Developers \
  -s 'attributes.department=Engineering'

# Create nested group
GROUP_ID=$(kcadm.sh get groups -r myrealm -q name==Developers --id)
kcadm.sh create groups/$GROUP_ID/children \
  -r myrealm \
  -s name=Backend
```

### Assigning Roles to Groups

**CLI:**
```bash
# Assign role to group
GROUP_ID=$(kcadm.sh get groups -r myrealm -q name==Developers --id)
ROLE_ID=$(kcadm.sh get roles/clients/app/roles/view -r myrealm --id)

kcadm.sh create groups/$GROUP_ID/role-mappings/clients/app \
  -r myrealm \
  -s roleId=$ROLE_ID \
  -s scope=false
```

### Adding Users to Groups

**CLI:**
```bash
# Add user to group
USER_ID=$(kcadm.sh get users -r myrealm -q username==john.doe --id)
GROUP_ID=$(kcadm.sh get groups -r myrealm -q name==Developers --id)

kcadm.sh put users/$USER_ID/groups/$GROUP_ID -r myrealm
```

### Listing Group Members

**CLI:**
```bash
# Get members of group
GROUP_ID=$(kcadm.sh get groups -r myrealm -q name==Developers --id)
kcadm.sh get groups/$GROUP_ID/members -r myrealm
```

### Listing User Groups

**CLI:**
```bash
# Get user's groups
USER_ID=$(kcadm.sh get users -r myrealm -q username==john.doe --id)
kcadm.sh get users/$USER_ID/groups -r myrealm
```

## Effective Permissions

### Permission Calculation

**User's effective roles =**
1. Directly assigned roles
2. Roles from group membership
3. Composite role inheritance
4. Client scope mappings

**Order of evaluation:**
1. User's direct role assignments
2. User's group memberships
3. For each group: group's roles
4. For each role: composite roles (recursive)
5. Client-specific scope mappings

### Viewing Effective Permissions

**Admin Console:**
1. Users → Select user
2. **Role mapping** tab
3. **Effective realm roles** section
4. **Assigned roles** dropdown (filter by client)
5. View all roles

**CLI:**
```bash
# Get user's role mappings
USER_ID=$(kcadm.sh get users -r myrealm -q username==john.doe --id)
kcadm.sh get users/$USER_ID/role-mappings -r myrealm
```

## Troubleshooting

### User Cannot Access Resource

**Debug steps:**
1. Check user's direct role assignments
2. Check user's group memberships
3. Verify group has required roles
4. Check for composite role issues
5. Verify client scope mappings
6. Check realm settings

**CLI debugging:**
```bash
# Get user info
USER_ID=$(kcadm.sh get users -r myrealm -q username==john.doe --id)
kcadm.sh get users/$USER_ID -r myrealm

# Get user's groups
kcadm.sh get users/$USER_ID/groups -r myrealm

# Get user's roles
kcadm.sh get users/$USER_ID/role-mappings -r myrealm

# Get group's roles
GROUP_ID=$(kcadm.sh get groups -r myrealm -q name==Developers --id)
kcadm.sh get groups/$GROUP_ID/role-mappings -r myrealm
```

### Group Inheritance Not Working

**Common issues:**
- Only roles inherit, not attributes
- Check group hierarchy depth
- Verify role assigned to parent group
- Check for disabled roles

**Solution:**
- Remember: Attributes don't inherit
- Only roles propagate to children
- Check group structure
- Verify role mapping

### Role Explosion

**Problem:** Too many roles to manage

**Solutions:**
1. **Consolidate similar roles:**
   ```
   Before: invoice_read, invoice_create, invoice_delete, invoice_approve
   After: invoice_viewer, invoice_editor, invoice_admin
   ```

2. **Use composite roles:**
   ```
   ADMIN = USER_MANAGER + CLIENT_MANAGER + GROUP_MANAGER
   ```

3. **Use groups for organization:**
   ```
   Assign roles to groups, not users directly
   ```

## Performance Considerations

### Large Numbers of Roles

**Impact:**
- Token size increase
- Permission evaluation overhead
- Management complexity

**Recommendations:**
- Limit to <100 realm roles
- Limit to <50 client roles per client
- Use composite roles effectively
- Regular cleanup of unused roles

### Large Numbers of Groups

**Impact:**
- Group membership checks
- Nested group evaluation
- Token size (if roles in groups)

**Recommendations:**
- Limit group depth to <5 levels
- Limit group memberships per user to <20
- Use attributes for metadata, not groups
- Regular cleanup of empty groups

## Auditing and Compliance

### Audit Reports

**Generate reports:**
1. **Users by role:**
   ```bash
   kcadm.sh get users -r myrealm -q role==admin
   ```

2. **Groups by role:**
   - Admin Console → Groups → Select group → Role mapping

3. **User group memberships:**
   ```bash
   kcadm.sh get users -r myrealm | jq '.[] | .username'
   ```

4. **Role changes over time:**
   - Admin Console → Events → Filter by role changes

### Compliance Considerations

**SoD (Separation of Duties):**
- Don't assign conflicting roles to same person
- Example: Person who can create payments shouldn't approve them

**Implement:**
- Use groups to enforce separation
- Document role conflicts
- Regular access reviews

**Example:**
```
Conflicting roles:
├── PAYMENT_CREATE
└── PAYMENT_APPROVE

Enforcement:
├── Accounts-Payable group (has: PAYMENT_CREATE)
├── Finance-Manager group (has: PAYMENT_APPROVE)
└── Rule: User cannot be in both groups
```

## Migration Strategies

### Migrating from Direct to Group-Based

**Step 1:** Analyze current state
```bash
# Export all user-role mappings
kcadm.sh get users -r myrealm > users.json

# Analyze patterns
jq '.[] | .username' users.json > usernames.txt
```

**Step 2:** Design group structure
- Identify common permission patterns
- Create logical groups
- Assign roles to groups

**Step 3:** Migrate users
```bash
# Add users to groups based on existing roles
for user in $(cat usernames.txt); do
  # Determine appropriate groups
  # Add user to groups
done
```

**Step 4:** Remove direct assignments
```bash
# Remove direct role assignments
# Keep only group memberships
```

**Step 5:** Verify
```bash
# Test access for sample users
# Verify permissions unchanged
```

## References

- <https://www.keycloak.org/docs/latest/server_admin/#assigning-permissions-using-roles-and-groups>
- Role-based access control (RBAC) best practices
- Attribute-based access control (ABAC)

## Related

- [[keycloak-server-administration]]
- [[keycloak-authorization-services]]
- [[keycloak-security]]
- [[keycloak-fine-grained-admin-permissions]]
