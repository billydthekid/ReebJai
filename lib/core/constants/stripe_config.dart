/// Stripe API Configuration
/// ───────────────────────────────────────────
/// Get your keys from: https://dashboard.stripe.com/apikeys
///
/// For testing, use keys that start with:
///   pk_test_... (Publishable Key)
///   sk_test_... (Secret Key)
///
/// For production, use keys that start with:
///   pk_live_... (Publishable Key)
///   sk_live_... (Secret Key)
class StripeConfig {
  /// Publishable key — used in Flutter app (client-side)
  static const String publishableKey = 'pk_test_YOUR_KEY_HERE';

  /// Secret key — ⚠️ ONLY used server-side (Cloud Function)
  /// NEVER expose this in the app in production!
  /// For prototype/testing only, we call Stripe API directly.
  static const String secretKey = 'sk_test_YOUR_KEY_HERE';

  /// Currency
  static const String currency = 'thb';

  /// Stripe requires amount in smallest unit (satang for THB)
  /// 1 THB = 100 satang
  static int toSmallestUnit(double amount) => (amount * 100).toInt();

  /// Check if keys are configured
  static bool get isConfigured =>
      publishableKey != 'pk_test_YOUR_KEY_HERE' &&
      secretKey != 'sk_test_YOUR_KEY_HERE';
}
