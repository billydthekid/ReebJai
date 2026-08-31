import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';
import '../models/board_command_model.dart';

/// Service for sending commands to ESP32 boards via Firebase Realtime Database.
///
/// RTDB Structure:
///   /boards/{boardId}/status   → BoardStatus (ESP32 writes, App reads)
///   /boards/{boardId}/command  → BoardCommand (App writes, ESP32 reads)
class BoardCommandService {
  static const String _rtdbUrl =
      'https://reejai-app-default-rtdb.asia-southeast1.firebasedatabase.app';

  DatabaseReference? _dbRef;
  final _uuid = const Uuid();

  /// Lazy-init DB ref so it doesn't connect on app startup
  DatabaseReference get _db {
    _dbRef ??= FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: _rtdbUrl,
    ).ref();
    return _dbRef!;
  }

  // ─── Board IDs (match with ESP32 firmware) ─────────
  static const String gateBoard = 'gate_001';
  static const String shelfBoard = 'shelf_001';

  // ─── Send Command ──────────────────────────────────

  /// Send a command to a specific board.
  /// ESP32 listens on /boards/{boardId}/command
  Future<void> sendCommand(String boardId, String type,
      {Map<String, dynamic> payload = const {},
      String? reason}) async {
    final command = BoardCommand(
      commandId: _uuid.v4(),
      boardId: boardId,
      type: type,
      payload: payload,
      status: 'pending',
      createdAt: DateTime.now(),
    );
    final map = command.toMap();
    if (reason != null) map['reason'] = reason;
    await _db.child('boards/$boardId/command').set(map);
  }

  // ─── Convenience Methods ───────────────────────────

  /// Open the gate (green LED + unlock)
  /// [reason]: 'checkin' (entry) or 'payment_complete' (exit)
  Future<void> openGate({String reason = 'checkin',
      String? line1, String? line2}) async {
    final payload = <String, dynamic>{};
    if (line1 != null) payload['line1'] = line1;
    if (line2 != null) payload['line2'] = line2;
    await sendCommand(gateBoard, 'open_gate',
        payload: payload, reason: reason);
  }

  /// Close the gate (red LED)
  Future<void> closeGate() async {
    await sendCommand(gateBoard, 'close_gate');
  }

  /// Trigger alarm (buzzer + red LED) — unpaid exit
  Future<void> triggerAlarm() async {
    await sendCommand(gateBoard, 'alarm');
  }

  /// Stop alarm
  Future<void> stopAlarm() async {
    await sendCommand(gateBoard, 'alarm_off');
  }

  /// Show product info on shelf LCD
  Future<void> showProductOnLcd(String productName, double price) async {
    await sendCommand(shelfBoard, 'show_product', payload: {
      'productName': productName,
      'price': price,
    });
  }

  /// Show custom message on shelf LCD
  Future<void> showLcdMessage(String line1, {String line2 = ''}) async {
    await sendCommand(shelfBoard, 'lcd_message', payload: {
      'line1': line1,
      'line2': line2,
    });
  }

  /// Show custom message on gate LCD
  Future<void> showGateLcdMessage(String line1, {String line2 = ''}) async {
    await sendCommand(gateBoard, 'lcd_message', payload: {
      'line1': line1,
      'line2': line2,
    });
  }

  /// Set gate LED color
  Future<void> setGateLed(String color) async {
    await sendCommand(gateBoard, 'led_$color'); // led_green, led_red, led_off
  }

  // ─── Read Board Status ─────────────────────────────

  /// Listen to a board's status in real-time
  Stream<BoardStatus> watchBoardStatus(String boardId) {
    return _db.child('boards/$boardId/status').onValue.map((event) {
      final data = event.snapshot.value;
      if (data == null) {
        return BoardStatus(boardId: boardId, role: 'unknown');
      }
      return BoardStatus.fromMap(Map<String, dynamic>.from(data as Map));
    });
  }

  /// Get current status of a board (one-time read)
  Future<BoardStatus?> getBoardStatus(String boardId) async {
    final snap = await _db.child('boards/$boardId/status').get();
    if (!snap.exists || snap.value == null) return null;
    return BoardStatus.fromMap(Map<String, dynamic>.from(snap.value as Map));
  }

  /// Check if a board is online
  Future<bool> isBoardOnline(String boardId) async {
    final status = await getBoardStatus(boardId);
    return status?.online ?? false;
  }
}
