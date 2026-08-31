/// ============================================================
/// Firestore Schema Reference — REEBJAI App
/// ============================================================
/// Firestore is schemaless, but this file serves as the
/// single source of truth for every collection's expected
/// document structure.
///
/// Legend:
///   [R] = Required now  (app will break without it)
///   [O] = Optional now   (nullable / has default)
///   [F] = Future field   (reserved for board / hardware)
/// ============================================================

class FirestoreSchemaReference {
  FirestoreSchemaReference._();

  // ──────────────────────────────────────────────
  // users
  // ──────────────────────────────────────────────
  static const usersSchema = {
    'userId': '[R] String — document ID, UUID',
    'firstName': '[R] String',
    'lastName': '[R] String',
    'phoneNumber': '[R] String',
    'hasPaymentCard': '[O] bool — default false',
    'allMemberPoints': '[O] int — default 0',
    'createdAt': '[R] String (ISO 8601)',
    'bleDeviceId': '[F] String? — BLE device pairing',
    'fcmToken': '[F] String? — push notification token',
  };

  // ──────────────────────────────────────────────
  // stores
  // ──────────────────────────────────────────────
  static const storesSchema = {
    'storeId': '[R] String — document ID',
    'name': '[R] String',
    'address': '[R] String',
    'qrCode': '[R] String — unique QR for check-in',
    'isOpen': '[O] bool — default true',
    'bleBeaconId': '[F] String? — BLE beacon at entrance',
    'espDeviceId': '[F] String? — ESP32 board ID',
    'wifiSsid': '[F] String? — store WiFi for auto-detect',
  };

  // ──────────────────────────────────────────────
  // products
  // ──────────────────────────────────────────────
  static const productsSchema = {
    'productId': '[R] String — document ID',
    'barcode': '[R] String — EAN-13 / UPC',
    'name': '[R] String',
    'price': '[R] double — THB',
    'category': '[R] String — beverage, snack, food, etc.',
    'imageUrl': '[O] String — product image URL',
    'stock': '[O] int — default 100',
    'rfidTag': '[F] String? — RFID tag for smart shelf',
    'weightGrams': '[F] double? — for weight sensor verification',
  };

  // ──────────────────────────────────────────────
  // sessions
  // ──────────────────────────────────────────────
  static const sessionsSchema = {
    'sessionId': '[R] String — document ID, UUID',
    'userId': '[R] String — ref → users',
    'storeId': '[R] String — ref → stores',
    'checkInTime': '[R] String (ISO 8601)',
    'checkOutTime': '[O] String? (ISO 8601)',
    'status': '[R] String — active | checked_out | paid',
    'entryGateId': '[F] String? — gate that opened on entry',
    'exitGateId': '[F] String? — gate that opened on exit',
    'bleConnectionId': '[F] String? — BLE session ID',
  };

  // ──────────────────────────────────────────────
  // sessions/{sessionId}/cart_items  (sub-collection)
  // ──────────────────────────────────────────────
  static const cartItemsSchema = {
    'cartItemId': '[R] String — document ID, UUID',
    'productId': '[R] String — ref → products',
    'productName': '[R] String — denormalized',
    'productPrice': '[R] double',
    'productImageUrl': '[O] String',
    'quantity': '[R] int',
    'subtotal': '[R] double — price × quantity',
  };

  // ──────────────────────────────────────────────
  // payments
  // ──────────────────────────────────────────────
  static const paymentsSchema = {
    'paymentId': '[R] String — document ID, UUID',
    'sessionId': '[R] String — ref → sessions',
    'userId': '[R] String — ref → users',
    'storeId': '[R] String — ref → stores',
    'amount': '[R] double — total THB',
    'method': '[R] String — truemoney | mobile_banking | saved_card',
    'status': '[R] String — pending | paid | failed',
    'createdAt': '[R] String (ISO 8601)',
    'paidAt': '[O] String? (ISO 8601)',
    'gatewayTransactionId': '[F] String? — from payment gateway',
    'gatewayProvider': '[F] String? — e.g. omise, stripe',
  };

  // ──────────────────────────────────────────────
  // receipts
  // ──────────────────────────────────────────────
  static const receiptsSchema = {
    'receiptId': '[R] String — document ID, UUID',
    'orderId': '[R] String — display order number e.g. #1234',
    'sessionId': '[R] String — ref → sessions',
    'userId': '[R] String — ref → users',
    'storeId': '[R] String — ref → stores',
    'storeName': '[R] String — denormalized',
    'paymentId': '[R] String — ref → payments',
    'paymentMethod': '[R] String',
    'items': '[R] List<Map> — [{productId, productName, price, quantity, subtotal}]',
    'totalAmount': '[R] double',
    'pointsEarned': '[R] int',
    'createdAt': '[R] String (ISO 8601)',
  };

  // ──────────────────────────────────────────────
  // counter_service_categories
  // ──────────────────────────────────────────────
  static const counterServiceCategoriesSchema = {
    'categoryId': '[R] String — document ID',
    'name': '[R] String — e.g. จ่ายบิล, เติมเงิน, พัสดุ',
    'icon': '[O] String — icon name or URL',
    'sortOrder': '[O] int — display order',
    'isActive': '[O] bool — default true',
  };

  // ──────────────────────────────────────────────
  // counter_service_items
  // ──────────────────────────────────────────────
  static const counterServiceItemsSchema = {
    'itemId': '[R] String — document ID',
    'categoryId': '[R] String — ref → counter_service_categories',
    'name': '[R] String — e.g. AIS Top-Up, ค่าไฟ MEA',
    'description': '[O] String',
    'icon': '[O] String — icon name or URL',
    'fee': '[O] double — service fee THB, default 0',
    'isActive': '[O] bool — default true',
  };

  // ──────────────────────────────────────────────
  // _meta  (internal — seed tracking)
  // ──────────────────────────────────────────────
  static const metaSchema = {
    'docId': '[R] String — e.g. "seed_status"',
    'seedVersion': '[R] int — bump to force reseed',
    'lastSeededAt': '[R] String (ISO 8601)',
    'collections': '[R] List<String> — which collections were seeded',
  };
}
