---
title: Zod v4.3.6 - TypeScript Schema Validation
type: reference
domain: Development Tools
tags:
  - zod
  - validation
  - typescript
  - schema
  - type-safety
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Zod v4.3.6 - TypeScript Schema Validation

## Overview

Zod is a TypeScript-first validation library that lets you define schemas to validate data, from a simple `string` to complex nested objects. Zod v4 brings major performance improvements, smaller bundle sizes, and enhanced developer experience. <https://zod.dev>

**Key Features:**
- Zero external dependencies
- Tiny: 2kb core bundle (gzipped)
- Works in Node.js and all modern browsers
- Immutable API with concise interface
- Built-in JSON Schema conversion
- Extensive ecosystem integrations
- TypeScript 5.5+ required with strict mode

**Latest Version:** v4.3.6 (January 2025)

## Installation

```bash
npm install zod
```

Also available as `@zod/zod` on jsr.io.

**TypeScript Configuration:**

```json
// tsconfig.json
{
  "compilerOptions": {
    "strict": true
  }
}
```

## v4.3.6 Performance Improvements

Zod 4 delivers dramatic performance gains over v3:
- **2.6x faster** string parsing
- **3x faster** array parsing
- **7x faster** object parsing
- **Improved TypeScript compilation** performance
- **Smaller bundle sizes** with tree-shaking
- **New `@zod/mini`** package for minimal bundle size

## Basic Usage

### Defining Schemas

```typescript
import * as z from "zod";

// Simple string schema
const nameSchema = z.string();

// Object schema
const User = z.object({
  name: z.string(),
  age: z.number(),
  email: z.string().email(),
});

// Parse and validate
const input = { name: "John", age: 30, email: "john@example.com" };
const data = User.parse(input); // type-safe and validated
console.log(data.name); // TypeScript knows this is a string
```

### Handling Errors

```typescript
try {
  User.parse(invalidInput);
} catch (err) {
  if (err instanceof z.ZodError) {
    console.log(err.errors);
    // [
    //   { path: ["name"], code: "invalid_type", ... },
    //   { path: ["email"], code: "invalid_string", ... }
    // ]
  }
}

// Safe parsing (doesn't throw)
const result = User.safeParse(input);
if (result.success) {
  console.log(result.data);
} else {
  console.log(result.error.errors);
}
```

## Primitives

### String

```typescript
z.string() // Basic string
z.string().min(5) // Minimum length
z.string().max(10) // Maximum length
z.string().length(5) // Exact length
z.string().email() // Email validation
z.string().url() // URL validation
z.string().uuid() // UUID (RFC 9562/4122)
z.string().guid() // Permissive UUID-like
z.string().datetime() // ISO datetime
z.string().date() // ISO date (YYYY-MM-DD)
z.string().time() // ISO time (HH:MM:SS)
z.string().ip() // IP address (v4 or v6)
z.string().ipv4() // IPv4 only
z.string().ipv6() // IPv6 only
z.string().cidr() // CIDR notation (v4 or v6)
z.string().cidrv4() // CIDR v4 only
z.string().cidrv6() // CIDR v6 only
z.string().emoji() // Emoji
z.string().cuid() // CUID
z.string().cuid2() // CUID2
z.string().ulid() // ULID
z.string().base64() // Base64 encoded
z.string().base64url() // Base64URL encoded (no padding)
z.string().hex() // Hexadecimal
z.string().trim() // Trim whitespace
z.string().toLowerCase() // Convert to lowercase
z.string().toUpperCase() // Convert to uppercase
z.string().includes("search") // Contains substring
z.string().startsWith("prefix") // Starts with
z.string().endsWith("suffix") // Ends with
z.string().regex(/pattern/) // Custom regex
z.string().datetime({ offset: true }) // Allow timezone offset
z.string().datetime({ precision: 3 }) // Require millisecond precision
```

### Custom String Formats (NEW in v4)

```typescript
// Define reusable custom formats
const customFormat = z.stringFormat("custom", {
  validate: (val) => val.startsWith("PREFIX-"),
});

// Template literal schemas
const template = z.templateLiteral(
  z.literal("user:"),
  z.string(),
  z.literal("-admin")
);
// Validates "user:john-admin"
```

### Number

