import 'dart:async';
import 'package:flutter/material.dart';
import '../models/board_command_model.dart';
import 'ble_service.dart';
import 'board_command_service.dart';

/// Provider for board connection state management.
/// Combines BLE proximity detection + Firebase RTDB command sending.
class BoardProvider extends ChangeNotifier {
  final BleService _ble = BleService();
  final BoardCommandService _cmd = BoardCommandService();

  bool _isScanning = false;
  bool _gateOnline = false;
  // bool _shelfOnline = false; // ไม่ใช้ shelf board (ใช้แค่ gate ตัวเดียว)
  bool _nearGate = false;
  // bool _nearShelf = false; // ไม่ใช้ shelf board
  String _gateState = 'idle'; // idle, gate_open, gate_closed, alarm
  // String _shelfState = 'idle'; // ไม่ใช้ shelf board

  StreamSubscription<String>? _bleSub;
  StreamSubscription<BoardStatus>? _gateStatusSub;
  // StreamSubscription<BoardStatus>? _shelfStatusSub; // ไม่ใช้ shelf board

  // ─── Getters ───────────────────────────────────────

  bool get isScanning => _isScanning;
  bool get gateOnline => _gateOnline;
  // bool get shelfOnline => _shelfOnline; // ไม่ใช้ shelf board
  bool get nearGate => _nearGate;
  // bool get nearShelf => _nearShelf; // ไม่ใช้ shelf board
  String get gateState => _gateState;
  // String get shelfState => _shelfState; // ไม่ใช้ shelf board
  BleService get ble => _ble;
  BoardCommandService get cmd => _cmd;

  // ─── Initialize ────────────────────────────────────

  /// Start listening to board statuses via Firebase RTDB.
  /// Wrapped in try-catch so RTDB errors don't crash the app.
  void startListening() {
    try {
      _gateStatusSub = _cmd.watchBoardStatus(BoardCommandService.gateBoard).listen(
        (status) {
          _gateOnline = status.online;
          _gateState = status.currentState;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('[BoardProvider] Gate status error: $e');
          _gateOnline = false;
        },
      );

      // Shelf board ไม่ใช้ — ใช้แค่ gate board ตัวเดียว
      // _shelfStatusSub = _cmd.watchBoardStatus(BoardCommandService.shelfBoard).listen(...);
    } catch (e) {
      debugPrint('[BoardProvider] Failed to start listening: $e');
    }
  }

  /// Start BLE scanning for nearby ESP32 beacons
  Future<void> startBleScan() async {
    _isScanning = true;
    notifyListeners();

    await _ble.startScan();

    _bleSub = _ble.onDeviceNearby.listen((deviceName) {
      if (deviceName == BleService.gateBeaconName) {
        _nearGate = true;
      // } else if (deviceName == BleService.shelfBeaconName) {
      //   _nearShelf = true; // ไม่ใช้ shelf board
      }
      notifyListeners();
    });
  }

  /// Stop BLE scanning
  Future<void> stopBleScan() async {
    await _ble.stopScan();
    _bleSub?.cancel();
    _bleSub = null;
    _isScanning = false;
    _nearGate = false;
    // _nearShelf = false; // ไม่ใช้ shelf board
    notifyListeners();
  }

  // ─── Gate Commands ─────────────────────────────────

  /// Open gate with reason: 'checkin' (entry) or 'payment_complete' (exit)
  Future<void> openGate({String reason = 'checkin',
      String? line1, String? line2}) async {
    await _cmd.openGate(reason: reason, line1: line1, line2: line2);
  }

  Future<void> closeGate() async {
    await _cmd.closeGate();
  }

  Future<void> triggerAlarm() async {
    await _cmd.triggerAlarm();
  }

  Future<void> stopAlarm() async {
    await _cmd.stopAlarm();
  }

  // ─── Shelf Commands (ไม่ใช้ — ใช้แค่ gate board ตัวเดียว) ──────

  // Future<void> showProduct(String name, double price) async {
  //   await _cmd.showProductOnLcd(name, price);
  // }

  // Future<void> showLcdMessage(String line1, {String line2 = ''}) async {
  //   await _cmd.showLcdMessage(line1, line2: line2);
  // }

  // ─── Cleanup ───────────────────────────────────────

  @override
  void dispose() {
    _bleSub?.cancel();
    _gateStatusSub?.cancel();
    // _shelfStatusSub?.cancel(); // ไม่ใช้ shelf board
    _ble.dispose();
    super.dispose();
  }
}
