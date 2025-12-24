import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/blood_request_model.dart';
import '../models/donation_model.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../../core/constants/app_constants.dart';

/// Abstract Firestore service interface
/// Allows easy swapping of database providers in the future
abstract class DatabaseServiceInterface {
  // User operations
  Future<void> createUser(UserModel user);
  Future<UserModel?> getUser(String userId);
  Future<void> updateUser(String userId, Map<String, dynamic> data);
  Future<void> deleteUser(String userId);
  Stream<UserModel?> userStream(String userId);
  Future<List<UserModel>> getNearbyDonors(
    double latitude,
    double longitude,
    String bloodGroup,
    double radiusKm,
  );

  // Blood request operations
  Future<String> createRequest(BloodRequest request);
  Future<BloodRequest?> getRequest(String requestId);
  Future<void> updateRequest(String requestId, Map<String, dynamic> data);
  Future<void> deleteRequest(String requestId);
  Stream<List<BloodRequest>> userRequestsStream(String userId);
  Stream<List<BloodRequest>> nearbyRequestsStream(
    double latitude,
    double longitude,
    double radiusKm,
  );
  Future<List<BloodRequest>> getActiveRequests();

  // Donation operations
  Future<String> createDonation(Donation donation);
  Stream<List<Donation>> userDonationsStream(String userId);
  Future<List<Donation>> getUserDonations(String userId);

  // Chat operations
  Future<String> createChat(Chat chat);
  Future<Chat?> getChat(String chatId);
  Stream<List<Chat>> userChatsStream(String userId);
  Future<void> updateChatLastMessage(
    String chatId,
    String message,
    String senderId,
  );
  Future<void> deleteChat(String chatId);

  // Message operations
  Future<String> sendMessage(Message message);
  Stream<List<Message>> messagesStream(String chatId);
  Future<void> markMessagesAsRead(String chatId, String userId);

  // Notification operations
  Future<void> createNotification(NotificationModel notification);
  Stream<List<NotificationModel>> notificationsStream(String userId);
  Future<void> markNotificationAsRead(String notificationId);
  Future<void> markAllNotificationsAsRead(String userId);
}

/// Firebase Firestore Service Implementation
class DatabaseService implements DatabaseServiceInterface {
  final FirebaseFirestore _firestore;

  DatabaseService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(AppConstants.usersCollection);

  CollectionReference<Map<String, dynamic>> get _requestsCollection =>
      _firestore.collection(AppConstants.requestsCollection);

  CollectionReference<Map<String, dynamic>> get _donationsCollection =>
      _firestore.collection(AppConstants.donationsCollection);

  CollectionReference<Map<String, dynamic>> get _chatsCollection =>
      _firestore.collection(AppConstants.chatsCollection);

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection(AppConstants.notificationsCollection);

  // ============ User Operations ============

  @override
  Future<void> createUser(UserModel user) async {
    await _usersCollection.doc(user.id).set(user.toFirestore());
  }

  @override
  Future<UserModel?> getUser(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  @override
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _usersCollection.doc(userId).update(data);
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _usersCollection.doc(userId).delete();
  }