```typescript
z.number() // Any finite number
z.number().min(5) // Minimum value
z.number().max(10) // Maximum value
z.number().int() // Integer only (safe integers)
z.number().positive() // > 0
z.number().nonnegative() // >= 0
z.number().negative() // < 0
z.number().nonpositive() // <= 0
z.number().multipleOf(5) // Must be divisible by 5
z.number().finite() // Not Infinity/-Infinity
z.nan() // NaN only
```

**Important Changes in v4:**
- `z.number()` no longer accepts `POSITIVE_INFINITY` or `NEGATIVE_INFINITY`
- `.int()` only accepts safe integers (within `Number.MIN_SAFE_INTEGER` and `Number.MAX_SAFE_INTEGER`)
- Use `z.int()` instead of `z.number().int()`

### Boolean

```typescript
z.boolean(); // true or false
```

### New: String to Boolean (v4.3+)

```typescript
// Parse "boolish" strings to boolean
const stringBool = z.stringbool({
  truthy: ["yes", "on", "1"],
  falsy: ["no", "off", "0"],
});
// Case-insensitive by default

// Make case-sensitive
z.stringbool({
  truthy: ["YES", "TRUE"],
  falsy: ["NO", "FALSE"],
  caseSensitive: true,
});
```

### Date

```typescript
z.date(); // Date instance
z.date().min(new Date("2025-01-01")); // After date
z.date().max(new Date("2025-12-31")); // Before date
```

## Complex Types

### Object

```typescript
// Basic object
const person = z.object({
  name: z.string(),
  age: z.number(),
});

// Optional properties
const person = z.object({
  name: z.string(),
  age: z.number().optional(),
  email: z.string().optional(),
});

// Nullable properties
const person = z.object({
  name: z.string(),
  nickname: z.string().nullable(),
});

// Nullish (optional or nullable)
const person = z.object({
  name: z.string(),
  nickname: z.string().nullish(),
});

// Default values
const person = z.object({
  name: z.string(),
  age: z.number().default(18),
  active: z.boolean().default(true),
});

// Strict object (no unknown keys)
const strictPerson = z.strictObject({
  name: z.string(),
  age: z.number(),
});

// Loose object (allows unknown keys)
const loosePerson = z.looseObject({
  name: z.string(),
  age: z.number(),
});

// Catchall schema for unknown keys
const person = z.object({
  name: z.string(),
}).catchall(z.unknown());

// Extend object
const basePerson = z.object({ name: z.string() });
const extendedPerson = basePerson.extend({
  age: z.number(),
});

// Pick and omit
const person = z.object({
  name: z.string(),
  age: z.number(),
  email: z.string(),
});

const personNameOnly = person.pick({ name: true });
const personNoEmail = person.omit({ email: true });

// Partial (all fields optional)
const partialPerson = person.partial();

// Partial (some fields)
const partialPerson = person.partial({ name: true });

// Required (all fields required)
const requiredPerson = person.required();

// Required (some fields)
const requiredPerson = person.required({ email: true });
```

### Array

```typescript
z.array(z.string()); // Array of strings
z.array(z.string()).min(1); // At least one element
z.array(z.string()).max(10); // At most 10 elements
z.array(z.string()).length(5); // Exactly 5 elements
z.array(z.string()).nonempty(); // Same as .min(1)

// .nonempty() now returns same type as .min(1)
```

### Tuple

```typescript
z.tuple([z.string(), z.number()]); // [string, number]
z.tuple([z.string(), z.number()]); // Fixed length array

// Variadic (rest) arguments
z.tuple([z.string(), z.number()]).rest(z.boolean());
// [string, number, ...boolean[]]
```

### Union

```typescript
z.union([z.string(), z.number()]); // string | number
z.discriminatedUnion("status", [
  z.object({ status: z.literal("active"), data: z.string() }),
  z.object({ status: z.literal("inactive"), reason: z.string() }),
]);

// XOR (exclusive OR) - exactly one must match
z.xor([z.string(), z.number()]); // One or the other, not both
```

### Intersection

```typescript
z.intersection(
  z.object({ name: z.string() }),
  z.object({ age: z.number() })
);
// { name: string } & { age: number }
```

**Note:** Prefer `.extend()` over `z.intersection()` for objects.

### Record

