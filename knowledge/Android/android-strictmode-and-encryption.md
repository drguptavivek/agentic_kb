# Android StrictMode and EncryptedSharedPreferences

> Domain: Android
> Type: howto
> Status: approved
> Tags: #android #security #encryption #strictmode #jetpack-security

---

## Problem: StrictMode Violation with EncryptedSharedPreferences

When using AndroidX Security's `EncryptedSharedPreferences`, the app crashes with `StrictMode ThreadPolicy violation` during initialization on the main thread.

### Crash Sequence

```
App.onCreate()
→ Dagger creates MedresAuthManager
→ Constructor calls refreshState()
→ refreshState() calls authStorage.getProjectId()
→ Triggers lazy initialization of masterKey
→ MasterKey.Builder.build() does disk I/O to Android Keystore
→ StrictMode detects disk I/O on main thread → CRASH
```

### Root Cause

`EncryptedSharedPreferences` and `MasterKey` initialization perform disk I/O to:
- Generate or retrieve encryption keys from Android Keystore
- Create encrypted preferences file
- Read/write encryption metadata

If StrictMode is enabled with "death" penalty, this crashes the app.

---

## Solution: StrictMode Suppression Pattern

Wrap initialization with `StrictMode.setThreadPolicy(StrictMode.ThreadPolicy.LAX)`:

```kotlin
import android.os.StrictMode
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

class SecureStorage(context: Context) {

    // Master key for encryption
    // Suppress StrictMode for key generation as it requires disk I/O to Android Keystore
    private val masterKey: MasterKey by lazy {
        val oldPolicy = StrictMode.getThreadPolicy()
        try {
            // Temporarily allow disk I/O for key generation
            StrictMode.setThreadPolicy(StrictMode.ThreadPolicy.LAX)
            MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()
        } finally {
            StrictMode.setThreadPolicy(oldPolicy)
        }
    }

    // Encrypted preferences for sensitive data
    // Suppress StrictMode for initialization as it may require disk I/O
    private val encryptedPrefs: SharedPreferences by lazy {
        val oldPolicy = StrictMode.getThreadPolicy()
        try {
            // Temporarily allow disk I/O for encrypted prefs creation
            StrictMode.setThreadPolicy(StrictMode.ThreadPolicy.LAX)
            EncryptedSharedPreferences.create(
                context,
                "secure_prefs",
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } finally {
            StrictMode.setThreadPolicy(oldPolicy)
        }
    }
}
```

### Key Points

1. **Always use `try-finally`** to restore original policy
2. **Only suppress during initialization** - not during regular operations
3. **Use lazy initialization** so it happens on first access, not during object creation
4. **Keep suppression scope minimal** - only around the I/O operation

---

## Alternative: Initialize on Background Thread

For more complex initialization, use a background thread:

```kotlin
class SecureStorage(context: Context) {

    private val _masterKey = MutexHolder<MasterKey>(null)
    private val _encryptedPrefs = MutexHolder<SharedPreferences>(null)

    suspend fun initialize() = withContext(Dispatchers.IO) {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()

        val encryptedPrefs = EncryptedSharedPreferences.create(
            context,
            "secure_prefs",
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )

        _masterKey.value = masterKey
        _encryptedPrefs.value = encryptedPrefs
    }

    suspend fun getToken(): String? {
        ensureInitialized()
        return _encryptedPrefs.value?.getString("token", null)
    }

    private suspend fun ensureInitialized() {
        if (_masterKey.value == null) {
            initialize()
        }
    }
}
```

**Trade-offs:**
- ✅ No StrictMode violations
- ❌ All operations become suspend functions
- ❌ More complex code

---

## Common Gotchas

### Gotcha 1: setUserAuthenticationRequired() Causes Crash

```kotlin
// DON'T DO THIS - Crashes on devices without lock screen
MasterKey.Builder(context)
    .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
    .setUserAuthenticationRequired(true)  // ❌ Crashes if no lock screen
    .build()
```

