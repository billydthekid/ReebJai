class StoreModel {
  final String storeId;
  final String name;
  final String address;
  final String qrCode;
  final bool isOpen;

  // Reserved for board/hardware integration
  final String? bleBeaconId;
  final String? espDeviceId;
  final String? wifiSsid;

  StoreModel({
    required this.storeId,
    required this.name,
    required this.address,
    required this.qrCode,
    this.isOpen = true,
    this.bleBeaconId,
    this.espDeviceId,
    this.wifiSsid,
  });

  Map<String, dynamic> toMap() {
    return {
      'storeId': storeId,
      'name': name,
      'address': address,
      'qrCode': qrCode,
      'isOpen': isOpen,
      'bleBeaconId': bleBeaconId,
      'espDeviceId': espDeviceId,
      'wifiSsid': wifiSsid,
    };
  }

  factory StoreModel.fromMap(Map<String, dynamic> map) {
    return StoreModel(
      storeId: map['storeId'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      qrCode: map['qrCode'] ?? '',
      isOpen: map['isOpen'] ?? true,
      bleBeaconId: map['bleBeaconId'],
      espDeviceId: map['espDeviceId'],
      wifiSsid: map['wifiSsid'],
    );
  }
}