```typescript
z.record(z.string(), z.number()); // Record<string, number>
z.record(z.enum(["a", "b"]), z.number()); // Keys must be "a" or "b"

// Partial record (enum keys not required)
z.partialRecord(z.enum(["a", "b"]), z.number());

// Loose record (passes through non-matching keys)
z.looseRecord(z.string(), z.number());

// Numeric keys (v4.2+)
const numericRecord = z.record(
  z.number().int().min(1).max(100),
  z.string()
);
```

### Set

```typescript
z.set(z.string()); // Set<string>
z.set(z.string()).size(5); // Exactly 5 elements
z.set(z.string()).min(1); // At least 1 element
z.set(z.string()).max(10); // At most 10 elements
```

### Map

```typescript
z.map(z.string(), z.number()); // Map<string, number>
```

### Enum

```typescript
// String enum
const statusEnum = z.enum(["active", "inactive", "pending"]);

// Get values as object
statusEnum.enum; // { active: "active", inactive: "inactive", pending: "pending" }

// Native TypeScript enum (NEW in v4)
enum NativeStatus {
  Active = "active",
  Inactive = "inactive",
}
const nativeEnum = z.enum(NativeStatus);

// Enum from object literal
const roleEnum = z.enum({
  ADMIN: "admin",
  USER: "user",
});

// Extract values
roleEnum.enum; // { ADMIN: "admin", USER: "user" }

// Exclude values
const activeStatus = statusEnum.exclude(["inactive"]);

// Extract values
const simpleStatus = statusEnum.extract(["active", "pending"]);
```

## Literals

```typescript
z.literal("hello"); // "hello"
z.literal(42); // 42
z.literal(true); // true
z.literal(null); // null
z.undefined(); // undefined

// Multiple literal values
z.union([z.literal("a"), z.literal("b"), z.literal("c")]);
```

## Optional, Nullable, Nullish

```typescript
z.string().optional(); // string | undefined
z.string().nullable(); // string | null
z.string().nullish(); // string | null | undefined
```

## Default Values

```typescript
// Default (short-circuits parsing)
z.string().default("default value");
z.number().default(() => Math.random()); // Function for dynamic defaults

// Prefault (NEW in v4 - "pre-parse default")
// Applies to input type, doesn't short-circuit
z.string().prefault("default value");
z.number().min(0).prefault(0); // Still validates min constraint
```

## Transformations

### Basic Transform

```typescript
const stringToNumber = z.string()
  .transform((val) => parseInt(val, 10));

const result = stringToNumber.parse("123"); // 123 (number)
```

### Pipe Transformations

```typescript
// Chain multiple transformations
const emailSchema = z.string()
  .transform((val) => val.toLowerCase().trim())
  .pipe(z.string().email());
```

### Async Transform

```typescript
const asyncSchema = z.string()
  .transform(async (val) => {
    return await fetchUserData(val);
  });

// Must use .parseAsync()
const result = await asyncSchema.parseAsync("userId");
```

## Refinements (Custom Validation)

```typescript
// Basic refinement
const positiveNumber = z.number()
  .refine((val) => val > 0, "Must be positive");

// With error object
const positiveNumber = z.number()
  .refine(
    (val) => val > 0,
    { message: "Must be positive", path: ["number"] }
  );

// Abort on failure (stop validation)
const passwordSchema = z.string()
  .refine(
    (val) => val.length >= 8,
    { message: "Too short", abort: true } // Stops if this fails
  )
  .refine((val) => /[A-Z]/.test(val));

// Async refinement
const uniqueEmail = z.string()
  .refine(
    async (email) => {
      return !(await emailExists(email));
    },
    "Email already exists"
  );

// Super refine (multiple issues)
const passwordSchema = z.string().superRefine((val, ctx) => {
  if (val.length < 8) {
    ctx.addIssue({
      code: z.ZodIssueCode.too_small,
      minimum: 8,
      type: "string",
      inclusive: true,
    });
  }
  if (!/[A-Z]/.test(val)) {
    ctx.addIssue({
      code: z.ZodIssueCode.custom,
      message: "Must contain uppercase letter",
    });
  }
});
```

### Conditional Refinement (WHEN)

