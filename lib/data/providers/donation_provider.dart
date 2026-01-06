import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/database_service.dart';
import '../models/donation_model.dart';
import 'auth_provider.dart';

class DonationNotifier extends StateNotifier<AsyncValue<void>> {
  final DatabaseService _databaseService;
  final String? _userId;

  DonationNotifier(this._databaseService, this._userId)
    : super(const AsyncValue.data(null));

  Future<String?> recordDonation({
    required String recipientId,
    required String recipientName,
    required String requestId,
    required String bloodGroup,
    required int units,
    required String hospitalName,
    required String hospitalAddress,
    required DateTime donationDate,
    required String donorName,
    String? notes,
  }) async {
    if (_userId == null) return null;

    state = const AsyncValue.loading();
    try {
      final donation = Donation(
        id: '',
        donorId: _userId,
        donorName: donorName,
        recipientId: recipientId,
        recipientName: recipientName,
        requestId: requestId,
        bloodGroup: bloodGroup,
        units: units,
        hospitalName: hospitalName,
        hospitalAddress: hospitalAddress,
        donationDate: donationDate,
        createdAt: DateTime.now(),
        notes: notes,
      );

      final donationId = await _databaseService.createDonation(donation);

      await _databaseService.updateUser(_userId, {
        'lastDonationDate': Timestamp.fromDate(donationDate),
        'totalDonations': FieldValue.increment(1),
      });

      state = const AsyncValue.data(null);
      return donationId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final donationNotifierProvider =
    StateNotifierProvider<DonationNotifier, AsyncValue<void>>((ref) {
      return DonationNotifier(
        ref.watch(databaseServiceProvider),
        ref.watch(currentUserIdProvider),
      );
    });

final userDonationsProvider = StreamProvider<List<Donation>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  final databaseService = ref.watch(databaseServiceProvider);
  return databaseService.userDonationsStream(userId);
});

final donationStatsProvider = Provider<DonationStats>((ref) {
  final donationsAsync = ref.watch(userDonationsProvider);
  final donations = donationsAsync.whenOrNull(data: (data) => data) ?? [];

  return DonationStats(
    totalDonations: donations.length,
    totalUnits: donations.fold(0, (sum, d) => sum + d.units),
    lastDonation: donations.isNotEmpty ? donations.first : null,
    donationsByMonth: _groupDonationsByMonth(donations),
  );
});

Map<String, int> _groupDonationsByMonth(List<Donation> donations) {
  final Map<String, int> grouped = {};

  for (final donation in donations) {
    final key =
        '${donation.donationDate.year}-${donation.donationDate.month.toString().padLeft(2, '0')}';
    grouped[key] = (grouped[key] ?? 0) + 1;
  }

  return grouped;
}

class DonationStats {
  final int totalDonations;
  final int totalUnits;
  final Donation? lastDonation;
  final Map<String, int> donationsByMonth;

  DonationStats({
    required this.totalDonations,
    required this.totalUnits,
    this.lastDonation,
    required this.donationsByMonth,
  });

  int get livesSaved => totalDonations;
}
