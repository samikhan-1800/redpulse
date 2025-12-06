import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/blood_request_model.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/donation_model.dart';
import 'auth_provider.dart';

/// Blood request notifier for managing requests
class BloodRequestNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _databaseService;
  final NotificationService _notificationService;
  final String? _userId;
  final UserModel? _currentUser;

  BloodRequestNotifier(
    this._databaseService,
    this._notificationService,
    this._userId,
    this._currentUser,
  ) : super(const AsyncValue.data(null));

  /// Create a new blood request
  Future<String?> createRequest({
    required String bloodGroup,
    required int unitsRequired,
    required String requestType,
    required String urgencyLevel,
    required String patientName,
    required String hospitalName,
    required String hospitalAddress,
    required double latitude,
    required double longitude,
    required DateTime requiredBy,
    String? additionalNotes,
  }) async {
    if (_userId == null || _currentUser == null) return null;

    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final request = BloodRequest(
        id: '', // Will be set by Firestore
        requesterId: _userId,
        requesterName: _currentUser.name,
        requesterPhone: _currentUser.phone,
        requesterImageUrl: _currentUser.profileImageUrl,
        bloodGroup: bloodGroup,
        unitsRequired: unitsRequired,
        requestType: requestType,
        urgencyLevel: urgencyLevel,
        status: 'pending',
        patientName: patientName,
        hospitalName: hospitalName,
        hospitalAddress: hospitalAddress,
        latitude: latitude,
        longitude: longitude,
        additionalNotes: additionalNotes,
        requiredBy: requiredBy,
        createdAt: now,
        updatedAt: now,
      );

      final requestId = await _databaseService.createRequest(request);

      print('🆘 Request created with ID: $requestId');
      print('🆘 Request type: $requestType');
      print('🆘 Location: ($latitude, $longitude)');
      print('🆘 Blood group: $bloodGroup');

      // Find and notify nearby donors
      final nearbyDonors = await _databaseService.getNearbyDonors(
        latitude,
        longitude,
        bloodGroup,
        requestType == 'sos' ? 25.0 : 10.0,
      );

      print('🆘 Found ${nearbyDonors.length} nearby donors');
      if (nearbyDonors.isNotEmpty) {
        print(
          '🆘 Notifying ${nearbyDonors.where((d) => d.id != _userId).length} donors (excluding self)',
        );

        await _notificationService.notifyNearbyDonors(
          requestId: requestId,
          bloodGroup: bloodGroup,
          hospitalName: hospitalName,
          requestType: requestType,
          donorIds: nearbyDonors
              .where((d) => d.id != _userId)
              .map((d) => d.id)
              .toList(),
        );

        print('✅ Notifications sent successfully');
      } else {
        print('❌ No nearby donors found to notify');
      }

      state = const AsyncValue.data(null);
      return requestId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Accept a blood request
  Future<String?> acceptRequest(BloodRequest request) async {
    if (_userId == null || _currentUser == null) return null;

    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();

      // Create chat between donor and requester
      final chat = Chat(
        id: '',
        requestId: request.id,
        participantIds: [_userId, request.requesterId],
        participantNames: {
          _userId: _currentUser.name,
          request.requesterId: request.requesterName,
        },
        participantImages: {
          _userId: _currentUser.profileImageUrl,
          request.requesterId: request.requesterImageUrl,
        },
        unreadCount: {_userId: 0, request.requesterId: 0},
        createdAt: now,
        updatedAt: now,
      );

      final chatId = await _databaseService.createChat(chat);

      // Update request status
      await _databaseService.updateRequest(request.id, {
        'status': 'accepted',
        'acceptedById': _userId,
        'acceptedByName': _currentUser.name,
        'acceptedAt': Timestamp.fromDate(now),
        'chatId': chatId,
      });

      // Notify requester
      await _notificationService.sendNotificationToUser(
        userId: request.requesterId,
        title: '🎉 Request Accepted!',
        body: '${_currentUser.name} has accepted your blood request',
        data: {
          'type': 'request_accepted',
          'requestId': request.id,
          'chatId': chatId,
        },
      );

      state = const AsyncValue.data(null);
      return chatId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Cancel a request
  Future<void> cancelRequest(String requestId) async {
    state = const AsyncValue.loading();
    try {
      await _databaseService.updateRequest(requestId, {'status': 'cancelled'});
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Complete a request (mark donation as done)
  Future<void> completeRequest(String requestId) async {
    state = const AsyncValue.loading();
    try {
      await _databaseService.updateRequest(requestId, {
        'status': 'completed',
        'completedAt': Timestamp.now(),
      });
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update request status
  Future<void> updateStatus(
    String requestId,
    String status, {
    String? acceptedById,
  }) async {
    state = const AsyncValue.loading();
    try {
      final updates = <String, dynamic>{
        'status': status,
        'updatedAt': Timestamp.now(),
      };

      if (status == 'accepted' &&
          acceptedById != null &&
          _currentUser != null) {
        updates['acceptedById'] = acceptedById;
        updates['acceptedByName'] = _currentUser.name;
        updates['acceptedAt'] = Timestamp.now();
      }

      if (status == 'completed') {
        updates['completedAt'] = Timestamp.now();

        // Get the request to find donor and requester
        final request = await _databaseService.getRequest(requestId);
        if (request != null && request.acceptedById != null) {
          final now = DateTime.now();

          // Create donation record
          final donation = Donation(
            id: '',
            donorId: request.acceptedById!,
            donorName: request.acceptedByName ?? '',
            recipientId: request.requesterId,
            recipientName: request.requesterName,
            requestId: requestId,
            bloodGroup: request.bloodGroup,
            units: request.unitsRequired,
            hospitalName: request.hospitalName,
            hospitalAddress: request.hospitalAddress,
            donationDate: now,
            createdAt: now,
            isVerified: true,
          );

          await _databaseService.createDonation(donation);

          // Notify donor about completion
          await _notificationService.sendNotificationToUser(
            userId: request.acceptedById!,
            title: '🎉 Donation Completed!',
            body:
                'Thank you for saving a life! Your donation has been recorded.',
            data: {'type': 'donation_completed', 'requestId': requestId},
          );
        }
      }

      await _databaseService.updateRequest(requestId, updates);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Blood request notifier provider
final bloodRequestNotifierProvider =
    StateNotifierProvider<BloodRequestNotifier, AsyncValue<void>>((ref) {
      final currentUser = ref.watch(currentUserProfileProvider).value;
      return BloodRequestNotifier(
        ref.watch(databaseServiceProvider),
        ref.watch(notificationServiceProvider),
        ref.watch(currentUserIdProvider),
        currentUser,
      );
    });

/// User's requests stream provider
final userRequestsProvider = StreamProvider<List<BloodRequest>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final databaseService = ref.watch(databaseServiceProvider);
  return databaseService.userRequestsStream(userId);
});

/// Nearby requests stream provider
final nearbyRequestsProvider =
    StreamProvider.family<List<BloodRequest>, NearbyRequestsParams>((
      ref,
      params,
    ) {
      final databaseService = ref.watch(databaseServiceProvider);
      return databaseService.nearbyRequestsStream(
        params.latitude,
        params.longitude,
        params.radiusKm,
      );
    });

/// Single request provider
final requestDetailProvider = FutureProvider.family<BloodRequest?, String>((
  ref,
  requestId,
) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getRequest(requestId);
});

/// Parameters for nearby requests query
class NearbyRequestsParams {
  final double latitude;
  final double longitude;
  final double radiusKm;

  NearbyRequestsParams({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10.0,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NearbyRequestsParams &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.radiusKm == radiusKm;
  }

  @override
  int get hashCode =>
      latitude.hashCode ^ longitude.hashCode ^ radiusKm.hashCode;
}
