---
title: Better Auth Plugins Guide
type: reference
domain: Development Tools
tags:
  - auth
  - better-auth
  - plugins
  - 2fa
  - passkey
  - organization
  - sso
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Better Auth Plugins Guide

## Overview

Plugins are a key part of Better Auth, allowing you to extend base functionalities with new authentication methods, features, or custom behaviors. Better Auth comes with many built-in plugins ready to use. <https://www.better-auth.com/docs/concepts/plugins>

**Key Plugin Capabilities:**
- Create custom endpoints
- Extend database tables with custom schemas
- Use middleware to target groups of routes
- Use hooks for specific routes or requests
- Create custom rate-limit rules
- Add client-side interfaces

## Using Plugins

### Server Plugins

Add plugins to the `plugins` array in your auth configuration:

```typescript
// lib/auth.ts
import { betterAuth } from "better-auth";
import { twoFactor } from "better-auth/plugins";
import { passkey } from "better-auth/plugins";

export const auth = betterAuth({
  plugins: [
    twoFactor(),
    passkey(),
  ],
});
```

### Client Plugins

Client plugins are added when creating the client:

```typescript
// lib/auth-client.ts
import { createAuthClient } from "better-auth/react";

export const authClient = createAuthClient({
  plugins: [
    // Add client plugins here
  ],
});
```

**Most plugins require both server and client plugins to work correctly.**

## Official Plugins

### Two Factor Authentication (2FA)

Secure user accounts with two-factor authentication using TOTP or backup codes.

```bash
npm install better-auth/plugins
```

**Server Setup:**

```typescript
import { twoFactor } from "better-auth/plugins";

export const auth = betterAuth({
  plugins: [
    twoFactor({
      // Optional: Customize TOTP settings
      totp: {
        issuer: "MyApp",
        algorithm: "SHA1",
        digits: 6,
        period: 30,
      },
    }),
  ],
});
```

**Client Setup:**

```typescript
import { createAuthClient } from "better-auth/react";
import { twoFactorClient } from "better-auth/plugins/client";

export const authClient = createAuthClient({
  plugins: [
    twoFactorClient(),
  ],
});
```

**Usage:**

```typescript
// Enable 2FA for user
await auth.twoFactor.enable();

// Verify TOTP code
await auth.twoFactor.verifyTotp({
  code: "123456",
});

// Generate backup codes
const { backupCodes } = await auth.twoFactor.generateBackupCodes();
```

### Passkey (WebAuthn)

Passwordless authentication using WebAuthn/FIDO2.

**Server Setup:**

```typescript
import { passkey } from "better-auth/plugins";

export const auth = betterAuth({
  plugins: [
    passkey({
      // Optional: Customize settings
      origin: "https://yourdomain.com",
      rpID: "yourdomain.com",
      timeout: 60000,
    }),
  ],
});
```

**Client Setup:**

```typescript
import { createAuthClient } from "better-auth/react";
import { passkeyClient } from "better-auth/plugins/client";

export const authClient = createAuthClient({
  plugins: [
    passkeyClient(),
  ],
});
```

### Username Authentication

Enable username-based authentication alongside email.

```typescript
import { username } from "better-auth/plugins";

export const auth = betterAuth({
  plugins: [
    username({
      // Optional: Username validation
      minUsernameLength: 3,
      maxUsernameLength: 20,
      allowUsernameChange: true,
    }),
  ],
});
```

### Magic Link

Passwordless authentication via email magic links.

```typescript
import { magicLink } from "better-auth/plugins";

export const auth = betterAuth({
  plugins: [
    magicLink({
      sendMagicLink: async ({ email, url }) => {
        // Send email with magic link
        await sendEmail(email, `Click here to sign in: ${url}`);
      },
      // Optional: Expire time
      expireIn: 600, // 10 minutes
    }),
  ],
});
```

### Organization & Team

Manage organizations, teams, and member roles.

```typescript
import { organization } from "better-auth/plugins";

export const auth = betterAuth({
  plugins: [
    organization({
      // Optional: Customize settings
      avatar: {
        enabled: true,
      },
      // Optional: Custom roles
      roles: {
        OWNER: "owner",
        ADMIN: "admin",
        MEMBER: "member",
        GUEST: "guest",
      },
    }),
  ],
});
```

**Usage:**

```typescript
// Create organization
const org = await auth.organization.create({
  name: "My Organization",
  slug: "my-org",
});

// Add member
await auth.organization.addMember({
  orgId: org.id,
  userId: user.id,
  role: "member",
});

// Update member role
await auth.organization.updateMemberRole({
  orgId: org.id,
  memberId: memberId,
  role: "admin",
});
```

### SSO (Single Sign-On)

Enterprise SSO with SAML and OIDC support.

