class ReceiptItemModel {
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final double subtotal;

  ReceiptItemModel({
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  Map<String, dynamic> toMap() => {
        'productId': productId,
        'productName': productName,
        'price': price,
        'quantity': quantity,
        'subtotal': subtotal,
      };

  factory ReceiptItemModel.fromMap(Map<String, dynamic> map) =>
      ReceiptItemModel(
        productId: map['productId'] ?? '',
        productName: map['productName'] ?? '',
        price: (map['price'] ?? 0).toDouble(),
        quantity: map['quantity'] ?? 1,
        subtotal: (map['subtotal'] ?? 0).toDouble(),
      );
}

class ReceiptModel {
  final String receiptId;
  final String orderId;
  final String sessionId;
  final String userId;
  final String storeId;
  final String storeName;
  final String paymentId;
  final String paymentMethod;
  final List<ReceiptItemModel> items;
  final double totalAmount;
  final int pointsEarned;
  final DateTime createdAt;

  ReceiptModel({
    required this.receiptId,
    required this.orderId,
    required this.sessionId,
    required this.userId,
    required this.storeId,
    required this.storeName,
    required this.paymentId,
    required this.paymentMethod,
    required this.items,
    required this.totalAmount,
    required this.pointsEarned,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'receiptId': receiptId,
      'orderId': orderId,
      'sessionId': sessionId,
      'userId': userId,
      'storeId': storeId,
      'storeName': storeName,
      'paymentId': paymentId,
      'paymentMethod': paymentMethod,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmount': totalAmount,
      'pointsEarned': pointsEarned,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReceiptModel.fromMap(Map<String, dynamic> map) {
    return ReceiptModel(
      receiptId: map['receiptId'] ?? '',
      orderId: map['orderId'] ?? '',
      sessionId: map['sessionId'] ?? '',
      userId: map['userId'] ?? '',
      storeId: map['storeId'] ?? '',
      storeName: map['storeName'] ?? '',
      paymentId: map['paymentId'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      items: (map['items'] as List<dynamic>? ?? [])
          .map((i) => ReceiptItemModel.fromMap(i as Map<String, dynamic>))
          .toList(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      pointsEarned: map['pointsEarned'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
