---
title: Product Flavors for AIIMS-ODK-Collect Separate Builds
type: howto
domain: Android Development
tags:
  - aiims
  - product-flavors
  - build-variants
  - gradle
  - versioning
  - apk-compilation
status: approved
created: 2025-12-26
updated: 2025-12-26
---

# Product Flavors for AIIMS-ODK-Collect Separate Builds

## Overview

AIIMS-ODK-Collect uses Android Product Flavors to create two distinct applications from a single codebase:

- **ODK Collect**: Standard ODK Collect (Package: `org.odk.collect.android`)
- **AIIMS ODK Collect**: AIIMS-customized version (Package: `org.aiims.odk.collect`)

Both apps can coexist on the same device with completely **separate data storage**, **independent authentication**, and **distinct feature flags**.

## Architecture

### Flavor Dimensions

```gradle
flavorDimensions "version"

productFlavors {
    odk {
        dimension "version"
        applicationId "org.odk.collect.android"
        // ODK-specific configuration
    }

    aiims {
        dimension "version"
        applicationId "org.aiims.odk.collect"
        // AIIMS-specific configuration
    }
}
```

**Key Point**: Different `applicationId` values = **separate app installations** + **separate data storage** on the device.

### Data Storage Isolation

Each flavor stores data in its own directory:

- **ODK**: `/data/data/org.odk.collect.android/`
  - SQLite databases (`forms.db`, `instances.db`)
  - SharedPreferences
  - File storage: `/Android/data/org.odk.collect.android/files/`

- **AIIMS**: `/data/data/org.aiims.odk.collect/`
  - Completely separate databases
  - Independent SharedPreferences
  - File storage: `/Android/data/org.aiims.odk.collect/files/`

**Result**: User A's data in ODK Collect is NOT accessible to User B's AIIMS-ODK-Collect installation.

## Flavor-Specific Configuration

### 1. App Name Customization

Each flavor overrides the app display name using `resValue`:

```gradle
productFlavors {
    odk {
        resValue("string", "collect_app_name", "ODK Collect")
    }

    aiims {
        resValue("string", "collect_app_name", "AIIMS ODK Collect")
    }
}
```

The app uses this resource in `MainMenuFragment.kt`:
```kotlin
binding.appName.text = getString(string.collect_app_name)
```

### 2. Feature Flags

Each flavor enables/disables AIIMS functionality via build-time configuration:

**ODK Flavor**:
```gradle
resValue("bool", "aiims_auth_enabled", "false")
resValue("bool", "odk_launcher_enabled", "true")
```

**AIIMS Flavor**:
```gradle
resValue("bool", "aiims_auth_enabled", "true")
resValue("bool", "odk_launcher_enabled", "false")
resValue("string", "aiims_default_api_url", "\"http://localhost:5174/api\"")
resValue("integer", "aiims_default_offline_period", "7")
resValue("integer", "aiims_default_auto_logout", "30")
```

These are read at runtime in `Collect.java`:
```java
if (getResources().getBoolean(R.bool.aiims_auth_enabled)) {
    registerActivityLifecycleCallbacks(new AiimsAppLock(this));
}
```

### 3. Google Firebase Configuration

Both `debug/google-services.json` and `release/google-services.json` include client entries for both package names:

```json
{
  "client": [
    {
      "android_client_info": {
        "package_name": "org.odk.collect.android"
      }
    },
    {
      "android_client_info": {
        "package_name": "org.aiims.odk.collect"
      }
    }
  ]
}
```

## Versioning Strategy

### Coordinated Versioning with Flavor Suffix

Both flavors **share the same `versionCode`** but have **distinct `versionName` values**:

**Base Version** (in `defaultConfig`):
```gradle
versionCode 5113
versionName "v2025.1.0-RC1"
```

**AIIMS Flavor Suffix**:
```gradle
aiims {
    versionNameSuffix "-AIIMS"
}
```

**Debug Build Type Suffix** (optional):
```gradle
debug {
    versionNameSuffix "-DEBUG"
}
```

### Version Examples

| Variant | versionCode | versionName |
|---------|-------------|-------------|
| ODK Debug | 5113 | v2025.1.0-RC1-DEBUG |
| ODK Release | 5113 | v2025.1.0-RC1 |
| AIIMS Debug | 5113 | v2025.1.0-RC1-AIIMS-DEBUG |
| AIIMS Release | 5113 | v2025.1.0-RC1-AIIMS |

**Suffix Concatenation**: `baseVersion + flavorSuffix + buildTypeSuffix`

### Updating Versions

Update ONLY the `defaultConfig` block:

```gradle
defaultConfig {
    versionCode 5114  // Increment by 1 for each release
    versionName "v2025.1.1"  // Update version string
}
```

**AIIMS and debug suffixes are automatically applied to all variants!**

## Build Variants

### Available Variants

The product flavor system creates 4 base build variants:

- `odkDebug` - ODK Collect debug build
- `odkRelease` - ODK Collect release build
- `aiimsDebug` - AIIMS ODK Collect debug build
- `aiimsRelease` - AIIMS ODK Collect release build

Plus **legacy variants** (backward compatibility):
- `debug`, `release` - Default builds (for ODK)
- `odkCollectRelease` - Official ODK release variant
- `selfSignedRelease` - Self-signed release variant

