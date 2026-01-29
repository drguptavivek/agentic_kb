---
title: Standard Schema - Universal Validation Interface
type: reference
domain: Development Tools
tags:
  - validation
  - typescript
  - schema
  - zod
  - valibot
  - arktype
  - standard-schema
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Standard Schema - Universal Validation Interface

## Overview

Standard Schema is a common interface specification designed by the creators of Zod, Valibot, and ArkType. It allows ecosystem tools to accept user-defined type validators without needing custom adapters for each library. The specification consists of a single TypeScript interface `StandardSchemaV1` that validation libraries implement. <https://standardschema.dev>

**Key benefits:**
- **Integrate once, validate anywhere** - Tools that accept Standard Schema work with any compliant library
- **No runtime dependencies** - The specification is types-only; you can copy/paste it directly
- **Zero breaking changes** - Guaranteed stability within major versions
- **Framework agnostic** - Works with any TypeScript/JavaScript project

## The Interface

The complete `StandardSchemaV1` interface (available at `@standard-schema/spec` on npm and JSR):

```typescript
/** The Standard Schema interface. */
export interface StandardSchemaV1<Input = unknown, Output = Input> {
  /** The Standard Schema properties. */
  readonly '~standard': StandardSchemaV1.Props<Input, Output>;
}

export declare namespace StandardSchemaV1 {
  /** The Standard Schema properties interface. */
  export interface Props<Input = unknown, Output = Input> {
    /** The version number of the standard. */
    readonly version: 1;
    /** The vendor name of the schema library. */
    readonly vendor: string;
    /** Validates unknown input values. */
    readonly validate: (
      value: unknown
    ) => Result<Output> | Promise<Result<Output>>;
    /** Inferred types associated with the schema. */
    readonly types?: Types<Input, Output> | undefined;
  }

  /** The result interface of the validate function. */
  export type Result<Output> = SuccessResult<Output> | FailureResult;

  /** The result interface if validation succeeds. */
  export interface SuccessResult<Output> {
    /** The typed output value. */
    readonly value: Output;
    /** The non-existent issues. */
    readonly issues?: undefined;
  }

  /** The result interface if validation fails. */
  export interface FailureResult {
    /** The issues of failed validation. */
    readonly issues: ReadonlyArray<Issue>;
  }

  /** The issue interface of the failure output. */
  export interface Issue {
    /** The error message of the issue. */
    readonly message: string;
    /** The path of the issue, if any. */
    readonly path?: ReadonlyArray<PropertyKey | PathSegment> | undefined;
  }

  /** The path segment interface of the issue. */
  export interface PathSegment {
    /** The key representing a path segment. */
    readonly key: PropertyKey;
  }

  /** The Standard Schema types interface. */
  export interface Types<Input = unknown, Output = Input> {
    /** The input type of the schema. */
    readonly input: Input;
    /** The output type of the schema. */
    readonly output: Output;
  }

  /** Infers the input type of a Standard Schema. */
  export type InferInput<Schema extends StandardSchemaV1> = NonNullable<
    Schema['~standard']['types']
  >['input'];

  /** Infers the output type of a Standard Schema. */
  export type InferOutput<Schema extends StandardSchemaV1> = NonNullable<
    Schema['~standard']['types']
  >['output'];
}
```

## Compatible Libraries

These libraries implement the Standard Schema interface:

| Library | Version | Notes |
|---------|---------|-------|
| **Zod** | 3.24.0+ | Most popular, TypeScript-first, feature-rich |
| **Valibot** | v1.0+ | Modular, smaller bundle size, tree-shakeable |
| **ArkType** | v2.0+ | Type-level validation, powerful inference |
| Effect Schema | v3.13.0+ | Via adapter |
| yup | v1.7.0+ | Classic validation library |
| joi | v18.0.0+ | Popular in Node.js ecosystem |
| typia | v9.2.0+ | High-performance validation |

And 20+ more libraries including Arri Schema, Formgator, decoders, Sury, and more. <https://standardschema.dev>

### Choosing a Library

**Choose Zod if:**
- You want the most mature, feature-rich library
- You're already familiar with it
- Extensive validation methods and error customization

**Choose Valibot if:**
- Bundle size is critical (10x smaller than Zod)
- You want modular, tree-shakeable validation
- You prefer a more modern API design

**Choose ArkType if:**
- You need powerful type-level inference
- You want inference that matches TypeScript's behavior exactly

## Using Standard Schema

### Installation (Optional)

You don't need to install `@standard-schema/spec` - you can copy/paste the types. But if you prefer a dependency:

```bash
npm install @standard-schema/spec       # npm
yarn add @standard-schema/spec          # yarn
pnpm add @standard-schema/spec          # pnpm
bun add @standard-schema/spec           # bun
deno add jsr:@standard-schema/spec      # deno
```

**Important:** Install as a regular dependency, NOT a dev dependency. The Standard Schema interface becomes part of your library's public API.

### Generic Validation Function

Here's a simple example of accepting any spec-compliant validator:

