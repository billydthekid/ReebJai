import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// BLE Service for detecting ESP32 beacons by proximity (RSSI).
///
/// ESP32 advertises with a known service name prefix "REEBJAI_".
/// The app scans for these beacons and reports proximity.
class BleService {
  // ESP32 advertised names — must match firmware
  static const String gateBeaconName = 'REEBJAI_GATE';
  static const String shelfBeaconName = 'REEBJAI_SHELF';

  // RSSI threshold: closer than this = "near"
  static const int nearThresholdRssi = -70; // dBm

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  final _nearbyDevices = <String, int>{}; // deviceName → RSSI
  final _onDeviceNearby = StreamController<String>.broadcast();

  /// Stream that emits a device name when it becomes "near"
  Stream<String> get onDeviceNearby => _onDeviceNearby.stream;

  /// Current nearby devices and their RSSI
  Map<String, int> get nearbyDevices => Map.unmodifiable(_nearbyDevices);

  /// Start scanning for REEBJAI ESP32 beacons
  Future<void> startScan() async {
    try {
      // Check if Bluetooth is available and on
      if (await FlutterBluePlus.isSupported == false) {
        debugPrint('[BLE] Bluetooth not supported on this device');
        return;
      }

      // Wait for Bluetooth to be on
      final state = await FlutterBluePlus.adapterState.first;
      if (state != BluetoothAdapterState.on) {
        debugPrint('[BLE] Bluetooth is off. Please turn it on.');
        return;
      }

      // Stop any existing scan
      await stopScan();

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          final name = r.advertisementData.advName;
          if (name.startsWith('REEBJAI_')) {
            final rssi = r.rssi;
            _nearbyDevices[name] = rssi;

            if (rssi > nearThresholdRssi) {
              _onDeviceNearby.add(name);
              debugPrint('[BLE] Near device: $name (RSSI: $rssi)');
            }
          }
        }
      });

      debugPrint('[BLE] Scan started');
    } catch (e) {
      debugPrint('[BLE] Scan error: $e');
    }
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSubscription?.cancel();
    _scanSubscription = null;
    _nearbyDevices.clear();
  }

  /// Check if a specific beacon is nearby
  bool isNearby(String beaconName) {
    final rssi = _nearbyDevices[beaconName];
    return rssi != null && rssi > nearThresholdRssi;
  }

  /// Check if gate ESP32 is nearby
  bool get isNearGate => isNearby(gateBeaconName);

  /// Check if shelf ESP32 is nearby
  bool get isNearShelf => isNearby(shelfBeaconName);

  /// Dispose resources
  void dispose() {
    stopScan();
    _onDeviceNearby.close();
  }
}
