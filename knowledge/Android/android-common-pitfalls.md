---
title: Common Android Pitfalls and Learnings
type: reference
domain: Android Development
tags:
  - android
  - threading
  - proguard
  - lifecycle
  - permissions
status: approved
created: 2025-12-25
updated: 2025-12-25
---

# Common Android Pitfalls and Learnings

## Threading & Async

### Problem: NetworkOnMainThreadException & ANRs
Performing network operations, heavy database I/O, or initialization on the main (UI) thread causes crashes (`NetworkOnMainThreadException`) and ANRs (Application Not Responding).

**Observed Triggers in Git History:**
- **Media Player Setup**: `MediaPlayer.setDataSource/prepare` on UI thread caused ANRs. Fix: Move to background.
- **Database Operations**: `ProjectCleaner` deletion logic and `Entity` loading. Fix: Use `Schedulers.io()`.
- **Location Services**: Specific versions of `play-services-location` caused ANRs. Fix: Downgrade or upgrade cautiously.
- **User Property Init**: Initializing heavy user properties on startup.

### Solution
- **Never** run network calls or heavy DB I/O on the main thread.
- Use **Coroutines** (`Dispatchers.IO`) or **RxJava** (`Schedulers.io()`).
- **Legacy Code**: If refactoring `AsyncTask`, move to `Scheduler` or `WorkManager`.
- **UI Updates**: Calculate data on background, switch to Main only for `setText`/`View` updates.

---

## App Lifecycle & State Persistence

### Problem: State Loss on Background/Minimize
Users reported the app showing the "PIN Setup" screen instead of "PIN Entry" after minimizing. This happens when in-memory state is cleared by the OS but not properly restored or persisted.
*Ref: Commit `4e8b3...` "PIN persistence fixed"*

### Best Practices
- Persist critical auth state (tokens, flags) to `SharedPreferences` or Encrypted Storage.
- Do not rely solely on static variables or singleton state that may be wiped.
- Handle `onResume` to re-validate state (e.g., check if PIN is required).

---

## Release Builds & ProGuard (R8)

### Problem: Crashes in Release Mode Only
"Fix release login crash" often points to ProGuard obfuscating code used via reflection (e.g., Retrofit models, Gson).

### Solution
- **Keep Rules**: Add `@Keep` annotations or `proguard-rules.pro` entries for data models.
- **Test Release Builds**: Always run `assembleRelease` and test locally before deploying.

---

## Permissions

### Problem: Request Loops
Requesting permissions in `onResume` without checking if they were effectively denied (checked "Don't ask again") can cause infinite loops or blocking UI.

### Solution
- Check `shouldShowRequestPermissionRationale`.
- If permission is permanently denied, show a specific UI/Dialog directing the user to App Settings, rather than requesting permission again immediately.
