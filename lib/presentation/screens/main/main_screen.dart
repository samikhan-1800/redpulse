import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/providers/chat_provider.dart';

import '../../widgets/notification_banner.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'requests_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';

/// Main navigation index provider
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    // Reset to home screen when MainScreen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bottomNavIndexProvider.notifier).state = 0;
      _setupNotificationListeners();
    });
  }

  void _setupNotificationListeners() {
    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (!mounted) return;

      final notification = message.notification;
      final data = message.data;

      if (notification != null) {
        final type = data['type'] ?? '';

        // Show different banner based on notification type
        if (type == 'emergency' || type == 'sos') {
          NotificationBanner.showEmergency(
            context,
            title: notification.title ?? '🚨 Emergency Request',
            message: notification.body ?? 'Blood needed urgently!',
            onTap: () {
              // Navigate to requests tab
              ref.read(bottomNavIndexProvider.notifier).state = 2;
            },
          );
        } else if (type == 'message' || type == 'chat') {
          NotificationBanner.showMessage(
            context,
            title: notification.title ?? '💬 New Message',
            message: notification.body ?? 'You have a new message',
            onTap: () {
              // Navigate to chats tab
              ref.read(bottomNavIndexProvider.notifier).state = 3;
            },
          );
        } else if (type == 'request') {
          NotificationBanner.show(
            context,
            title: notification.title ?? '🩸 Blood Request',
            message: notification.body ?? 'Someone needs your blood type',
            icon: Icons.water_drop_rounded,
            backgroundColor: AppColors.primary,
            onTap: () {
              // Navigate to requests tab
              ref.read(bottomNavIndexProvider.notifier).state = 2;
            },
          );
        } else {
          NotificationBanner.show(
            context,
            title: notification.title ?? 'Notification',
            message: notification.body ?? 'You have a new notification',
          );
        }
      }
    });

    // Listen to notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final data = message.data;
      final type = data['type'] ?? '';

      // Navigate based on notification type
      if (type == 'message' || type == 'chat') {
        ref.read(bottomNavIndexProvider.notifier).state = 3;
      } else if (type == 'request' || type == 'emergency' || type == 'sos') {
        ref.read(bottomNavIndexProvider.notifier).state = 2;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final unreadMessages = ref.watch(unreadMessagesCountProvider);

    // Screens
    final screens = [
      const HomeScreen(),
      const MapScreen(),
      const RequestsScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];

    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final navBarHeight = isLandscape ? 56.0 : 70.h;

    return Scaffold(
      resizeToAvoidBottomInset:
          false, // Prevent keyboard from pushing bottom nav
      extendBody: false, // Don't extend body behind bottom nav
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : AppColors.primary,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: navBarHeight,
            padding: EdgeInsets.symmetric(
              horizontal: 4.w,
              vertical: isLandscape ? 4 : 6.h,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.home_rounded,
                  label: AppStrings.home,
                  isSelected: currentIndex == 0,
                  onTap: () =>
                      ref.read(bottomNavIndexProvider.notifier).state = 0,
                ),
                _NavBarItem(
                  icon: Icons.location_on_rounded,
                  label: AppStrings.map,
                  isSelected: currentIndex == 1,
                  onTap: () =>
                      ref.read(bottomNavIndexProvider.notifier).state = 1,
                ),
                _NavBarItem(
                  icon: Icons.water_drop_rounded,
                  label: AppStrings.requests,
                  isSelected: currentIndex == 2,
                  onTap: () =>
                      ref.read(bottomNavIndexProvider.notifier).state = 2,
                  isPrimary: true,
                ),
                _NavBarItem(
                  icon: Icons.forum_rounded,
                  label: AppStrings.chat,
                  isSelected: currentIndex == 3,
                  badgeCount: unreadMessages,
                  onTap: () =>
                      ref.read(bottomNavIndexProvider.notifier).state = 3,
                ),
                _NavBarItem(
                  icon: Icons.person_rounded,
                  label: AppStrings.profile,
                  isSelected: currentIndex == 4,
                  onTap: () =>
                      ref.read(bottomNavIndexProvider.notifier).state = 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badgeCount;
  final bool isPrimary;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final color = isSelected
        ? (isDark ? AppColors.primary : Colors.white)
        : (isDark
              ? Colors.white.withOpacity(0.6)
              : Colors.white.withOpacity(0.6));

    final iconSize = isLandscape
        ? (isPrimary ? 22.0 : 20.0)
        : (isPrimary ? 26.sp : 22.sp);
    final labelSize = isLandscape ? 8.0 : 9.5.sp;
    final iconPadding = isLandscape
        ? (isPrimary ? 6.0 : 4.0)
        : (isPrimary ? 8.w : 6.w);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isLandscape ? 2 : 2.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  // Icon container with background
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(iconPadding),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (Theme.of(context).brightness == Brightness.dark
                                ? AppColors.primary.withOpacity(0.3)
                                : Colors.white.withOpacity(0.2))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        isPrimary ? 14.r : 10.r,
                      ),
                    ),
                    child: Icon(icon, size: iconSize, color: color),
                  ),
                  // Badge
                  if (badgeCount != null && badgeCount! > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: EdgeInsets.all(isLandscape ? 2 : 3.w),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: BoxConstraints(
                          minWidth: isLandscape ? 14 : 16.w,
                          minHeight: isLandscape ? 14 : 16.w,
                        ),
                        child: Center(
                          child: Text(
                            badgeCount! > 99 ? '99+' : badgeCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isLandscape ? 7 : 8.sp,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: isLandscape ? 2 : 3.h),
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: labelSize,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: color,
                  height: 1,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
