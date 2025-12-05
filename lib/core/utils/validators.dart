import '../constants/app_constants.dart';
import '../constants/app_strings.dart';

/// Form validation utilities
class Validators {
  Validators._();

  /// Validate email address
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value)) {
      return AppStrings.invalidEmail;
    }
    return null;
  }

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value.length < AppConstants.minPasswordLength) {
      return AppStrings.invalidPassword;
    }
    return null;
  }

  /// Validate password confirmation
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value != password) {
      return AppStrings.passwordsDoNotMatch;
    }
    return null;
  }

  /// Validate required field
  static String? validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    return null;
  }

  /// Validate name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (value.length > AppConstants.maxNameLength) {
      return 'Name must be less than ${AppConstants.maxNameLength} characters';
    }
    final nameRegex = RegExp(r'^[a-zA-Z\s]+$');
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  /// Validate phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    if (!phoneRegex.hasMatch(value.replaceAll(' ', ''))) {
      return AppStrings.invalidPhoneNumber;
    }
    return null;
  }

  /// Validate age
  static String? validateAge(int? age) {
    if (age == null) {
      return AppStrings.fieldRequired;
    }
    if (age < AppConstants.minAge) {
      return 'You must be at least ${AppConstants.minAge} years old to donate blood';
    }
    if (age > AppConstants.maxAge) {
      return 'You must be under ${AppConstants.maxAge} years old to donate blood';
    }
    return null;
  }

  /// Validate blood group
  static String? validateBloodGroup(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    if (!AppConstants.bloodGroups.contains(value)) {
      return 'Please select a valid blood group';
    }
    return null;
  }

  /// Validate units required
  static String? validateUnitsRequired(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.fieldRequired;
    }
    final units = int.tryParse(value);
    if (units == null || units < 1) {
      return 'Please enter a valid number of units (minimum 1)';
    }
    if (units > 10) {
      return 'Maximum 10 units can be requested at once';
    }
    return null;
  }

  /// Validate date (for required by date)
  static String? validateFutureDate(DateTime? date) {
    if (date == null) {
      return AppStrings.fieldRequired;
    }
    if (date.isBefore(DateTime.now())) {
      return 'Date must be in the future';
    }
    return null;
  }

  /// Validate bio
  static String? validateBio(String? value) {
    if (value != null && value.length > AppConstants.maxBioLength) {
      return 'Bio must be less than ${AppConstants.maxBioLength} characters';
    }
    return null;
  }
}
