---
title: Keycloak Passkeys and WebAuthn
type: reference
domain: Keycloak
tags:
  - keycloak
  - webauthn
  - passkeys
  - passwordless
  - fido2
  - mfa
  - security
  - biometric
status: approved
created: 2025-01-29
updated: 2025-01-29
---

# Keycloak Passkeys and WebAuthn

## Overview

Keycloak supports WebAuthn (Web Authentication) and FIDO2 standards for passwordless authentication and two-factor authentication using passkeys, security keys, and biometric devices. <https://www.keycloak.org/docs/latest/server_admin/#passkeys>

## What are Passkeys?

**Passkeys are:**
- FIDO2 credentials
- Passwordless authentication method
- Device-bound (phone, computer, security key)
- Biometric (fingerprint, Face ID) or PIN protected
- Phishing-resistant
- Created using public key cryptography

**Benefits:**
- No passwords to remember
- Stronger security than passwords
- Better user experience
- Protection against phishing
- Protection against data breaches

## WebAuthn vs Passkeys

| Aspect | WebAuthn | Passkeys |
|--------|----------|----------|
| **Standard** | FIDO2/WebAuthn | FIDO2/WebAuthn |
| **Storage** | Device-bound | Cloud-synced |
| **Experience** | Hardware key | Biometric + PIN |
| **Platform** | Any device | Platform-specific |
| **Recovery** | Lost key = problem | Sync across devices |

**Note:** Passkeys are built on WebAuthn with cloud synchronization.

## Enabling WebAuthn/Passkeys

### Server Configuration

**Admin Console:** Realm Settings → Authentication → Required Actions

**Enable required actions:**
1. **WebAuthn Register Passwordless** - Passwordless authentication
2. **WebAuthn Register** - Two-factor authentication
3. **Recovery Codes Authentication** - Backup codes

**Configure settings:**
```
Realm Settings → Authentication → WebAuthn
```

**Settings:**
- **Signature algorithms:** ES256, RS256, ES384, RS384, ES512, RS512
- **Attestation conveyance:** none, direct, indirect, enterprise
- **Authenticator attachment:** platform, cross-platform
- **User verification requirement:** required, preferred
- **Require timeout:** seconds (default: 60)
- **Avoid same-authenticator-register:** prevent duplicate registration
- **Releaseable credential:** allow credential removal

### Alternative Authentication

**Enable WebAuthn in flow:**
1. Authentication → Flows
2. Select flow (e.g., "Browser")
3. Add execution: **WebAuthn Browser Authenticator**
4. Configure as alternative or required

## WebAuthn Flows

### Passwordless Flow

**Using passkeys instead of password:**

1. User visits login page
2. Enters username
3. Keycloak checks for registered passkeys
4. Browser prompts for biometric/PIN
5. User authenticates with passkey
6. User logged in (no password)

**Flow configuration:**
```
Browser Flow:
1. Cookie Reset (alternative)
2. WebAuthn Browser (conditional)
   ├─ Identity Provider Redirector (alternative)
   └─ WebAuthn Passwordless (required)
```

### Two-Factor Authentication (2FA)

**Using passkeys as second factor:**

1. User enters username/password
2. Keycloak requires second factor
3. Browser prompts for security key/passkey
4. User authenticates with passkey
5. User logged in

**Flow configuration:**
```
Browser Flow:
1. Cookie Reset (alternative)
2. Auth Forms (conditional)
   └─ Username Password Form (required)
3. WebAuthn Browser (conditional)
   └─ WebAuthn Authenticator (required)
```

### Conditional WebAuthn

**Based on user, role, or client:**

1. **Add Conditional Execution**
2. **Condition: User attribute or role**
3. **Execution: WebAuthn Authenticator**

**Example: Require for admin users**
```
Browser Flow:
1. Username Password Form (required)
2. Conditional Role: admin (conditional)
   └─ WebAuthn Authenticator (required)
```

## Recovery Codes

### What are Recovery Codes?

**Recovery codes are:**
- Backup codes for 2FA scenarios
- One-time use codes
- Generated during 2FA setup
- Used when security key unavailable

**Use cases:**
- Lost security key
- Phone unavailable
- Biometric not working
- Device replacement

### Configuring Recovery Codes

**Required action:**
1. Realm Settings → Authentication → Required Actions
2. **Recovery Codes Authentication** action
3. Set as default for new users (optional)

**Regenerate codes:**
- Users can generate new codes
- Old codes invalidated
- User authentication event logged

**Per-user configuration:**
1. Users → Select user
2. **Required Actions** tab
3. Add "Recovery Codes Authentication"
4. Next login: User prompted to generate codes

### Recovery Code Format

