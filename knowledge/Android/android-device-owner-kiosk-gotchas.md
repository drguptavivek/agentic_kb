---
title: Android Device Owner and Kiosk Gotchas
type: reference
domain: Android Development
tags:
  - android
  - kiosk
  - device-owner
  - lock-task
  - package-visibility
  - launcher
status: draft
created: 2025-12-26
updated: 2025-12-26
---

# Android Device Owner and Kiosk Gotchas

## Problem / Context
Device Owner and kiosk flows are brittle: a small misconfiguration can silently block app launches, break app discovery on Android 11+, or make provisioning fail. These notes capture reusable Android-wide gotchas and fixes.

## Device Owner Provisioning Requirements
- Device must be factory reset or a fresh AVD; DO cannot be set if any accounts exist.
- DO must be set before the app is launched the first time.
- Once set, DO cannot be removed without factory reset.
- Use QR provisioning for production to avoid manual setup mistakes.

### Setup Command (Dev)
```bash
adb shell dpm set-device-owner com.example.launcher/.admin.LauncherAdminReceiver
```

### Verification
```bash
adb shell dpm get-device-owner
adb shell dumpsys device_policy | rg -n "Device Owner" -C 2
```

### Failure Patterns
- "Not allowed to set device owner because there are already some accounts" -> factory reset required.
- "Not a device owner" -> app was launched before DO provisioning, or command used the wrong component.

## Lock Task Allow-List Pitfalls
- If `startLockTask()` is used, Android will only allow apps in the lock task allow-list to launch.
- If a target app is missing from `setLockTaskPackages()`, launch attempts silently fail or flash and disappear.
- `setLockTaskPackages()` must be called by the Device Owner admin component, or it is ignored.
- Always include your own launcher package in the allow-list.

### Safe Allow-List Update Pattern
```kotlin
val all = (allowedPackages + context.packageName).toSet().toTypedArray()
dpm.setLockTaskPackages(adminComponent, all)
```

### Diagnostics
```bash
adb shell dumpsys device_policy | rg -n "Lock task" -C 6
adb shell dumpsys activity activities | rg -n "mLockTaskModeState" -C 2
```

## Duplicate Package Entries Crash
`setLockTaskPackages()` throws `IllegalArgumentException: duplicate element` if the allow-list has duplicates. Always dedupe using `toSet()` before passing the array.

## Android 11+ Package Visibility
On Android 11+, app discovery is blocked unless you declare package visibility.

### Required Manifest Queries
```xml
<queries>
  <intent>
    <action android:name="android.intent.action.MAIN" />
    <category android:name="android.intent.category.LAUNCHER" />
  </intent>
  <package android:name="org.odk.collect.android" />
</queries>
```

### Symptoms
- `queryIntentActivities()` returns empty list.
- `getLaunchIntentForPackage()` returns null for installed apps.

## App Discovery Limitations
- Some apps do not appear via `queryIntentActivities()` or `getLaunchIntentForPackage()`.
- For those apps, check install with `getPackageInfo()` and add them manually with a known entry activity.

### Manual Launch Pattern
```kotlin
val isInstalled = runCatching { pm.getPackageInfo(pkg, 0) }.isSuccess
if (isInstalled) {
  val intent = Intent().setClassName(pkg, activityClass)
  intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
  context.startActivity(intent)
}
```

## Multi-App Kiosk vs Lock Task
- Multi-app kiosk can be achieved by only setting the lock task allow-list and avoiding `startLockTask()`.
- Lock task pins the current activity and blocks switching unless the target app is allow-listed.
- Choose based on strictness: lock task for hard kiosk, allow-list only for softer multi-app mode.

## Recovery When Kiosk Gets Stuck
- If lock task is active and Settings is blocked, recovery often requires ADB or a device wipe.
- Plan an admin escape path (supervisor PIN + stop lock task) before deploying at scale.

### ADB Recovery Shortcut
```bash
adb shell am force-stop com.android.settings
adb shell am start -a android.intent.action.MAIN -c android.intent.category.HOME
```

## References
- [[android-common-pitfalls]]

## Related
- [[android-common-pitfalls]]
