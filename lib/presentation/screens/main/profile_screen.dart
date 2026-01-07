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
      resizeToAvoidBottomInset: false,
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
                  child: Column(children: [_BiometricToggle(user: user)]),
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
                // Professional Logout Button
                _buildLogoutButton(context, ref),
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
        activeThumbColor: AppColors.primary,
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
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20.r)),
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
                child: Icon(Icons.bloodtype, size: 48.sp, color: Colors.white),
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
              _buildAboutRow(Icons.code, 'Developed by', 'Sami Khan'),
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
          child: Icon(icon, size: 20.sp, color: AppColors.primary),
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
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
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
              style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
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

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return OutlinedButton(
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
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          }
        }
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: BorderSide(color: AppColors.error.withOpacity(0.5), width: 1.5),
        padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.logout_rounded, size: 20.sp),
          SizedBox(width: 8.w),
          Text(
            AppStrings.logout,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Biometric toggle widget with fast and optimized behavior
class _BiometricToggle extends ConsumerStatefulWidget {
  final dynamic user;

  const _BiometricToggle({required this.user});

  @override
  ConsumerState<_BiometricToggle> createState() => _BiometricToggleState();
}

class _BiometricToggleState extends ConsumerState<_BiometricToggle> {
  bool _isProcessing = false;
  late bool _biometricEnabled;

  @override
  void initState() {
    super.initState();
    _biometricEnabled = widget.user.useBiometric;
  }

  @override
  void didUpdateWidget(covariant _BiometricToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync with user data if changed externally
    if (oldWidget.user.useBiometric != widget.user.useBiometric &&
        !_isProcessing) {
      _biometricEnabled = widget.user.useBiometric;
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final biometricService = ref.read(biometricServiceProvider);

      // Quick check for availability
      final isAvailable = await biometricService.isBiometricAvailable();
      if (!isAvailable) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Biometric not available on this device'),
              backgroundColor: AppColors.error,
              duration: Duration(seconds: 2),
            ),
          );
        }
        setState(() => _isProcessing = false);
        return;
      }

      if (value) {
        // First ask for password
        final password = await _showPasswordDialog(context);
        if (password == null || password.isEmpty) {
          setState(() => _isProcessing = false);
          return;
        }

        // Verify password by trying to re-authenticate
        final authProvider = ref.read(authNotifierProvider.notifier);
        final success = await authProvider.verifyPassword(
          widget.user.email,
          password,
        );

        if (!success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Incorrect password. Please try again.'),
                backgroundColor: AppColors.error,
                duration: Duration(seconds: 2),
              ),
            );
          }
          setState(() => _isProcessing = false);
          return;
        }

        // Authenticate with biometric
        final result = await biometricService.authenticate(
          localizedReason: 'Authenticate to enable biometric login',
        );

        if (!result.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.userMessage),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          setState(() => _isProcessing = false);
          return;
        }

        // Save credentials
        await biometricService.saveCredentials(widget.user.email, password);
      }

      // Update local state immediately for responsive UI
      setState(() => _biometricEnabled = value);

      // Update biometric setting in database
      await ref
          .read(userProfileNotifierProvider.notifier)
          .updateProfile(useBiometric: value);

      // Update local biometric settings
      await biometricService.setBiometricEnabled(value);

      if (value) {
        await biometricService.saveUserEmail(widget.user.email);
      } else {
        await biometricService.clearCredentials();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value ? 'Biometric login enabled' : 'Biometric login disabled',
            ),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Revert local state on error
      setState(() => _biometricEnabled = widget.user.useBiometric);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String?> _showPasswordDialog(BuildContext context) async {
    final passwordController = TextEditingController();
    bool obscureText = true;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: AppColors.primary),
              SizedBox(width: 8.w),
              const Text('Enter Password'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your account password to enable biometric login',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                controller: passwordController,
                obscureText: obscureText,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setDialogState(() => obscureText = !obscureText);
                    },
                  ),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    Navigator.pop(context, value);
                  }
                },
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
                if (passwordController.text.isNotEmpty) {
                  Navigator.pop(context, passwordController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text('Biometric Login', style: TextStyle(fontSize: 14.sp)),
      subtitle: Text(
        'Use fingerprint or face ID to login',
        style: TextStyle(fontSize: 12.sp, color: AppColors.textSecondary),
      ),
      secondary: _isProcessing
          ? SizedBox(
              width: 24.w,
              height: 24.h,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.fingerprint, color: AppColors.primary),
      value: _biometricEnabled,
      onChanged: _isProcessing ? null : _toggleBiometric,
    );
  }
}
