import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';

/// In-app notification banner widget
class NotificationBanner extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationBanner({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.notifications,
    this.backgroundColor,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.up,
      onDismissed: (_) => onDismiss?.call(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: backgroundColor ?? AppColors.primary,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: Colors.white, size: 24.sp),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        message,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    onPressed: onDismiss,
                    icon: Icon(Icons.close, color: Colors.white, size: 20.sp),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Show notification banner
  static void show(
    BuildContext context, {
    required String title,
    required String message,
    IconData icon = Icons.notifications,
    Color? backgroundColor,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 0,
        right: 0,
        child: NotificationBanner(
          title: title,
          message: message,
          icon: icon,
          backgroundColor: backgroundColor,
          onTap: () {
            overlayEntry.remove();
            onTap?.call();
          },
          onDismiss: () => overlayEntry.remove(),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto dismiss after duration
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  /// Show emergency notification banner (red)
  static void showEmergency(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onTap,
  }) {
    show(
      context,
      title: title,
      message: message,
      icon: Icons.warning_amber_rounded,
      backgroundColor: Colors.red.shade700,
      onTap: onTap,
      duration: const Duration(seconds: 6),
    );
  }

  /// Show message notification banner (blue)
  static void showMessage(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onTap,
  }) {
    show(
      context,
      title: title,
      message: message,
      icon: Icons.message_rounded,
      backgroundColor: Colors.blue.shade600,
      onTap: onTap,
    );
  }

  /// Show success notification banner (green)
  static void showSuccess(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onTap,
  }) {
    show(
      context,
      title: title,
      message: message,
      icon: Icons.check_circle_rounded,
      backgroundColor: Colors.green.shade600,
      onTap: onTap,
    );
  }
}