### Gradle Build Commands

```bash
# Build ODK flavor
./gradlew assembleOdkDebug      # ODK debug APK
./gradlew assembleOdkRelease    # ODK release APK
./gradlew assembleOdk           # All ODK variants

# Build AIIMS flavor
./gradlew assembleAiimsDebug    # AIIMS debug APK
./gradlew assembleAiimsRelease  # AIIMS release APK
./gradlew assembleAiims         # All AIIMS variants

# Build all flavors
./gradlew assemble              # All variants (debug + release)
./gradlew assembleDebug         # All debug variants
./gradlew assembleRelease       # All release variants

# Install on device
./gradlew installOdkDebug       # Install ODK debug
./gradlew installAiimsDebug     # Install AIIMS debug
```

## Generated APK Structure

After building, APKs are organized by flavor:

```
collect_app/build/outputs/apk/
├── odk/
│   ├── debug/
│   │   └── ODK-Collect-debug.apk
│   └── release/
│       └── ODK-Collect-release.apk
├── aiims/
│   ├── debug/
│   │   └── AIIMS-ODK-Collect-debug.apk
│   └── release/
│       └── AIIMS-ODK-Collect-release.apk
├── debug/
│   └── [legacy builds]
└── release/
    └── [legacy builds]
```

## APK Naming Convention

The `applicationVariants` configuration automatically renames APKs based on flavor and build type:

```gradle
applicationVariants.configureEach { variant ->
    def baseName
    if (variant.flavorName == "aiims") {
        baseName = "AIIMS-ODK-Collect"
    } else if (variant.flavorName == "odk") {
        baseName = "ODK-Collect"
    } else {
        baseName = "Collect"
    }

    def buildTypeSuffix = ...
    variant.outputs.configureEach { output ->
        output.outputFileName = "${baseName}-${buildTypeSuffix}.apk"
    }
}
```

## Testing Both Flavors

To verify both apps work independently:

1. **Build both debug variants**:
   ```bash
   ./gradlew installOdkDebug installAiimsDebug
   ```

2. **Verify on device**:
   ```bash
   adb shell pm list packages | grep odk.collect
   # Output:
   # package:org.odk.collect.android
   # package:org.aiims.odk.collect
   ```

3. **Check app launcher**:
   - Both appear as separate apps
   - ODK Collect (standard)
   - AIIMS ODK Collect (custom)

4. **Test data isolation**:
   - Create a form in ODK Collect
   - Verify it does NOT appear in AIIMS ODK Collect
   - Create data in one app, verify it's inaccessible in the other

## Flavor-Specific Resources

Each flavor can have its own resource overrides in flavor-specific directories:

```
collect_app/
├── src/
│   ├── main/          # Shared code and resources
│   │   ├── res/
│   │   └── java/
│   ├── odk/           # ODK-specific resources
│   │   └── res/
│   │       └── values/
│   │           └── strings.xml
│   └── aiims/         # AIIMS-specific resources
│       └── res/
│           └── values/
│               └── strings.xml
```

**Merge Priority** (highest to lowest):
1. Flavor-specific resources (`src/aiims/`, `src/odk/`)
2. Build-type resources (`src/debug/`, `src/release/`)
3. Main resources (`src/main/`)

## Key Configuration Files

### build.gradle

**Location**: `collect_app/build.gradle`

**Key Sections**:
- Lines 81-82: `defaultConfig` with base `versionCode` and `versionName`
- Lines 87-118: `productFlavors` definitions
- Lines 182-190: `buildTypes` with debug suffix
- Lines 193-218: `applicationVariants` APK naming logic

### Google Services

- `collect_app/src/debug/google-services.json`
- `collect_app/src/release/google-services.json`

Both must include Firebase client configurations for both package names.

### Flavor-Specific Strings

- `collect_app/src/odk/res/values/strings.xml`
- `collect_app/src/aiims/res/values/strings.xml`

## Benefits of Product Flavors

✅ **Complete Separation**: Distinct apps with independent data storage
✅ **Single Codebase**: Share common code while customizing specific behaviors
✅ **Modular Architecture**: AIIMS code stays in `aiims_auth_module`, feature-flagged by flavor
✅ **Coexistence**: Both apps install together without conflict
✅ **Professional Structure**: Industry-standard Android pattern
✅ **Easy Versioning**: Update version once, all flavors get new version
✅ **Release Management**: Separate APKs for different audiences

## Troubleshooting

### Error: "No matching client found for package name"

**Cause**: `google-services.json` missing client configuration for one of the package names.

**Solution**: Add both package names to `google-services.json`:
```json
{
  "client": [
    { "android_client_info": { "package_name": "org.odk.collect.android" } },
    { "android_client_info": { "package_name": "org.aiims.odk.collect" } }
  ]
}
```

### Build Variants Not Appearing

**Solution**: Sync Gradle project:
```bash
./gradlew clean :collect_app:clean
# Then in Android Studio: File -> Sync Now
```

### Version Suffix Not Applied

**Cause**: Gradle cache or stale build.

**Solution**:
```bash
./gradlew clean assemble
```

## Related

- [[aiims-odk-collect-customizations]] - AIIMS authentication and PIN security implementation
- [[odk-collect-core]] - ODK Collect architecture and core modules
- [[android-common-pitfalls]] - Common Android development issues
