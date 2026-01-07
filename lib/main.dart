import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/utils/responsive_utils.dart';
import 'data/providers/auth_provider.dart';
import 'data/providers/notification_provider.dart';
import 'data/providers/theme_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main/main_screen.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/widgets/common_widgets.dart';

bool _firebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Enable all orientations for responsive layout
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  try {
    if (kIsWeb) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'YOUR_API_KEY',
          authDomain: 'YOUR_AUTH_DOMAIN',
          projectId: 'YOUR_PROJECT_ID',
          storageBucket: 'YOUR_STORAGE_BUCKET',
          messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
          appId: 'YOUR_APP_ID',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    _firebaseInitialized = true;
    debugPrint('Firebase initialized successfully!');
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    _firebaseInitialized = false;
  }

  runApp(const ProviderScope(child: RedPulseApp()));
}

class RedPulseApp extends ConsumerWidget {
  const RedPulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme.copyWith(
        appBarTheme: AppTheme.lightTheme.appBarTheme.copyWith(
          toolbarHeight: 56, // Fixed app bar height
        ),
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        appBarTheme: AppTheme.darkTheme.appBarTheme.copyWith(
          toolbarHeight: 56, // Fixed app bar height
        ),
      ),
      themeMode: themeMode,
      builder: (context, child) {
        // Initialize responsive utils
        ResponsiveUtils.init(context);
        return child ?? const SizedBox.shrink();
      },
      home: const ResponsiveWrapper(),
    );
  }
}

/// Responsive wrapper that handles orientation changes smoothly
class ResponsiveWrapper extends StatelessWidget {
  const ResponsiveWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    // Update responsive utils
    ResponsiveUtils.init(context);

    // Use fixed design sizes that work well
    final designSize = isLandscape
        ? const Size(844, 390) // Landscape
        : const Size(390, 844); // Portrait

    return ScreenUtilInit(
      designSize: designSize,
      minTextAdapt: true,
      splitScreenMode: true,
      useInheritedMediaQuery: true,
      rebuildFactor: (old, data) => false, // Prevent unnecessary rebuilds
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          // Wrap in ClipRect to prevent overflow during rotation
          child: ClipRect(child: const AuthWrapper()),
        );
      },
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _showSplash = true;
  bool _splashCompleted = false;

  @override
  void initState() {
    super.initState();
    if (_firebaseInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(notificationNotifierProvider.notifier).initialize();
      });
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
          _splashCompleted = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_firebaseInitialized) {
      return Scaffold(
        body: ErrorState(
          message: 'Firebase failed to initialize. Please restart the app.',
          onRetry: () => ref.refresh(authStateChangesProvider),
        ),
      );
    }

    // Only show splash on initial load, never on orientation change
    if (_showSplash && !_splashCompleted) {
      return const SplashScreen();
    }

    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      loading: () => _splashCompleted
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : const SplashScreen(),
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
