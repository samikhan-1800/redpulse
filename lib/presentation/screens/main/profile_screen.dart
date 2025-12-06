import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/donation_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../widgets/cards.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'donation_history_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProfileProvider);
    final donationStats = ref.watch(donationStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
              );
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: userAsync.when(
        loading: () => const LoadingPage(),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.refresh(currentUserProfileProvider),
        ),
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                // Profile header
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(24.w),
                    child: Column(
                      children: [
                        UserAvatar(
                          imageUrl: user.profileImageUrl,
                          name: user.name,
                          size: 100,
                        ),
                        SizedBox(height: 16.h),
                        Text(
                          user.name,
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          user.email,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            BloodGroupBadge(
                              bloodGroup: user.bloodGroup,
                              size: 48,
                            ),
                            SizedBox(width: 12.w),
                            AvailabilityToggle(
                              isAvailable: user.isAvailable,
                              onChanged: (value) {
                                ref
                                    .read(userProfileNotifierProvider.notifier)
                                    .toggleAvailability(value);
                              },
                            ),
                          ],
                        ),
                        if (user.bio != null && user.bio!.isNotEmpty) ...[
                          SizedBox(height: 16.h),
                          Text(
                            user.bio!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                // Stats
                Row(
                  children: [
                    Expanded(
                      child: StatsCard(
                        title: AppStrings.totalDonations,
                        value: donationStats.totalDonations.toString(),
                        icon: Icons.volunteer_activism,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: StatsCard(
                        title: AppStrings.livesSaved,
                        value: donationStats.livesSaved.toString(),
                        icon: Icons.favorite,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                // Details card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        Icons.phone,
                        AppStrings.phoneNumber,
                        user.phone.isNotEmpty ? user.phone : 'Not provided',
                      ),
                      const Divider(height: 1),
                      _buildInfoRow(
                        Icons.cake,
                        AppStrings.dateOfBirth,
                        user.dateOfBirth.formattedDate,
                      ),
                      const Divider(height: 1),
                      _buildInfoRow(
                        Icons.person,
                        AppStrings.gender,
                        user.gender.isNotEmpty
                            ? user.gender.capitalize
                            : 'Not specified',
                      ),
                      if (user.city != null && user.city!.isNotEmpty) ...[
                        const Divider(height: 1),
                        _buildInfoRow(
                          Icons.location_city,
                          AppStrings.city,
                          user.city!,
                        ),
                      ],
                      const Divider(height: 1),
                      _buildInfoRow(
                        Icons.water_drop,
                        AppStrings.lastDonation,
                        user.lastDonationDate?.formattedDate ?? 'Never',
                      ),
                      if (user.lastDonationDate != null) ...[
                        const Divider(height: 1),
                        _buildInfoRow(
                          Icons.calendar_today,
                          AppStrings.nextEligibleDate,
                          user.canDonate
                              ? 'You can donate now!'
                              : user.nextEligibleDate?.formattedDate ?? '',
                          valueColor: user.canDonate ? AppColors.success : null,
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                // Menu items
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        Icons.history,
                        AppStrings.donationHistory,
                        () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const DonationHistoryScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(
                        Icons.notifications_outlined,
                        AppStrings.notifications,
                        () {
                          // TODO: Navigate to notifications settings
                        },
                      ),
                      const Divider(height: 1),
                      _buildMenuItem(Icons.help_outline, 'Help & Support', () {
                        // TODO: Navigate to help
                      }),
                      const Divider(height: 1),
                      _buildMenuItem(Icons.info_outline, 'About', () {
                        // TODO: Show about dialog
                      }),
                    ],
                  ),
                ),
                SizedBox(height: 24.h),
                // Logout button
                PrimaryButton(
                  text: AppStrings.logout,
                  isOutlined: true,
                  backgroundColor: AppColors.error,
                  textColor: AppColors.error,
                  icon: Icons.logout,
                  onPressed: () async {
                    final confirmed = await ConfirmationDialog.show(
                      context,
                      title: AppStrings.logout,
                      message: AppStrings.confirmLogout,
                      confirmText: AppStrings.logout,
                      isDangerous: true,
                    );

                    if (confirmed == true) {
                      await ref.read(authNotifierProvider.notifier).signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    }
                  },
                ),
                SizedBox(height: 32.h),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          Icon(icon, size: 20.sp, color: AppColors.textSecondary),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