**Typical format:**
```
8-character codes
10-20 codes per set
Can include: letters, numbers, both

Example:
- A1B2C3D4
- E5F6G7H8
- I9J0K1L2
```

## Device Support

### Platform Authenticators

**Built into devices:**
- **Windows Hello** - Face recognition, fingerprint, PIN
- **Touch ID** - MacBook, Magic Keyboard
- **Face ID** - iPhone, iPad
- **Android Biometric** - Fingerprint, face unlock

**Passkey support:**
- iOS 16+ / iPadOS 16+
- Android 9+
- Windows 11 22H2+
- macOS 13+

### Cross-Platform Authenticators

**Separate hardware devices:**
- **YubiKey** - USB/NFC security keys
- **Titan Security Key** - Google's security key
- **Feitan** - FIDO2 security keys
- **SoloKeys** - Open source security keys

**Benefits:**
- Portable between devices
- Work on most platforms
- No battery required
- Very secure

## Registration Process

### User Registration

**Step-by-step:**

1. **Enable WebAuthn for user:**
   - Admin Console → Users → Select user
   - **Required Actions** → Add "WebAuthn Register"
   - Or: **Credentials** tab → **Register WebAuthn**

2. **User logs in:**
   - Prompted to register authenticator
   - Selects authenticator type:
     - **Platform** - Built-in biometric
     - **Cross-platform** - Security key

3. **User registers:**
   - Browser prompts for authenticator
   - User performs gesture (biometric, touch, PIN)
   - Keycloak stores credential ID and public key

4. **Registration complete:**
   - Authenticator ready for use
   - Can set as required for login

### Multiple Authenticators

**Users can register:**
- Multiple passkeys (different devices)
- Security key + phone passkey
- Backup authenticators

**Benefits:**
- Device flexibility
- Redundancy for recovery
- Multi-device support

## Authentication Process

### Passwordless Authentication

**Step-by-step:**

1. **User visits login page**
2. **Enters username**
3. **Keycloak checks for registered passkeys**
4. **Initiates WebAuthn authentication:**
   ```javascript
   navigator.credentials.get({
     publicKey: {
       challenge: base64urlDecode(serverChallenge),
       allowCredentials: [{
         type: 'public-key',
         id: base64urlDecode(credentialId),
         transports: ['internal', 'hybrid']
       }],
       userVerification: 'preferred',
       timeout: 60000
     }
   })
   ```
5. **Browser shows passkey prompt**
6. **User authenticates with:**
   - Biometric (fingerprint, face)
   - Device PIN
   - Security key touch
7. **Signature sent to Keycloak**
8. **Keycloak verifies signature**
9. **User logged in**

### Two-Factor with WebAuthn

**Step-by-step:**

1. **User enters username/password**
2. **Keycloak validates password**
3. **Initiates WebAuthn as second factor:**
   ```javascript
   navigator.credentials.get({
     publicKey: {
       challenge: base64urlDecode(serverChallenge),
       allowCredentials: [{
         type: 'public-key',
         id: base64urlDecode(credentialId),
         transports: ['usb', 'nfc', 'ble']
       }],
       userVerification: 'required',
       timeout: 60000
     }
   })
   ```
4. **User touches security key or uses passkey**
5. **Keycloak verifies signature**
6. **User logged in**

## Configuration Options

### Signature Algorithms

**Available algorithms:**
- **ES256** - ECDSA with SHA-256 (most common)
- **ES384** - ECDSA with SHA-384
- **ES512** - ECDSA with SHA-512
- **RS256** - RSA with SHA-256
- **RS384** - RSA with SHA-384
- **RS512** - RSA with SHA-512

**Recommendation:** ES256 (widely supported, efficient)

### Attestation Conveyance

**Options:**

**none (default):**
- No attestation information
- Fast registration
- Privacy-preserving

**direct:**
- Full attestation certificate
- Device verification
- Privacy concerns

**indirect:**
- Anonymized by CA
- Some device verification
- Balanced approach

**enterprise:**
- Full attestation
- Enterprise device IDs
- Corporate environment

### Authenticator Attachment

**Platform:**
- Built-in device authenticators
- Biometric sensors
- Passkey support

**Cross-platform:**
- USB security keys
- NFC security keys
- Bluetooth security keys

**Recommendation:** Support both for flexibility

### User Verification

**required:**
- Always require biometric/PIN
- Most secure
- May impact UX

**preferred:**
- Prefer verification if available
- Fall back to device protection
- Balanced security/UX

**discouraged:**
- Don't require verification
- Weakest security
- Not recommended

## Best Practices

### Security

**✅ DO:**
- Enable user verification (required or preferred)
- Use short attestation timeout (60s)
- Avoid same-authenticator reuse
- Require multiple authenticators for admins
- Enable recovery codes
- Monitor failed WebAuthn attempts
- Log authentication events
- Use HTTPS (required for WebAuthn)

