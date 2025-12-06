import 'package:cloud_firestore/cloud_firestore.dart';

/// Chat model for donor-recipient communication
class Chat {
  final String id;
  final String requestId;
  final List<String> participantIds;
  final Map<String, String> participantNames;
  final Map<String, String?> participantImages;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Chat({
    required this.id,
    required this.requestId,
    required this.participantIds,
    required this.participantNames,
    required this.participantImages,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    required this.unreadCount,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  /// Create from Firestore document
  factory Chat.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return Chat(
        id: doc.id,
        requestId: data['requestId'] ?? '',
        participantIds: List<String>.from(data['participantIds'] ?? []),
        participantNames: Map<String, String>.from(
          data['participantNames'] ?? {},
        ),
        participantImages: Map<String, String?>.from(
          data['participantImages'] ?? {},
        ),
        lastMessage: data['lastMessage'],
        lastMessageTime: data['lastMessageTime'] != null
            ? (data['lastMessageTime'] as Timestamp).toDate()
            : null,
        lastMessageSenderId: data['lastMessageSenderId'],
        unreadCount: Map<String, int>.from(data['unreadCount'] ?? {}),
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        updatedAt: data['updatedAt'] != null
            ? (data['updatedAt'] as Timestamp).toDate()
            : DateTime.now(),
        isActive: data['isActive'] ?? true,
      );
    } catch (e) {
      print('Error parsing chat from Firestore: $e');
      // Return a fallback chat instead of crashing
      return Chat(
        id: doc.id,
        requestId: '',
        participantIds: [],
        participantNames: {},
        participantImages: {},
        unreadCount: {},
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'requestId': requestId,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'participantImages': participantImages,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime != null
          ? Timestamp.fromDate(lastMessageTime!)
          : null,
      'lastMessageSenderId': lastMessageSenderId,
      'unreadCount': unreadCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }

  /// Get other participant ID
  String getOtherParticipantId(String currentUserId) {
    return participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
  }

  /// Get other participant name
  String getOtherParticipantName(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantNames[otherId] ?? 'Unknown';
  }

  /// Get other participant image
  String? getOtherParticipantImage(String currentUserId) {
    final otherId = getOtherParticipantId(currentUserId);
    return participantImages[otherId];
  }

  /// Get unread count for user
  int getUnreadCount(String userId) {
    return unreadCount[userId] ?? 0;
  }

  /// Copy with modified fields
  Chat copyWith({
    String? id,
    String? requestId,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    Map<String, String?>? participantImages,
    String? lastMessage,
    DateTime? lastMessageTime,
    String? lastMessageSenderId,
    Map<String, int>? unreadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Chat(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      participantImages: participantImages ?? this.participantImages,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'Chat(id: $id, requestId: $requestId, participants: $participantIds)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Chat && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
