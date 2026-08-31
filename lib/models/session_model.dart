class SessionModel {
  final String sessionId;
  final String userId;
  final String storeId;
  final DateTime checkInTime;
  DateTime? checkOutTime;
  String status; // active | checked_out | paid

  // Reserved for board/hardware integration
  final String? entryGateId;
  final String? exitGateId;
  final String? bleConnectionId;

  SessionModel({
    required this.sessionId,
    required this.userId,
    required this.storeId,
    required this.checkInTime,
    this.checkOutTime,
    this.status = 'active',
    this.entryGateId,
    this.exitGateId,
    this.bleConnectionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'storeId': storeId,
      'checkInTime': checkInTime.toIso8601String(),
      'checkOutTime': checkOutTime?.toIso8601String(),
      'status': status,
      'entryGateId': entryGateId,
      'exitGateId': exitGateId,
      'bleConnectionId': bleConnectionId,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      sessionId: map['sessionId'] ?? '',
      userId: map['userId'] ?? '',
      storeId: map['storeId'] ?? '',
      checkInTime: DateTime.parse(map['checkInTime']),
      checkOutTime: map['checkOutTime'] != null
          ? DateTime.parse(map['checkOutTime'])
          : null,
      status: map['status'] ?? 'active',
      entryGateId: map['entryGateId'],
      exitGateId: map['exitGateId'],
      bleConnectionId: map['bleConnectionId'],
    );
  }
}