```typescript
// Control when refinement runs
const passwordConfirmSchema = z.object({
  password: z.string(),
  confirmPassword: z.string(),
}).refine(
  (data) => data.password === data.confirmPassword,
  {
    message: "Passwords don't match",
    // Only run when password field is valid
    when: (data, ctx) => {
      const passwordStatus = ctx.common.issueCache?.get(
        ["password", "password"].join(".")
      );
      return !passwordStatus; // Only run if password has no errors
    },
  }
);
```

## Coercion

```typescript
// Coerce input to appropriate type
const coercedNumber = z.coerce.number();
coercedNumber.parse("123"); // 123 (number)

const coercedDate = z.coerce.date();
coercedDate.parse("2025-01-29"); // Date object

const coercedBoolean = z.coerce.boolean();
coercedBoolean.parse("true"); // true

// Coerce with specific input type
const stringOrNumberToNumber = z.coerce.number<string>();
// Accepts string, outputs number
```

## Branding (Nominal Types)

```typescript
// Branded type (opaque type)
const brandedEmail = z.string()
  .email()
  .brand("Email");

type Email = z.infer<typeof brandedEmail>;
// This type is branded - can't assign plain string

// Brand both input and output
const brandedInputOutput = z.string()
  .brand("MyBrand", "input" | "output");
```

## Readonly

```typescript
const readonlySchema = z.object({
  name: z.string(),
}).readonly();

// Result is frozen with Object.freeze()
const result = readonlySchema.parse({ name: "John" });
result.name = "Jane"; // Error in strict mode
```

## Error Handling (v4 Changes)

### New Error Parameter

```typescript
// Unified error customization
const schema = z.string({
  error: "Invalid input", // Simple string
});

const schema = z.string({
  error: (ctx) => ({
    message: `Invalid at ${ctx.path.join(".")}`,
  }),
});

// Error map precedence changed
// Schema-level error map now takes precedence
const schema = z.string({
  error: "Schema error",
});

const result = schema.safeParse(123, {
  error: "Parse-level error", // No longer takes precedence
});
```

### Treeify Error (New in v4)

```typescript
import { treeifyError } from "zod";

try {
  schema.parse(data);
} catch (err) {
  if (err instanceof z.ZodError) {
    // New tree format
    const tree = treeifyError(err);
    console.log(tree);
    // {
    //   field: {
    //     subfield: {
    //       _errors: ["error message"]
    //     }
    //   }
    // }
  }
}
```

### Deprecated APIs

```typescript
// Deprecated - use treeifyError instead
error.format();
error.flatten();
error.formErrors; // Removed
error.addIssue(); // Deprecated - push to err.issues directly
```

## Codecs (NEW in v4.1+)

Bidirectional transformations between schemas:

```typescript
import { z } from "zod";

// String to number codec
const stringToNumber = z.codec(
  z.string(),
  z.number(),
  (str) => parseInt(str, 10),
  (num) => String(num)
);

// Forward transform (decode)
const num = stringToNumber.parse("123"); // 123
z.decode(stringToNumber, "123"); // 123

// Reverse transform (encode)
const str = z.encode(stringToNumber, 123); // "123"
```

**Built-in Codecs:**
- `stringToNumber`
- `stringToInt`
- `stringToBigInt`
- `numberToBigInt`
- `isoDatetimeToDate`
- `epochSecondsToDate`
- `epochMillisToDate`
- `jsonCodec`
- `utf8ToBytes`
- `base64ToBytes`
- `base64urlToBytes`
- `hexToBytes`
- `stringToURL`
- `stringToHttpURL`
- `uriComponent`
- `stringToBoolean`

## Function Validation

```typescript
// Define function schema
const myFunction = z.function()
  .input(z.string())
  .output(z.number());

// Implement function
const validatedFunc = myFunction.implement((input) => {
  // input is typed as string
  return input.length; // returns number
});

// Async function
const asyncFunc = z.function()
  .input(z.string())
  .output(z.boolean())
  .implementAsync(async (input) => {
    return await validateUser(input);
  });
```

## Catch

```typescript
const schema = z.string().catch("default value");

const result = schema.parse(123); // "default value"
const result = schema.parse("hello"); // "hello"

// With function
const schema = z.number().catch(() => 0);
```

## Custom Validation

```typescript
// Custom schema for any type
const customSchema = z.custom<string>((val) => {
  if (typeof val === "string" && val.startsWith("custom-")) {
    return val;
  }
  throw new z.ZodError([]);
});

// With error options
const customSchema = z.custom((val) => {
  // validation logic
}, {
  errorMap: () => ({ message: "Custom error" }),
});

// Apply external functions
const schema = z.string().apply(externalValidator);
```

