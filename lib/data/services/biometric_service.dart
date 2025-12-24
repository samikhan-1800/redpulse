import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for handling biometric authentication
class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if device supports biometric authentication
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Authenticate using biometrics with timeout
  Future<bool> authenticate({
    String localizedReason = 'Please authenticate to continue',
    bool useErrorDialogs = true,
    bool stickyAuth = true,
  }) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      // Check if biometrics are enrolled
      final availableBiometrics = await getAvailableBiometrics();
      if (availableBiometrics.isEmpty) {
        return false;
      }

      // Add timeout to prevent hanging
      return await _localAuth
          .authenticate(
            localizedReason: localizedReason,
            options: AuthenticationOptions(
              useErrorDialogs: useErrorDialogs,
              stickyAuth: stickyAuth,
              biometricOnly: false,
            ),
          )
          .timeout(const Duration(seconds: 30), onTimeout: () => false);
    } on PlatformException catch (e) {
      // Handle specific error codes
      if (e.code == 'NotEnrolled' || e.code == 'NotAvailable') {
        return false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Save user credentials for biometric login
  Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('biometric_email', email);
    await prefs.setString('biometric_password', password);
  }

  /// Get saved credentials
  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('biometric_email');
    final password = prefs.getString('biometric_password');

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  /// Clear saved credentials
  Future<void> clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('biometric_email');
    await prefs.remove('biometric_password');
  }

  /// Check if biometric is enabled for current user
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled') ?? false;
  }

  /// Enable/disable biometric authentication
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', enabled);
  }
}
