---
title: ODK Central Client UI Architecture Patterns
type: reference
domain: ODK Central
tags:
  - odk-central
  - frontend
  - vue
  - ui
  - client
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# ODK Central Client UI Architecture Patterns

This document describes the standard architecture patterns used in ODK Central frontend (`central-frontend` / `client` submodule).

## Overview

ODK Central frontend is a Vue.js single-page application (SPA) with:
- **Framework**: Vue 3 (Composition API + Options API)
- **Router**: Vue Router 4
- **State Management**: Request-data pattern (reactive resources)
- **Styling**: Bootstrap 3 + custom SCSS
- **i18n**: vue-i18n
- **Build Tool**: Vite
- **HTTP Client**: Axios

## Tech Stack

**Core Dependencies**:
```json
{
  "vue": "~3",
  "vue-router": "~4",
  "vue-i18n": "^10.0.7",
  "bootstrap": "~3",
  "axios": "^1.6.2",
  "luxon": "~1",  // Date/time handling
  "ramda": "~0.27"  // Functional utilities
}
```

**Node Version**: 22.21.1 (see `package.json` volta/engines)

## Project Structure

```
client/
├── src/
│   ├── components/          # Vue components
│   │   ├── account/
│   │   ├── analytics/
│   │   ├── audit/
│   │   ├── dataset/
│   │   ├── field-key/       # App user components
│   │   ├── form/
│   │   ├── project/
│   │   ├── submission/
│   │   ├── system/
│   │   ├── user/
│   │   └── *.vue            # Shared components
│   ├── composables/         # Composition API composables
│   ├── container/           # DI container modules
│   ├── locales/             # i18n translations
│   ├── request-data/        # State management
│   ├── util/                # Utility functions
│   ├── routes.js            # Route definitions
│   ├── router.js            # Router configuration
│   └── main.js              # App entry point
├── docs/                    # Documentation
├── test/                    # Unit tests (Karma + Mocha)
├── e2e-tests/               # Playwright E2E tests
├── vite.config.js           # Vite build config
└── package.json
```

## Request-Data Pattern (State Management)

### Concept

Instead of Vuex/Pinia, ODK Central uses a **request-data pattern** for reactive state tied to API resources.

### Resource Definition

**Location**: `src/request-data/resources.js`

**Pattern**:
```javascript
export default (container, createResource) => {
  // Session resources
  createResource('session');
  createResource('currentUser', () => ({
    transformResponse: ({ data }) => {
      data.verbs = new Set(data.verbs);
      data.can = hasVerbs;
      return shallowReactive(data);
    }
  }));

  // Domain resources
  createResource('projects');
  createResource('forms');
  createResource('fieldKeys');
}
```

### Resource Structure

Each resource is a reactive object with:
- `dataExists`: boolean - Whether data has been loaded
- `awaitingResponse`: boolean - Loading state
- `data`: The resource data (null/undefined if not loaded)
- `error`: Error object if request failed

### Computed Properties

**Pattern**:
```javascript
createResource('fieldKeys', () => ({
  withToken: computeIfExists(() =>
    fieldKeys.filter(fieldKey => fieldKey.token != null))
}));
```

### Using Resources in Components

**Inject**:
```javascript
export default {
  inject: ['currentUser', 'projects'],
  computed: {
    canCreateProject() {
      return this.currentUser.dataExists &&
             this.currentUser.can(['project.create']);
    }
  }
}
```

## Routing Pattern

### Route Definition

**Location**: `src/routes.js`

**Pattern**:
```javascript
import { asyncRoute } from './util/router';

const routes = [
  {
    path: '/projects/:projectId',
    component: ProjectShow,
    children: [
      asyncRoute({
        path: 'app-users',
        component: 'FieldKeyList',  // Lazy-loaded
        loading: 'tab',
        meta: {
          validateData: {
            project: () => project.dataExists,
            currentUser: () => currentUser.can(['field_key.list'])
          },
          title: () => ['App Users', project.name]
        }
      })
    ]
  }
];
```

### Async Routes (Lazy Loading)

**Pattern**:
```javascript
// src/util/load-async.js
const loaders = new Map()
  .set('FieldKeyList', loader(() => import(
    /* webpackChunkName: "component-field-key-list" */
    '../components/field-key/list.vue'
  )))
  .set('ProjectList', loader(() => import(
    '../components/project/list.vue'
  )));
```

**Usage**:
- Routes reference component by **string name** (e.g., `'FieldKeyList'`)
- `asyncRoute()` helper looks up loader and creates lazy route
- Components are code-split into separate chunks

