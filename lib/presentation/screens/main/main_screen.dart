import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../data/providers/chat_provider.dart';
import '../../../data/providers/notification_provider.dart';
import '../../widgets/common_widgets.dart';
import 'home_screen.dart';
import 'map_screen.dart';
import 'requests_screen.dart';
import 'chat_list_screen.dart';
import 'profile_screen.dart';

/// Main navigation index provider
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class MainScreen extends ConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final unreadMessages = ref.watch(unreadMessagesCountProvider);
    final unreadNotifications = ref.watch(unreadNotificationsCountProvider);

    // Screens
    final screens = [
      const HomeScreen(),
      const MapScreen(),
      const RequestsScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.navBarBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 70.h,
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 6.h),
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
                  badgeCount: unreadNotifications,
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
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 2.h),
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
                    padding: EdgeInsets.all(isPrimary ? 8.w : 6.w),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(
                        isPrimary ? 14.r : 10.r,
                      ),
                    ),
                    child: Icon(
                      icon,
                      size: isPrimary ? 26.sp : 22.sp,
                      color: isPrimary && isSelected
                          ? AppColors.primary
                          : color,
                    ),
                  ),
                  // Badge
                  if (badgeCount != null && badgeCount! > 0)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 16.w,
                          minHeight: 16.w,
                        ),
                        child: Center(
                          child: Text(
                            badgeCount! > 99 ? '99+' : badgeCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 3.h),
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 9.5.sp,
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
