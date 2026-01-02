---
title: Gradle Build Compatibility Matrix
type: reference
domain: Android
tags:
  - gradle
  - kotlin
  - room
  - ksp
  - build-configuration
status: approved
created: 2025-12-30
updated: 2025-12-30
---

# Gradle Build Compatibility Matrix

## Context

This document maintains the proven compatible versions of Kotlin, KSP, Room, and Gradle plugins for the MEDRES ODK Collect project. Mismatches between these tools—particularly regarding Kotlin metadata versions—can lead to build failures.

## Stable Configuration (Dec 2025)

> **Authority**
> This configuration is verified to work with the project codebase as of late 2025. Deviating from these versions (e.g., upgrading to Kotlin 2.3.0 without a confirmed compatible KSP artifact) is discouraged.

| Library | Version | Note |
| :--- | :--- | :--- |
| **Kotlin** | `2.1.0` | Latest stable 2.3.0 encountered plugin resolution failures |
| **Room** | `2.8.4` | Latest stable, supports KSP |
| **KSP** | `2.1.0-1.0.29` | **Must match Kotlin 2.1.0 exactly** |

## Configuration Steps

### 1. Update Version Catalog

In `gradle/libs.versions.toml`:

```toml
[versions]
kotlin = "2.1.0"
room = "2.8.4"

[plugins]
ksp = { id = "com.google.devtools.ksp", version = "2.1.0-1.0.29" }
```

### 2. Configure Modules

In module-level `build.gradle` files (e.g., `medres-auth-module`), migrate from `kapt` to `ksp`:

```gradle
dependencies {
    // Room
    implementation libs.androidxRoomRuntime
    ksp libs.androidxRoomCompiler
    implementation libs.androidxRoomKtx

    // Dagger
    implementation libs.dagger
    ksp libs.daggerCompiler
}
```

## Troubleshooting

### Metadata Version Error

**Symptom:**
`Provided Metadata instance has version x, while maximum supported version is y`

**Resolution:**
This indicates your Room/KSP compiler is outdated relative to your Kotlin version.
1. Check `libs.versions.toml`.
2. Ensure `ksp` version strictly matches the `kotlin` version suffix (e.g., `2.1.0` -> `2.1.0-x.y.z`).
3. If a compatible KSP version doesn't exist for your Kotlin version, downgrade Kotlin.

### Plugin Not Found

**Symptom:**
`Plugin [id: 'com.google.devtools.ksp', version: '...'] was not found`

**Resolution:**
Ensure `settings.gradle` includes the Google Maven repository in `pluginManagement`:

```gradle
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
```