### Route Metadata

**validateData**: Pre-route data validation
```javascript
meta: {
  validateData: {
    project: () => project.dataExists,
    currentUser: () => currentUser.can(['form.update'])
  }
}
```

**title**: Dynamic page titles
```javascript
meta: {
  title: () => [
    i18n.t('resource.forms'),
    project.name,
    i18n.t('common.project')
  ]
}
```

**fullWidth**: Layout flag
```javascript
meta: { fullWidth: true }  // Skip sidebar
```

## Component Patterns

### Component Structure (Options API)

**Standard Pattern**:
```vue
<template>
  <div>
    <loading :state="project.initiallyLoading"/>
    <page-section v-if="project.dataExists">
      <template #heading>
        <span>{{ project.name }}</span>
      </template>
      <template #body>
        <!-- content -->
      </template>
    </page-section>
  </div>
</template>

<script>
import Loading from '../loading.vue';
import PageSection from '../page/section.vue';

export default {
  name: 'ProjectOverview',
  components: { Loading, PageSection },
  inject: ['project', 'currentUser'],
  data() {
    return {
      localState: null
    };
  },
  computed: {
    canEdit() {
      return this.currentUser.can(['project.update']);
    }
  },
  methods: {
    submit() {
      this.$http.patch(`/v1/projects/${this.project.id}`, data)
        .then(() => {
          this.$alert().success('Project updated');
          this.project.patch(data);
        })
        .catch(() => {
          this.$alert().danger('Update failed');
        });
    }
  }
};
</script>

<style lang="scss" scoped>
// Component-specific styles
</style>
```

### Composition API Pattern (Modern)

**Pattern**:
```vue
<script setup>
import { inject, computed } from 'vue';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
const project = inject('project');
const currentUser = inject('currentUser');

const canEdit = computed(() =>
  currentUser.can(['project.update'])
);
</script>
```

## HTTP Requests

### Using $http (Axios)

**Pattern**:
```javascript
this.$http.get('/v1/projects')
  .then(response => {
    this.projects = response.data;
  })
  .catch(() => {
    this.$alert().danger('Failed to load projects');
  });
```

### Request Helpers

**Location**: `src/util/request.js`

**Pattern**:
```javascript
// Path builders
const projectPath = (projectId, suffix = '') =>
  `/v1/projects/${projectId}${suffix}`;

const apiPaths = {
  projects: '/v1/projects',
  project: (id) => projectPath(id),
  forms: (projectId) => projectPath(projectId, '/forms'),
  fieldKeys: (projectId) => projectPath(projectId, '/app-users')
};

// Use in components:
this.$http.get(apiPaths.forms(this.projectId))
```

### Standard Responses

**Success**:
```javascript
this.$http.post(url, data)
  .then(response => {
    this.$alert().success('Created successfully');
    this.$router.push('/path');
  });
```

**Error Handling**:
```javascript
this.$http.post(url, data)
  .catch(error => {
    if (error.response?.status === 409) {
      this.$alert().danger('Conflict: resource already exists');
    } else {
      this.$alert().danger(error.message || 'An error occurred');
    }
  });
```

## Alert System

### Usage

**Inject**:
```javascript
export default {
  methods: {
    showAlert() {
      this.$alert().success('Operation completed');
      this.$alert().info('FYI: Something to note');
      this.$alert().danger('Error occurred');
    }
  }
}
```

### Alert Types

- `success(message)`: Green success toast (auto-hide)
- `info(message)`: Blue info banner (persistent)
- `danger(message)`: Red error alert

### Implementation

**Location**: `src/container/alerts.js`

**Pattern**:
```javascript
export default ({ toast, alert }) => ({
  alert: () => ({
    success: (message) => toast.show(message, { type: 'success' }),
    info: (message) => toast.show(message, { type: 'info', autoHide: false }),
    danger: (message) => alert.danger(message)
  })
});
```

## i18n Pattern

### Usage in Templates

```vue
<template>
  <span>{{ $t('project.action.create') }}</span>
  <span>{{ $t('resource.projects', { count: 5 }) }}</span>
</template>
```

### Usage in Script

```javascript
import { useI18n } from 'vue-i18n';

export default {
  setup() {
    const { t } = useI18n();
    return { t };
  },
  methods: {
    showMessage() {
      this.$alert().success(this.t('project.alert.created'));
    }
  }
};
```

### Translation Files

**Location**: `src/locales/en.json5`

