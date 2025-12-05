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
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            ref.read(bottomNavIndexProvider.notifier).state = index;
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12.sp,
          unselectedFontSize: 12.sp,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: AppStrings.home,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: AppStrings.map,
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: AppStrings.requests,
            ),
            BottomNavigationBarItem(
              icon: BadgeCounter(
                count: unreadMessages,
                child: const Icon(Icons.chat_bubble_outline),
              ),
              activeIcon: BadgeCounter(
                count: unreadMessages,
                child: const Icon(Icons.chat_bubble),
              ),
              label: AppStrings.chat,
            ),
            BottomNavigationBarItem(
              icon: BadgeCounter(
                count: unreadNotifications,
                child: const Icon(Icons.person_outline),
              ),
              activeIcon: BadgeCounter(
                count: unreadNotifications,
                child: const Icon(Icons.person),
              ),
              label: AppStrings.profile,
            ),
          ],
        ),
      ),
    );
  }
}
