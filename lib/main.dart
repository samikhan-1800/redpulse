import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/notification_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main/main_screen.dart';
import 'presentation/widgets/common_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp();

  runApp(const ProviderScope(child: RedPulseApp()));
}

class RedPulseApp extends ConsumerWidget {
  const RedPulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: AppStrings.appName,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          home: const AuthWrapper(),
        );
      },
    );
  }
}

/// Wrapper widget that handles authentication state
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationNotifierProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => const _SplashScreen(),
      error: (error, _) => Scaffold(
        body: ErrorState(
          message: 'Authentication error: $error',
          onRetry: () => ref.refresh(authStateChangesProvider),
        ),
      ),
      data: (user) {
        if (user != null) {
          return const MainScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

/// Splash screen shown while loading
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withOpacity(0.8),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo
              Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.water_drop,
                  size: 64.sp,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                AppStrings.appName,
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                AppStrings.appTagline,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              SizedBox(height: 48.h),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
