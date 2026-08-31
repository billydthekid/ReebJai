/// Commands sent from Flutter app → Firebase RTDB → ESP32
class BoardCommand {
  final String commandId;
  final String boardId;
  final String type; // open_gate, close_gate, alarm, show_product, lcd_message, led_green, led_red, led_off, buzzer_on, buzzer_off
  final Map<String, dynamic> payload; // e.g. {'productName': '...', 'price': 20.0}
  final String status; // pending, executing, done, error
  final DateTime createdAt;

  BoardCommand({
    required this.commandId,
    required this.boardId,
    required this.type,
    this.payload = const {},
    this.status = 'pending',
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'commandId': commandId,
      'boardId': boardId,
      'type': type,
      'payload': payload,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory BoardCommand.fromMap(Map<String, dynamic> map) {
    return BoardCommand(
      commandId: map['commandId'] ?? '',
      boardId: map['boardId'] ?? '',
      type: map['type'] ?? '',
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

/// Status reported by ESP32 → Firebase RTDB → Flutter app
class BoardStatus {
  final String boardId;
  final String role; // gate, shelf
  final bool online;
  final String lastSeen;
  final String currentState; // idle, alarm, gate_open, gate_closed

  BoardStatus({
    required this.boardId,
    required this.role,
    this.online = false,
    this.lastSeen = '',
    this.currentState = 'idle',
  });

  Map<String, dynamic> toMap() {
    return {
      'boardId': boardId,
      'role': role,
      'online': online,
      'lastSeen': lastSeen,
      'currentState': currentState,
    };
  }

  factory BoardStatus.fromMap(Map<String, dynamic> map) {
    return BoardStatus(
      boardId: map['boardId'] ?? '',
      role: map['role'] ?? '',
      online: map['online'] ?? false,
      lastSeen: map['lastSeen'] ?? '',
      currentState: map['currentState'] ?? 'idle',
    );
  }
}
