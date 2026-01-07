import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../models/blood_request_model.dart';
import '../models/user_model.dart';
import '../models/chat_model.dart';
import '../models/donation_model.dart';
import 'auth_provider.dart';

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
    if (_userId == null || _currentUser == null) {
      state = AsyncValue.error(
        'Authentication required. Please log in again.',
        StackTrace.current,
      );
      return null;
    }

    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();
      final request = BloodRequest(
        id: '',
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

      final nearbyDonors = await _databaseService.getNearbyDonors(
        latitude,
        longitude,
        bloodGroup,
        requestType == 'sos' ? 25.0 : 10.0,
      );

      if (nearbyDonors.isNotEmpty) {
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
      }

      state = const AsyncValue.data(null);
      return requestId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; // Ensure error reaches UI
    }
  }

  Future<void> updateRequest({
    required String requestId,
    required String bloodGroup,
    required int unitsRequired,
    required String requestType,
    required String urgencyLevel,
    required String patientName,
    required String hospitalName,
    required String hospitalAddress,
    required double latitude,
    required double longitude,
    String? additionalNotes,
  }) async {
    if (_userId == null || _currentUser == null) return;

    state = const AsyncValue.loading();
    try {
      final existingRequest = await _databaseService.getRequest(requestId);
      if (existingRequest == null) {
        throw Exception('Request not found');
      }

      if (existingRequest.status != 'pending') {
        throw Exception('Only pending requests can be edited');
      }

      await _databaseService.updateRequest(requestId, {
        'bloodGroup': bloodGroup,
        'unitsRequired': unitsRequired,
        'requestType': requestType,
        'urgencyLevel': urgencyLevel,
        'patientName': patientName,
        'hospitalName': hospitalName,
        'hospitalAddress': hospitalAddress,
        'latitude': latitude,
        'longitude': longitude,
        'additionalNotes': additionalNotes,
        'updatedAt': Timestamp.now(),
      });

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deleteRequest(String requestId) async {
    if (_userId == null) return;

    state = const AsyncValue.loading();
    try {
      final request = await _databaseService.getRequest(requestId);
      if (request == null) {
        throw Exception('Request not found');
      }

      if (request.requesterId != _userId) {
        throw Exception('You can only delete your own requests');
      }

      await _databaseService.deleteRequest(requestId);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<String?> acceptRequest(BloodRequest request) async {
    if (_userId == null || _currentUser == null) return null;

    if (request.acceptedByIds.contains(_userId)) {
      throw Exception('You have already accepted this request');
    }

    if (request.isFulfilled) {
      throw Exception('This request has already been fulfilled');
    }

    state = const AsyncValue.loading();
    try {
      final now = DateTime.now();

      final chatId = await _databaseService.createChat(
        Chat(
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
        ),
      );

      final updatedAcceptedByIds = [...request.acceptedByIds, _userId];
      final updatedUnitsAccepted = request.unitsAccepted + 1;

      await _databaseService.updateRequest(request.id, {
        'status': updatedUnitsAccepted >= request.unitsRequired
            ? 'fulfilled'
            : 'accepted',
        'acceptedById': _userId,
        'acceptedByName': _currentUser.name,
        'acceptedAt': Timestamp.fromDate(now),
        'chatId': chatId,
        'acceptedByIds': updatedAcceptedByIds,
        'unitsAccepted': updatedUnitsAccepted,
      });

      await _notificationService.sendNotificationToUser(
        userId: request.requesterId,
        title: '🎉 Request Accepted!',
        body: updatedUnitsAccepted >= request.unitsRequired
            ? '${_currentUser.name} accepted - All ${request.unitsRequired} units fulfilled!'
            : '${_currentUser.name} accepted - $updatedUnitsAccepted of ${request.unitsRequired} units',
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

  Future<void> cancelRequest(String requestId) async {
    state = const AsyncValue.loading();
    try {
      await _databaseService.updateRequest(requestId, {'status': 'cancelled'});
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

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

        final request = await _databaseService.getRequest(requestId);
        if (request != null && request.acceptedById != null) {
          final now = DateTime.now();

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

          await _databaseService.updateUser(request.acceptedById!, {
            'lastDonationDate': Timestamp.fromDate(now),
            'totalDonations': FieldValue.increment(1),
          });

          await _notificationService.sendNotificationToUser(
            userId: request.acceptedById!,
            title: '🎉 Donation Completed!',
            body:
                'Thank you for saving a life! Your donation has been recorded.',
            data: {'type': 'donation_completed', 'requestId': requestId},
          );
          if (request.chatId != null) {
            try {
              await _databaseService.deleteChat(request.chatId!);
            } catch (e) {
              print('Failed to delete chat: $e');
            }
          }
        }
      }

      await _databaseService.updateRequest(requestId, updates);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

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

final userRequestsProvider = StreamProvider<List<BloodRequest>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final databaseService = ref.watch(databaseServiceProvider);
  return databaseService.userRequestsStream(userId);
});

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

final requestDetailProvider = FutureProvider.family<BloodRequest?, String>((
  ref,
  requestId,
) async {
  final databaseService = ref.read(databaseServiceProvider);
  return await databaseService.getRequest(requestId);
});

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
