class UserModel {
  final String userId;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final bool hasPaymentCard;
  final int allMemberPoints;
  final DateTime createdAt;

  // Reserved for board/hardware integration
  final String? bleDeviceId;
  final String? fcmToken;

  UserModel({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.hasPaymentCard = false,
    this.allMemberPoints = 0,
    required this.createdAt,
    this.bleDeviceId,
    this.fcmToken,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'hasPaymentCard': hasPaymentCard,
      'allMemberPoints': allMemberPoints,
      'createdAt': createdAt.toIso8601String(),
      'bleDeviceId': bleDeviceId,
      'fcmToken': fcmToken,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map['userId'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      hasPaymentCard: map['hasPaymentCard'] ?? false,
      allMemberPoints: map['allMemberPoints'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      bleDeviceId: map['bleDeviceId'],
      fcmToken: map['fcmToken'],
    );
  }
}
