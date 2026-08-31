/// Central collection name constants for Cloud Firestore.
/// Use these everywhere instead of hardcoded strings.
class FC {
  FC._();

  static const String users = 'users';
  static const String stores = 'stores';
  static const String products = 'products';
  static const String sessions = 'sessions';
  static const String payments = 'payments';
  static const String receipts = 'receipts';

  // Sub-collections
  static const String cartItems = 'cart_items';

  // Counter service (เคาน์เตอร์บริการ เช่น จ่ายบิล, เติมเงิน)
  static const String counterServiceCategories = 'counter_service_categories';
  static const String counterServiceItems = 'counter_service_items';

  // Internal / system
  static const String meta = '_meta'; // seed tracking etc.
}
