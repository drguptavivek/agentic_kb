---
title: Svelte Security Advisories (CVE-2025)
type: security
domain: Development Tools
tags:
  - svelte
  - sveltekit
  - security
  - cve
  - vulnerabilities
  - patches
  - devalue
  - hydratable
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Svelte Security Advisories (January 2026)

## Overview

**Critical Security Update Required** - The Svelte team has released patches for **5 vulnerabilities** across `devalue`, `svelte`, `@sveltejs/kit`, and `@sveltejs/adapter-node`. These vulnerabilities primarily affect applications using remote functions, prerendering, or the `hydratable` feature. <https://svelte.dev/blog/cves-affecting-the-svelte-ecosystem>

**Published:** January 15, 2026

## Quick Patch Commands

```bash
npm update devalue@5.6.2 svelte@5.46.4 @sveltejs/kit@2.49.5 @sveltejs/adapter-node@5.5.1
```

**Note:** Cross-dependencies are already updated in the patched versions. For example, `svelte` and `@sveltejs/kit` depend on `devalue`, and their patched versions include the upgraded dependency.

## Vulnerabilities Summary

| CVE | Package | Severity | Affected Versions | Patched Version | Type |
|-----|--------|----------|-------------------|----------------|------|
| CVE-2026-22775 | devalue | High | 5.1.0 - 5.6.1 | 5.6.2 | DoS (Memory/CPU) |
| CVE-2026-22774 | devalue | High | 5.3.0 - 5.6.1 | 5.6.2 | DoS (Memory) |
| CVE-2026-22803 | @sveltejs/kit | High | 2.49.0 - 2.49.4 | 2.49.5 | DoS (Remote Functions) |
| CVE-2025-67647 | @sveltejs/kit, @sveltejs/adapter-node | High | 2.19.0 - 2.49.4 | 2.49.5 / 5.5.1 | DoS, SSRF |
| CVE-2025-15265 | svelte | Medium | 5.46.0 - 5.46.3 | 5.46.4 | XSS (hydratable) |

## Detailed Vulnerability Information

### CVE-2026-22775: DoS in devalue.parse (Memory/CPU Exhaustion)

**Packages Affected:**
- `devalue` (direct dependency or transitive)

**Affected Versions:** 5.1.0 through 5.6.1

**Patched Version:** 5.6.2

**You're affected if:**
- Using `devalue` versions 5.1.0 - 5.6.1
- Parsing user-controlled input

**Impact:**
- A malicious payload can cause arbitrarily large memory allocation
- Can crash the process due to memory exhaustion
- CPU exhaustion from parsing complexity

**How it affects SvelteKit:**
- SvelteKit applications using **remote functions** are vulnerable
- Remote function parameters are run through `devalue.parse`
- Attackers can send malicious payloads that crash the server

**Example Attack Vector:**
```javascript
// Malicious payload that causes massive memory allocation
// SvelteKit remote functions would parse this via devalue
const maliciousPayload = { /* deeply nested object */ };
```

### CVE-2026-22774: DoS in devalue.parse (Memory Exhaustion)

**Packages Affected:**
- `devalue`

**Affected Versions:** 5.3.0 through 5.6.1

**Patched Version:** 5.6.2

**You're affected if:**
- Using `devalue` versions 5.3.0 - 5.6.1
- Parsing user-controlled input

**Impact:**
- A malicious payload can cause arbitrarily large memory allocation
- Can crash the process due to memory exhaustion
- Similar to CVE-2026-22775 but via different code path

**How it affects SvelteKit:**
- Same as CVE-2026-22775 - affects SvelteKit remote functions
- Attackers can send crafted JSON that causes memory exhaustion during parsing

### CVE-2026-22803: Memory Amplification DoS in Remote Functions

**Packages Affected:**
- `@sveltejs/kit`

**Affected Versions:** 2.49.0 through 2.49.4

**Patched Version:** 2.49.5

**You're affected if:**
- Using SvelteKit versions 2.49.0 - 2.49.4
- Have `experimental.remoteFunctions` enabled
- Using `form` remote functions

**Impact:**
- Users can submit malicious requests that cause:
  - Application to hang (becomes unresponsive)
  - Arbitrarily large memory allocation
  - Potential server crash

**Attack Vector:**
```javascript
// Form field with malicious value
await form.submit({
  maliciousField: /* crafted to cause memory amplification */
});
```

### CVE-2025-67647: DoS and SSRF when Using Prerendering

**Packages Affected:**
- `@sveltejs/kit`
- `@sveltejs/adapter-node`

**Affected Versions:**
- `@sveltejs/kit`: 2.44.0 - 2.49.4
- `@sveltejs/adapter-node`: various versions

**Patched Versions:**
- `@sveltejs/kit`: 2.49.5
- `@sveltejs/adapter-node`: 5.5.1

