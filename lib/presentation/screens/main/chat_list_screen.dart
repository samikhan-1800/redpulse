import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_animations.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/models/chat_model.dart';
import '../../widgets/cards.dart';
import '../../widgets/common_widgets.dart';
import '../chat/chat_screen.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(currentUserIdProvider);
    final chatsAsync = ref.watch(userChatsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.messages)),
      body: chatsAsync.when(
        loading: () => const ShimmerList(),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.refresh(userChatsProvider),
        ),
        data: (chats) {
          if (chats.isEmpty) {
            return const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: AppStrings.noChats,
              subtitle: 'Accept a request to start chatting',
              animationUrl: AppAnimations.chat,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(userChatsProvider);
            },
            child: ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: chats.length,
              cacheExtent: 300,
              addRepaintBoundaries: true,
              itemBuilder: (context, index) {
                final chat = chats[index];
                return _ChatListItem(
                  chat: chat,
                  userId: userId ?? '',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ChatListItem extends StatelessWidget {
  final Chat chat;
  final String userId;
  final VoidCallback? onTap;

  const _ChatListItem({required this.chat, required this.userId, this.onTap});

  @override
  Widget build(BuildContext context) {
    final otherName = chat.getOtherParticipantName(userId);
    final otherImage = chat.getOtherParticipantImage(userId);
    final unreadCount = chat.getUnreadCount(userId);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      elevation: unreadCount > 0 ? 2 : 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: unreadCount > 0
              ? AppColors.primary.withOpacity(0.3)
              : Colors.grey.withOpacity(0.2),
          width: unreadCount > 0 ? 1.5 : 0.5,
        ),
      ),
      color: unreadCount > 0
          ? AppColors.primary.withOpacity(0.05)
          : Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : AppColors.cardBackground,
      child: ListTile(
        onTap: onTap,
        leading: UserAvatar(imageUrl: otherImage, name: otherName, size: 50),
        title: Row(
          children: [
            Expanded(
              child: Text(
                otherName,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chat.lastMessageTime != null)
              Text(
                chat.lastMessageTime!.timeAgo,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: unreadCount > 0
                      ? AppColors.primary
                      : AppColors.textHint,
                  fontWeight: unreadCount > 0
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                chat.lastMessage ?? 'No messages yet',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: unreadCount > 0
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: unreadCount > 0
                      ? FontWeight.w500
                      : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (unreadCount > 0)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  unreadCount > 99 ? '99+' : unreadCount.toString(),
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      ),
    );
  }
}
