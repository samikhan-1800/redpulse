# Google Maps API Key Setup

## Security Setup

Your Google Maps API Key has been configured securely and will NOT be committed to GitHub.

### Files Protected (in .gitignore):
- `.env` - Contains your actual API key
- `android/local.properties` - Contains Android-specific configuration
- `android/key.properties` - Signing keys (if created)
- `ios/Runner/GoogleService-Info.plist` - Firebase iOS config

### Files You CAN Commit:
- `.env.example` - Template without real keys
- All other configuration files

## Setup Instructions for New Developers

If someone clones this repository, they need to:

1. **Copy the example environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Add their own Google Maps API Key to `.env`:**
   ```
   GOOGLE_MAPS_API_KEY=your_actual_api_key_here
   ```

3. **Update `android/local.properties`:**
   Add this line (the file is auto-generated, so add it manually):
   ```
   GOOGLE_MAPS_API_KEY=your_actual_api_key_here
   ```

4. **Update iOS AppDelegate** (if the key isn't there):
   The key is hardcoded in `ios/Runner/AppDelegate.swift` for iOS.
   In production, you should use a more secure method.

## Where the API Key is Used

### Android:
- **Location**: `android/local.properties`
- **Injected into**: `AndroidManifest.xml` via gradle build script
- **Build config**: `android/app/build.gradle.kts` reads from local.properties

### iOS:
- **Location**: `ios/Runner/AppDelegate.swift`
- **Initialized**: When app launches via `GMSServices.provideAPIKey()`

### Flutter Code:
- **Location**: `lib/core/config/app_config.dart`
- **Usage**: Available as `AppConfig.googleMapsApiKey`

## Permissions Added

### Android (AndroidManifest.xml):
- `INTERNET` - Network access
- `ACCESS_FINE_LOCATION` - Precise location
- `ACCESS_COARSE_LOCATION` - Approximate location
- `ACCESS_BACKGROUND_LOCATION` - Background location updates
- `CAMERA` - Profile picture updates
- `READ_EXTERNAL_STORAGE` - Access photos
- `WRITE_EXTERNAL_STORAGE` - Save photos

### iOS (Info.plist):
- `NSLocationWhenInUseUsageDescription` - Location while using app
- `NSLocationAlwaysUsageDescription` - Background location
- `NSLocationAlwaysAndWhenInUseUsageDescription` - Combined permission
- `NSCameraUsageDescription` - Camera access
- `NSPhotoLibraryUsageDescription` - Photo library access

## Important Notes

⚠️ **NEVER commit your actual API key to GitHub!**

The following files contain your real API key and are in `.gitignore`:
- `.env`
- `android/local.properties`

If you accidentally commit them:
1. Remove them from git history
2. Regenerate your API key in Google Cloud Console
3. Update the new key in your local files

## Google Cloud Console Setup

Make sure these APIs are enabled in your Google Cloud Console:
1. Maps SDK for Android
2. Maps SDK for iOS
3. Geocoding API
4. Places API
5. Directions API (if needed)

## Testing

After setup, run:
```bash
flutter clean
flutter pub get
flutter run
```

The maps should load correctly with your API key.