```typescript
import { sso } from "better-auth/plugins";

export const auth = betterAuth({
  plugins: [
    sso({
      // Optional: Customize settings
      issuer: "https://your-idp.com",
      // SAML or OIDC configuration
    }),
  ],
});
```

### Email OTP

One-time password authentication via email.

```typescript
import { emailOTP } from "better-auth/plugins";

export const auth = betterAuth({
  plugins: [
    emailOTP({
      sendVerificationEmail: async ({ email, otp }) => {
        await sendEmail(email, `Your code is: ${otp}`);
      },
      // Optional: OTP length
      otpLength: 6,
      // Optional: Expiration
      expiresIn: 300, // 5 minutes
    }),
  ],
});
```

### API Key

API key authentication for programmatic access.

```typescript
import { apiKey } from "better-auth/plugins";

export const auth = betterAuth({
  plugins: [
    apiKey({
      // Optional: Customize key prefix
      keyPrefix: "sk_",
      // Optional: Key length
      keyLength: 32,
      // Optional: Rate limit per key
      rateLimit: {
        interval: 60, // seconds
        maxRequests: 100,
      },
    }),
  ],
});
```

### Stripe Integration

Simplify Stripe customer and subscription management.

```typescript
import { stripe } from "better-auth/plugins";

export const auth = betterAuth({
  plugins: [
    stripe({
      apiKey: process.env.STRIPE_SECRET_KEY,
      webhookSecret: process.env.STRIPE_WEBHOOK_SECRET,
      // Optional: Sync customer data
      syncCustomer: true,
      // Optional: Handle subscription changes
      onSubscriptionUpdate: async (subscription) => {
        // Update user access based on subscription
      },
    }),
  ],
});
```

### Admin Panel

Built-in admin panel for user and organization management.

```typescript
import { admin } from "better-auth/plugins";

export const auth = betterAuth({
  plugins: [
    admin({
      // Optional: Admin role check
      adminRole: "admin",
      // Optional: Default admin email
      defaultAdminEmail: "admin@yourdomain.com",
    }),
  ],
});
```

### Last Login Method

Track and store the last login method used by each user.

```typescript
import { lastLoginMethod } from "better-auth/plugins";

export const auth = betterAuth({
  plugins: [
    lastLoginMethod({
      // Optional: Database persistence
      database: true,
    }),
  ],
});
```

## Custom Plugins

### Server Plugin Structure

Create custom plugins by implementing the `BetterAuthPlugin` interface:

```typescript
import type { BetterAuthPlugin } from "better-auth";

export const myPlugin = (options?: {
  customOption?: string;
}) => {
  return {
    id: "my-plugin",
    // Optional: Database schema
    schema: {
      myTable: {
        fields: {
          name: {
            type: "string",
            required: true,
          },
        },
      },
    },
    // Optional: Custom endpoints
    endpoints: {
      getHelloWorld: createAuthEndpoint(
        "/my-plugin/hello-world",
        {
          method: "GET",
        },
        async (ctx) => {
          return ctx.json({
            message: "Hello World",
          });
        }
      ),
    },
    // Optional: Hooks
    hooks: {
      before: [
        {
          matcher: (context) => {
            return context.headers.get("x-my-header") === "my-value";
          },
          handler: createAuthMiddleware(async (ctx) => {
            // Run before matched requests
            return { context: ctx };
          }),
        },
      ],
    },
    // Optional: Middleware
    middlewares: [
      {
        path: "/my-plugin/*",
        middleware: createAuthMiddleware(async (ctx) => {
          // Run for matched paths
        }),
      },
    ],
    // Optional: Rate limiting
    rateLimit: [
      {
        pathMatcher: (path) => path === "/my-plugin/hello-world",
        limit: 10,
        window: 60,
      },
    ],
    // Optional: On request/response
    onRequest: async (request, context) => {
      // Modify any request
    },
    onResponse: async (response, context) => {
      // Modify any response
    },
  } satisfies BetterAuthPlugin;
};
```

### Client Plugin Structure

```typescript
import type { BetterAuthClientPlugin } from "better-auth/client";
import type { myPlugin } from "./plugin";

export const myPluginClient = () => {
  return {
    id: "my-plugin",
    // Infer server plugin endpoints
    $InferServerPlugin: {} as ReturnType<typeof myPlugin>,
    // Optional: Custom actions
    getActions: ($fetch) => {
      return {
        myCustomAction: async (data: { foo: string }) => {
          return $fetch("/custom/action", {
            method: "POST",
            body: { foo: data.foo },
          });
        },
      };
    },
    // Optional: State atoms
    getAtoms: ($fetch) => {
      const myAtom = atom<null>();
      return { myAtom };
    },
    // Optional: Override path methods
    pathMethods: {
      "/my-plugin/hello-world": "POST",
    },
  } satisfies BetterAuthClientPlugin;
};
```