**❌ DON'T:**
- Disable user verification
- Allow unlimited attestation time
- Skip backup/recovery options
- Ignore failed attempts
- Use HTTP (breaks WebAuthn)
- Mix passwordless and password flows confusingly

### User Experience

**✅ DO:**
- Support both platform and cross-platform
- Provide clear instructions
- Show device compatibility
- Offer recovery options
- Allow multiple authenticators
- Test on real devices
- Provide help documentation

**❌ DON'T:**
- Force single device type
- Make registration confusing
- Skip recovery setup
- Ignore device limitations
- Assume all users have same devices
- Require security key for everyone

### Implementation

**✅ DO:**
- Start with passwordless for new users
- Gradually migrate existing users
- Offer both password and passkey
- Monitor adoption rates
- Support biometric fallbacks
- Test cross-browser
- Test mobile devices

**❌ DON'T:**
- Force immediate migration
- Remove password option prematurely
- Ignore browser support
- Skip mobile testing
- Assume perfect hardware support
- Rush deployment

## Troubleshooting

### Common Issues

**WebAuthn not working:**
1. Check HTTPS enabled (required)
2. Verify browser supports WebAuthn
3. Check user has registered authenticator
4. Review authentication logs
5. Test with different authenticator

**Passkey not syncing:**
1. Check device OS version (iOS 16+, Android 9+)
2. Verify cloud sync enabled on device
3. Check browser support (Safari, Chrome, Edge)
4. Try alternative browser

**Security key not recognized:**
1. Check key properly inserted/connected
2. Try different USB port
3. Test on different device
4. Verify key not locked
5. Check key firmware updated

**Biometric failing:**
1. Ensure user has biometric enrolled
2. Check for fingerprints/clean sensor
3. Try alternative biometric
4. Fall back to PIN if available
5. Re-enroll biometric if needed

### Debug Logging

**Enable WebAuthn logging:**
```bash
bin/kc.sh start-dev \
  --log-level=org.keycloak.authentication:DEBUG \
  --log-level=org.keycloak.keys:DEBUG \
  --log-level=org.keycloak.models.WebAuthn:DEBUG
```

## Browser Support

### Desktop Browsers

| Browser | WebAuthn | Passkeys | Version |
|---------|----------|----------|---------|
| Chrome | ✅ | ✅ | 67+ |
| Edge | ✅ | ✅ | 18+ |
| Firefox | ✅ | ⚠️ | 60+ |
| Safari | ✅ | ✅ | 13+ |

### Mobile Browsers

| Browser | WebAuthn | Passkeys | Platform |
|---------|----------|----------|----------|
| Safari iOS | ✅ | ✅ | iOS 16+ |
| Chrome Android | ✅ | ✅ | Android 9+ |
| Edge Android | ✅ | ✅ | Android 9+ |

**Note:** Firefox has limited passkey support as of 2025.

## Security Considerations

### Threat Model

**WebAuthn protects against:**
- ✅ Phishing attacks
- ✅ Credential stuffing
- ✅ Password reuse
- ✅ Man-in-the-middle attacks
- ✅ Data breaches

**WebAuthn doesn't protect against:**
- ❌ Device theft (without biometric/PIN)
- ❌ User coercion
- ❌ Server-side vulnerabilities
- ❌ Session hijacking

### Risk Mitigation

**Complement WebAuthn with:**
- Device binding (trust on first use)
- IP-based risk scoring
- Behavioral analytics
- Session limits
- Account recovery verification

## Migration Strategy

### Phase 1: Enable 2FA (Weeks 1-4)
1. Enable WebAuthn authenticator
2. Require for admin users
3. Offer optional for all users
4. Monitor adoption and support

### Phase 2: Passwordless Pilot (Weeks 5-8)
1. Enable passwordless flow
2. Pilot with test group
3. Gather user feedback
4. Refine process and documentation

### Phase 3: Gradual Rollout (Weeks 9-16)
1. Offer passwordless to all users
2. Support both password and passkey
3. Monitor success rates
4. Optimize user experience

### Phase 4: Full Migration (Weeks 17+)
1. Make passwordless default
2. Deprecate passwords gradually
3. Maintain password fallback
4. Achieve 90%+ passkey adoption

## References

- <https://www.keycloak.org/docs/latest/server_admin/#passkeys>
- <https://www.keycloak.org/docs/latest/server_admin/#recovery-codes>
- WebAuthn Specification (W3C)
- FIDO2 Specification
- Passkeys documentation

## Related

- [[keycloak-authentication-flows]]
- [[keycloak-security]]
- [[keycloak-server-administration]]
