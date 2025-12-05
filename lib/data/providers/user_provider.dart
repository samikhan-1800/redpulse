import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';
import '../models/user_model.dart';
import 'auth_provider.dart';

/// User profile notifier for managing user profile updates
class UserProfileNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _databaseService;
  final StorageService _storageService;
  final String? _userId;

  UserProfileNotifier(this._databaseService, this._storageService, this._userId)
    : super(const AsyncValue.data(null));

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? phone,
    String? bloodGroup,
    String? gender,
    DateTime? dateOfBirth,
    String? bio,
    String? address,
    String? city,
    File? profileImage,
  }) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final updates = <String, dynamic>{};

      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (bloodGroup != null) updates['bloodGroup'] = bloodGroup;
      if (gender != null) updates['gender'] = gender;
      if (dateOfBirth != null) {
        updates['dateOfBirth'] = Timestamp.fromDate(dateOfBirth);
      }
      if (bio != null) updates['bio'] = bio;
      if (address != null) updates['address'] = address;
      if (city != null) updates['city'] = city;

      // Upload profile image if provided
      if (profileImage != null) {
        final imageUrl = await _storageService.uploadProfileImage(
          _userId,
          profileImage,
        );
        updates['profileImageUrl'] = imageUrl;
      }

      if (updates.isNotEmpty) {
        await _databaseService.updateUser(_userId, updates);
      }

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update user location
  Future<void> updateLocation(double latitude, double longitude) async {
    if (_userId == null) return;

    try {
      await _databaseService.updateUser(_userId, {
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (e) {
      // Silent fail for location updates
    }
  }

  /// Toggle availability status
  Future<void> toggleAvailability(bool isAvailable) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      await _databaseService.updateUser(_userId, {'isAvailable': isAvailable});
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update last donation date
  Future<void> updateLastDonation(DateTime donationDate) async {
    if (_userId == null) return;

    try {
      await _databaseService.updateUser(_userId, {
        'lastDonationDate': Timestamp.fromDate(donationDate),
        'totalDonations': FieldValue.increment(1),
      });
    } catch (e) {
      // Handle error
    }
  }
}

/// User profile notifier provider
final userProfileNotifierProvider =
    StateNotifierProvider<UserProfileNotifier, AsyncValue<void>>((ref) {
      return UserProfileNotifier(
        ref.watch(databaseServiceProvider),
        ref.watch(storageServiceProvider),
        ref.watch(currentUserIdProvider),
      );
    });

/// Nearby donors provider
final nearbyDonorsProvider =
    FutureProvider.family<List<UserModel>, NearbyDonorsParams>((
      ref,
      params,
    ) async {
      final databaseService = ref.read(databaseServiceProvider);
      return await databaseService.getNearbyDonors(
        params.latitude,
        params.longitude,
        params.bloodGroup,
        params.radiusKm,
      );
    });

/// Parameters for nearby donors query
class NearbyDonorsParams {
  final double latitude;
  final double longitude;
  final String bloodGroup;
  final double radiusKm;

  NearbyDonorsParams({
    required this.latitude,
    required this.longitude,
    required this.bloodGroup,
    this.radiusKm = 10.0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NearbyDonorsParams &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.bloodGroup == bloodGroup &&
        other.radiusKm == radiusKm;
  }

  @override
  int get hashCode =>
      latitude.hashCode ^
      longitude.hashCode ^
      bloodGroup.hashCode ^
      radiusKm.hashCode;
}
