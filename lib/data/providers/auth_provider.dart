import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/biometric_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

final currentFirebaseUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).value;
});

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentFirebaseUserProvider)?.uid;
});
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);

  final databaseService = ref.watch(databaseServiceProvider);
  return databaseService.userStream(userId);
});

final userProfileProvider = FutureProvider.family<UserModel?, String>((
  ref,
  userId,
) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getUser(userId);
});

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;
  final DatabaseService _databaseService;
  final NotificationService _notificationService;

  AuthNotifier(
    this._authService,
    this._databaseService,
    this._notificationService,
  ) : super(const AsyncValue.data(null));

  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithEmail(email, password);
      try {
        final userId = _authService.currentUser?.uid;
        if (userId != null) {
          final token = await _notificationService.initialize();
          if (token != null) {
            await _notificationService.saveToken(userId, token);
          }
        }
      } catch (notificationError) {
        print('Notification setup failed: $notificationError');
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String bloodGroup,
    required String gender,
    required DateTime dateOfBirth,
  }) async {
    state = const AsyncValue.loading();
    try {
      final credential = await _authService.signUpWithEmail(email, password);
      final userId = credential.user!.uid;

      final now = DateTime.now();
      final user = UserModel(
        id: userId,
        email: email,
        name: name,
        phone: phone,
        bloodGroup: bloodGroup,
        gender: gender,
        dateOfBirth: dateOfBirth,
        createdAt: now,
        updatedAt: now,
      );

      await _databaseService.createUser(user);

      final token = await _notificationService.initialize();
      if (token != null) {
        await _notificationService.saveToken(userId, token);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    try {
      await _authService.sendPasswordResetEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<void>>((ref) {
      return AuthNotifier(
        ref.watch(authServiceProvider),
        ref.watch(databaseServiceProvider),
        ref.watch(notificationServiceProvider),
      );
    });
