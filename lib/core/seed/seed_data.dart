import 'package:cloud_firestore/cloud_firestore.dart';
import '../firestore/firestore_collections.dart';

/// ============================================================
/// Seed Data Service — REEBJAI App
/// ============================================================
/// - Version-based: bump [_seedVersion] to force reseed
/// - Duplicate guard: skips if already seeded at current version
/// - [seedAll] for normal startup, [forceReseedAll] to wipe & re-seed
/// ============================================================
class SeedData {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Bump this number to force reseed on next app start
  static const int _seedVersion = 1;

  // ─── Public API ────────────────────────────────────────

  /// Called from main.dart on startup.
  /// Seeds only if current version has not been seeded yet.
  static Future<void> seedAll() async {
    if (await _isAlreadySeeded()) return;
    await _runSeed();
  }

  /// Deletes all seeded collections and re-seeds from scratch.
  static Future<void> forceReseedAll() async {
    await _deleteCollection(FC.stores);
    await _deleteCollection(FC.products);
    await _deleteCollection(FC.counterServiceCategories);
    await _deleteCollection(FC.counterServiceItems);
    await _deleteCollection(FC.users);
    await _runSeed();
  }

  // ─── Internal ──────────────────────────────────────────

  static Future<void> _runSeed() async {
    await _seedStores();
    await _seedProducts();
    await _seedCounterServiceCategories();
    await _seedCounterServiceItems();
    await _seedExampleUser();
    await _markSeeded();
  }

