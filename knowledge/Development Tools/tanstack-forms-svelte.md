---
title: TanStack Forms for Svelte
type: howto
domain: Development Tools
tags:
  - forms
  - svelte
  - tanstack
  - validation
  - zod
  - standard-schema
  - type-safe
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# TanStack Forms for Svelte

## Overview

TanStack Form is a headless, performant, and type-safe form state management library for TypeScript/JavaScript. The Svelte integration (`@tanstack/svelte-form`) provides fine-grained reactivity, type safety, and framework-agnostic form handling with minimal boilerplate. <https://tanstack.com/form/latest/docs/framework/svelte>

**Key Features:**
- Headless UI - Bring your own components
- Type-safe by default
- Framework-agnostic validation (Standard Schema support)
- Performance optimized with fine-grained reactivity
- Small bundle size
- Supports sync and async validation
- Array fields, nested objects, and complex forms

**Latest Version:** v1 (Released March 2025)

## Installation

```bash
npm install @tanstack/svelte-form
```

**TypeScript Configuration:**

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true
  }
}
```

## Quick Start

### Basic Form

```svelte
<script>
  import { createForm } from '@tanstack/svelte-form';

  const form = createForm(() => ({
    defaultValues: {
      fullName: '',
    },
    onSubmit: async ({ value }) => {
      console.log(value);
    },
  }));
</script>

<form
  onsubmit={(e) => {
    e.preventDefault();
    e.stopPropagation();
    form.handleSubmit();
  }}
