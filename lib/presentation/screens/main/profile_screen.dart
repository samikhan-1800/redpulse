import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/extensions.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/donation_provider.dart';
import '../../../data/providers/user_provider.dart';
import '../../../data/providers/theme_provider.dart';
import '../../widgets/cards.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/dialogs.dart';
import '../auth/login_screen.dart';
import 'edit_profile_screen.dart';
import 'donation_history_screen.dart';
import '../notification/notifications_screen.dart';

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
                            Flexible(
                              child: AvailabilityToggle(
                                isAvailable: user.isAvailable,
                                onChanged: (value) {
                                  ref
                                      .read(
                                        userProfileNotifierProvider.notifier,
                                      )
                                      .toggleAvailability(value);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                // Settings Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: Text(
                          'Biometric Login',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        subtitle: Text(
                          'Use fingerprint or face ID to login',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        secondary: Icon(
                          Icons.fingerprint,
                          color: AppColors.primary,
                        ),
                        value: user.useBiometric,
                        onChanged: (value) async {
                          try {
                            final biometricService = ref.read(
                              biometricServiceProvider,
                            );

                            // Check availability first
                            final isAvailable = await biometricService
                                .isBiometricAvailable();

                            if (!isAvailable) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Biometric authentication is not available on this device',
                                    ),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                              return;
                            }

                            if (value) {
                              // Authenticate before enabling
                              final result = await biometricService
                                  .authenticate(
                                    localizedReason:
                                        'Authenticate to enable biometric login',
                                  );

                              if (!result.success) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(result.userMessage),
                                      backgroundColor: AppColors.error,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                                return;
                              }

                              // Ask user to enter password to save credentials
                              if (context.mounted) {
                                final password = await _showPasswordDialog(context);
                                if (password == null || password.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Password required to enable biometric login',
                                      ),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }

                                // Save credentials for biometric login
                                await biometricService.saveCredentials(
                                  user.email,
                                  password,
                                );
                              }
                            }

                            // Show loading for database update
                            if (context.mounted) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            // Update user preference
                            await ref
                                .read(userProfileNotifierProvider.notifier)
                                .updateProfile(useBiometric: value);

                            // Save biometric enabled flag and user email
                            await biometricService.setBiometricEnabled(value);
                            if (value) {
                              // Save user email for future logins
                              await biometricService.saveUserEmail(user.email);
                            } else {
                              // Clear saved credentials when disabling
                              await biometricService.clearCredentials();
                            }

                            // Refresh user data to show updated state
                            ref.invalidate(currentUserProfileProvider);

                            if (context.mounted) {
                              Navigator.pop(context); // Close loading
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value
                                        ? 'Biometric login enabled successfully'
                                        : 'Biometric login disabled',
                                  ),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              // Try to close loading dialog if it's open
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
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
                        user.lastDonationDate != null
                            ? '${user.lastDonationDate!.formattedDate} (${user.lastDonationDate!.timeAgo})'
                            : 'Never',
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
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                      _buildThemeMenuItem(context, ref),
                      const Divider(height: 1),
                      _buildMenuItem(Icons.info_outline, 'About', () {
                        _showAboutDialog(context);
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

  Widget _buildThemeMenuItem(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return ListTile(
      leading: Icon(
        isDark ? Icons.dark_mode : Icons.light_mode,
        color: AppColors.textSecondary,
      ),
      title: const Text('Theme'),
      subtitle: Text(
        isDark ? 'Dark Mode' : 'Light Mode',
        style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
      ),
      trailing: Switch(
        value: isDark,
        activeColor: AppColors.primary,
        onChanged: (value) {
          ref.read(themeModeProvider.notifier).toggleTheme();
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // App Icon with Gradient
              Container(
                width: 80.w,
                height: 80.h,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bloodtype,
                  size: 48.sp,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20.h),
              // App Name
              Text(
                'RedPulse',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 8.h),
              // Version
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Text(
                  'Version 1.0',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              // Divider
              Divider(color: AppColors.textSecondary.withOpacity(0.2)),
              SizedBox(height: 16.h),
              // Purpose
              _buildAboutRow(
                Icons.school_outlined,
                'Purpose',
                'Semester Project',
              ),
              SizedBox(height: 12.h),
              // Developer
              _buildAboutRow(
                Icons.code,
                'Developed by',
                'Sami Khan',
              ),
              SizedBox(height: 24.h),
              // Tagline
              Text(
                'Donate Blood, Save Lives',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(
            icon,
            size: 20.sp,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<String?> _showPasswordDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your password to enable biometric login',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: 16.h),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, passwordController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
