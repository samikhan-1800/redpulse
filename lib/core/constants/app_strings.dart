/// Centralized strings for the application
/// Easy to maintain and localize
class AppStrings {
  AppStrings._();

  // Auth Strings
  static const String login = 'Login';
  static const String signUp = 'Sign Up';
  static const String logout = 'Logout';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String confirmPassword = 'Confirm Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String resetPassword = 'Reset Password';
  static const String dontHaveAccount = "Don't have an account? ";
  static const String alreadyHaveAccount = 'Already have an account? ';
  static const String loginToContinue = 'Login to continue';
  static const String createAccount = 'Create your account';
  static const String welcomeBack = 'Welcome Back!';
  static const String getStarted = 'Get Started';

  // Profile Strings
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String fullName = 'Full Name';
  static const String phoneNumber = 'Phone Number';
  static const String dateOfBirth = 'Date of Birth';
  static const String gender = 'Gender';
  static const String bloodGroup = 'Blood Group';
  static const String address = 'Address';
  static const String city = 'City';
  static const String bio = 'Bio';
  static const String male = 'Male';
  static const String female = 'Female';
  static const String other = 'Other';
  static const String saveProfile = 'Save Profile';
  static const String updateProfile = 'Update Profile';

  // Navigation Strings
  static const String home = 'Home';
  static const String map = 'Map';
  static const String requests = 'Requests';
  static const String chat = 'Chat';
  static const String settings = 'Settings';

  // Home Screen Strings
  static const String hello = 'Hello';
  static const String availableToDonate = 'Available to Donate';
  static const String notAvailable = 'Not Available';
  static const String nearbyRequests = 'Nearby Requests';
  static const String recentDonations = 'Recent Donations';
  static const String totalDonations = 'Total Donations';
  static const String livesSaved = 'Lives Saved';
  static const String quickActions = 'Quick Actions';

  // Request Strings
  static const String createRequest = 'Create Request';
  static const String emergencyRequest = 'Emergency Request';
  static const String normalRequest = 'Normal Request';
  static const String sosAlert = 'SOS Alert';
  static const String myRequests = 'My Requests';
  static const String allRequests = 'All Requests';
  static const String requestDetails = 'Request Details';
  static const String acceptRequest = 'Accept Request';
  static const String cancelRequest = 'Cancel Request';
  static const String requestFor = 'Request For';
  static const String patientName = 'Patient Name';
  static const String hospitalName = 'Hospital Name';
  static const String unitsRequired = 'Units Required';
  static const String urgencyLevel = 'Urgency Level';
  static const String additionalNotes = 'Additional Notes';
  static const String requiredBy = 'Required By';
  static const String contactNumber = 'Contact Number';

  // Status Strings
  static const String pending = 'Pending';
  static const String accepted = 'Accepted';
  static const String completed = 'Completed';
  static const String cancelled = 'Cancelled';
  static const String expired = 'Expired';

  // Urgency Strings
  static const String low = 'Low';
  static const String medium = 'Medium';
  static const String high = 'High';
  static const String critical = 'Critical';

  // Chat Strings
  static const String messages = 'Messages';
  static const String noMessages = 'No messages yet';
  static const String typeMessage = 'Type a message...';
  static const String send = 'Send';

  // Map Strings
  static const String findDonors = 'Find Donors';
  static const String nearbyDonors = 'Nearby Donors';
  static const String searchRadius = 'Search Radius';
  static const String showDonors = 'Show Donors';
  static const String showRequests = 'Show Requests';
  static const String myLocation = 'My Location';
  static const String directions = 'Directions';

  // Donation Strings
  static const String donationHistory = 'Donation History';
  static const String noDonations = 'No donations yet';
  static const String lastDonation = 'Last Donation';
  static const String nextEligibleDate = 'Next Eligible Date';
  static const String donate = 'Donate';
  static const String donateNow = 'Donate Now';

  // Notification Strings
  static const String notifications = 'Notifications';
  static const String noNotifications = 'No notifications';
  static const String markAllRead = 'Mark all as read';

  // Error Strings
  static const String error = 'Error';
  static const String somethingWentWrong = 'Something went wrong';
  static const String noInternetConnection = 'No internet connection';
  static const String tryAgain = 'Try Again';
  static const String invalidEmail = 'Invalid email address';
  static const String invalidPassword =
      'Password must be at least 8 characters';
  static const String passwordsDoNotMatch = 'Passwords do not match';
  static const String fieldRequired = 'This field is required';
  static const String invalidPhoneNumber = 'Invalid phone number';

  // Success Strings
  static const String success = 'Success';
  static const String profileUpdated = 'Profile updated successfully';
  static const String requestCreated = 'Request created successfully';
  static const String requestAccepted = 'Request accepted successfully';
  static const String requestCancelled = 'Request cancelled';
  static const String passwordResetSent = 'Password reset email sent';

  // Confirmation Strings
  static const String areYouSure = 'Are you sure?';
  static const String confirmLogout = 'Are you sure you want to logout?';
  static const String confirmCancel =
      'Are you sure you want to cancel this request?';
  static const String yes = 'Yes';
  static const String no = 'No';
  static const String ok = 'OK';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';

  // Loading Strings
  static const String loading = 'Loading...';
  static const String pleaseWait = 'Please wait...';
  static const String processing = 'Processing...';

  // Empty State Strings
  static const String noData = 'No data available';
  static const String noRequests = 'No requests found';
  static const String noDonors = 'No donors found nearby';
  static const String noChats = 'No conversations yet';

  // Permission Strings
  static const String locationPermission = 'Location Permission';
  static const String locationPermissionMessage =
      'We need location permission to find nearby donors and requests';
  static const String notificationPermission = 'Notification Permission';
  static const String notificationPermissionMessage =
      'Enable notifications to receive alerts for blood requests';
  static const String allowPermission = 'Allow';
  static const String denyPermission = 'Deny';
}
