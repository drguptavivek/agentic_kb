---
title: Workflows - Automating Administrative Tasks
domain: Keycloak
type: tutorial
status: draft
tags: [keycloak, workflows, automation, iga, identity-governance, experimental, administrative-tasks]
created: 2026-01-29
related: [[keycloak-server-configuration-guide]], [[keycloak-required-action-spi]], [[keycloak-events]]
---

# Workflows - Automating Administrative Tasks

## Overview

**Workflows** is an automation engine for administrative tasks in Keycloak, introduced in version 26.4 as an **experimental** feature. It enables administrators to define automated processes that run in response to specific events.

### What Problems Do Workflows Solve?

| Problem | Solution |
|---------|----------|
| Inactive user accounts create security vulnerabilities | Automatically disable/delete inactive users |
| Manual onboarding is inefficient and error-prone | Auto-assign groups, roles, attributes on user creation |
| Compliance requires user lifecycle management | Automated notifications, deactivation, deletion |
| Repetitive administrative tasks consume time | Event-driven automation reduces manual work |

### Identity Governance and Administration (IGA)

Workflows directly address IGA principles:

- **Policy-based identity management**
- **Automated compliance enforcement**
- **User lifecycle automation**
- **Access control governance**
- **Reduced administrative overhead**

## Core Capabilities

### 1. User-Centric Automation

Initially focused on user resource management. Future versions will extend to:
- Clients
- Organizations
- Identity Providers
- Other realm components

### 2. Event-Driven Triggers

Workflows are triggered by realm events:

| Event | Description |
|-------|-------------|
| `USER_LOGIN` | User successfully logs in |
| `USER_ADD` | User created or registered |
| `USER_GROUP_MEMBERSHIP_ADD` | User added to group |
| `USER_ROLE_ADD` | User assigned role |

**Planned future events:**
- `USER_UPDATED`
- `USER_GROUP_MEMBERSHIP_REMOVE`
- `USER_ROLE_REMOVE`
- `USER_ORGANIZATION_ADD/REMOVE`

### 3. Configurable Steps and Conditions

**Steps**: Actions executed sequentially when conditions are met
**Conditions**: Filter which resources are affected

Built-in conditions:
- `is-member-of(group)`: Check group membership
- `has-role(role)`: Check role assignment
- `has-user-attribute(key, value)`: Check user attributes
- `has-identity-provider-link(identity-provider)`: Check IdP link

### 4. Schedulable Steps

Steps can run:
- **Immediately**: Upon workflow activation
- **After delay**: Relative to previous step completion

Example: Notify user 30 days before deactivation, then disable after another 30 days.

## Built-in Steps (Current)

### Current Steps (26.4+)

| Step | Description | Use Case |
|------|-------------|----------|
| `notify-user` | Send automated email notifications | Warn users of impending account action |
| `disable-user` | Disable user account | Inactive account management |
| `delete-user` | Remove account from system | Data retention compliance |

### Planned Future Steps

- `join-group` / `leave-group`
- `assign-role` / `unassign-role`
- `add-user-attribute` / `remove-user-attribute`
- `join-organization` / `leave-organization`

## Getting Started

### Enable Workflows Feature

```bash
# Start Keycloak with workflows enabled
./kc.sh start-dev \
  --features=workflows \
  --spi-events-listener--workflow-event-listener--step-runner-task-interval=1000 \
  --log-level="INFO,org.keycloak.models.workflow:DEBUG"
```

**Configuration Options:**

| Option | Description | Default |
|--------|-------------|---------|
| `--features=workflows` | Enable workflows feature | disabled |
| `step-runner-task-interval` | Background task interval (ms) | 43200000 (12 hours) |
| `log-level` | Logging for workflows | INFO |

**Production Recommendation:**

```bash
# Production settings (12-hour interval)
./kc.sh start \
  --features=workflows \
  --spi-events-listener--workflow-event-listener--step-runner-task-interval=43200000
```

## Workflow Definition

