# Biometric Authentication Troubleshooting

## Problem
Fingerprint toggle shows "Authentication failed or cancelled"

## Common Causes & Solutions

### 1. No Fingerprints Enrolled on Device
**Symptoms:** Authentication immediately fails without showing fingerprint prompt

**Solution:**
1. Go to your device Settings
2. Navigate to **Security** or **Biometrics**
3. Select **Fingerprint** or **Face Recognition**
4. Add at least one fingerprint/face
5. Try enabling biometric in the app again

### 2. Device Doesn't Support Biometrics
**Symptoms:** App says "Biometric authentication is not available"

**Solution:**
- Verify your device has fingerprint scanner or Face ID hardware
- Android: Requires Android 6.0+ with fingerprint hardware
- iOS: Requires iPhone 5s+ with Touch ID or iPhone X+ with Face ID
- Test on a different device if needed

### 3. Permission Issues (Android)
**Symptoms:** Authentication fails on first try

**Solution:**
1. Check if USE_BIOMETRIC permission is granted in app settings
2. Uninstall and reinstall the app
3. Grant biometric permission when prompted

### 4. App Permissions Not Set
**Symptoms:** No fingerprint dialog appears

**Solution:**
1. Go to device Settings → Apps → RedPulse
2. Check Permissions
3. Ensure all required permissions are granted
4. Clear app cache and try again

### 5. Testing on Emulator
**Symptoms:** Always fails on Android emulator

**Solution:**
1. Use Extended Controls in emulator (three dots menu)
2. Go to Fingerprint section
3. Add a virtual fingerprint
4. Try authentication again

### 6. Biometric Hardware Locked
**Symptoms:** "Too many attempts" error

**Solution:**
1. Wait for the timeout period (usually 30 seconds)
2. Unlock device with PIN/Password
3. Try fingerprint again

## Testing Checklist
- [ ] Device has fingerprint hardware
- [ ] At least one fingerprint is enrolled in device settings
- [ ] App has biometric permission
- [ ] Android version is 6.0 or higher
- [ ] Device is unlocked and fingerprint scanner is clean
- [ ] Not too many failed attempts recently

## How It Should Work
1. Toggle switch ON
2. System fingerprint dialog appears immediately
3. Place finger on scanner
4. Success: Toggle stays ON, success message shown
5. Failure: Toggle stays OFF, error message shown

## Current Implementation Details
- Timeout: 30 seconds
- useErrorDialogs: true (shows system error messages)
- stickyAuth: true (requires fingerprint, not PIN fallback)
- biometricOnly: false (allows PIN if biometric fails)

## If Still Not Working
The most common issue is **no fingerprints enrolled**. Please verify in your device settings:
- Android: Settings → Security → Fingerprint
- iOS: Settings → Touch ID & Passcode or Face ID & Passcode