  @override
  Stream<UserModel?> userStream(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  @override
  Future<List<UserModel>> getNearbyDonors(
    double latitude,
    double longitude,
    String bloodGroup,
    double radiusKm,
  ) async {
    // Get compatible blood groups
    final compatibleGroups =
        AppConstants.bloodCompatibility[bloodGroup] ?? [bloodGroup];

    // Query users who can donate
    final querySnapshot = await _usersCollection
        .where('isAvailable', isEqualTo: true)
        .where('bloodGroup', whereIn: compatibleGroups)
        .get();

    final donors = querySnapshot.docs
        .map((doc) => UserModel.fromFirestore(doc))
        .where((user) {
          if (!user.hasLocation) return false;
          // Calculate distance (simplified)
          final distance = _calculateDistance(
            latitude,
            longitude,
            user.latitude!,
            user.longitude!,
          );
          return distance <= radiusKm && user.canDonate;
        })
        .toList();

    // Sort by distance
    donors.sort((a, b) {
      final distA = _calculateDistance(
        latitude,
        longitude,
        a.latitude!,
        a.longitude!,
      );
      final distB = _calculateDistance(
        latitude,
        longitude,
        b.latitude!,
        b.longitude!,
      );
      return distA.compareTo(distB);
    });

    return donors;
  }

  // ============ Blood Request Operations ============

  @override
  Future<String> createRequest(BloodRequest request) async {
    final docRef = await _requestsCollection.add(request.toFirestore());
    return docRef.id;
  }

  @override
  Future<BloodRequest?> getRequest(String requestId) async {
    final doc = await _requestsCollection.doc(requestId).get();
    if (!doc.exists) return null;
    return BloodRequest.fromFirestore(doc);
  }

  @override
  Future<void> updateRequest(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    data['updatedAt'] = Timestamp.now();
    await _requestsCollection.doc(requestId).update(data);
  }

  @override
  Future<void> deleteRequest(String requestId) async {
    await _requestsCollection.doc(requestId).delete();
  }

  @override
  Stream<List<BloodRequest>> userRequestsStream(String userId) {
    return _requestsCollection
        .where('requesterId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => BloodRequest.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Stream<List<BloodRequest>> nearbyRequestsStream(
    double latitude,
    double longitude,
    double radiusKm,
  ) {
    return _requestsCollection
        .where('status', isEqualTo: AppConstants.statusPending)
        .orderBy('createdAt', descending: true)
        .limit(50) // Limit to prevent too much data
        .snapshots()
        .map((snapshot) {
          final requests = snapshot.docs
              .map((doc) => BloodRequest.fromFirestore(doc))
              .where((request) {
                // Calculate distance
                final distance = _calculateDistance(
                  latitude,
                  longitude,
                  request.latitude,
                  request.longitude,
                );

                // Show all requests within radius
                return distance <= radiusKm;
              })
              .toList();

          // Sort by urgency and distance
          requests.sort((a, b) {
            // Priority: SOS > Emergency > Normal
            final priorityA = _getRequestPriority(a.requestType);
            final priorityB = _getRequestPriority(b.requestType);
            if (priorityA != priorityB) return priorityB.compareTo(priorityA);

            // Then by urgency level
            final urgencyA = _getUrgencyPriority(a.urgencyLevel);
            final urgencyB = _getUrgencyPriority(b.urgencyLevel);
            if (urgencyA != urgencyB) return urgencyB.compareTo(urgencyA);

            // Then by distance
            final distA = _calculateDistance(
              latitude,
              longitude,
              a.latitude,
              a.longitude,
            );
            final distB = _calculateDistance(
              latitude,
              longitude,
              b.latitude,
              b.longitude,
            );
            return distA.compareTo(distB);
          });

          return requests;
        });
  }

  @override
  Future<List<BloodRequest>> getActiveRequests() async {
    final snapshot = await _requestsCollection
        .where(
          'status',
          whereIn: [AppConstants.statusPending, AppConstants.statusAccepted],
        )
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => BloodRequest.fromFirestore(doc)).toList();
  }

  // ============ Donation Operations ============

  @override
  Future<String> createDonation(Donation donation) async {
    final docRef = await _donationsCollection.add(donation.toFirestore());
    return docRef.id;
  }

  @override
  Stream<List<Donation>> userDonationsStream(String userId) {
    return _donationsCollection
        .where('donorId', isEqualTo: userId)
        .orderBy('donationDate', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Donation.fromFirestore(doc)).toList(),
        );
  }

  @override
  Future<List<Donation>> getUserDonations(String userId) async {
    final snapshot = await _donationsCollection
        .where('donorId', isEqualTo: userId)
        .orderBy('donationDate', descending: true)
        .get();

    return snapshot.docs.map((doc) => Donation.fromFirestore(doc)).toList();
  }

  // ============ Chat Operations ============

  @override
  Future<String> createChat(Chat chat) async {
    final docRef = await _chatsCollection.add(chat.toFirestore());
    return docRef.id;
  }

