import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/models/chat_model.dart';
import '../../../data/models/message_model.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/cards.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Chat chat;

  const ChatScreen({super.key, required this.chat});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Mark messages as read when entering chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final userId = ref.read(currentUserIdProvider);
        if (userId != null) {
          ref
              .read(chatNotifierProvider.notifier)
              .markAsRead(widget.chat.id, userId);
        }
      } catch (e) {
        print('Error marking messages as read: $e');
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Timer(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients && mounted) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = true);
    _messageController.clear();

    try {
      await ref
          .read(chatNotifierProvider.notifier)
          .sendMessage(chatId: widget.chat.id, content: text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sending message: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final otherName = widget.chat.getOtherParticipantName(userId ?? '');
    final otherImage = widget.chat.getOtherParticipantImage(userId ?? '');

    final messagesAsync = ref.watch(chatMessagesProvider(widget.chat.id));

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final shortestSide = min(mediaQuery.size.width, mediaQuery.size.height);
    final scaleFactor = (shortestSide / 375).clamp(0.7, 1.2);

    return Scaffold(
      resizeToAvoidBottomInset: true, // Let keyboard push content up
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(isLandscape ? 48 : 56),
        child: AppBar(
          elevation: 0,
          titleSpacing: 0,
          toolbarHeight: isLandscape ? 48 : 56,
          title: Row(
            children: [
              UserAvatar(
                imageUrl: otherImage,
                name: otherName,
                size: isLandscape ? 32 : 40,
              ),
              SizedBox(width: isLandscape ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      otherName,
                      style: TextStyle(
                        fontSize: isLandscape ? 13 : 17,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Blood Request',
                      style: TextStyle(
                        fontSize: isLandscape ? 9 : 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: messagesAsync.when(
                loading: () => const LoadingPage(),
                error: (error, _) => ErrorState(
                  message: error.toString(),
                  onRetry: () =>
                      ref.refresh(chatMessagesProvider(widget.chat.id)),
                ),
                data: (messages) {
                  if (messages.isEmpty) {
                    return const EmptyState(
                      icon: Icons.chat_bubble_outline,
                      title: 'No messages yet',
                      subtitle: 'Send a message to start the conversation',
                    );
                  }

                  // Scroll to bottom when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    try {
                      _scrollToBottom();
                    } catch (e) {
                      print('Error scrolling to bottom: $e');
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 24 : 16,
                      vertical: isLandscape ? 6 : 8,
                    ),
                    itemCount: messages.length,
                    cacheExtent: 500,
                    addRepaintBoundaries: true,
                    addAutomaticKeepAlives: true,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == userId;
                      final showDate =
                          index == 0 ||
                          !_isSameDay(
                            messages[index - 1].createdAt,
                            message.createdAt,
                          );

                      return Column(
                        children: [
                          if (showDate)
                            Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: isLandscape ? 10 : 16,
                              ),
                              child: Text(
                                message.createdAt.formattedDate,
                                style: TextStyle(
                                  fontSize: isLandscape ? 10 : 12,
                                  color: AppColors.textHint,
                                ),
                              ),
                            ),
                          _MessageBubble(
                            message: message,
                            isMe: isMe,
                            isLandscape: isLandscape,
                            scaleFactor: scaleFactor,
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            // Message input - Wrapped in Container to prevent overflow
            _buildMessageInput(isLandscape, scaleFactor),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput(bool isLandscape, double scaleFactor) {
    final inputPadding = isLandscape ? 8.0 : 16.0;
    final verticalPadding = isLandscape ? 4.0 : 8.0;
    final iconSize = isLandscape ? 18.0 : 24.0;
    final buttonPadding = isLandscape ? 8.0 : 12.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: inputPadding,
        vertical: verticalPadding,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: isLandscape ? 60 : 120),
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: AppStrings.typeMessage,
                  hintStyle: TextStyle(fontSize: isLandscape ? 12 : 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: AppColors.cardBackground,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? 12 : 16,
                    vertical: isLandscape ? 6 : 10,
                  ),
                  isDense: true,
                ),
                style: TextStyle(fontSize: isLandscape ? 12 : 14),
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                minLines: 1,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
              ),
            ),
          ),
          SizedBox(width: isLandscape ? 4 : 8),
          Padding(
            padding: EdgeInsets.only(bottom: isLandscape ? 2 : 4),
            child: Material(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: _isSending ? null : _sendMessage,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: EdgeInsets.all(buttonPadding),
                  child: _isSending
                      ? SizedBox(
                          width: iconSize,
                          height: iconSize,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Icon(Icons.send, color: Colors.white, size: iconSize),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isLandscape;
  final double scaleFactor;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isLandscape,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final margin = isLandscape ? 32.0 : 48.0;
    final padding = isLandscape ? 10.0 : 16.0;
    final fontSize = isLandscape ? 12.0 : 15.0;
    final timeSize = isLandscape ? 8.0 : 11.0;
    final iconSize = isLandscape ? 11.0 : 14.0;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: isLandscape ? 6 : 8,
          left: isMe ? margin : 0,
          right: isMe ? 0 : margin,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: padding,
          vertical: isLandscape ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? AppColors.primary
              : Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : AppColors.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: fontSize,
                color: isMe
                    ? Colors.white
                    : Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
            ),
            SizedBox(height: isLandscape ? 3 : 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.createdAt.formattedTime,
                  style: TextStyle(
                    fontSize: timeSize,
                    color: isMe
                        ? Colors.white.withOpacity(0.7)
                        : AppColors.textHint,
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: isLandscape ? 3 : 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: iconSize,
                    color: message.isRead
                        ? Colors.lightBlueAccent
                        : Colors.white.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
