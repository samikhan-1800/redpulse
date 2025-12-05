import 'package:cloud_firestore/cloud_firestore.dart';

/// Donation record model
class Donation {
  final String id;
  final String donorId;
  final String donorName;
  final String recipientId;
  final String recipientName;
  final String requestId;
  final String bloodGroup;
  final int units;
  final String hospitalName;
  final String hospitalAddress;
  final DateTime donationDate;
  final DateTime createdAt;
  final String? notes;
  final bool isVerified;

  Donation({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.recipientId,
    required this.recipientName,
    required this.requestId,
    required this.bloodGroup,
    required this.units,
    required this.hospitalName,
    required this.hospitalAddress,
    required this.donationDate,
    required this.createdAt,
    this.notes,
    this.isVerified = false,
  });

  /// Create from Firestore document
  factory Donation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Donation(
      id: doc.id,
      donorId: data['donorId'] ?? '',
      donorName: data['donorName'] ?? '',
      recipientId: data['recipientId'] ?? '',
      recipientName: data['recipientName'] ?? '',
      requestId: data['requestId'] ?? '',
      bloodGroup: data['bloodGroup'] ?? '',
      units: data['units'] ?? 1,
      hospitalName: data['hospitalName'] ?? '',
      hospitalAddress: data['hospitalAddress'] ?? '',
      donationDate: (data['donationDate'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      notes: data['notes'],
      isVerified: data['isVerified'] ?? false,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'donorId': donorId,
      'donorName': donorName,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'requestId': requestId,
      'bloodGroup': bloodGroup,
      'units': units,
      'hospitalName': hospitalName,
      'hospitalAddress': hospitalAddress,
      'donationDate': Timestamp.fromDate(donationDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
      'isVerified': isVerified,
    };
  }

  /// Copy with modified fields
  Donation copyWith({
    String? id,
    String? donorId,
    String? donorName,
    String? recipientId,
    String? recipientName,
    String? requestId,
    String? bloodGroup,
    int? units,
    String? hospitalName,
    String? hospitalAddress,
    DateTime? donationDate,
    DateTime? createdAt,
    String? notes,
    bool? isVerified,
  }) {
    return Donation(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      requestId: requestId ?? this.requestId,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      units: units ?? this.units,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalAddress: hospitalAddress ?? this.hospitalAddress,
      donationDate: donationDate ?? this.donationDate,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      isVerified: isVerified ?? this.isVerified,
    );
  }

  @override
  String toString() {
    return 'Donation(id: $id, donorId: $donorId, bloodGroup: $bloodGroup)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Donation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
