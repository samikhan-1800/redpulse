import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';

/// Notifications stream provider
final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final databaseService = ref.watch(databaseServiceProvider);
  return databaseService.notificationsStream(userId);
});

/// Unread notifications count provider
final unreadNotificationsCountProvider = Provider<int>((ref) {
  // Handle errors gracefully - return 0 if query fails
  final notificationsAsync = ref.watch(notificationsProvider);
  final notifications =
      notificationsAsync.whenOrNull(data: (data) => data) ?? [];
  return notifications.where((n) => !n.isRead).length;
});

/// Notification notifier for handling FCM initialization
class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final NotificationService _notificationService;
  final String? _userId;

  NotificationNotifier(this._notificationService, this._userId)
    : super(const AsyncValue.data(null));

  /// Initialize notifications
  Future<void> initialize() async {
    if (_userId == null) return;

    try {
      final token = await _notificationService.initialize();
      if (token != null) {
        await _notificationService.saveToken(_userId, token);
      }
    } catch (e) {
      // Silent fail
    }
  }
}

/// Notification notifier provider
final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
      return NotificationNotifier(
        ref.watch(notificationServiceProvider),
        ref.watch(currentUserIdProvider),
      );
    });

/// Notification actions notifier
class NotificationActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _databaseService;
  final String? _userId;

  NotificationActionsNotifier(this._databaseService, this._userId)
    : super(const AsyncValue.data(null));

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _databaseService.markNotificationAsRead(notificationId);
    } catch (e) {
      // Silent fail
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _databaseService.markAllNotificationsAsRead(_userId);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Notification actions provider
final notificationActionsProvider =
    StateNotifierProvider<NotificationActionsNotifier, AsyncValue<void>>((ref) {
      return NotificationActionsNotifier(
        ref.watch(databaseServiceProvider),
        ref.watch(currentUserIdProvider),
      );
    });