### JSON Structure

```json
{
  "name": "disable-inactive-users",
  "uses": "event-based-workflow",
  "on": "USER_LOGIN",
  "reset-on": "USER_LOGIN",
  "if": [
    {
      "uses": "expression",
      "with": {
        "expression": "!has-role(\"realm-management/realm-admin\")"
      }
    }
  ],
  "steps": [
    {
      "uses": "notify-user",
      "after": "2592000000",
      "with": {
        "custom_message": "Your account will be disabled due to inactivity!"
      }
    },
    {
      "uses": "disable-user",
      "after": "2592000000"
    }
  ]
}
```

### Property Reference

| Property | Required | Description |
|----------|----------|-------------|
| `name` | Yes | Workflow identifier |
| `uses` | Yes | Provider ID (e.g., `event-based-workflow`) |
| `on` | Yes | Trigger event (e.g., `USER_LOGIN`) |
| `reset-on` | No | Event that resets workflow |
| `if` | No | Conditions to evaluate |
| `steps` | Yes | Array of workflow steps |
| `uses` (step) | Yes | Step provider ID |
| `after` | No | Delay before step execution (ms) |
| `with` | No | Step-specific configuration |

## Common Workflow Patterns

### 1. Inactive User Management

**Scenario**: Disable users who haven't logged in for 60 days (non-admins)

```json
{
  "name": "disable-inactive-non-admins",
  "uses": "event-based-workflow",
  "on": "USER_LOGIN",
  "reset-on": "USER_LOGIN",
  "if": [
    {
      "uses": "expression",
      "with": {
        "expression": "!has-role(\"realm-management/realm-admin\")"
      }
    }
  ],
  "steps": [
    {
      "uses": "notify-user",
      "after": "5184000000",
      "with": {
        "custom_message": "Your account will be disabled in 30 days due to inactivity. Please log in to keep it active."
      }
    },
    {
      "uses": "notify-user",
      "after": "2592000000",
      "with": {
        "custom_message": "Your account will be disabled in 7 days due to inactivity."
      }
    },
    {
      "uses": "disable-user",
      "after": "604800000"
    }
  ]
}
```

**Timeline:**
- Day 0: User logs in (workflow starts)
- Day 60: First warning (30 days before disable)
- Day 83: Second warning (7 days before disable)
- Day 90: Account disabled

### 2. New User Onboarding

**Scenario**: Auto-assign groups and roles to new users from specific IdP

```json
{
  "name": "onboarding-sso-users",
  "uses": "event-based-workflow",
  "on": "USER_ADD",
  "if": [
    {
      "uses": "expression",
      "with": {
        "expression": "has-identity-provider-link(\"saml-provider\")"
      }
    }
  ],
  "steps": [
    {
      "uses": "join-group",
      "after": "0",
      "with": {
        "group": "sso-users"
      }
    },
    {
      "uses": "assign-role",
      "after": "0",
      "with": {
        "role": "user",
        "client": "my-app"
      }
    }
  ]
}
```

### 3. Progressive Security Enforcement

**Scenario**: Notify, then disable, then delete inactive accounts

```json
{
  "name": "progressive-inactivity-cleanup",
  "uses": "event-based-workflow",
  "on": "USER_LOGIN",
  "reset-on": "USER_LOGIN",
  "if": [
    {
      "uses": "expression",
      "with": {
        "expression": "!has-role(\"admin\") AND !is-member-of(\"permanent-users\")"
      }
    }
  ],
  "steps": [
    {
      "uses": "notify-user",
      "after": "7776000000",
      "with": {
        "custom_message": "Your account has been inactive for 90 days."
      }
    },
    {
      "uses": "disable-user",
      "after": "2592000000"
    },
    {
      "uses": "notify-user",
      "after": "15552000000",
      "with": {
        "custom_message": "Your disabled account will be deleted in 30 days."
      }
    },
    {
      "uses": "delete-user",
      "after": "2592000000"
    }
  ]
}
```

