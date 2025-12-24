/// Result of biometric authentication attempt
class BiometricAuthResult {
  final bool success;
  final BiometricErrorType? errorType;
  final String? errorMessage;

  const BiometricAuthResult({
    required this.success,
    this.errorType,
    this.errorMessage,
  });

  /// Success result
  factory BiometricAuthResult.success() {
    return const BiometricAuthResult(success: true);
  }

  /// Failure result with error type and message
  factory BiometricAuthResult.failure({
    required BiometricErrorType errorType,
    String? errorMessage,
  }) {
    return BiometricAuthResult(
      success: false,
      errorType: errorType,
      errorMessage: errorMessage,
    );
  }

  /// Get user-friendly error message
  String get userMessage {
    if (success) return 'Authentication successful';

    switch (errorType) {
      case BiometricErrorType.notEnrolled:
        return 'No fingerprint or face data found. Please add biometric authentication in your device settings first.';
      case BiometricErrorType.notAvailable:
        return 'Biometric authentication is not available on this device.';
      case BiometricErrorType.userCancelled:
        return 'Authentication was cancelled.';
      case BiometricErrorType.lockedOut:
        return 'Too many failed attempts. Please wait and try again.';
      case BiometricErrorType.permanentlyLockedOut:
        return 'Biometric authentication is locked. Please unlock your device with PIN/password first.';
      case BiometricErrorType.timeout:
        return 'Authentication timed out. Please try again.';
      case BiometricErrorType.other:
        return errorMessage ?? 'Authentication failed. Please try again.';
      case null:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Types of biometric authentication errors
enum BiometricErrorType {
  /// No biometrics enrolled on device
  notEnrolled,

  /// Biometric hardware not available
  notAvailable,

  /// User cancelled the authentication
  userCancelled,

  /// Temporarily locked out due to too many attempts
  lockedOut,

  /// Permanently locked out
  permanentlyLockedOut,

  /// Authentication timed out
  timeout,

  /// Other/unknown error
  other,
}
