import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/firestore/firestore_collections.dart';
import '../models/user_model.dart';
import '../models/store_model.dart';
import '../models/product_model.dart';
import '../models/session_model.dart';
import '../models/payment_model.dart';
import '../models/receipt_model.dart';
import '../models/counter_service_category_model.dart';
import '../models/counter_service_item_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Users ───────────────────────────────────────────

  Future<void> createUser(UserModel user) async {
    await _db.collection(FC.users).doc(user.userId).set(user.toMap());
  }

  Future<UserModel?> getUser(String userId) async {
    final doc = await _db.collection(FC.users).doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!);
  }

  Future<void> updateUserPoints(String userId, int points) async {
    await _db.collection(FC.users).doc(userId).update({
      'allMemberPoints': FieldValue.increment(points),
    });
  }

  // ─── Stores ──────────────────────────────────────────

  Future<StoreModel?> getStoreByQrCode(String qrCode) async {
    // 1. Try fetching by Document ID (recommended structure)
    final doc = await _db.collection(FC.stores).doc(qrCode).get();
    if (doc.exists) {
      final data = doc.data()!;
      // Ensure storeId and qrCode are set if missing in data
      if (!data.containsKey('storeId')) data['storeId'] = doc.id;
      if (!data.containsKey('qrCode')) data['qrCode'] = qrCode;
      return StoreModel.fromMap(data);
    }

    // 2. Try searching by 'qrCode' field
    var snap = await _db
        .collection(FC.stores)
        .where('qrCode', isEqualTo: qrCode)
        .limit(1)
        .get();
    
    // 3. Try searching by 'qr' field (legacy/admin panel compatibility)
    if (snap.docs.isEmpty) {
      snap = await _db
          .collection(FC.stores)
          .where('qr', isEqualTo: qrCode)
          .limit(1)
          .get();
    }

    if (snap.docs.isEmpty) return null;
    
    final docSnap = snap.docs.first;
    final data = docSnap.data();
    if (!data.containsKey('storeId')) data['storeId'] = docSnap.id;
    if (!data.containsKey('qrCode')) data['qrCode'] = data['qr'] ?? qrCode;
    
    return StoreModel.fromMap(data);
  }

  Future<StoreModel?> getStore(String storeId) async {
    final doc = await _db.collection(FC.stores).doc(storeId).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (!data.containsKey('storeId')) data['storeId'] = doc.id;
    if (!data.containsKey('qrCode')) data['qrCode'] = data['qr'] ?? '';
    return StoreModel.fromMap(data);
  }

  Future<List<StoreModel>> getAllStores() async {
    final snap = await _db.collection(FC.stores).get();
    return snap.docs.map((d) {
      final data = d.data();
      if (!data.containsKey('storeId')) data['storeId'] = d.id;
      if (!data.containsKey('qrCode')) data['qrCode'] = data['qr'] ?? '';
      return StoreModel.fromMap(data);
    }).toList();
  }

  // ─── Products ────────────────────────────────────────

  Future<ProductModel?> getProductByBarcode(String storeId, String barcode) async {
    final snap = await _db
        .collection(FC.stores)
        .doc(storeId)
        .collection(FC.products)
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    
    final docSnap = snap.docs.first;
    final data = docSnap.data();
    if (!data.containsKey('productId')) data['productId'] = docSnap.id;
    return ProductModel.fromMap(data);
  }

  Future<ProductModel?> getProduct(String storeId, String productId) async {
    final doc = await _db
        .collection(FC.stores)
        .doc(storeId)
        .collection(FC.products)
        .doc(productId)
        .get();
    if (!doc.exists) return null;
    
    final data = doc.data()!;
    if (!data.containsKey('productId')) data['productId'] = doc.id;
    return ProductModel.fromMap(data);
  }

  Future<List<ProductModel>> getAllProducts(String storeId) async {
    final snap = await _db
        .collection(FC.stores)
        .doc(storeId)
        .collection(FC.products)
        .get();
    return snap.docs.map((d) => ProductModel.fromMap(d.data())).toList();
  }

  Future<List<ProductModel>> getProductsByCategory(
      String storeId, String category) async {
    final snap = await _db
        .collection(FC.stores)
        .doc(storeId)
        .collection(FC.products)
        .where('category', isEqualTo: category)
        .get();
    return snap.docs.map((d) => ProductModel.fromMap(d.data())).toList();
  }

  Future<void> deductStoreProductStock(String storeId, List<Map<String, dynamic>> items) async {
    final batch = _db.batch();
    for (final item in items) {
      final productId = item['productId'] as String;
      final qty = item['quantity'] as int;
      final ref = _db.collection(FC.stores).doc(storeId).collection('products').doc(productId);
      
      // using increment for atomic modification
      batch.set(
        ref, 
        {'stock': FieldValue.increment(-qty), 'updatedAt': DateTime.now().toIso8601String()}, 
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  // ─── Sessions ────────────────────────────────────────

  Future<void> createSession(SessionModel session) async {
    await _db
        .collection(FC.sessions)
        .doc(session.sessionId)
        .set(session.toMap());
  }

  Future<SessionModel?> getSession(String sessionId) async {
    final doc = await _db.collection(FC.sessions).doc(sessionId).get();
    if (!doc.exists) return null;
    return SessionModel.fromMap(doc.data()!);
  }

  Future<void> updateSessionStatus(String sessionId, String status,
      {DateTime? checkOutTime}) async {
    final data = <String, dynamic>{'status': status};
    if (checkOutTime != null) {
      data['checkOutTime'] = checkOutTime.toIso8601String();
    }
    await _db.collection(FC.sessions).doc(sessionId).update(data);
  }

  // ─── Cart Items (sub-collection under sessions) ──────

  Future<void> saveCartItems(
      String sessionId, List<Map<String, dynamic>> items) async {
    final batch = _db.batch();
    final cartRef = _db
        .collection(FC.sessions)
        .doc(sessionId)
        .collection(FC.cartItems);
    for (final item in items) {
      batch.set(cartRef.doc(item['cartItemId'] as String), item);
    }
    await batch.commit();
  }

  Future<List<Map<String, dynamic>>> getCartItems(String sessionId) async {
    final snap = await _db
        .collection(FC.sessions)
        .doc(sessionId)
        .collection(FC.cartItems)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  // ─── Payments ────────────────────────────────────────

  Future<void> createPayment(PaymentModel payment) async {
    await _db
        .collection(FC.payments)
        .doc(payment.paymentId)
        .set(payment.toMap());
  }

  Future<PaymentModel?> getPayment(String paymentId) async {
    final doc = await _db.collection(FC.payments).doc(paymentId).get();
    if (!doc.exists) return null;
    return PaymentModel.fromMap(doc.data()!);
  }

  Future<void> updatePaymentStatus(String paymentId, String status,
      {DateTime? paidAt}) async {
    final data = <String, dynamic>{'status': status};
    if (paidAt != null) data['paidAt'] = paidAt.toIso8601String();
    data['updatedAt'] = DateTime.now().toIso8601String();
    await _db.collection(FC.payments).doc(paymentId).update(data);
  }

  // ─── Manual QR Payment — Admin functions ─────────────

  /// Mark payment as customer has transferred (upload slip info)
  Future<void> markPaymentAsTransferred(
    String paymentId, {
    String? slipImageUrl,
  }) async {
    final now = DateTime.now();
    final data = <String, dynamic>{
      'status': 'pending_verification',
      'customerMarkedPaidAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    };
    if (slipImageUrl != null) {
      data['slipImageUrl'] = slipImageUrl;
    }
    await _db.collection(FC.payments).doc(paymentId).update(data);
  }

  /// Update slip image URL
  Future<void> updatePaymentSlip(
      String paymentId, String slipImageUrl) async {
    await _db.collection(FC.payments).doc(paymentId).update({
      'slipImageUrl': slipImageUrl,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Admin confirms a payment
  Future<void> confirmPayment(
      String paymentId, String adminUserId) async {
    final now = DateTime.now();
    await _db.collection(FC.payments).doc(paymentId).update({
      'status': 'paid',
      'confirmedBy': adminUserId,
      'confirmedAt': now.toIso8601String(),
      'paidAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });
  }

  /// Admin rejects a payment
  Future<void> rejectPayment(
      String paymentId, String adminUserId, String reason) async {
    final now = DateTime.now();
    await _db.collection(FC.payments).doc(paymentId).update({
      'status': 'rejected',
      'confirmedBy': adminUserId,
      'confirmedAt': now.toIso8601String(),
      'rejectedReason': reason,
      'updatedAt': now.toIso8601String(),
    });
  }

  /// Get all payments with a specific status
  Future<List<PaymentModel>> getPaymentsByStatus(String status) async {
    final snap = await _db
        .collection(FC.payments)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => PaymentModel.fromMap(d.data())).toList();
  }

  /// Stream payments by status (real-time)
  Stream<List<PaymentModel>> streamPaymentsByStatus(String status) {
    return _db
        .collection(FC.payments)
        .where('status', isEqualTo: status)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PaymentModel.fromMap(d.data())).toList());
  }

  /// Stream a single payment (for customer waiting real-time status)
  Stream<PaymentModel?> streamPayment(String paymentId) {
    return _db
        .collection(FC.payments)
        .doc(paymentId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return PaymentModel.fromMap(doc.data()!);
    });
  }

  /// Get all payments (for admin overview)
  Future<List<PaymentModel>> getAllPayments() async {
    final snap = await _db
        .collection(FC.payments)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => PaymentModel.fromMap(d.data())).toList();
  }

  // ─── Receipts ────────────────────────────────────────

  Future<void> createReceipt(ReceiptModel receipt) async {
    await _db
        .collection(FC.receipts)
        .doc(receipt.receiptId)
        .set(receipt.toMap());
  }

  Future<ReceiptModel?> getReceipt(String receiptId) async {
    final doc = await _db.collection(FC.receipts).doc(receiptId).get();
    if (!doc.exists) return null;
    return ReceiptModel.fromMap(doc.data()!);
  }

  Future<List<ReceiptModel>> getReceiptsByUser(String userId) async {
    final snap = await _db
        .collection(FC.receipts)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => ReceiptModel.fromMap(d.data())).toList();
  }

  // ─── Counter Service Categories ──────────────────────

  Future<List<CounterServiceCategoryModel>> getCounterServiceCategories() async {
    final snap = await _db
        .collection(FC.counterServiceCategories)
        .where('isActive', isEqualTo: true)
        .orderBy('sortOrder')
        .get();
    return snap.docs
        .map((d) => CounterServiceCategoryModel.fromMap(d.data()))
        .toList();
  }

  // ─── Counter Service Items ───────────────────────────

  Future<List<CounterServiceItemModel>> getCounterServiceItems(
      String categoryId) async {
    final snap = await _db
        .collection(FC.counterServiceItems)
        .where('categoryId', isEqualTo: categoryId)
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs
        .map((d) => CounterServiceItemModel.fromMap(d.data()))
        .toList();
  }

  Future<List<CounterServiceItemModel>> getAllCounterServiceItems() async {
    final snap = await _db
        .collection(FC.counterServiceItems)
        .where('isActive', isEqualTo: true)
        .get();
    return snap.docs
        .map((d) => CounterServiceItemModel.fromMap(d.data()))
        .toList();
  }
}