**Timeline:**
- Day 0: Last login
- Day 90: Warning sent
- Day 120: Account disabled
- Day 270: Deletion warning (90 days after disable)
- Day 300: Account deleted

### 4. Role-Based Onboarding

**Scenario**: Assign different groups based on user attributes

```json
{
  "name": "department-based-onboarding",
  "uses": "event-based-workflow",
  "on": "USER_ADD",
  "steps": [
    {
      "uses": "join-group",
      "after": "0",
      "if": [
        {
          "uses": "expression",
          "with": {
            "expression": "has-user-attribute(\"department\", \"engineering\")"
          }
        }
      ],
      "with": {
        "group": "engineering"
      }
    },
    {
      "uses": "join-group",
      "after": "0",
      "if": [
        {
          "uses": "expression",
          "with": {
            "expression": "has-user-attribute(\"department\", \"sales\")"
          }
        }
      ],
      "with": {
        "group": "sales"
      }
    }
  ]
}
```

## Advanced Expression Logic

### Logical Operators

Combine conditions using:

```json
{
  "if": [
    {
      "uses": "expression",
      "with": {
        "expression": "!has-role(\"admin\") AND has-user-attribute(\"department\", \"engineering\")"
      }
    }
  ]
}
```

**Available operators:**
- `AND`: Both conditions must be true
- `OR`: Either condition can be true
- `!` (NOT): Negate condition
- `()`: Group conditions

### Complex Examples

**Exclude multiple roles:**

```json
"expression": "!has-role(\"admin\") AND !has-role(\"super-admin\")"
```

**Multiple attribute checks:**

```json
"expression": "has-user-attribute(\"status\", \"active\") AND has-user-attribute(\"region\", \"US\")"
```

**Complex filtering:**

```json
"expression": "(has-user-attribute(\"type\", \"contractor\") OR has-user-attribute(\"type\", \"temp\")) AND !is-member-of(\"permanent-contractors\")"
```

## Administration Console

### Create Workflow

1. Navigate to **Configure** → **Workflows**
2. Click **Create Workflow**
3. Paste JSON workflow definition
4. Click **Save**

### Manage Workflows

View, edit, and delete workflows from the Workflows console.

### Testing

**Recommended approach:**
1. Create test realm
2. Use short time intervals for testing
3. Enable debug logging
4. Verify with test users
5. Adjust times for production

## Custom Steps and Conditions

### SPI Extension

Steps and conditions have their own SPIs for custom implementations.

### Custom Step Example

```java
package com.example.keycloak.workflow;

import org.keycloak.models.KeycloakSession;
import org.keycloak.models.UserModel;
import org.keycloak.workflow.WorkflowContext;
import org.keycloak.workflow.WorkflowStep;
import org.keycloak.workflow.WorkflowStepFactory;

public class CustomAttributeStep implements WorkflowStep {

    @Override
    public void execute(WorkflowContext context) {
        KeycloakSession session = context.getSession();
        UserModel user = session.users().getUserById(context.getResourceId());

        // Custom logic
        user.setSingleAttribute("lastWorkflowExecution",
                                java.time.Instant.now().toString());

        context.complete();
    }

    public static class Factory implements WorkflowStepFactory {

        @Override
        public String getId() {
            return "custom-attribute-step";
        }

        @Override
        public WorkflowStep create(KeycloakSession session) {
            return new CustomAttributeStep();
        }
    }
}
```

### Register Custom Provider

Create `META-INF/services/org.keycloak.workflow.WorkflowStepFactory`:

```
com.example.keycloak.workflow.CustomAttributeStep$Factory
```

### Use in Workflow

```json
{
  "steps": [
    {
      "uses": "custom-attribute-step",
      "after": "0"
    }
  ]
}
```

## Roadmap

Keycloak 26.5+: Planned to become **supported** (currently experimental)

### Planned Improvements