**DoS Vulnerability (2.44.0 - 2.49.4):**
- Any app with at least one prerendered route
- Server process can be crashed
- Impact: Complete denial of service

**SSRF + SXSS Vulnerability (2.19.0 - 2.49.4):**
- Apps with prerendered routes
- Using `@sveltejs/adapter-node` **without** `ORIGIN` environment variable
- Not using a reverse proxy with Host header validation

**SSRF Impact:**
- Can access internal resources without authentication
- SvelteKit server runtime can be reached from external sources
- Cache poisoning attacks possible

**SXSS Impact:**
- Potential for Stored XSS via cache poisoning
- Attacker can specify cache-control headers
- Can affect other users visiting the poisoned cache

**Attack Vector for SSRF:**
```javascript
// Malicious request with Host header pointing to internal service
fetch('https://your-app.com/prerendered-page', {
  headers: {
    'Host': 'internal-service.local'
  }
});
```

**Mitigation for SSRF:**

1. **Set ORIGIN environment variable:**
```bash
ORIGIN=https://your-domain.com
```

2. **Use reverse proxy with Host validation:**
```nginx
server {
    server_name your-domain.com;

    # Validate Host header
    if ($host != $server_name) {
        return 403;
    }

    location / {
        proxy_pass http://your-sveltekit-app;
    }
}
```

### CVE-2025-15265: XSS via hydratable

**Packages Affected:**
- `svelte`

**Affected Versions:** 5.46.0 - 5.46.3

**Patched Version:** 5.46.4

**You're vulnerable if:**
- Using `svelte` versions 5.46.0 - 5.46.3
- Using `hydratable` feature
- Passing unsanitized, user-controlled strings as keys
- Returning the hydratable result to another user

**Impact:**
- Cross-site scripting (XSS) vulnerability
- Attackers can inject malicious JavaScript through controlled keys
- Users visiting the same page can be attacked

**Vulnerable Code Pattern:**
```svelte
<script>
  import { hydratable } from 'svelte';

  // ❌ VULNERABLE - User input as key
  const userId = /* from URL parameter */;
  const user = await hydratable(userId, () => getUser(userId));
</script>
```

**Secure Code Pattern:**
```svelte
<script>
  import { hydratable } from 'svelte';

  // ✅ SECURE - Static, library-prefixed key
  const user = await hydratable('mylib:user:v1', () => getUser(userId));
</script>
```

**Best Practices:**
1. **Never use user input as `hydratable` keys** - use static strings
2. **Prefix your keys** with library/app name
3. **Version your keys** when data structure changes
4. **Validate/sanitize** all data before serialization
5. **Keep keys simple** - alphanumeric and hyphens only

**See:** [[svelte-hydratable]] for detailed documentation on secure `hydratable` usage.

## Affected Features by CVE

| Feature | CVE | Severity | Actions Required |
|---------|-----|----------|------------------|
| **Remote Functions** | CVE-2026-22803, CVE-2026-22775, CVE-2026-22774 | Upgrade, patch ASAP |
| **Prerendering** | CVE-2025-67647 | Set ORIGIN env var, use reverse proxy |
| **Hydratable** | CVE-2025-15265 | Never use user input as keys, upgrade Svelte |

## Patching Strategy

### Immediate Actions Required

1. **Update all affected packages:**
   ```bash
   npm update devalue svelte @sveltejs/kit @sveltejs/adapter-node
   ```

2. **Verify versions:**
   ```bash
   npm list devalue svelte @sveltejs/kit @sveltejs/adapter-node
   ```

3. **Restart your application** to load patched versions

4. **If you cannot update immediately:**
   - Disable remote functions temporarily
   - Disable prerendering temporarily
   - Set `ORIGIN` environment variable for adapter-node

### Dependency Tree Considerations

Since `svelte` and `@sveltejs/kit` depend on `devalue`, the patched versions include the upgraded dependency. You don't need to update `devalue` separately if you update these packages - but doing so is harmless and safe.

## Additional Resources

- [Svelte CVE Blog Post](https://svelte.dev/blog/cves-affecting-the-svelte-ecosystem)
- [Svelte Security Reporting](https://svelte.dev/docs/security) - Report vulnerabilities privately
- [devalue Repository](https://github.com/developit/devalue)
- [SvelteKit Repository](https://github.com/sveltejs/kit)

## Prevention for Future Vulnerabilities

1. **Keep dependencies updated** - Enable automated security updates
2. **Subscribe to security advisories** - Follow Svelte/SvelteKit announcements
3. **Review security advisories** - Check for new CVEs regularly
4. **Use CSP headers** - Implement Content Security Policy
5. **Validate all user input** - Especially for keys in `hydratable`
6. **Test for vulnerabilities** - Use security scanners and SAST tools
7. **Monitor for unusual activity** - Set up logging and alerting

## Related

- [[svelte-hydratable]]
- [[sveltekit-remote-functions]]
- [[sveltekit-fullstack-features]]
