/// App configuration constants
class AppConfig {
  // Private constructor to prevent instantiation
  AppConfig._();

  /// Google Maps API Key
  /// In production, load this from environment variables or secure storage
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyAmcx9_fozn4B-aaUm9nWVgHp_IWvUuFiY',
  );

  /// Firebase configuration (if needed for web)
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  static const String firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: '',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: '',
  );

  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );

  static const String firebaseAppId = String.fromEnvironment(
    'FIREBASE_APP_ID',
    defaultValue: '',
  );

  /// Check if running in debug mode
  static const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;

  /// API endpoints (if you have a backend)
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.redpulse.com',
  );
}
