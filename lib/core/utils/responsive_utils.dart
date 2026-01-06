import 'dart:math';
import 'package:flutter/material.dart';

/// Utility class for responsive sizing that works well in both orientations
class ResponsiveUtils {
  static late MediaQueryData _mediaQuery;
  static late double _screenWidth;
  static late double _screenHeight;
  static late bool _isLandscape;

  /// Initialize with the current context
  static void init(BuildContext context) {
    _mediaQuery = MediaQuery.of(context);
    _screenWidth = _mediaQuery.size.width;
    _screenHeight = _mediaQuery.size.height;
    _isLandscape = _mediaQuery.orientation == Orientation.landscape;
  }

  /// Check if device is in landscape mode
  static bool get isLandscape => _isLandscape;

  /// Get the shorter side of the screen (for consistent sizing)
  static double get shortestSide => min(_screenWidth, _screenHeight);

  /// Get the longer side of the screen
  static double get longestSide => max(_screenWidth, _screenHeight);

  /// Get screen width
  static double get screenWidth => _screenWidth;

  /// Get screen height
  static double get screenHeight => _screenHeight;

  /// Scale factor based on shortest side (consistent across orientations)
  static double get scaleFactor => shortestSide / 375;

  /// Get responsive font size (scales consistently)
  static double fontSize(double size) {
    final scale = scaleFactor.clamp(0.8, 1.4);
    return size * scale;
  }

  /// Get responsive size that respects landscape constraints
  static double size(double portraitSize, {double? landscapeSize}) {
    if (_isLandscape) {
      return landscapeSize ?? portraitSize * 0.65;
    }
    return portraitSize;
  }

  /// Get responsive horizontal padding
  static double horizontalPadding({double portrait = 16, double? landscape}) {
    return _isLandscape ? (landscape ?? portrait * 1.5) : portrait;
  }

  /// Get responsive vertical padding
  static double verticalPadding({double portrait = 16, double? landscape}) {
    return _isLandscape ? (landscape ?? portrait * 0.5) : portrait;
  }

  /// Get responsive spacing (vertical)
  static double verticalSpacing(double size) {
    return _isLandscape ? size * 0.5 : size;
  }

  /// Get responsive spacing (horizontal)
  static double horizontalSpacing(double size) {
    return _isLandscape ? size * 1.2 : size;
  }

  /// Get responsive icon size
  static double iconSize(double size) {
    return _isLandscape ? size * 0.75 : size;
  }

  /// Get responsive app bar height
  static double get appBarHeight => _isLandscape ? 48.0 : 56.0;

  /// Get responsive bottom nav height
  static double get bottomNavHeight => _isLandscape ? 52.0 : 65.0;

  /// Get safe area paddings
  static EdgeInsets get safeAreaPadding => _mediaQuery.padding;

  /// Check if keyboard is visible
  static bool get isKeyboardVisible => _mediaQuery.viewInsets.bottom > 0;

  /// Get keyboard height
  static double get keyboardHeight => _mediaQuery.viewInsets.bottom;
}

/// Extension methods for responsive sizing
extension ResponsiveSize on num {
  /// Responsive size that adapts to orientation
  double get rs {
    final scale = ResponsiveUtils.scaleFactor.clamp(0.8, 1.3);
    return toDouble() * scale;
  }

  /// Responsive font size
  double get rf {
    final scale = ResponsiveUtils.scaleFactor.clamp(0.85, 1.2);
    return toDouble() * scale;
  }

  /// Responsive width
  double get rw => ResponsiveUtils.isLandscape ? toDouble() * 0.6 : toDouble();

  /// Responsive height
  double get rh => ResponsiveUtils.isLandscape ? toDouble() * 0.55 : toDouble();

  /// Responsive icon size
  double get ri => ResponsiveUtils.isLandscape ? toDouble() * 0.7 : toDouble();
}