```typescript
import type {StandardSchemaV1} from '@standard-schema/spec';

export async function standardValidate<T extends StandardSchemaV1>(
  schema: T,
  input: StandardSchemaV1.InferInput<T>
): Promise<StandardSchemaV1.InferOutput<T>> {
  let result = schema['~standard'].validate(input);
  if (result instanceof Promise) result = await result;

  // if the `issues` field exists, the validation failed
  if (result.issues) {
    throw new Error(JSON.stringify(result.issues, null, 2));
  }

  return result.value;
}
```

This works with any spec-compliant library:

```typescript
import * as z from 'zod';
import * as v from 'valibot';
import {type} from 'arktype';

const zodResult = await standardValidate(z.string(), 'hello');
const valibotResult = await standardValidate(v.string(), 'hello');
const arktypeResult = await standardValidate(type('string'), 'hello');
```

## Integration Examples

### SvelteKit Remote Functions

SvelteKit uses Standard Schema for validating remote function arguments:

```typescript
import { query } from '$app/server';
import * as z from 'zod';

const Params = z.object({
  slug: z.string()
});

export const getPost = query(Params, async ({ slug }) => {
  // slug is typed as string
  return await db.posts.findUnique({ where: { slug } });
});
```

Works equally well with Valibot:

```typescript
import * as v from 'valibot';

const Params = v.object({
  slug: v.string()
});

export const getPost = query(Params, async ({ slug }) => {
  // Same implementation, different library
});
```

### Implementing Standard Schema in Your Library

If you're building a library that accepts schemas, implement the spec:

```typescript
import type {StandardSchemaV1} from '@standard-schema/spec';

interface StringSchema extends StandardSchemaV1<string> {
  type: 'string';
  message: string;
}

function string(message: string = 'Invalid type'): StringSchema {
  return {
    type: 'string',
    message,
    '~standard': {
      version: 1,
      vendor: 'my-validator',
      validate(value) {
        return typeof value === 'string' ? {value} : {issues: [{message}]};
      },
    },
  };
}
```

## Tools That Accept Standard Schema

These frameworks and libraries accept Standard Schema for validation:

| Tool | Use Case |
|------|----------|
| **SvelteKit** | Remote function validation |
| **tRPC** | End-to-end typesafe APIs |
| **TanStack Form** | Form state management |
| **TanStack Router** | Search param validation |
| **Hono** | Server middleware |
| **UploadThing** | File upload validation |
| **React Hook Form** | React form validation |
| **Conformal** | Framework-agnostic FormData parsing |
| **next-safe-action** | Next.js Server Actions |
| **Better-fetch** | Fetch with schema validation |

And 40+ more tools. <https://standardschema.dev>

## Design Decisions

### Why `~standard` prefix?

The `~` prefix serves two purposes:
1. **Avoids conflicts** - Tucked inside a single property, avoiding naming conflicts
2. **De-prioritizes in autocomplete** - The `~` character sorts after `A-Za-z0-9`, so VS Code shows these suggestions at the bottom of the list

### Why not use Symbol keys?

TypeScript symbols either:
- Collapse to simple `symbol` type (inline symbols), causing conflicts
- Sort alphabetically in autocomplete (unique symbols), not at the bottom

Tilde-prefixed string keys provide the best developer experience.

### Synchronous vs Async Validation

The `~standard.validate()` function might return a synchronous value OR a Promise. Libraries are encouraged to prefer synchronous validation when possible. If you only accept synchronous validation, check for Promise and throw:

```typescript
function validateInput(schema: StandardSchemaV1, data: unknown) {
  const result = schema['~standard'].validate(data);
  if (result instanceof Promise) {
    throw new TypeError('Schema validation must be synchronous');
  }
  // ...
}
```

## FAQ

### Do I need to add `@standard-schema/spec` as a dependency?

No. You can copy/paste the types directly. The spec guarantees no breaking changes without a major version bump. If you don't mind the dependency, you can install it and consume with `import type`.

### Can I add it as a dev dependency?

**No.** Despite being types-only, the Standard Schema interface becomes part of your library's public API. It must be available in production installs.

### How do I switch between Zod and Valibot?

Since both implement the same spec, you can swap them without changing your integration code:

```typescript
// Before: using Zod
import * as z from 'zod';
const schema = z.object({ name: z.string() });

// After: using Valibot
import * as v from 'valibot';
const schema = v.object({ name: v.string() });

// The rest of your code doesn't change!
```

## Migration from Direct Zod Usage

If you have existing code that uses Zod directly, migrating to Standard Schema is straightforward:

**Before (Zod-specific):**
```typescript
import * as z from 'zod';
import { myZodAwareFunction } from './my-lib';

const schema = z.object({ name: z.string() });
myZodAwareFunction(schema);
```

**After (Standard Schema):**
```typescript
import type { StandardSchemaV1 } from '@standard-schema/spec';
import { myUniversalFunction } from './my-lib';

// Works with Zod, Valibot, ArkType, etc.
const schema = z.object({ name: z.string() });
myUniversalFunction(schema);
```

## References

- <https://standardschema.dev>
- <https://github.com/standard-schema/standard-schema>
- Zod implementation: <https://github.com/colinhacks/zod>
- Valibot implementation: <https://valibot.dev>
- ArkType implementation: <https://arktype.io>

## Related

- [[sveltekit-remote-functions]]
- [[sveltekit-form-actions]]