  static Future<bool> _isAlreadySeeded() async {
    try {
      final doc = await _db.collection(FC.meta).doc('seed_status').get();
      if (!doc.exists) return false;
      final data = doc.data()!;
      return (data['seedVersion'] ?? 0) >= _seedVersion;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _markSeeded() async {
    await _db.collection(FC.meta).doc('seed_status').set({
      'seedVersion': _seedVersion,
      'lastSeededAt': DateTime.now().toIso8601String(),
      'collections': [
        FC.stores,
        FC.products,
        FC.counterServiceCategories,
        FC.counterServiceItems,
        FC.users,
      ],
    });
  }

  static Future<void> _deleteCollection(String path) async {
    final snap = await _db.collection(path).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ─── Stores ────────────────────────────────────────────

  static Future<void> _seedStores() async {
    final ref = _db.collection(FC.stores);
    final batch = _db.batch();

    for (final s in _storesData) {
      batch.set(ref.doc(s['storeId'] as String), s);
    }
    await batch.commit();
  }

  static final List<Map<String, dynamic>> _storesData = [
    {
      'storeId': 'store_001',
      'name': 'REEBJAI Store Siam Square',
      'address': 'Siam Square Soi 2, Pathum Wan, Bangkok 10330',
      'qrCode': 'REEBJAI_STORE_001',
      'isOpen': true,
      'bleBeaconId': null,
      'espDeviceId': null,
      'wifiSsid': null,
    },
    {
      'storeId': 'store_002',
      'name': 'REEBJAI Store Central World',
      'address': 'Central World, Ratchaprasong, Bangkok 10330',
      'qrCode': 'REEBJAI_STORE_002',
      'isOpen': true,
      'bleBeaconId': null,
      'espDeviceId': null,
      'wifiSsid': null,
    },
  ];

  // ─── Products (10 items) ───────────────────────────────

  static Future<void> _seedProducts() async {
    final ref = _db.collection(FC.products);
    final batch = _db.batch();

    for (final p in _productsData) {
      batch.set(ref.doc(p['productId'] as String), p);
    }
    await batch.commit();
  }

  static final List<Map<String, dynamic>> _productsData = [
    {
      'productId': 'prod_001',
      'barcode': '8850006140021',
      'name': 'Crystal Drinking Water 600ml',
      'price': 7.0,
      'category': 'beverage',
      'imageUrl': '',
      'stock': 100,
      'rfidTag': null,
      'weightGrams': 600.0,
    },
    {
      'productId': 'prod_002',
      'barcode': '8851123456789',
      'name': "Lay's Original Chips",
      'price': 20.0,
      'category': 'snack',
      'imageUrl': '',
      'stock': 50,
      'rfidTag': null,
      'weightGrams': 44.0,
    },
    {
      'productId': 'prod_003',
      'barcode': '8850006140022',
      'name': 'Pepsi Can 330ml',
      'price': 17.0,
      'category': 'beverage',
      'imageUrl': '',
      'stock': 80,
      'rfidTag': null,
      'weightGrams': 330.0,
    },
    {
      'productId': 'prod_004',
      'barcode': '8851987654321',
      'name': 'Mama Shrimp Tom Yum',
      'price': 6.0,
      'category': 'food',
      'imageUrl': '',
      'stock': 200,
      'rfidTag': null,
      'weightGrams': 55.0,
    },
    {
      'productId': 'prod_005',
      'barcode': '8850001234567',
      'name': 'KitKat Chocolate 2F',
      'price': 35.0,
      'category': 'snack',
      'imageUrl': '',
      'stock': 60,
      'rfidTag': null,
      'weightGrams': 41.5,
    },
    {
      'productId': 'prod_006',
      'barcode': '8852222222222',
      'name': 'Red Bull Original 150ml',
      'price': 12.0,
      'category': 'beverage',
      'imageUrl': '',
      'stock': 120,
      'rfidTag': null,
      'weightGrams': 150.0,
    },
    {
      'productId': 'prod_007',
      'barcode': '8858998581110',
      'name': 'Oishi Green Tea Honey Lemon 500ml',
      'price': 20.0,
      'category': 'beverage',
      'imageUrl': '',
      'stock': 90,
      'rfidTag': null,
      'weightGrams': 520.0,
    },
    {
      'productId': 'prod_008',
      'barcode': '8850999111222',
      'name': 'Testo Corn Snack BBQ',
      'price': 10.0,
      'category': 'snack',
      'imageUrl': '',
      'stock': 75,
      'rfidTag': null,
      'weightGrams': 48.0,
    },
    {
      'productId': 'prod_009',
      'barcode': '8851111333444',
      'name': 'CP Chicken Rice (Frozen)',
      'price': 45.0,
      'category': 'food',
      'imageUrl': '',
      'stock': 40,
      'rfidTag': null,
      'weightGrams': 300.0,
    },
    {
      'productId': 'prod_010',
      'barcode': '8850777555666',
      'name': 'Dutch Mill Yoghurt Strawberry',
      'price': 15.0,
      'category': 'beverage',
      'imageUrl': '',
      'stock': 60,
      'rfidTag': null,
      'weightGrams': 180.0,
    },
  ];

  // ─── Counter Service Categories (2) ────────────────────

  static Future<void> _seedCounterServiceCategories() async {
    final ref = _db.collection(FC.counterServiceCategories);
    final batch = _db.batch();

    for (final c in _counterCategoriesData) {
      batch.set(ref.doc(c['categoryId'] as String), c);
    }
    await batch.commit();
  }

  static final List<Map<String, dynamic>> _counterCategoriesData = [
    {
      'categoryId': 'cs_cat_001',
      'name': 'เติมเงิน (Top-Up)',
      'icon': 'phone_android',
      'sortOrder': 1,
      'isActive': true,
    },
    {
      'categoryId': 'cs_cat_002',
      'name': 'จ่ายบิล (Bill Payment)',
      'icon': 'receipt_long',
      'sortOrder': 2,
      'isActive': true,
    },
  ];

  // ─── Counter Service Items (5) ─────────────────────────

  static Future<void> _seedCounterServiceItems() async {
    final ref = _db.collection(FC.counterServiceItems);
    final batch = _db.batch();

    for (final item in _counterItemsData) {
      batch.set(ref.doc(item['itemId'] as String), item);
    }
    await batch.commit();
  }

  static final List<Map<String, dynamic>> _counterItemsData = [
    {
      'itemId': 'cs_item_001',
      'categoryId': 'cs_cat_001',
      'name': 'AIS Top-Up',
      'description': 'เติมเงิน AIS 1-2-Call',
      'icon': 'signal_cellular_alt',
      'fee': 0.0,
      'isActive': true,
    },
    {
      'itemId': 'cs_item_002',
      'categoryId': 'cs_cat_001',
      'name': 'True Move H Top-Up',
      'description': 'เติมเงิน True Move H',
      'icon': 'signal_cellular_alt',
      'fee': 0.0,
      'isActive': true,
    },
    {
      'itemId': 'cs_item_003',
      'categoryId': 'cs_cat_001',
      'name': 'DTAC Top-Up',
      'description': 'เติมเงิน DTAC',
      'icon': 'signal_cellular_alt',
      'fee': 0.0,
      'isActive': true,
    },
    {
      'itemId': 'cs_item_004',
      'categoryId': 'cs_cat_002',
      'name': 'ค่าไฟ MEA',
      'description': 'ชำระค่าไฟฟ้า การไฟฟ้านครหลวง',
      'icon': 'bolt',
      'fee': 10.0,
      'isActive': true,
    },
    {
      'itemId': 'cs_item_005',
      'categoryId': 'cs_cat_002',
      'name': 'ค่าน้ำ MWA',
      'description': 'ชำระค่าน้ำประปา การประปานครหลวง',
      'icon': 'water_drop',
      'fee': 10.0,
      'isActive': true,
    },
  ];

  // ─── Example User ──────────────────────────────────────

  static Future<void> _seedExampleUser() async {
    final ref = _db.collection(FC.users);
    final doc = await ref.doc('user_example_001').get();
    if (doc.exists) return; // don't overwrite if user edited

    await ref.doc('user_example_001').set({
      'userId': 'user_example_001',
      'firstName': 'สมชาย',
      'lastName': 'ใจดี',
      'phoneNumber': '0812345678',
      'hasPaymentCard': true,
      'allMemberPoints': 150,
      'createdAt': DateTime.now().toIso8601String(),
      'bleDeviceId': null,
      'fcmToken': null,
    });
  }
}
