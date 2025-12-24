import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../models/blood_request_model.dart';
import 'auth_provider.dart';

/// Provider for chat messages stream
final chatMessagesProvider = StreamProvider.family<List<Message>, String>((
  ref,
  chatId,
) {
  final databaseService = ref.watch(databaseServiceProvider);
  return databaseService.messagesStream(chatId);
});

/// Chat notifier for managing chat operations
class ChatNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _databaseService;
  final NotificationService _notificationService;
  final String? _userId;
  final UserModel? _currentUser;

  ChatNotifier(
    this._databaseService,
    this._notificationService,
    this._userId,
    this._currentUser,
  ) : super(const AsyncValue.data(null));

  /// Start a chat for a blood request
  Future<Chat?> startChatForRequest(BloodRequest request) async {
    if (_userId == null || _currentUser == null) return null;

    try {
      // Create a new chat
      final now = DateTime.now();
      final chat = Chat(
        id: '',
        requestId: request.id,
        participantIds: [_userId, request.requesterId],
        participantNames: {
          _userId: _currentUser.name,
          request.requesterId: request.requesterName,
        },
        participantImages: {
          _userId: _currentUser.profileImageUrl,
          request.requesterId: request.requesterImageUrl,
        },
        unreadCount: {_userId: 0, request.requesterId: 0},
        createdAt: now,
        updatedAt: now,
      );

      final chatId = await _databaseService.createChat(chat);
      return chat.copyWith(id: chatId);
    } catch (e) {
      return null;
    }
  }

  /// Send a text message
  Future<void> sendMessage({
    required String chatId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    if (_userId == null || _currentUser == null) return;

    try {
      final message = Message(
        id: '',
        chatId: chatId,
        senderId: _userId,
        senderName: _currentUser.name,
        content: content,
        type: type,
        createdAt: DateTime.now(),
        metadata: metadata,
      );

      await _databaseService.sendMessage(message);

      // Send notification to the other user
      final chat = await _databaseService.getChat(chatId);
      if (chat != null) {
        final recipientId = chat.user1Id == _userId
            ? chat.user2Id
            : chat.user1Id;

        await _notificationService.sendNotificationToUser(
          userId: recipientId,
          title: '💬 ${_currentUser.name}',
          body: content.length > 100
              ? '${content.substring(0, 100)}...'
              : content,
          data: {'type': 'message', 'chatId': chatId, 'senderId': _userId},
        );
      }
    } catch (e) {
      // Handle error silently for chat messages
    }
  }

  /// Send location message
  Future<void> sendLocationMessage({
    required String chatId,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    await sendMessage(
      chatId: chatId,
      content: address,
      type: 'location',
      metadata: {'latitude': latitude, 'longitude': longitude},
    );
  }

  /// Mark messages as read
  Future<void> markAsRead(String chatId, String? userId) async {
    final uid = userId ?? _userId;
    if (uid == null) return;

    try {
      await _databaseService.markMessagesAsRead(chatId, uid);
    } catch (e) {
      // Handle error silently
    }
  }
}

/// Chat notifier provider
final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, AsyncValue<void>>((ref) {
      final currentUser = ref.watch(currentUserProfileProvider).value;
      return ChatNotifier(
        ref.watch(databaseServiceProvider),
        ref.watch(notificationServiceProvider),
        ref.watch(currentUserIdProvider),
        currentUser,
      );
    });

/// User's chats stream provider
final userChatsProvider = StreamProvider<List<Chat>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final databaseService = ref.watch(databaseServiceProvider);
  return databaseService.userChatsStream(userId);
});

/// Messages stream provider for a specific chat
final messagesProvider = StreamProvider.family<List<Message>, String>((
  ref,
  chatId,
) {
  final databaseService = ref.watch(databaseServiceProvider);
  return databaseService.messagesStream(chatId);
});

/// Single chat provider
final chatDetailProvider = FutureProvider.family<Chat?, String>((
  ref,
  chatId,
) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getChat(chatId);
});

/// Unread messages count provider
final unreadMessagesCountProvider = Provider<int>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  final chats = ref.watch(userChatsProvider).value ?? [];

  if (userId == null) return 0;

  return chats.fold(0, (sum, chat) => sum + chat.getUnreadCount(userId));
});