- [ ] Additional built-in steps (onboarding/offboarding)
- [ ] Additional events (UPDATE, REMOVE operations)
- [ ] Workflow templates for common patterns
- [ ] YAML format support
- [ ] Assign workflows to existing resources (not just event-triggered)
- [ ] Improved UI
- [ ] Human-readable time formats (`30d`, `12h` instead of milliseconds)
- [ ] Scheduled task configuration (specific time of day)

## Best Practices

### Development

- [ ] Test in non-production environment first
- [ ] Use separate test realm
- [ ] Start with short intervals for testing
- [ ] Enable debug logging during development
- [ ] Monitor logs for workflow execution

### Production

- [ ] Use appropriate time intervals (days, not seconds)
- [ ] Set up email notifications for users
- [ ] Document all workflows
- [ ] Monitor workflow execution regularly
- [ ] Have rollback plan for misconfigurations

### Security

- [ ] Exclude admins from automated workflows
- [ ] Use conditions to filter sensitive accounts
- [ ] Test workflows with non-admin accounts first
- [ ] Review workflow definitions before deploying
- [ ] Monitor for unintended side effects

### User Experience

- [ ] Provide clear notification messages
- [ ] Give users time to react before disabling
- [ ] Document workflow behavior in user guides
- [ ] Consider multiple warnings before drastic action
- [ ] Provide self-service reactivation options

## Troubleshooting

### Workflow Not Triggered

**Check:**
- Feature is enabled
- Workflow is saved
- Event matches `on` property
- Conditions are met

**Debug logging:**

```bash
--log-level="DEBUG,org.keycloak.models.workflow:DEBUG"
```

### Steps Not Executing

**Check:**
- Background task interval setting
- Step order and `after` values
- Previous step completed successfully

**View execution status:**

```bash
# Check logs for workflow execution
grep "workflow" /opt/keycloak/data/log/keycloak.log
```

### Email Not Sent

**Check:**
- Email settings configured for realm
- User has valid email
- Notification step configured correctly

**Test email:**

```bash
# Test email configuration
kcadm.sh create users/$USER_ID/execute-actions-email \
  -r myrealm \
  -q '["UPDATE_PASSWORD"]'
```

### Workflow Not Resetting

**Check:**
- `reset-on` property is set
- Reset event is occurring
- Event type matches `reset-on` value

## Monitoring

### Audit Events

Workflows generate audit events:

```json
{
  "eventType": "WORKFLOW_EXECUTED",
  "realmId": "my-realm",
  "workflow": "disable-inactive-users",
  "resourceId": "user-id",
  "timestamp": 1706227200000
}
```

### Metrics

Monitor via Prometheus:

```
# Workflow metrics
keycloak_workflow_started_total
keycloak_workflow_completed_total
keycloak_workflow_failed_total
keycloak_workflow_step_executed_total
```

### Logging

Key workflow log messages:

```
DEBUG [org.keycloak.models.workflow.WorkflowExecutionContext]
  Started workflow '{name}' for resource {id}

DEBUG [org.keycloak.models.workflow.WorkflowsManager]
  Scheduling step {step} to run in {ms} ms

DEBUG [org.keycloak.models.workflow.WorkflowExecutionContext]
  Step {step} completed successfully
```

## API Access

### Create Workflow via Admin API

```bash
kcadm.sh create workflows/config -r myrealm -f workflow.json
```

### List Workflows

```bash
kcadm.sh get workflows/config -r myrealm
```

### Delete Workflow

```bash
kcadm.sh delete workflows/config/{id} -r myrealm
```

## Related Topics

- [[keycloak-events]] - Event system overview
- [[keycloak-required-action-spi]] - Required actions
- [[keycloak-server-configuration-guide]] - Server configuration
- [[keycloak-admin-console]] - Admin console usage

## Additional Resources

- [Workflows Blog Post](https://www.keycloak.org/2025/10/workflows-experimental-26-4)
- [GitHub Discussion Thread](https://github.com/keycloak/keycloak/discussions)
- [Server Development Guide](https://www.keycloak.org/docs/latest/server_development)
