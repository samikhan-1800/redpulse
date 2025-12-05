import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

/// FCM Notification Service
class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  /// Initialize FCM and get token
  Future<String?> initialize() async {
    // Request permission for iOS
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Get FCM token
      final token = await _messaging.getToken();
      return token;
    }

    return null;
  }

  /// Save FCM token to user document
  Future<void> saveToken(String userId, String token) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({'fcmToken': token});
  }

  /// Listen for token refresh
  void onTokenRefresh(String userId) {
    _messaging.onTokenRefresh.listen((token) {
      saveToken(userId, token);
    });
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  /// Handle foreground messages
  void onForegroundMessage(Function(RemoteMessage) callback) {
    FirebaseMessaging.onMessage.listen(callback);
  }

  /// Handle background/terminated message tap
  void onMessageOpenedApp(Function(RemoteMessage) callback) {
    FirebaseMessaging.onMessageOpenedApp.listen(callback);
  }

  /// Check for initial message (app opened from terminated state)
  Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }

  /// Send notification to specific user (server-side function would handle this)
  /// This is a placeholder - actual sending should be done via Cloud Functions
  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    // Store notification in Firestore
    // A Cloud Function would listen to this and send the actual push notification
    await _firestore.collection(AppConstants.notificationsCollection).add({
      'userId': userId,
      'title': title,
      'body': body,
      'data': data,
      'isRead': false,
      'createdAt': Timestamp.now(),
      'type': data?['type'] ?? 'system',
    });
  }

  /// Send notification to nearby donors
  Future<void> notifyNearbyDonors({
    required String requestId,
    required String bloodGroup,
    required String hospitalName,
    required String requestType,
    required List<String> donorIds,
  }) async {
    final batch = _firestore.batch();

    for (final donorId in donorIds) {
      final notificationRef = _firestore
          .collection(AppConstants.notificationsCollection)
          .doc();

      batch.set(notificationRef, {
        'userId': donorId,
        'title': requestType == 'sos'
            ? '🚨 SOS: Blood Needed Urgently!'
            : requestType == 'emergency'
            ? '⚠️ Emergency Blood Request'
            : '🩸 Blood Request Nearby',
        'body': '$bloodGroup blood needed at $hospitalName',
        'data': {
          'type': 'request',
          'requestId': requestId,
          'bloodGroup': bloodGroup,
        },
        'isRead': false,
        'createdAt': Timestamp.now(),
        'type': 'request',
      });
    }

    await batch.commit();
  }
}
