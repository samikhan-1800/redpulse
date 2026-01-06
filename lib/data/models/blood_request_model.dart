import 'package:cloud_firestore/cloud_firestore.dart';

class BloodRequest {
  final String id;
  final String requesterId;
  final String requesterName;
  final String requesterPhone;
  final String? requesterImageUrl;
  final String bloodGroup;
  final int unitsRequired;
  final String requestType;
  final String urgencyLevel;
  final String status;
  final String patientName;
  final String hospitalName;
  final String hospitalAddress;
  final double latitude;
  final double longitude;
  final String? additionalNotes;
  final DateTime requiredBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? acceptedById;
  final String? acceptedByName;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final String? chatId;
  final List<String> acceptedByIds;
  final int unitsAccepted;

  BloodRequest({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.requesterPhone,
    this.requesterImageUrl,
    required this.bloodGroup,
    required this.unitsRequired,
    required this.requestType,
    required this.urgencyLevel,
    required this.status,
    required this.patientName,
    required this.hospitalName,
    required this.hospitalAddress,
    required this.latitude,
    required this.longitude,
    this.additionalNotes,
    required this.requiredBy,
    required this.createdAt,
    required this.updatedAt,
    this.acceptedById,
    this.acceptedByName,
    this.acceptedAt,
    this.completedAt,
    this.chatId,
    this.acceptedByIds = const [],
    this.unitsAccepted = 0,
  });

  factory BloodRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BloodRequest(
      id: doc.id,
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? '',
      requesterPhone: data['requesterPhone'] ?? '',
      requesterImageUrl: data['requesterImageUrl'],
      bloodGroup: data['bloodGroup'] ?? '',
      unitsRequired: data['unitsRequired'] ?? 1,
      requestType: data['requestType'] ?? 'normal',
      urgencyLevel: data['urgencyLevel'] ?? 'medium',
      status: data['status'] ?? 'pending',
      patientName: data['patientName'] ?? '',
      hospitalName: data['hospitalName'] ?? '',
      hospitalAddress: data['hospitalAddress'] ?? '',
      latitude: (data['latitude'] ?? 0).toDouble(),
      longitude: (data['longitude'] ?? 0).toDouble(),
      additionalNotes: data['additionalNotes'],
      requiredBy: (data['requiredBy'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      acceptedById: data['acceptedById'],
      acceptedByName: data['acceptedByName'],
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      chatId: data['chatId'],
      acceptedByIds: data['acceptedByIds'] != null
          ? List<String>.from(data['acceptedByIds'] as List)
          : [],
      unitsAccepted: data['unitsAccepted'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterPhone': requesterPhone,
      'requesterImageUrl': requesterImageUrl,
      'bloodGroup': bloodGroup,
      'unitsRequired': unitsRequired,
      'requestType': requestType,
      'urgencyLevel': urgencyLevel,
      'status': status,
      'patientName': patientName,
      'hospitalName': hospitalName,
      'hospitalAddress': hospitalAddress,
      'latitude': latitude,
      'longitude': longitude,
      'additionalNotes': additionalNotes,
      'requiredBy': Timestamp.fromDate(requiredBy),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'acceptedById': acceptedById,
      'acceptedByName': acceptedByName,
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'chatId': chatId,
      'acceptedByIds': acceptedByIds,
      'unitsAccepted': unitsAccepted,
    };
  }

  BloodRequest copyWith({
    String? id,
    String? requesterId,
    String? requesterName,
    String? requesterPhone,
    String? requesterImageUrl,
    String? bloodGroup,
    int? unitsRequired,
    String? requestType,
    String? urgencyLevel,
    String? status,
    String? patientName,
    String? hospitalName,
    String? hospitalAddress,
    double? latitude,
    double? longitude,
    String? additionalNotes,
    DateTime? requiredBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? acceptedById,
    String? acceptedByName,
    DateTime? acceptedAt,
    DateTime? completedAt,
    String? chatId,
    List<String>? acceptedByIds,
    int? unitsAccepted,
  }) {
    return BloodRequest(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterPhone: requesterPhone ?? this.requesterPhone,
      requesterImageUrl: requesterImageUrl ?? this.requesterImageUrl,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      unitsRequired: unitsRequired ?? this.unitsRequired,
      requestType: requestType ?? this.requestType,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      status: status ?? this.status,
      patientName: patientName ?? this.patientName,
      hospitalName: hospitalName ?? this.hospitalName,
      hospitalAddress: hospitalAddress ?? this.hospitalAddress,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      requiredBy: requiredBy ?? this.requiredBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      acceptedById: acceptedById ?? this.acceptedById,
      acceptedByName: acceptedByName ?? this.acceptedByName,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      chatId: chatId ?? this.chatId,
      acceptedByIds: acceptedByIds ?? this.acceptedByIds,
      unitsAccepted: unitsAccepted ?? this.unitsAccepted,
    );
  }

  bool get isFulfilled {
    return unitsAccepted >= unitsRequired;
  }

  String get acceptanceProgress {
    return '$unitsAccepted of $unitsRequired';
  }

  bool get isExpired {
    return requiredBy.isBefore(DateTime.now()) && status == 'pending';
  }

  bool get isActive {
    return (status == 'pending' || status == 'accepted') && !isFulfilled;
  }

  bool get isEmergency => requestType == 'emergency';

  bool get isSOS => requestType == 'sos';

  List<String> get compatibleBloodGroups {
    switch (bloodGroup) {
      case 'A+':
        return ['A+', 'A-', 'O+', 'O-'];
      case 'A-':
        return ['A-', 'O-'];
      case 'B+':
        return ['B+', 'B-', 'O+', 'O-'];
      case 'B-':
        return ['B-', 'O-'];
      case 'AB+':
        return ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
      case 'AB-':
        return ['A-', 'B-', 'AB-', 'O-'];
      case 'O+':
        return ['O+', 'O-'];
      case 'O-':
        return ['O-'];
      default:
        return [bloodGroup];
    }
  }

  @override
  String toString() {
    return 'BloodRequest(id: $id, bloodGroup: $bloodGroup, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BloodRequest && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
