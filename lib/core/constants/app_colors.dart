import 'package:flutter/material.dart';

/// Centralized color scheme for the application
/// Using blood/medical themed colors for a professional look
class AppColors {
  AppColors._();

  // Primary Colors - Blood Red Theme
  static const Color primary = Color(0xFFD32F2F);
  static const Color primaryLight = Color(0xFFFF6659);
  static const Color primaryDark = Color(0xFF9A0007);
  static const Color primaryVariant = Color(0xFFB71C1C);

  // Secondary Colors - Medical Blue
  static const Color secondary = Color(0xFF1976D2);
  static const Color secondaryLight = Color(0xFF63A4FF);
  static const Color secondaryDark = Color(0xFF004BA0);

  // Accent Colors
  static const Color accent = Color(0xFFE91E63);
  static const Color accentLight = Color(0xFFFF6090);
  static const Color accentDark = Color(0xFFB0003A);

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surface = Color(0xFFFFFBF5);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundDark = Color(0xFF2C2C2C);

  // AppBar and Navigation Colors
  static const Color appBarBackground = Color(0xFFFFFFFF);
  static const Color navBarBackground = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFFB0B0B0);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Blood Group Colors
  static const Color bloodGroupA = Color(0xFFE53935);
  static const Color bloodGroupB = Color(0xFF1E88E5);
  static const Color bloodGroupAB = Color(0xFF8E24AA);
  static const Color bloodGroupO = Color(0xFF43A047);

  // Request Type Colors
  static const Color emergency = Color(0xFFD32F2F);
  static const Color normal = Color(0xFF1976D2);
  static const Color sos = Color(0xFFFF5722);

  // Urgency Colors
  static const Color urgencyLow = Color(0xFF4CAF50);
  static const Color urgencyMedium = Color(0xFFFFC107);
  static const Color urgencyHigh = Color(0xFFFF9800);
  static const Color urgencyCritical = Color(0xFFF44336);

  // Status Colors for Requests
  static const Color statusPending = Color(0xFFFFC107);
  static const Color statusAccepted = Color(0xFF2196F3);
  static const Color statusCompleted = Color(0xFF4CAF50);
  static const Color statusCancelled = Color(0xFF9E9E9E);
  static const Color statusExpired = Color(0xFF795548);

  // Misc Colors
  static const Color divider = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );

  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [emergency, Color(0xFFB71C1C)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFF5F5F5)],
  );

  /// Get color for blood group
  static Color getBloodGroupColor(String bloodGroup) {
    if (bloodGroup.startsWith('A')) {
      return bloodGroup.contains('B') ? bloodGroupAB : bloodGroupA;
    } else if (bloodGroup.startsWith('B')) {
      return bloodGroupB;
    } else {
      return bloodGroupO;
    }
  }

  /// Get color for urgency level
  static Color getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'low':
        return urgencyLow;
      case 'medium':
        return urgencyMedium;
      case 'high':
        return urgencyHigh;
      case 'critical':
        return urgencyCritical;
      default:
        return urgencyMedium;
    }
  }

  /// Get color for request status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return statusPending;
      case 'accepted':
        return statusAccepted;
      case 'completed':
        return statusCompleted;
      case 'cancelled':
        return statusCancelled;
      case 'expired':
        return statusExpired;
      default:
        return statusPending;
    }
  }
}
