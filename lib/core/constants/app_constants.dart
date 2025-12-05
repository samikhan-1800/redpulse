/// Application-wide constants
/// Centralized configuration for easy maintenance
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'RedPulse';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Donate Blood, Save Lives';

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String requestsCollection = 'blood_requests';
  static const String donationsCollection = 'donations';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String notificationsCollection = 'notifications';

  // Blood Groups
  static const List<String> bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  // Blood Compatibility Map (who can receive from whom)
  static const Map<String, List<String>> bloodCompatibility = {
    'A+': ['A+', 'A-', 'O+', 'O-'],
    'A-': ['A-', 'O-'],
    'B+': ['B+', 'B-', 'O+', 'O-'],
    'B-': ['B-', 'O-'],
    'AB+': ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'],
    'AB-': ['A-', 'B-', 'AB-', 'O-'],
    'O+': ['O+', 'O-'],
    'O-': ['O-'],
  };

  // Request Status
  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusExpired = 'expired';

  // Request Types
  static const String typeEmergency = 'emergency';
  static const String typeNormal = 'normal';
  static const String typeSOS = 'sos';

  // Urgency Levels
  static const String urgencyLow = 'low';
  static const String urgencyMedium = 'medium';
  static const String urgencyHigh = 'high';
  static const String urgencyCritical = 'critical';

  // Search Radius (in km)
  static const double defaultSearchRadius = 10.0;
  static const double maxSearchRadius = 50.0;
  static const double sosSearchRadius = 25.0;

  // Donation Cooldown (in days)
  static const int maleDonationCooldown = 90;
  static const int femaleDonationCooldown = 120;

  // Pagination
  static const int defaultPageSize = 20;

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Asset Paths
  static const String imagePath = 'assets/images/';
  static const String iconPath = 'assets/icons/';
  static const String lottiePath = 'assets/lottie/';

  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  static const int maxBioLength = 200;
  static const int minAge = 18;
  static const int maxAge = 65;
}