**Error:** `IllegalStateException: Secure lock screen must be enabled`

**Solution:** Either remove `setUserAuthenticationRequired(true)` or add try-catch fallback:

```kotlin
private val masterKey: MasterKey by lazy {
    val oldPolicy = StrictMode.getThreadPolicy()
    try {
        StrictMode.setThreadPolicy(StrictMode.ThreadPolicy.LAX)
        MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            // .setUserAuthenticationRequired(true)  // Optional - requires lock screen
            .build()
    } catch (e: Exception) {
        // Fallback for devices without lock screen
        MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
    } finally {
        StrictMode.setThreadPolicy(oldPolicy)
    }
}
```

### Gotcha 2: Early Access Triggers Initialization

```kotlin
class AuthManager(context: Context) {
    private val secureStorage = SecureStorage(context)

    init {
        // ❌ This triggers masterKey/encryptedPrefs initialization on main thread
        val projectId = secureStorage.projectId
    }
}
```

**Solution:** Defer access until after initialization completes, or use suspend functions.

### Gotcha 3: Dagger Injection During Construction

```kotlin
@Singleton
class AuthManager @Inject constructor(
    private val secureStorage: SecureStorage
) {
    init {
        // ❌ Runs during Dagger injection on main thread
        refreshState()
    }

    private fun refreshState() {
        // ❌ Accesses secureStorage.projectId
        // → Triggers lazy initialization
        // → Disk I/O on main thread
        // → StrictMode crash
    }
}
```

**Solution:** Either:
1. Use StrictMode suppression (shown above)
2. Make `refreshState()` a suspend function and call it lazily
3. Initialize `SecureStorage` with a suspend function before first use

---

## Encryption Best Practices

### Data Classification

**Encrypt (EncryptedSharedPreferences):**
- Auth tokens
- API keys
- PINs/passwords (use hash + salt)
- User credentials
- Sensitive configuration

**Plain SharedPreferences:**
- User preferences (theme, notifications)
- Non-sensitive settings
- Cached UI state
- Feature flags

### Key Schemes

```kotlin
// Recommended: AES-256-GCM (most secure)
MasterKey.KeyScheme.AES256_GCM

// Alternative: AES256_GCM_SPEC (compatibility mode)
MasterKey.KeyScheme.AES256_GCM_SPEC
```

### Encryption Schemes

```kotlin
EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV  // Keys
EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM  // Values
```

---

## Testing

### Unit Tests

```kotlin
@Test
fun testTokenStorageEncrypted() {
    val storage = SecureStorage(context)
    storage.token = "test_token_123"

    // Verify token is stored encrypted (not plain text in SharedPreferences)
    val prefs = context.getSharedPreferences("secure_prefs", Context.MODE_PRIVATE)
    val storedValue = prefs.all["token"] as? String

    // Value should NOT be plain "test_token_123"
    assertNotEquals("test_token_123", storedValue)
}

@Test
fun testTokenRetrieval() {
    val storage = SecureStorage(context)
    storage.token = "test_token_123"

    assertEquals("test_token_123", storage.token)
}
```

### Manual Tests

1. **Rooted Device Test:** Extract app data, verify tokens not readable
2. **Lock Screen Test:** Test with/without lock screen enabled
3. **StrictMode Test:** Enable StrictMode death penalty, verify no crash
4. **Reinstall Test:** Verify encrypted data clears on reinstall

---

## References

- [Android Security Crypto Library](https://developer.android.com/topic/security/data)
- [MasterKey Documentation](https://developer.android.com/reference/androidx/security/crypto/MasterKey)
- [EncryptedSharedPreferences Documentation](https://developer.android.com/reference/androidx/security/crypto/EncryptedSharedPreferences)
- [StrictMode Documentation](https://developer.android.com/reference/android/os/StrictMode)
