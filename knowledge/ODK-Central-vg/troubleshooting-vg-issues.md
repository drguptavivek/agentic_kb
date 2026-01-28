---
title: Troubleshooting VG Customization Issues
type: reference
domain: ODK-Central-vg
tags:
  - odk-central
  - vg-fork
  - troubleshooting
  - bugs
  - fixes
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Troubleshooting VG Customization Issues

This document captures issues encountered during VG fork development and their solutions, derived from git commit history and test failures.

## Database Issues

### Issue: Duplicate App-User Rows (DataIntegrityError)

**Commit**: `fde3708a` - "fix: avoid duplicate app-user rows and harden auth"

**Symptom**:
- `DataIntegrityError` when using `maybeOne()` lookups on `vg_field_key_auth`
- Multiple rows returned for single `actorId` in `vg_field_key_auth` table

**Root Cause**:
- Missing `UNIQUE` constraint on `vg_field_key_auth.actorId`
- `insertAuth()` query did not handle `ON CONFLICT` for duplicate inserts
- Multiple sessions join in field-keys query could return duplicate rows

**Solution**:

1. **Add unique constraint** (migration + SQL):
   ```sql
   CREATE UNIQUE INDEX IF NOT EXISTS idx_vg_field_key_auth_actorId
   ON vg_field_key_auth ("actorId");
   ```

2. **Update insert query** to handle conflicts:
   ```javascript
   INSERT INTO vg_field_key_auth (...)
   VALUES (...)
   ON CONFLICT ("actorId") DO UPDATE
     SET vg_username = EXCLUDED.vg_username,
         vg_password_hash = EXCLUDED.vg_password_hash,
         vg_phone = EXCLUDED.vg_phone,
         vg_active = EXCLUDED.vg_active
   ```

3. **Fix sessions join** to deduplicate:
   ```javascript
   // Before (incorrect - Cartesian product with multiple sessions):
   left outer join sessions on field_keys."actorId"=sessions."actorId"

   // After (correct - lateral join with LIMIT 1):
   left outer join lateral (
     select token, "actorId"
       from sessions
      where sessions."actorId" = field_keys."actorId"
      order by "createdAt" desc
      limit 1
   ) as sessions on true
   ```

**Files Changed**:
- `lib/model/migrations/20251218-01-unique-vg-field-key-auth-actorId.js` (new)
- `lib/model/query/field-keys.js` (lateral join fix)
- `lib/model/query/vg-app-user-auth.js` (ON CONFLICT clause)
- `plan/sql/vg_app_user_auth.sql` (unique index)

**Prevention**:
- Always add unique constraints for one-to-one relationships
- Use `maybeOne()` with UNIQUE constraints, not arbitrary queries
- Use lateral joins with `LIMIT 1` when joining to deduplicate many-to-one relationships

---

### Issue: Migration vs. Manual SQL Conflict

**Commit**: `1cfa0ebf` - "chore: drop unused unique actorId migration (handled via manual SQL)"

**Symptom**:
- Knex migration for `vg_field_key_auth` unique constraint exists
- But production uses manual SQL (`plan/sql/vg_app_user_auth.sql`)
- Duplication between migration and manual SQL

**Root Cause**:
- VG uses two database initialization paths:
  - **Test**: Knex migrations + test fixtures
  - **Production**: Manual SQL script (`plan/sql/vg_app_user_auth.sql`)

**Solution**:
- Drop unused Knex migration (keep only `plan/sql/vg_app_user_auth.sql`)
- OR: Keep migration but document that production uses manual SQL

**Pattern**:
- **Test DB**: Fixtures create VG tables (`test/integration/fixtures/03-vg-app-user-auth.js`)
- **Production DB**: Manual SQL (`docker exec ... psql ... < plan/sql/vg_app_user_auth.sql`)

**Best Practice**:
- Document which path is authoritative (manual SQL for VG tables)
- Keep fixtures synchronized with manual SQL schema

---

## Timestamp and Date Handling Issues

### Issue: Telemetry Timestamp Binding Error

**Commit**: `d456e1e7` - "fix telemetry timestamp binding"

**Symptom**:
- SQL query binding error when inserting telemetry with `deviceDateTime`
- Slonik expects ISO string, received JavaScript `Date` object

