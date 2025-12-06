import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/notification_model.dart';
import '../../../data/providers/notification_provider.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/providers/request_provider.dart';
import '../chat/chat_screen.dart';
import '../request/request_detail_screen.dart';
import '../main/donation_history_screen.dart';

/// Notification types enum
enum NotificationType {
  newRequest,
  requestAccepted,
  requestCancelled,
  newMessage,
  donationCompleted,
  system,
}

/// Screen to display all user notifications
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Mark notifications as read when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationActionsProvider.notifier).markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.appBarBackground,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20.r)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Notifications'),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'clear') {
                    _showClearConfirmation();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.clear_all, size: 20),
                        SizedBox(width: 12),
                        Text('Clear All'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          // Handle Firestore errors gracefully
          return Center(
            child: Padding(
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64.sp,
                    color: AppColors.textSecondary,
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'No Notifications',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'You don\'t have any notifications yet',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
        data: (notifications) {
          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
            },
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: notifications.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, thickness: 1, color: AppColors.divider),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return _NotificationTile(notification: notification);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80.sp,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16.h),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'When you get notifications, they\'ll show up here',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text(
          'Are you sure you want to clear all notifications? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement clear all notifications
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications cleared')),
              );
            },
            child: const Text(
              'Clear All',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: notification.isRead
          ? Colors.transparent
          : AppColors.primary.withOpacity(0.05),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        leading: _buildIcon(),
        title: Text(
          notification.title,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4.h),
            Text(
              notification.body,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 6.h),
            Text(
              _formatTime(notification.createdAt),
              style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 10.w,
                height: 10.w,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          _handleNotificationTap(context, notification);
        },
      ),
    );
  }

  NotificationType _getNotificationType() {
    switch (notification.type.toLowerCase()) {
      case 'newrequest':
      case 'new_request':
      case 'request':
        return NotificationType.newRequest;
      case 'requestaccepted':
      case 'request_accepted':
      case 'accepted':
        return NotificationType.requestAccepted;
      case 'requestcancelled':
      case 'request_cancelled':
      case 'cancelled':
        return NotificationType.requestCancelled;
      case 'newmessage':
      case 'new_message':
      case 'message':
      case 'chat':
        return NotificationType.newMessage;
      case 'donationcompleted':
      case 'donation_completed':
      case 'donation':
      case 'completed':
        return NotificationType.donationCompleted;
      default:
        return NotificationType.system;
    }
  }

  Widget _buildIcon() {
    IconData iconData;
    Color iconColor;

    switch (_getNotificationType()) {
      case NotificationType.newRequest:
        iconData = Icons.campaign;
        iconColor = AppColors.error;
        break;
      case NotificationType.requestAccepted:
        iconData = Icons.check_circle;
        iconColor = AppColors.success;
        break;
      case NotificationType.requestCancelled:
        iconData = Icons.cancel;
        iconColor = AppColors.warning;
        break;
      case NotificationType.newMessage:
        iconData = Icons.message;
        iconColor = AppColors.info;
        break;
      case NotificationType.donationCompleted:
        iconData = Icons.favorite;
        iconColor = AppColors.primary;
        break;
      case NotificationType.system:
        iconData = Icons.notifications;
        iconColor = AppColors.textSecondary;
        break;
    }

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor, size: 24.sp),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  void _handleNotificationTap(
    BuildContext context,
    NotificationModel notification,
  ) {
    final ref = ProviderScope.containerOf(context);

    // Navigate based on notification type
    switch (_getNotificationType()) {
      case NotificationType.newRequest:
      case NotificationType.requestAccepted:
      case NotificationType.requestCancelled:
        // Navigate to request detail if we have a requestId
        if (notification.data?.containsKey('requestId') ?? false) {
          final requestId = notification.data!['requestId'];
          ref
              .read(requestDetailProvider(requestId).future)
              .then((request) {
                if (request != null && context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RequestDetailScreen(request: request),
                    ),
                  );
                }
              })
              .catchError((e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request not found')),
                  );
                }
              });
        }
        break;
      case NotificationType.newMessage:
        // Navigate to chat if we have a chatId
        if (notification.data?.containsKey('chatId') ?? false) {
          final chatId = notification.data!['chatId'];
          ref
              .read(chatDetailProvider(chatId).future)
              .then((chat) {
                if (chat != null && context.mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
                  );
                }
              })
              .catchError((e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Chat not found')),
                  );
                }
              });
        }
        break;
      case NotificationType.donationCompleted:
        // Navigate to donation history
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DonationHistoryScreen()),
        );
        break;
      case NotificationType.system:
        // Show notification details in a dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(notification.title),
            content: Text(notification.body),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        break;
    }
  }
}
