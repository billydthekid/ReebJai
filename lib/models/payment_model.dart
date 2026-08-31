class PaymentModel {
  final String paymentId;
  final String sessionId;
  final String userId;
  final String storeId;
  final double amount;
  final String method; // stripe_card | truemoney | mobile_banking | bank_qr_manual
  String status; // pending | pending_verification | paid | rejected | cancelled
  final DateTime createdAt;
  DateTime? paidAt;

  // Reserved for payment gateway integration
  final String? gatewayTransactionId;
  final String? gatewayProvider;

  // ─── New fields for manual QR payment ─────────────────
  final String? orderId;
  final String? provider; // stripe | bank_qr_manual | etc.
  final String? qrType; // promptpay | bank_account
  final String? qrImageUrl; // URL of generated QR image (optional)
  final String? slipImageUrl; // URL of uploaded transfer slip
  final DateTime? customerMarkedPaidAt;
  final String? confirmedBy; // admin userId who confirmed
  final DateTime? confirmedAt;
  final String? rejectedReason;
  DateTime? updatedAt;

  PaymentModel({
    required this.paymentId,
    required this.sessionId,
    required this.userId,
    required this.storeId,
    required this.amount,
    required this.method,
    this.status = 'pending',
    required this.createdAt,
    this.paidAt,
    this.gatewayTransactionId,
    this.gatewayProvider,
    this.orderId,
    this.provider,
    this.qrType,
    this.qrImageUrl,
    this.slipImageUrl,
    this.customerMarkedPaidAt,
    this.confirmedBy,
    this.confirmedAt,
    this.rejectedReason,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'paymentId': paymentId,
      'sessionId': sessionId,
      'userId': userId,
      'storeId': storeId,
      'amount': amount,
      'method': method,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'gatewayTransactionId': gatewayTransactionId,
      'gatewayProvider': gatewayProvider,
      'orderId': orderId,
      'provider': provider,
      'qrType': qrType,
      'qrImageUrl': qrImageUrl,
      'slipImageUrl': slipImageUrl,
      'customerMarkedPaidAt': customerMarkedPaidAt?.toIso8601String(),
      'confirmedBy': confirmedBy,
      'confirmedAt': confirmedAt?.toIso8601String(),
      'rejectedReason': rejectedReason,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      paymentId: map['paymentId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      userId: map['userId'] ?? '',
      storeId: map['storeId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      method: map['method'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: DateTime.parse(map['createdAt']),
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt']) : null,
      gatewayTransactionId: map['gatewayTransactionId'],
      gatewayProvider: map['gatewayProvider'],
      orderId: map['orderId'],
      provider: map['provider'],
      qrType: map['qrType'],
      qrImageUrl: map['qrImageUrl'],
      slipImageUrl: map['slipImageUrl'],
      customerMarkedPaidAt: map['customerMarkedPaidAt'] != null
          ? DateTime.parse(map['customerMarkedPaidAt'])
          : null,
      confirmedBy: map['confirmedBy'],
      confirmedAt: map['confirmedAt'] != null
          ? DateTime.parse(map['confirmedAt'])
          : null,
      rejectedReason: map['rejectedReason'],
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  PaymentModel copyWith({
    String? paymentId,
    String? sessionId,
    String? userId,
    String? storeId,
    double? amount,
    String? method,
    String? status,
    DateTime? createdAt,
    DateTime? paidAt,
    String? gatewayTransactionId,
    String? gatewayProvider,
    String? orderId,
    String? provider,
    String? qrType,
    String? qrImageUrl,
    String? slipImageUrl,
    DateTime? customerMarkedPaidAt,
    String? confirmedBy,
    DateTime? confirmedAt,
    String? rejectedReason,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      paymentId: paymentId ?? this.paymentId,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      storeId: storeId ?? this.storeId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      paidAt: paidAt ?? this.paidAt,
      gatewayTransactionId: gatewayTransactionId ?? this.gatewayTransactionId,
      gatewayProvider: gatewayProvider ?? this.gatewayProvider,
      orderId: orderId ?? this.orderId,
      provider: provider ?? this.provider,
      qrType: qrType ?? this.qrType,
      qrImageUrl: qrImageUrl ?? this.qrImageUrl,
      slipImageUrl: slipImageUrl ?? this.slipImageUrl,
      customerMarkedPaidAt: customerMarkedPaidAt ?? this.customerMarkedPaidAt,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      rejectedReason: rejectedReason ?? this.rejectedReason,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
