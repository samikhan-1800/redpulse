import 'package:cloud_firestore/cloud_firestore.dart';

/// User model representing a blood donor/recipient
class UserModel {
  final String id;
  final String email;
  final String name;
  final String phone;
  final String bloodGroup;
  final String gender;
  final DateTime dateOfBirth;
  final String? profileImageUrl;
  final String? bio;
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final bool isAvailable;
  final bool isVerified;
  final DateTime? lastDonationDate;
  final int totalDonations;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fcmToken;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.bloodGroup,
    required this.gender,
    required this.dateOfBirth,
    this.profileImageUrl,
    this.bio,
    this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.isAvailable = true,
    this.isVerified = false,
    this.lastDonationDate,
    this.totalDonations = 0,
    required this.createdAt,
    required this.updatedAt,
    this.fcmToken,
  });

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      bloodGroup: data['bloodGroup'] ?? '',
      gender: data['gender'] ?? '',
      dateOfBirth: (data['dateOfBirth'] as Timestamp).toDate(),
      profileImageUrl: data['profileImageUrl'],
      bio: data['bio'],
      address: data['address'],
      city: data['city'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      isAvailable: data['isAvailable'] ?? true,
      isVerified: data['isVerified'] ?? false,
      lastDonationDate: data['lastDonationDate'] != null
          ? (data['lastDonationDate'] as Timestamp).toDate()
          : null,
      totalDonations: data['totalDonations'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      fcmToken: data['fcmToken'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'bloodGroup': bloodGroup,
      'gender': gender,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'address': address,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'isAvailable': isAvailable,
      'isVerified': isVerified,
      'lastDonationDate': lastDonationDate != null
          ? Timestamp.fromDate(lastDonationDate!)
          : null,
      'totalDonations': totalDonations,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'fcmToken': fcmToken,
    };
  }

  /// Copy with modified fields
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    String? bloodGroup,
    String? gender,
    DateTime? dateOfBirth,
    String? profileImageUrl,
    String? bio,
    String? address,
    String? city,
    double? latitude,
    double? longitude,
    bool? isAvailable,
    bool? isVerified,
    DateTime? lastDonationDate,
    int? totalDonations,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fcmToken,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      address: address ?? this.address,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isAvailable: isAvailable ?? this.isAvailable,
      isVerified: isVerified ?? this.isVerified,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      totalDonations: totalDonations ?? this.totalDonations,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }

  /// Calculate age from date of birth
  int get age {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  /// Check if user can donate based on last donation date and gender
  bool get canDonate {
    if (lastDonationDate == null) return true;
    final daysSinceLastDonation = DateTime.now()
        .difference(lastDonationDate!)
        .inDays;
    // Males can donate every 90 days, females every 120 days
    final cooldownDays = gender.toLowerCase() == 'male' ? 90 : 120;
    return daysSinceLastDonation >= cooldownDays;
  }

  /// Get next eligible donation date
  DateTime? get nextEligibleDate {
    if (lastDonationDate == null) return null;
    final cooldownDays = gender.toLowerCase() == 'male' ? 90 : 120;
    return lastDonationDate!.add(Duration(days: cooldownDays));
  }

  /// Check if user has location set
  bool get hasLocation => latitude != null && longitude != null;

  @override
  String toString() {
    return 'UserModel(id: $id, name: $name, bloodGroup: $bloodGroup)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