## Plugin Development Best Practices

1. **Use kebab-case for endpoint paths:** `/my-plugin/hello-world` not `/myPlugin/helloWorld`
2. **Use POST for mutations, GET for queries:** Only use these methods for endpoints
3. **Prefix paths with plugin name:** Avoid conflicts with `/my-plugin/hello-world` instead of `/hello-world`
4. **Make plugins functions:** Return configuration from a function for consistency
5. **Provide both server and client plugins:** Most features need both sides
6. **Use `sessionMiddleware` for protected endpoints:** Ensures valid session
7. **Don't store sensitive data in user/session tables:** Create separate tables
8. **Test with database migrations:** Use `npx @better-auth/cli generate` to test schema

## Advanced Plugin Features

### Extending Core Tables

Add fields to core tables:

```typescript
export const myPlugin = () => {
  return {
    id: "my-plugin",
    schema: {
      user: {
        fields: {
          age: {
            type: "number",
          },
          bio: {
            type: "string",
          },
        },
      },
    },
  } satisfies BetterAuthPlugin;
};
```

**Fields automatically inferred** in `getSession` and `signUpEmail` responses.

### Trusted Origins in Plugins

Validate URLs against trusted origins:

```typescript
import { createAuthEndpoint, APIError } from "better-auth/api";

export const myPlugin = () => {
  return {
    id: "my-plugin",
    trustedOrigins: [
      "http://trusted.com",
    ],
    endpoints: {
      getTrustedHello: createAuthEndpoint(
        "/my-plugin/hello",
        {
          method: "GET",
          query: z.object({
            url: z.string(),
          }),
        },
        async (ctx) => {
          if (!ctx.context.isTrustedOrigin(ctx.query.url, {
            allowRelativePaths: false,
          })) {
            throw new APIError("FORBIDDEN", {
              message: "Origin is not trusted.",
            });
          }
          return ctx.json({ message: "Hello" });
        }
      ),
    },
  } satisfies BetterAuthPlugin;
};
```

### Session Middleware

Protect endpoints with session validation:

```typescript
import { createAuthMiddleware } from "better-auth/plugins";
import { sessionMiddleware } from "better-auth/api";

export const myPlugin = () => {
  return {
    id: "my-plugin",
    endpoints: {
      getProfile: createAuthEndpoint(
        "/my-plugin/profile",
        {
          method: "GET",
          use: [sessionMiddleware],
        },
        async (ctx) => {
          const session = ctx.context.session;
          return ctx.json({
            user: session.user,
          });
        }
      ),
    },
  } satisfies BetterAuthPlugin;
};
```

### Get Session from Context

Access session data in middleware/hooks:

```typescript
import { createAuthMiddleware } from "better-auth/plugins";
import { getSessionFromCtx } from "better-auth/api";

export const myPlugin = () => {
  return {
    id: "my-plugin",
    hooks: {
      before: [
        {
          matcher: (context) => context.path === "/protected",
          handler: createAuthMiddleware(async (ctx) => {
            const session = await getSessionFromCtx(ctx);
            if (!session) {
              throw new APIError("UNAUTHORIZED");
            }
            return { context: ctx };
          }),
        },
      ],
    },
  } satisfies BetterAuthPlugin;
};
```

## Plugin Examples

### Custom Auth Method

```typescript
export const smsAuth = () => {
  return {
    id: "sms-auth",
    schema: {
      smsVerification: {
        fields: {
          phoneNumber: {
            type: "string",
            required: true,
          },
          code: {
            type: "string",
          },
        },
      },
    },
    endpoints: {
      sendSmsCode: createAuthEndpoint(
        "/sms/send",
        {
          method: "POST",
          body: z.object({
            phoneNumber: z.string(),
          }),
        },
        async (ctx) => {
          const code = Math.floor(100000 + Math.random() * 900000);
          // Store code in database
          // Send SMS
          return ctx.json({ success: true });
        }
      ),
      verifySmsCode: createAuthEndpoint(
        "/sms/verify",
        {
          method: "POST",
          body: z.object({
            phoneNumber: z.string(),
            code: z.string(),
          }),
        },
        async (ctx) => {
          // Verify code
          // Create session
          return ctx.json({ success: true });
        }
      ),
    },
  } satisfies BetterAuthPlugin;
};
```

## References

- <https://www.better-auth.com/docs/concepts/plugins>
- <https://www.better-auth.com/docs/plugins>

## Related

- [[better-auth-installation]]
- [[better-auth-sveltekit-integration]]
- [[sveltekit-auth-best-practices]]
