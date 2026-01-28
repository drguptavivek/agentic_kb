---
domain: ODK-Central-vg
type: reference
status: approved
tags: #odk #vg-fork #client #enketo #vue #ui
created: 2026-01-28
---

# ODK Central VG Enketo Status UI

> **Source**: `docs/vg/vg-client/vg_client_changes.md`

## Overview

VG adds a new System tab for viewing and managing Enketo IDs across all forms and projects.

## Route

**Path**: `/system/enketo-status`

**Component**: `VgEnketoStatus`

**Permissions**:
- **View**: `config.read`
- **Regenerate**: `config.set` (admin only)

## Component

**File**: `src/components/system/vg-enketo-status.vue`

**Features**:
- Summary cards with counts by status
- Filterable table by Project ID and Form ID
- Individual regenerate buttons
- Bulk regenerate action for "never pushed" forms

## Status Categories

| Status | Description | Can Regenerate |
|--------|-------------|----------------|
| `healthy` | Has both `enketoId` and `enketoOnceId` | No |
| `never_pushed` | `enketoId` is NULL (never pushed to Enketo) | Yes |
| `draft_only` | Only draft has `enketoId`, published form doesn't | No |
| `closed` | Form state is not 'open' | No |
| `push_failed` | Last push attempt failed | Yes |

## Summary Cards

```
┌─────────────────┬─────────────────┬─────────────────┬─────────────────┐
│      Healthy    │  Never Pushed   │    Draft Only    │      Closed     │
│       142       │        3        │        1        │        5        │
└─────────────────┴─────────────────┴─────────────────┴─────────────────┘
```

## Table Columns

| Column | Description |
|--------|-------------|
| Project ID | Filterable project identifier |
| Form ID/Name | Filterable form identifier |
| Enketo ID | Current Enketo identifier |
| Status | Current status (color-coded) |
| Actions | Regenerate button (when available) |

## Filters

- **Project ID**: Text input for filtering by project
- **Form ID**: Text input for filtering by form XML ID
- **Status**: Dropdown to filter by status type

## Actions

### Individual Regenerate

1. Click "Regenerate" button on a form row
2. Confirms admin permission
3. Calls backend to generate new Enketo ID
4. Updates row on success

**API call**:
```javascript
POST /v1/system/enketo-status/regenerate
{
  "xmlFormId": "basic",
  "projectId": 1
}
```

### Bulk Regenerate

1. Click "Regenerate All Never Pushed" button
2. Confirms admin permission
3. Regenerates all forms with `never_pushed` status
4. Updates all affected rows

**API call**:
```javascript
POST /v1/system/enketo-status/regenerate
{
  "filter": "never_pushed"
}
```

## API Integration

**Request data resource**:
```javascript
// src/request-data/resources.js
createResource('enketoStatus', noargs(setupOption), {
  transformResponse: (data) => ({
    // Custom transform for status summary and table data
  })
});
```

**API paths**:
```javascript
// src/util/request.js
enketoStatus: (query = undefined) =>
  `/v1/system/enketo-status${queryString(query)}`,
enketoStatusRegenerate: () =>
  `/v1/system/enketo-status/regenerate`
```

## i18n Keys

```javascript
// Tab label
"systemHome.tab.enketoStatus": "Enketo Status"

// Status types
"vgEnketoStatus.status.healthy": "Healthy"
"vgEnketoStatus.status.never_pushed": "Never Pushed"
"vgEnketoStatus.status.draft_only": "Draft Only"
"vgEnketoStatus.status.closed": "Closed"
"vgEnketoStatus.status.push_failed": "Push Failed"

// Actions
"vgEnketoStatus.action.regenerate": "Regenerate"
"vgEnketoStatus.action.regenerateAll": "Regenerate All Never Pushed"

// Filters
"vgEnketoStatus.filter.projectId": "Project ID"
"vgEnketoStatus.filter.formId": "Form ID"
"vgEnketoStatus.filter.status": "Status"

// Alerts
"vgEnketoStatus.alert.regenerateSuccess": "Enketo ID regenerated successfully."
"vgEnketoStatus.alert.regenerateError": "Failed to regenerate Enketo ID."
```

## Related Documentation

- [[ODK-Central-vg/client-overview]] - Client changes overview
- [[ODK-Central-vg/odk-central-vg-overview]] - Main VG overview