>
  <form.Field name="fullName">
    {#snippet children(field)}
      <input
        name={field.name}
        value={field.state.value}
        onblur={field.handleBlur}
        oninput={(e) => field.handleChange(e.target.value)}
      />
    {/snippet}
  </form.Field>
  <button type="submit">Submit</button>
</form>
```

## Core Concepts

### Form Instance

Created using `createForm()`, accepts configuration object:

```typescript
const form = createForm<Person>(() => ({
  defaultValues: {
    firstName: '',
    lastName: '',
    hobbies: [],
  },
  onSubmit: async ({ value }) => {
    // Submit to API
    await fetch('/api/users', {
      method: 'POST',
      body: JSON.stringify(value),
    });
  },
}));
```

### Form Options (Reusable)

```typescript
import { formOptions } from '@tanstack/svelte-form';

const formOpts = formOptions({
  defaultValues: {
    firstName: '',
    lastName: '',
    hobbies: [],
  } as Person,
});

const form = createForm(() => ({
  ...formOpts,
  onSubmit: async ({ value }) => {
    console.log(value);
  },
}));
```

### Field Component

Fields are created using `<form.Field>` with snippet syntax:

```svelte
<form.Field name="firstName">
  {#snippet children(field)}
    <input
      name={field.name}
      value={field.state.value}
      onblur={field.handleBlur}
      oninput={(e) => field.handleChange(e.target.value)}
    />
  {/snippet}
</form.Field>
```

### Field State

Access field state via `field.state`:

```typescript
const {
  value,              // Current value
  meta: {
    errors,          // Array of error messages
    isValidating,    // Boolean - async validation in progress
    isTouched,       // User interacted with field
    isDirty,         // Value has changed (persistent)
    isPristine,      // Opposite of isDirty
    isBlurred,       // Field has been blurred
    isDefaultValue,  // Value equals default
  },
} = field.state;
```

**Field State Visualization:**

```
┌─────────────────────────────────────┐
│ Field States                         │
├─────────────────────────────────────┤
│ isTouched  ─────────────────────────┤
│ isDirty    ────────┬───────────────┤
│ isPristine ◄────────┘               │
│ isBlurred                            │
│ isDefaultValue                       │
│ isValidating (async only)            │
└─────────────────────────────────────┘
```

## Validation

### Field-Level Validation

```svelte
<form.Field
  name="firstName"
  validators={{
    onChange: ({ value }) =>
      value.length < 3
        ? 'First name must be at least 3 characters'
        : undefined,
    onBlur: ({ value }) =>
      !value
        ? 'First name is required'
        : undefined,
  }}
>
  {#snippet children(field)}
    <input
      name={field.name}
      value={field.state.value}
      onblur={field.handleBlur}
      oninput={(e) => field.handleChange(e.target.value)}
    />
    {#if field.state.meta.errors}
      <em role="alert">{field.state.meta.errors.join(', ')}</em>
    {/if}
  {/snippet}
</form.Field>
```

### Async Validation with Debouncing

```svelte
<form.Field
  name="username"
  asyncDebounceMs={500}
  validators={{
    onChange: ({ value }) =>
      value.length < 3 ? 'Too short' : undefined,
    onChangeAsyncDebounceMs: 1000,
    onChangeAsync: async ({ value }) => {
      // Check if username exists
      const exists = await checkUsernameExists(value);
      return exists ? 'Username already taken' : undefined;
    },
  }}
>
  {#snippet children(field)}
    <input
      name={field.name}
      value={field.state.value}
      onblur={field.handleBlur}
      oninput={(e) => field.handleChange(e.target.value)}
    />
    {#if field.state.meta.isValidating}
      <small>Checking availability...</small>
    {/if}
    {#if field.state.meta.errors}
      <em role="alert">{field.state.meta.errors.join(', ')}</em>
    {/if}
  {/snippet}
</form.Field>
```

### Form-Level Validation

```typescript
const form = createForm(() => ({
  defaultValues: {
    age: 0,
  },
  validators: {
    onChange({ value }) {
      if (value.age < 13) {
        return 'Must be 13 or older to sign up';
      }
      return undefined;
    },
  },
  onSubmit: async ({ value }) => {
    console.log(value);
  },
}));

// Subscribe to form errors
const formErrorMap = form.useStore((state) => state.errorMap);
```

### Display Errors

```svelte
<!-- Display all errors -->
{#if field.state.meta.errors}
  <em role="alert">{field.state.meta.errors.join(', ')}</em>
{/if}

<!-- Display specific error by validation type -->
{#if field.state.meta.errorMap['onChange']}
  <em role="alert">{field.state.meta.errorMap['onChange']}</em>
{/if}

<!-- Display errors in FieldInfo component -->
<FieldInfo {field} />
```

**FieldInfo Component:**

```svelte
<!-- FieldInfo.svelte -->
<script lang="ts">
  import type { AnyFieldApi } from '@tanstack/svelte-form';

  let { field }: { field: AnyFieldApi } = $props();
</script>

{#if field.state.meta.isTouched}
  {#each field.state.meta.errors as error}
    <em>{error.message}</em>
  {/each}
  {:else if field.state.meta.isValidating}
    Validating...
  {/if}
{/if}
```

## Standard Schema Validation

TanStack Form natively supports all libraries implementing the [Standard Schema](https://github.com/standard-schema/standard-schema) specification.

**Supported Libraries:**
- **Zod** (v3.24.0+) - `z.object({...})`
- **Valibot** (v1.0.0+) - `v.object({...})`
- **ArkType** (v2.1.20+) - `type({...})`
- **Effect Schema** (via adapter) - `S.Struct({...})`
- **Yup** (v1.7.0+)

### Zod Integration

```svelte
<script>
  import { z } from 'zod';

  const ZodSchema = z.object({
    firstName: z
      .string()
      .min(3, '[Zod] You must have a length of at least 3')
      .startsWith('A', "[Zod] First name must start with 'A'"),
    lastName: z.string().min(3, '[Zod] Last name too short'),
  });

  const form = createForm(() => ({
    defaultValues: {
      firstName: '',
      lastName: '',
    },
    validators: {
      onChange: ZodSchema,
    },
    onSubmit: async ({ value }) => {
      console.log(value);
    },
  }));
</script>

<form.Field name="firstName">
  {#snippet children(field)}
    <input
      name={field.name}
      value={field.state.value}
      onblur={field.handleBlur}
      oninput={(e) => field.handleChange(e.target.value)}
    />
    <FieldInfo {field} />
  {/snippet}
</form.Field>
```

### Valibot Integration

```svelte
<script>
  import * as v from 'valibot';

  const ValibotSchema = v.object({
    firstName: v.pipe(
      v.string(),
      v.minLength(3, '[Valibot] Too short'),
      v.startsWith('A', "[Valibot] Must start with 'A'"),
    ),
    lastName: v.pipe(
      v.string(),
      v.minLength(3, '[Valibot] Too short'),
    ),
  });

  const form = createForm(() => ({
    defaultValues: {
      firstName: '',
      lastName: '',
    },
    validators: {
      onChange: ValibotSchema,
    },
  }));
</script>
```

### ArkType Integration

```svelte
<script>
  import { type } from 'arktype';

  const ArkTypeSchema = type({
    firstName: 'string >= 3',
    lastName: 'string >= 3',
  });

  const form = createForm(() => ({
    defaultValues: {
      firstName: '',
      lastName: '',
    },
    validators: {
      onChange: ArkTypeSchema,
    },
  }));
</script>
```

### Switching Between Schemas

```svelte
<script>
  // You can seamlessly switch between schema libraries
  const form = createForm(() => ({
    defaultValues: { firstName: '', lastName: '' },
    validators: {
      // Uncomment to use different schema
      onChange: ZodSchema,
      // onChange: ValibotSchema,
      // onChange: ArkTypeSchema,
      // onChange: EffectSchema,
    },
  }));
</script>
```

## Reactivity and Performance

### form.useStore Hook

Subscribe to specific form state for fine-grained reactivity:

```svelte
<script>
  // Subscribe to specific value
  const firstName = form.useStore((state) => state.values.firstName);

  // Subscribe to derived state
  const canSubmit = form.useStore((state) => state.canSubmit);
</script>

<p>First name: {firstName}</p>
<button disabled={!canSubmit}>Submit</button>
```

### form.Subscribe Component

Alternative to `useStore` for template-based subscriptions:

```svelte
<form.Subscribe
  selector={(state) => ({
    canSubmit: state.canSubmit,
    isSubmitting: state.isSubmitting,
  })}
>
  {#snippet children(state)}
    <button type="submit" disabled={!state.canSubmit}>
      {state.isSubmitting ? '...' : 'Submit'}
    </button>
  {/snippet}
</form.Subscribe>
```

**Performance:** TanStack Form uses fine-grained reactivity, so components only re-render when the specific state they subscribe to changes.

## Array Fields

Manage dynamic lists with `mode="array"`:

```svelte
<script>
  const form = createForm(() => ({
    defaultValues: {
      people: [] as Array<{ name: string; age: number }>,
    },
    onSubmit: ({ value }) => console.log(value),
  }));
</script>

<form.Field name="people" mode="array">
  {#snippet children(field)}
    {#each field.state.value as person, i}
      <div>
        <form.Field name={`people[${i}].name`}>
          {#snippet children(subField)}
            <input
              value={subField.state.value}
              oninput={(e) => subField.handleChange(e.target.value)}
            />
          {/snippet}
        </form.Field>
        <button type="button" onclick={() => field.removeValue(i)}>
          Remove
        </button>
      </div>
    {:else}
      <p>No people yet</p>
    {/each}
    <button type="button" onclick={() => field.pushValue({ name: '', age: 0 })}>
      Add Person
    </button>
  {/snippet}
  </form.Field>
```

### Array Field Methods

- `pushValue(value)` - Add value to end
- `insertValue(index, value)` - Insert at index
- `removeValue(index)` - Remove at index
- `replaceValue(index, value)` - Replace at index
- `swapValues(indexA, indexB)` - Swap two values
- `moveValue(from, to)` - Move value from one index to another
- `clearValues()` - Clear all values

## Conditional Fields

Show/hide fields based on other field values:

```svelte
<script>
  const form = createForm(() => ({
    defaultValues: {
      employed: false,
      jobTitle: '',
    },
  }));
</script>

<form.Field name="employed">
  {#snippet children(field)}
    <label>
      <input
        type="checkbox"
        checked={field.state.value}
        oninput={() => field.handleChange(!field.state.value)}
      />
      Employed?
    </label>
  {/snippet}
</form.Field>

{#if form.useStore((s) => s.values.employed)}
  <form.Field
    name="jobTitle"
    validators={{
      onChange: ({ value }) =>
        value.length === 0 ? 'Job title is required' : undefined,
    }}
  >
    {#snippet children(field)}
      <input
        name={field.name}
        value={field.state.value}
        onblur={field.handleBlur}
        oninput={(e) => field.handleChange(e.target.value)}
      />
      <FieldInfo {field} />
    {/snippet}
  </form.Field>
{/if}
```

## Form State Properties

Access form state properties:

```typescript
const {
  // Values
  values,              // Current form values
  // Errors
  errorMap,            // Errors by validation type
  // Meta
  isSubmitting,       // Form is submitting
  isValid,            // Form is valid (no errors)
  isDirty,            // Form has been modified
  isPristine,         // Form is pristine
  canSubmit,          // Form can be submitted (valid + touched)
  // Methods
  handleSubmit,       // Submit handler
  reset,              // Reset to defaults
} = form.useStore((state) => state);
```

## Submit Handling

### Basic Submit

```svelte
<form
  onsubmit={(e) => {
    e.preventDefault();
    e.stopPropagation();
    form.handleSubmit();
  }}
>
  <!-- fields -->
  <button type="submit">Submit</button>
</form>
```

### Submit Button State

```svelte
<form.Subscribe
  selector={(state) => ({
    canSubmit: state.canSubmit,
    isSubmitting: state.isSubmitting,
  })}
>
  {#snippet children(state)}
    <button type="submit" disabled={!state.canSubmit}>
      {state.isSubmitting ? 'Submitting...' : 'Submit'}
    </button>
  {/snippet}
</form.Subscribe>
```

### Preventing Invalid Submission

The `canSubmit` flag is false when:
- Any field has errors, AND
- The form has been touched (user interacted with it)

**To prevent submission before interaction:**

```svelte
<form.Subscribe
  selector={(state) => ({
    canSubmit: state.canSubmit,
    isPristine: state.isPristine,
  })}
>
  {#snippet children(state)}
    <button type="submit" disabled={!state.canSubmit || state.isPristine}>
      Submit
    </button>
  {/snippet}
</form.Subscribe>
```

## Reset Form

```svelte
<button
  type="button"
  onclick={() => form.reset()}
>
  Reset
</button>
```

## Advanced Features

### Custom Error Objects

Return objects instead of strings for typed errors:

```svelte
<script>
  const form = createForm(() => ({
    defaultValues: { age: 0 },
    validators: {
      onChange: ({ value }) => {
        if (value < 13) {
          return { isOldEnough: false };
        }
        return undefined;
      },
    },
  }));
</script>

<!-- Access typed error -->
{#if form.FieldApi('age').state.meta.errorMap['onChange']?.isOldEnough}
  <em>Not old enough</em>
{/if}
```

### Linked Fields

Validate one field based on another:

```svelte
<script>
  const form = createForm(() => ({
    defaultValues: {
      password: '',
      confirmPassword: '',
    },
    validators: {
      onChange: ({ value }) => {
        if (value.password !== value.confirmPassword) {
          return {
            confirmPassword: 'Passwords must match',
            password: 'Passwords must match',
          };
        }
        return undefined;
      },
    },
  }));
</script>
```

### Async Initial Values

```svelte
<script>
  const form = createForm(async () => ({
    defaultValues: await fetchUserData(),
    onSubmit: async ({ value }) => {
      await saveUser(value);
    },
  }));
</script>
```

## Type Safety

### Type Inference

```typescript
// Types are inferred from defaultValues
const form = createForm(() => ({
  defaultValues: {
    firstName: '',
    age: 0,
    employed: false,
  },
}));

type FormValues = typeof form._def.defaultValues;
// { firstName: string; age: number; employed: boolean }
```

### Generic Types

```typescript
interface User {
  firstName: string;
  lastName: string;
  age: number;
}

const form = createForm<User>(() => ({
  defaultValues: {
    firstName: '',
    lastName: '',
    age: 0,
  },
  onSubmit: async ({ value }) => {
    // value is typed as User
  },
}));
```

## Best Practices

1. **Use Standard Schema** for type-safe validation (Zod, Valibot, ArkType)
2. **Leverage field states** (`isTouched`, `isDirty`) for conditional validation
3. **Debounce async validation** to prevent API spam
4. **Use `form.useStore`** for fine-grained reactivity
5. **Prefer snippet syntax** for better type inference
6. **Use FieldInfo component** for reusable error display
7. **Combine sync and async validation** for optimal UX
8. **Use `mode="array"`** for dynamic lists
9. **Subscribe to specific state** to avoid unnecessary re-renders
10. **Type your forms** with TypeScript for full safety

## Comparison with Other Libraries

| Feature | TanStack Form | Superforms | Formik |
|---------|---------------|------------|--------|
| Bundle Size | Small | Medium | Large |
| Type Safety | ✅ Native | ✅ Via Zod | ✅ Via Zod |
| Standard Schema | ✅ Native | ✅ Yes | ⚠️ Manual |
| Reactivity | Fine-grained | Store-based | Force updates |
| Framework Agnostic | ✅ | ❌ SvelteKit | ❌ React |
| Headless UI | ✅ | ⚠️ Some | ⚠️ Some |

## Integration with SvelteKit

### Server Actions

```svelte
<!-- +page.svelte -->
<script>
  import { createForm } from '@tanstack/svelte-form';
  import { enhance } from '$app/forms';

  const form = createForm(() => ({
    defaultValues: {
      email: '',
      password: '',
    },
    onSubmit: async ({ value }) => {
      // Use SvelteKit server actions
      const response = await enhance(
        { data: value },
        ({ result }) => {
          // Handle response
        }
      );
    },
  }));
</script>
```

### With Zod Validation

```typescript
import { z } from 'zod';
import { fail } from '@sveltejs/kit';

const UserSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

export const actions = {
  default: async ({ request }) => {
    const formData = await request.formData();
    const data = Object.fromEntries(formData);

    const result = UserSchema.safeParse(data);

    if (!result.success) {
      return fail(result.error.flatten());
    }

    // Process validated data
    return { success: true };
  },
};
```

## Examples

### Simple Form

```svelte
<script>
  import { createForm } from '@tanstack/svelte-form';
  import FieldInfo from './FieldInfo.svelte';

  const form = createForm(() => ({
    defaultValues: {
      firstName: '',
      lastName: '',
      employed: false,
      jobTitle: '',
    },
    onSubmit: async ({ value }) => {
      alert(JSON.stringify(value));
    },
  }));
</script>

<form onsubmit={(e) => { e.preventDefault(); e.stopPropagation(); form.handleSubmit(); }}>
  <form.Field
    name="firstName"
    validators={{
      onChange: ({ value }) =>
        value.length < 3 ? 'Not long enough' : undefined,
    }}
  >
    {#snippet children(field)}
      <label for={field.name}>First Name</label>
      <input
        id={field.name}
        value={field.state.value}
        onblur={field.handleBlur}
        oninput={(e) => field.handleChange(e.target.value)}
      />
      <FieldInfo {field} />
    {/snippet}
  </form.Field>
</form>
```

### Array Form

```svelte
<script>
  const form = createForm(() => ({
    defaultValues: {
      people: [] as Array<{ name: string; age: number }>,
    },
    onSubmit: ({ value }) => alert(JSON.stringify(value)),
  }));
</script>

<form.Field name="people" mode="array">
  {#snippet children(field)}
    {#each field.state.value as person, i}
      <form.Field name={`people[${i}].name`}>
        {#snippet children(subField)}
          <input
            value={subField.state.value}
            oninput={(e) => subField.handleChange(e.target.value)}
          />
        {/snippet}
      </form.Field>
      <button type="button" onclick={() => field.removeValue(i)}>
        Remove
      </button>
    {/each}
    <button type="button" onclick={() => field.pushValue({ name: '', age: 0 })}>
      Add Person
    </button>
  {/snippet}
</form.Field>
```

## References

- <https://tanstack.com/form/latest/docs/framework/svelte>
- <https://tanstack.com/form/latest/docs/framework/svelte/guides/basic-concepts>
- <https://tanstack.com/form/latest/docs/framework/svelte/guides/validation>
- <https://github.com/tanstack/form/tree/main/examples/svelte>

## Related

- [[zod-validation-library]]
- [[standard-schema-validation]]
- [[sveltekit-remote-functions]]
- [[sveltekit-form-actions]]
