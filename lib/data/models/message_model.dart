import 'package:cloud_firestore/cloud_firestore.dart';

/// Message model for chat
class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String content;
  final String type; // text, image, location
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? metadata;

  Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.type = 'text',
    required this.createdAt,
    this.isRead = false,
    this.metadata,
  });

  /// Create from Firestore document
  factory Message.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      return Message(
        id: doc.id,
        chatId: data['chatId'] ?? '',
        senderId: data['senderId'] ?? '',
        senderName: data['senderName'] ?? 'Unknown',
        content: data['content'] ?? '',
        type: data['type'] ?? 'text',
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
        isRead: data['isRead'] ?? false,
        metadata: data['metadata'],
      );
    } catch (e) {
      print('Error parsing message from Firestore: $e');
      // Return a fallback message instead of crashing
      return Message(
        id: doc.id,
        chatId: '',
        senderId: '',
        senderName: 'Error',
        content: 'Failed to load message',
        createdAt: DateTime.now(),
      );
    }
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'type': type,
      'createdAt': Timestamp.fromDate(createdAt),
      'isRead': isRead,
      'metadata': metadata,
    };
  }

  /// Copy with modified fields
  Message copyWith({
    String? id,
    String? chatId,
    String? senderId,
    String? senderName,
    String? content,
    String? type,
    DateTime? createdAt,
    bool? isRead,
    Map<String, dynamic>? metadata,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      content: content ?? this.content,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if message is from current user
  bool isFromUser(String userId) => senderId == userId;

  /// Check if message is text
  bool get isText => type == 'text';

  /// Check if message is image
  bool get isImage => type == 'image';

  /// Check if message is location
  bool get isLocation => type == 'location';

  @override
  String toString() {
    return 'Message(id: $id, senderId: $senderId, content: $content)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
