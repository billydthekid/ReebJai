import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../core/constants/stripe_config.dart';

/// Service for handling Stripe payments.
///
/// Flow:
///   1. createPaymentIntent() — calls Stripe API to create PaymentIntent
///   2. initPaymentSheet() — displays Stripe's built-in payment UI
///   3. presentPaymentSheet() — user fills in card details and confirms
///
/// For production: move createPaymentIntent to a Cloud Function / backend server.
/// The secret key should NEVER be in the client app in production.
class StripeService {
  static final StripeService _instance = StripeService._();
  factory StripeService() => _instance;
  StripeService._();

  bool _initialized = false;

  /// Initialize Stripe SDK — call once at app startup
  void initialize() {
    if (_initialized) return;
    if (!StripeConfig.isConfigured) {
      debugPrint('[Stripe] ⚠️ Not configured — using mock payments');
      return;
    }
    Stripe.publishableKey = StripeConfig.publishableKey;
    _initialized = true;
    debugPrint('[Stripe] Initialized');
  }

  /// Whether Stripe is ready to process real payments
  bool get isReady => _initialized && StripeConfig.isConfigured;

  /// Process a payment with Stripe Payment Sheet
  ///
  /// Returns true if payment succeeded, false if cancelled/failed.
  /// Throws on unexpected errors.
  Future<bool> processPayment({
    required double amount,
    String currency = StripeConfig.currency,
    String? description,
  }) async {
    if (!isReady) {
      debugPrint('[Stripe] Not configured — cannot process payment');
      return false; // No more mock success in production mode
    }

    try {
      // 1. Create PaymentIntent on Stripe
      final paymentIntent = await _createPaymentIntent(
        amount: StripeConfig.toSmallestUnit(amount),
        currency: currency,
        description: description,
      );

      if (paymentIntent == null) return false;

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntent['client_secret'],
          merchantDisplayName: 'REEBJAI Store',
          style: ThemeMode.light,
        ),
      );

      // 3. Present Payment Sheet to user
      await Stripe.instance.presentPaymentSheet();

      debugPrint('[Stripe] Payment successful');
      return true;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        debugPrint('[Stripe] Payment cancelled by user');
        return false;
      }
      debugPrint('[Stripe] Error: ${e.error.localizedMessage}');
      rethrow;
    } catch (e) {
      debugPrint('[Stripe] Unexpected error: $e');
      rethrow;
    }
  }

  /// Create a PaymentIntent via Stripe API
  ///
  /// ⚠️ In production, this should be a server-side call (Cloud Function).
  /// We call Stripe API directly here for prototype/testing only.
  Future<Map<String, dynamic>?> _createPaymentIntent({
    required int amount,
    required String currency,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.stripe.com/v1/payment_intents'),
        headers: {
          'Authorization': 'Bearer ${StripeConfig.secretKey}',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'amount': amount.toString(),
          'currency': currency,
          'payment_method_types[]': 'card',
          if (description != null) 'description': description,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        debugPrint('[Stripe] PaymentIntent failed: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[Stripe] Network error: $e');
      return null;
    }
  }
}
