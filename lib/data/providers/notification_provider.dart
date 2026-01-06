import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';

final notificationsProvider = StreamProvider<List<NotificationModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final databaseService = ref.watch(databaseServiceProvider);
  return databaseService.notificationsStream(userId);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(notificationsProvider);
  final notifications =
      notificationsAsync.whenOrNull(data: (data) => data) ?? [];
  return notifications.where((n) => !n.isRead).length;
});

class NotificationNotifier extends StateNotifier<AsyncValue<void>> {
  final NotificationService _notificationService;
  final String? _userId;

  NotificationNotifier(this._notificationService, this._userId)
    : super(const AsyncValue.data(null));

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

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, AsyncValue<void>>((ref) {
      return NotificationNotifier(
        ref.watch(notificationServiceProvider),
        ref.watch(currentUserIdProvider),
      );
    });

class NotificationActionsNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _databaseService;
  final String? _userId;

  NotificationActionsNotifier(this._databaseService, this._userId)
    : super(const AsyncValue.data(null));

  Future<void> markAsRead(String notificationId) async {
    try {
      await _databaseService.markNotificationAsRead(notificationId);
    } catch (e) {
      // Silent fail
    }
  }

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

final notificationActionsProvider =
    StateNotifierProvider<NotificationActionsNotifier, AsyncValue<void>>((ref) {
      return NotificationActionsNotifier(
        ref.watch(databaseServiceProvider),
        ref.watch(currentUserIdProvider),
      );
    });