## Recursive Types

```typescript
// Self-referential type
const category = z.object({
  name: z.string(),
  subcategories: z.lazy(() => z.array(category)),
});

// Mutually recursive
const typeA = z.object({
  value: z.string(),
  b: z.lazy(() => typeB),
});

const typeB = z.object({
  value: z.number(),
  a: z.lazy(() => typeA),
});

// Fix circular errors with type annotation
const category: z.ZodType<{
  name: string;
  subcategories: Array<typeof category>;
}> = z.object({
  name: z.string(),
  subcategories: z.lazy(() => z.array(category)),
});
```

## Inference

```typescript
const schema = z.object({
  name: z.string(),
  age: z.number(),
});

// Infer output type
type User = z.infer<typeof schema>;
// { name: string; age: number; }

// Infer input type
type UserInput = z.input<typeof schema>;
// { name: string; age: number; }
// (same for basic schemas, differs with transformations)

// Infer output type
type UserOutput = z.output<typeof schema>;
// { name: string; age: number; }
```

## Utility Methods

### Schema Methods

```typescript
// Optional
const optionalSchema = z.string().optional();
optionalSchema.unwrap(); // Returns z.string()

// Nullable
const nullableSchema = z.string().nullable();
nullableSchema.unwrap(); // Returns z.string()

// Describe
const describedSchema = z.string().describe("User's name");

// Safe parsing with type guard
const result = schema.safeParse(data);
if (result.success) {
  console.log(result.data); // typed as inferred type
} else {
  console.log(result.error); // ZodError
}
```

## Migration from v3 to v4

### Key Breaking Changes

1. **Error Customization**
   - `message` → `error` (deprecated)
   - `invalid_type_error` / `required_error` → removed
   - `errorMap` → `error`

2. **String Formats**
   - `z.string().email()` → `z.email()` (method deprecated)
   - `z.string().uuid()` → `z.uuid()` (method deprecated)
   - Use top-level APIs instead

3. **Object Methods**
   - `.strict()` → `z.strictObject()`
   - `.passthrough()` → `z.looseObject()`
   - `.merge()` → `.extend()` (deprecated)

4. **Other**
   - `.deepPartial()` removed
   - `z.nativeEnum()` → `z.enum()` (deprecated)
   - `z.promise()` deprecated
   - `ctx.path` removed (performance improvement)

### New Features in v4

- **Codecs** for bidirectional transforms
- **`.prefault()`** for pre-parse defaults
- **`z.stringbool()`** for parsing boolean strings
- **`z.interface()`** for intersection types
- **Template literal schemas**
- **Custom string formats**
- **Better performance** (up to 7x faster)

## Integrations

Zod integrates with many frameworks and libraries:

**Forms:**
- React Hook Form (Zod resolver)
- Conform (SvelteKit forms)
- FormKit (Vue)
- Zod-powered form libraries

**APIs:**
- tRPC (end-to-end typesafe APIs)
- OpenAPI (Zod to OpenAPI schema)
- Hono (Zod validation middleware)

**Utilities:**
- zod-openapi (OpenAPI 3.1 spec from Zod)
- zod-to-ts (Generate TypeScript types from Zod)
- zod-mock (Generate mock data from Zod schemas)
- zod-to-json-schema (Convert Zod to JSON Schema)

## Best Practices

1. **Use strict mode** in TypeScript
2. **Prefer `.safeParse()`** to avoid try/catch
3. **Use top-level format APIs** (`z.email()`, `z.uuid()`, etc.)
4. **Leverage refinements** for custom validation
5. **Use branded types** for opaque types
6. **Prefer `.extend()`** over `.merge()` for objects
7. **Use `z.codecs`** for bidirectional transforms
8. **Use `z.treeifyError()`** instead of deprecated `.format()`
9. **Take advantage of performance gains** in v4
10. **Use `@zod/mini`** for smaller bundles

## References

- <https://zod.dev>
- <https://zod.dev/v4>
- <https://zod.dev/api>
- <https://github.com/colinhacks/zod>

## Related

- [[standard-schema-validation]]
- [[sveltekit-remote-functions]]
- [[better-auth-plugins]]
