import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    // Check if biometric is enabled (user turned on the toggle)
    final isEnabled = await biometricService.isBiometricEnabled();

    // Check if biometric hardware is available
    final isAvailable = await biometricService.isBiometricAvailable();

    // Show button if both enabled and available
    if (isEnabled && isAvailable && mounted) {
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
    final result = await biometricService.authenticate(
      localizedReason: 'Authenticate to login to RedPulse',
    );

    if (!result.success) {
      if (mounted) {
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

    // Get saved credentials
    final credentials = await biometricService.getSavedCredentials();

    // If no saved credentials, get the saved email and ask user to enter password
    if (credentials == null) {
      final savedEmail = await biometricService.getSavedUserEmail();
      if (savedEmail != null) {
        _emailController.text = savedEmail;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your password to complete login'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
      return;
    }

    // Login with saved credentials
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
        // Wait for user profile to load
        await Future.delayed(const Duration(milliseconds: 500));

        // Check if user has biometric enabled and save credentials
        final user = ref.read(currentUserProfileProvider).value;
        if (user != null && user.useBiometric) {
          final biometricService = ref.read(biometricServiceProvider);
          await biometricService.saveCredentials(email, password);
        }

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;

    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final shortestSide = min(mediaQuery.size.width, mediaQuery.size.height);
    final scaleFactor = (shortestSide / 375).clamp(0.7, 1.2);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: isLandscape
            ? _buildLandscapeLayout(isLoading, scaleFactor)
            : _buildPortraitLayout(isLoading, scaleFactor),
      ),
    );
  }

  Widget _buildPortraitLayout(bool isLoading, double scaleFactor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 30),
            _buildHeader(scaleFactor),
            const SizedBox(height: 36),
            _buildWelcomeText(scaleFactor),
            const SizedBox(height: 28),
            _buildLoginForm(isLoading, scaleFactor),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(bool isLoading, double scaleFactor) {
    return Row(
      children: [
        // Left side - Logo and title
        Expanded(
          flex: 2,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildHeader(scaleFactor * 0.85),
            ),
          ),
        ),
        // Right side - Form
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildWelcomeText(scaleFactor * 0.85),
                  const SizedBox(height: 20),
                  _buildLoginForm(isLoading, scaleFactor * 0.9),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(double scaleFactor) {
    final logoSize = 70 * scaleFactor;
    final iconSize = 40 * scaleFactor;
    final titleSize = 24 * scaleFactor;
    final subtitleSize = 12 * scaleFactor;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18 * scaleFactor),
          ),
          child: Icon(Icons.bloodtype, size: iconSize, color: Colors.white),
        ),
        SizedBox(height: 14 * scaleFactor),
        Text(
          'RedPulse',
          style: TextStyle(
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        SizedBox(height: 6 * scaleFactor),
        Text(
          'Donate Blood, Save Lives',
          style: TextStyle(
            fontSize: subtitleSize,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeText(double scaleFactor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppStrings.welcomeBack,
          style: TextStyle(
            fontSize: 22 * scaleFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 6 * scaleFactor),
        Text(
          AppStrings.loginToContinue,
          style: TextStyle(
            fontSize: 13 * scaleFactor,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isLoading, double scaleFactor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Email field
        CustomTextField(
          controller: _emailController,
          label: AppStrings.email,
          hint: 'Enter your email',
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: Validators.validateEmail,
          prefixIcon: Icon(Icons.email_outlined, size: 18 * scaleFactor),
        ),
        SizedBox(height: 14 * scaleFactor),
        // Password field
        PasswordTextField(
          controller: _passwordController,
          label: AppStrings.password,
          hint: 'Enter your password',
          textInputAction: TextInputAction.done,
          validator: Validators.validatePassword,
        ),
        SizedBox(height: 6 * scaleFactor),
        // Forgot password
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
              );
            },
            child: const Text(AppStrings.forgotPassword),
          ),
        ),
        SizedBox(height: 20 * scaleFactor),
        // Login button
        PrimaryButton(
          text: AppStrings.login,
          onPressed: _login,
          isLoading: isLoading,
        ),
        // Biometric login button
        if (_showBiometricButton) ...[
          SizedBox(height: 14 * scaleFactor),
          OutlinedButton.icon(
            onPressed: _loginWithBiometric,
            icon: Icon(
              Icons.fingerprint,
              size: 22 * scaleFactor,
              color: AppColors.primary,
            ),
            label: Text(
              'Login with Biometric',
              style: TextStyle(fontSize: 13 * scaleFactor),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 14 * scaleFactor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
        SizedBox(height: 20 * scaleFactor),
        // Sign up link
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              AppStrings.dontHaveAccount,
              style: TextStyle(
                fontSize: 13 * scaleFactor,
                color: AppColors.textSecondary,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                );
              },
              child: const Text(AppStrings.signUp),
            ),
          ],
        ),
      ],
    );
  }
}