**Root Cause**:
```javascript
// Incorrect:
const parseDateTime = (value, field, payload) => {
  const trimmed = value.trim();
  const date = new Date(trimmed);
  return date;  // ❌ Returns Date object
};
```

**Solution**:
```javascript
// Correct:
const parseDateTime = (value, field, payload) => {
  const trimmed = value.trim();
  const date = new Date(trimmed);
  if (Number.isNaN(date.getTime()))
    throw Problem.user.invalidDataTypeOfParameter({ field, expected: 'UTC ISO datetime' });
  return trimmed;  // ✅ Return original ISO string
};
```

**File Changed**: `lib/domain/vg-telemetry.js`

**Key Lesson**:
- **Slonik SQL bindings expect primitives** (strings, numbers), not objects
- Validate `Date` object, but **bind the original ISO string**
- PostgreSQL `timestamptz` columns accept ISO 8601 strings directly

---

### Issue: Telemetry Date Filter Type Mismatch

**Commit**: `3eec000a` - "fix telemetry date filters"

**Symptom**:
- SQL WHERE clause comparison fails for `dateFrom`/`dateTo` filters
- Type mismatch between `Date` object and `timestamptz` column

**Root Cause**:
```javascript
// Incorrect:
const parseDateParam = (value, field) => {
  const date = new Date(value);
  return date;  // ❌ Date object doesn't bind correctly to SQL
};
```

**Solution**:
```javascript
// Correct:
const parseDateParam = (value, field) => {
  const date = new Date(value);
  if (Number.isNaN(date.getTime()))
    throw Problem.user.invalidDataTypeOfParameter({ field, expected: 'ISO datetime' });
  return date.toISOString();  // ✅ Convert to ISO string
};
```

**File Changed**: `lib/resources/vg-telemetry.js`

**Pattern for Date Handling in ODK Central**:

1. **Query parameters** (filters): Convert to ISO string via `.toISOString()`
2. **Request body** (telemetry payload): Keep original ISO string
3. **SQL binding**: Always bind ISO strings, not `Date` objects
4. **Validation**: Parse to `Date` to validate, then convert back to string

---

## Testing Issues

### Issue: Legacy App-User Tests Failing (172 failures)

**Source**: `server/docs/summary_failing_tests.md`

**Categories**:

1. **Legacy app-user flow (38 failures)**:
   - File: `test/integration/api/app-users.js`
   - Symptom: 400s instead of 200s, transaction depth errors
   - **Root Cause**: VG replaced long-lived tokens with short-lived sessions
   - **Status**: Superseded by VG tests (`vg-app-user-auth.js`, `vg-tests-orgAppUsers.js`)
   - **Action**: Mark legacy specs as `pending` or rewrite to VG flow

2. **Submissions API flow (≈60 failures)**:
   - File: `test/integration/api/submissions.js`
   - Symptom: 400/409/500 mismatches, base URL differences
   - **Root Cause**: VG app-user auth changes submission flow
   - **Action**: Decide whether to align behavior or update/skip specs

3. **User email/reset notifications (≈30 failures)**:
   - File: `test/integration/api/users.js`
   - Symptom: Mail count assertions fail, 400 vs 200 for app-user `users/current`
   - **Root Cause**: VG changes email behavior for app users
   - **Action**: Investigate if intentional, update or skip tests

**Strategy**:
- **Run VG-specific tests**: `npm test test/integration/api/vg-*`
- **Skip upstream tests** that conflict with VG behavior
- **Document test gaps** in `server/docs/vg_tests.md`

**Coverage Gaps** (from legacy tests, not in VG suite):
- Creation/list permissions (403 cases)
- Project-manager create/delete paths
- Ordered listing with revoked/ended sessions
- Extended metadata/last-used fields
- Audit logging for delete
- Delete assignment cleanup and project scoping
- Legacy long-session restore endpoint

---

## Development Environment Issues

### Issue: EXTRA_SERVER_NAME Optional Configuration

**Commits**:
- `4a990d0` - "fix: make EXTRA_SERVER_NAME optional in nginx template"
- `ce27239` - "docs: note optional EXTRA_SERVER_NAME"

**Symptom**:
- Nginx config fails if `EXTRA_SERVER_NAME` not set
- Dev setup breaks when only `DOMAIN` is configured