**Pattern**:
```json5
{
  project: {
    action: {
      create: "New Project",
      update: "Edit Project"
    },
    alert: {
      created: "Project created successfully"
    }
  },
  resource: {
    projects: "{count} Project | {count} Projects"
  }
}
```

## Form Handling

### Modal Pattern

**Pattern**:
```vue
<template>
  <modal id="project-new" :state="state" hideable backdrop
    @hide="$emit('hide')" @shown="focusInput">
    <template #title>{{ $t('action.create') }}</template>
    <template #body>
      <form @submit.prevent="submit">
        <form-group v-model="name" :placeholder="$t('field.name')"
          required autocomplete="off"/>
        <div class="modal-actions">
          <button type="submit" class="btn btn-primary"
            :disabled="state.awaitingResponse">
            {{ $t('action.create') }}
          </button>
          <button type="button" class="btn btn-link"
            @click="$emit('hide')">
            {{ $t('action.cancel') }}
          </button>
        </div>
      </form>
    </template>
  </modal>
</template>

<script>
export default {
  data() {
    return {
      name: '',
      state: { awaitingResponse: false }
    };
  },
  methods: {
    submit() {
      this.state.awaitingResponse = true;
      this.$http.post('/v1/projects', { name: this.name })
        .then(() => {
          this.$alert().success('Project created');
          this.$emit('success');
          this.$emit('hide');
        })
        .catch(() => {
          this.$alert().danger('Failed to create project');
        })
        .finally(() => {
          this.state.awaitingResponse = false;
        });
    },
    focusInput() {
      this.$refs.nameInput.focus();
    }
  }
};
</script>
```

## Loading States

### Using Loading Component

```vue
<template>
  <div>
    <loading :state="projects.initiallyLoading"/>
    <div v-if="projects.dataExists">
      <!-- content -->
    </div>
  </div>
</template>
```

### Conditional Rendering

**Pattern**:
- `initiallyLoading`: Show spinner on first load
- `dataExists`: Render content only when data is available
- `awaitingResponse`: Disable buttons during submission

## Common Components

### PageSection

Provides consistent section layout:
```vue
<page-section>
  <template #heading>
    <span>Section Title</span>
  </template>
  <template #body>
    Section content
  </template>
</page-section>
```

### CollectQR

Displays QR code for ODK Collect:
```vue
<collect-qr :settings="qrSettings" :error-correction-level="errorCorrectionLevel"/>
```

### DateTime

Formats timestamps:
```vue
<date-time :iso="submission.createdAt"/>
```

### Pagination

Handles paginated lists:
```vue
<pagination v-model:offset="offset" :total-count="totalCount" :limit="limit"/>
```

## Build and Dev

### Development

```bash
npm install
npm run dev  # Starts Vite dev server + Nginx proxy
```

**Dev Server**: `http://localhost:8989`

### Production Build

```bash
npm run build  # Output: dist/
```

### Linting

```bash
npm run lint       # ESLint + Transifex
npm run lint:fix   # Auto-fix
```

### Testing

```bash
npm test           # Unit tests (Karma + Mocha + Chai)
npm run test:e2e   # E2E tests (Playwright)
```

## Styling Conventions

### Bootstrap 3

- Use Bootstrap classes for layout and components
- Grid system: `.row`, `.col-xs-*`, `.col-sm-*`
- Buttons: `.btn`, `.btn-primary`, `.btn-danger`
- Forms: `.form-group`, `.form-control`

### Custom SCSS

**Pattern**:
```scss
<style lang="scss" scoped>
@import '../assets/scss/variables';

.custom-class {
  color: $color-action-foreground;
  margin-bottom: $margin-bottom-default;
}
</style>
```

### Scoped Styles

- Use `scoped` attribute to limit CSS to component
- Avoid global styles unless in `src/assets/scss/`

## Naming Conventions

### Components

- **PascalCase** for component names: `FieldKeyList`, `ProjectShow`
- **kebab-case** in templates: `<field-key-list/>`
- Group by domain: `field-key/list.vue`, `project/show.vue`

### Files

- Components: `component-name.vue`
- Utilities: `util-name.js`
- Tests: `component-name.spec.js`

### Props and Events

- Props: **camelCase** (`errorMessage`)
- Events: **kebab-case** (`@update-name`, `@hide`)

## Related

- [[vg-client-customizations]] - VG fork UI patterns
- [[server-architecture-patterns]] - Backend patterns

## References

- client/package.json - Dependencies and scripts
- client/src/routes.js - Route definitions
- client/src/request-data/resources.js - State management
- client/docs/dev-server.md - Development setup