  @override
  Future<Chat?> getChat(String chatId) async {
    final doc = await _chatsCollection.doc(chatId).get();
    if (!doc.exists) return null;
    return Chat.fromFirestore(doc);
  }

  @override
  Stream<List<Chat>> userChatsStream(String userId) {
    return _chatsCollection
        .where('participantIds', arrayContains: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Chat.fromFirestore(doc)).toList(),
        );
  }

  @override
  Future<void> updateChatLastMessage(
    String chatId,
    String message,
    String senderId,
  ) async {
    await _chatsCollection.doc(chatId).update({
      'lastMessage': message,
      'lastMessageTime': Timestamp.now(),
      'lastMessageSenderId': senderId,
      'updatedAt': Timestamp.now(),
    });
  }

  @override
  Future<void> deleteChat(String chatId) async {
    // Delete all messages in the chat first
    final messagesSnapshot = await _chatsCollection
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .get();

    final batch = _firestore.batch();
    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete the chat document
    batch.delete(_chatsCollection.doc(chatId));

    await batch.commit();
  }

  // ============ Message Operations ============

  @override
  Future<String> sendMessage(Message message) async {
    final docRef = await _chatsCollection
        .doc(message.chatId)
        .collection(AppConstants.messagesCollection)
        .add(message.toFirestore());

    // Update chat last message
    await updateChatLastMessage(
      message.chatId,
      message.content,
      message.senderId,
    );

    // Get chat participants to send notification
    final chat = await getChat(message.chatId);
    if (chat != null) {
      final recipientId = chat.participantIds.firstWhere(
        (id) => id != message.senderId,
        orElse: () => '',
      );

      if (recipientId.isNotEmpty) {
        // Create notification for recipient
        await _notificationsCollection.add({
          'userId': recipientId,
          'title': '💬 New Message',
          'body': '${message.senderName}: ${message.content}',
          'data': {'type': 'message', 'chatId': message.chatId},
          'isRead': false,
          'createdAt': Timestamp.now(),
          'type': 'message',
        });
      }
    }

    return docRef.id;
  }

  @override
  Stream<List<Message>> messagesStream(String chatId) {
    return _chatsCollection
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .handleError((error) {
          print('Error in messagesStream: $error');
          return <Message>[];
        })
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList(),
        );
  }

  @override
  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final batch = _firestore.batch();

    final unreadMessages = await _chatsCollection
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    for (final doc in unreadMessages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    // Reset unread count for user
    batch.update(_chatsCollection.doc(chatId), {'unreadCount.$userId': 0});

    await batch.commit();
  }

  // ============ Notification Operations ============

  @override
  Future<void> createNotification(NotificationModel notification) async {
    await _notificationsCollection.add(notification.toFirestore());
  }

  @override
  Stream<List<NotificationModel>> notificationsStream(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList(),
        );
  }

  @override
  Future<void> markNotificationAsRead(String notificationId) async {
    await _notificationsCollection.doc(notificationId).update({'isRead': true});
  }

  @override
  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = _firestore.batch();

    final notifications = await _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in notifications.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  // ============ Helper Methods ============

  /// Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0; // Earth's radius in kilometers

    // Convert degrees to radians
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    // Haversine formula
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    final distance = earthRadius * c;

    return distance;
  }

  double _toRadians(double degree) => degree * math.pi / 180;

  int _getRequestPriority(String type) {
    switch (type) {
      case AppConstants.typeSOS:
        return 3;
      case AppConstants.typeEmergency:
        return 2;
      case AppConstants.typeNormal:
        return 1;
      default:
        return 0;
    }
  }

  int _getUrgencyPriority(String urgency) {
    switch (urgency) {
      case AppConstants.urgencyCritical:
        return 4;
      case AppConstants.urgencyHigh:
        return 3;
      case AppConstants.urgencyMedium:
        return 2;
      case AppConstants.urgencyLow:
        return 1;
      default:
        return 0;
    }
  }
}
