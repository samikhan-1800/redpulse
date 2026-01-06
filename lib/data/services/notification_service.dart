import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/app_constants.dart';

class NotificationService {
  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  NotificationService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  Future<String?> initialize() async {
    try {
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
        final token = await _messaging.getToken();
        return token;
      }

      return null;
    } catch (e) {
      print('FCM initialization failed: $e');
      return null;
    }
  }

  Future<void> saveToken(String userId, String token) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update({'fcmToken': token});
    } catch (e) {
      print('Failed to save FCM token: $e');
    }
  }

  void onTokenRefresh(String userId) {
    _messaging.onTokenRefresh.listen((token) {
      saveToken(userId, token);
    });
  }

  Future<void> subscribeToTopic(String topic) async {
    await _messaging.subscribeToTopic(topic);
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    await _messaging.unsubscribeFromTopic(topic);
  }

  void onForegroundMessage(Function(RemoteMessage) callback) {}

  void onMessageOpenedApp(Function(RemoteMessage) callback) {}

  Future<RemoteMessage?> getInitialMessage() async {
    return await _messaging.getInitialMessage();
  }

  Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
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

  Future<void> notifyNearbyDonors({
    required String requestId,
    required String bloodGroup,
    required String hospitalName,
    required String requestType,
    required List<String> donorIds,
  }) async {
    final batch = _firestore.batch();

    final title = requestType == 'sos'
        ? '🚨 SOS: Blood Needed Urgently!'
        : requestType == 'emergency'
        ? '⚠️ Emergency Blood Request'
        : '🩸 Blood Request Nearby';

    final body = '$bloodGroup blood needed at $hospitalName';
    for (final donorId in donorIds) {
      final notificationRef = _firestore
          .collection(AppConstants.notificationsCollection)
          .doc();

      batch.set(notificationRef, {
        'userId': donorId,
        'title': title,
        'body': body,
        'data': {
          'type': 'blood_request',
          'requestId': requestId,
          'bloodGroup': bloodGroup,
          'requestType': requestType,
        },
        'isRead': false,
        'createdAt': Timestamp.now(),
        'type': 'blood_request',
      });
    }

    await batch.commit();
  }
}
