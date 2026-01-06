class BiometricAuthResult {
  final bool success;
  final BiometricErrorType? errorType;
  final String? errorMessage;

  const BiometricAuthResult({
    required this.success,
    this.errorType,
    this.errorMessage,
  });

  factory BiometricAuthResult.success() {
    return const BiometricAuthResult(success: true);
  }

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

enum BiometricErrorType {
  notEnrolled,

  notAvailable,

  userCancelled,

  lockedOut,

  permanentlyLockedOut,

  timeout,

  other,
}
