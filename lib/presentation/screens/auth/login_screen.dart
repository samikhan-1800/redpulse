import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/validators.dart';
import '../../../data/providers/auth_provider.dart';
import '../../widgets/buttons.dart';
import '../../widgets/text_fields.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../main/main_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showBiometricButton = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final biometricService = ref.read(biometricServiceProvider);
    final credentials = await biometricService.getSavedCredentials();
    if (credentials != null && mounted) {
      setState(() => _showBiometricButton = true);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginWithBiometric() async {
    final biometricService = ref.read(biometricServiceProvider);

    // Authenticate with biometrics
    final authenticated = await biometricService.authenticate(
      localizedReason: 'Authenticate to login to RedPulse',
    );

    if (!authenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentication failed or cancelled'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    // Get saved credentials and login
    final credentials = await biometricService.getSavedCredentials();
    if (credentials == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No saved credentials found'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    await ref
        .read(authNotifierProvider.notifier)
        .signIn(credentials['email']!, credentials['password']!);

    if (mounted) {
      final authState = ref.read(authNotifierProvider);
      if (authState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (authState.hasValue) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text;
    final password = _passwordController.text;

    await ref.read(authNotifierProvider.notifier).signIn(email, password);

    if (mounted) {
      final authState = ref.read(authNotifierProvider);
      if (authState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authState.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      } else if (authState.hasValue) {
        // Check if user has biometric enabled and save credentials
        final user = ref.read(currentUserProfileProvider).value;
        if (user != null && user.useBiometric) {
          final biometricService = ref.read(biometricServiceProvider);
          await biometricService.saveCredentials(email, password);
        }

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 40.h),
                // Logo and title
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80.w,
                        height: 80.h,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Icon(
                          Icons.bloodtype,
                          size: 48.sp,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'RedPulse',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        'Donate Blood, Save Lives',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 48.h),
                // Welcome text
                Text(
                  AppStrings.welcomeBack,
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  AppStrings.loginToContinue,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 32.h),
                // Email field
                CustomTextField(
                  controller: _emailController,
                  label: AppStrings.email,
                  hint: 'Enter your email',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.validateEmail,
                  prefixIcon: Icon(Icons.email_outlined, size: 20.sp),
                ),
                SizedBox(height: 16.h),
                // Password field
                PasswordTextField(
                  controller: _passwordController,
                  label: AppStrings.password,
                  hint: 'Enter your password',
                  textInputAction: TextInputAction.done,
                  validator: Validators.validatePassword,
                ),
                SizedBox(height: 8.h),
                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: const Text(AppStrings.forgotPassword),
                  ),
                ),
                SizedBox(height: 24.h),
                // Login button
                PrimaryButton(
                  text: AppStrings.login,
                  onPressed: _login,
                  isLoading: isLoading,
                ),
                // Biometric login button
                if (_showBiometricButton) ...[
                  SizedBox(height: 16.h),
                  OutlinedButton.icon(
                    onPressed: _loginWithBiometric,
                    icon: Icon(
                      Icons.fingerprint,
                      size: 24.sp,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      'Login with Biometric',
                      style: TextStyle(fontSize: 14.sp),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                ],
                SizedBox(height: 24.h),
                // Sign up link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      AppStrings.dontHaveAccount,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(AppStrings.signUp),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
