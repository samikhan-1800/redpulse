import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String content;
  final String type;
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

  bool isFromUser(String userId) => senderId == userId;

  bool get isText => type == 'text';

  bool get isImage => type == 'image';

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
