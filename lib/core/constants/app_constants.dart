class AppConstants {
  AppConstants._();

  static const String appName = 'RedPulse';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Donate Blood, Save Lives';

  static const String usersCollection = 'users';
  static const String requestsCollection = 'blood_requests';
  static const String donationsCollection = 'donations';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String notificationsCollection = 'notifications';

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

  static const String statusPending = 'pending';
  static const String statusAccepted = 'accepted';
  static const String statusCompleted = 'completed';
  static const String statusCancelled = 'cancelled';
  static const String statusExpired = 'expired';

  static const String typeEmergency = 'emergency';
  static const String typeNormal = 'normal';
  static const String typeSOS = 'sos';

  static const String urgencyLow = 'low';
  static const String urgencyMedium = 'medium';
  static const String urgencyHigh = 'high';
  static const String urgencyCritical = 'critical';

  static const double defaultSearchRadius = 10.0;
  static const double maxSearchRadius = 50.0;
  static const double sosSearchRadius = 25.0;

  static const int maleDonationCooldown = 90;
  static const int femaleDonationCooldown = 120;

  static const int defaultPageSize = 20;

  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  static const String imagePath = 'assets/images/';
  static const String iconPath = 'assets/icons/';
  static const String lottiePath = 'assets/lottie/';

  static const int minPasswordLength = 8;
  static const int maxNameLength = 50;
  static const int maxBioLength = 200;
  static const int minAge = 18;
  static const int maxAge = 65;
}