**Root Cause**:
- Nginx template assumed `EXTRA_SERVER_NAME` always exists
- Self-signed cert generation required both `DOMAIN` and `EXTRA_SERVER_NAME`

**Solution**:
- Make `EXTRA_SERVER_NAME` optional in nginx template
- Update cert generation to handle missing `EXTRA_SERVER_NAME`
- Document as optional in setup instructions

**Related Commits**:
- `e94da56` - "chore: set default dev host to central.local"
- `63ea65a` - "chore: generate selfsigned cert with SANs for DOMAIN/EXTRA_SERVER_NAME"

**Dev Environment Defaults**:
- `DOMAIN=central.local`
- `EXTRA_SERVER_NAME` (optional, for additional domains)

---

## Common Pitfalls and Prevention

### 1. Slonik SQL Binding Types

**Rule**: Always bind **primitives** (strings, numbers, booleans), never objects

**Bad**:
```javascript
const date = new Date();
sql`SELECT * FROM table WHERE created_at > ${date}`  // ❌ Binding error
```

**Good**:
```javascript
const date = new Date();
sql`SELECT * FROM table WHERE created_at > ${date.toISOString()}`  // ✅
```

### 2. Database Constraints for Data Integrity

**Rule**: Add unique constraints for one-to-one relationships

**Pattern**:
```sql
CREATE TABLE vg_field_key_auth (
  "actorId" integer REFERENCES actors(id),
  -- other columns
  UNIQUE ("actorId")  -- ✅ Prevents duplicates
);
```

### 3. Lateral Joins for Deduplication

**Rule**: Use `LATERAL JOIN` with `LIMIT 1` for many-to-one with single result

**Pattern**:
```sql
FROM field_keys fk
LEFT JOIN LATERAL (
  SELECT token, "actorId"
  FROM sessions
  WHERE sessions."actorId" = fk."actorId"
  ORDER BY "createdAt" DESC
  LIMIT 1
) AS s ON true
```

### 4. Test Organization for Fork

**Rule**: Separate VG tests from upstream tests to avoid merge conflicts

**Pattern**:
- VG tests: `test/integration/api/vg-*.js`
- Upstream tests: `test/integration/api/*.js` (mark conflicting ones as `pending`)

### 5. Date/Time Handling

**Rule**: Parse to validate, bind as ISO string

**Pattern**:
```javascript
// Validate:
const date = new Date(input);
if (Number.isNaN(date.getTime())) throw error;

// Bind:
sql`WHERE date_col > ${input}`  // Use original ISO string
// OR
sql`WHERE date_col > ${date.toISOString()}`  // Convert to ISO
```

---

## Debugging Checklist

When encountering VG-related issues:

### 1. Database Errors

- [ ] Check for missing unique constraints on one-to-one tables
- [ ] Verify `ON CONFLICT` clauses in insert queries
- [ ] Review joins for potential Cartesian products (use `LATERAL` if needed)
- [ ] Confirm SQL binding types (primitives, not objects)

### 2. Authentication Errors

- [ ] Verify `vg_field_key_auth` row exists for actor
- [ ] Check `vg_active` flag is `true`
- [ ] Confirm session hasn't expired (`expiresAt > NOW()`)
- [ ] Validate bearer token format and presence

### 3. Test Failures

- [ ] Run VG-specific tests in isolation: `npm test test/integration/api/vg-*`
- [ ] Check if failure is legacy test expecting upstream behavior
- [ ] Review test fixtures for VG table creation
- [ ] Verify test database has VG schema applied

### 4. Query Errors

- [ ] Check Slonik binding types (no `Date` objects)
- [ ] Verify SQL parameter count matches placeholders
- [ ] Review `maybeOne()` usage (requires unique result)
- [ ] Check for missing table joins (e.g., `vg_field_key_auth`)

---

## Related

- [[server-architecture-patterns]] - Standard ODK Central architecture
- [[vg-customization-patterns]] - VG fork conventions

## References

- server/docs/summary_failing_tests.md - Test failure summary
- server/docs/vg_tests.md - VG test coverage
- Git commits: `fde3708a`, `3eec000a`, `d456e1e7`, `1edd465`
