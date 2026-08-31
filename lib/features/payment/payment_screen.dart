import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/payment_model.dart';
import '../../models/receipt_model.dart';
import '../../services/firestore_service.dart';
import '../../services/cart_provider.dart';
import '../../services/session_provider.dart';
import '../../services/board_provider.dart';
import '../../services/stripe_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? _selectedMethod;
  bool _isProcessing = false;
  final _firestoreService = FirestoreService();
  final _stripeService = StripeService();

  static final _methods = [
    {
      'id': 'bank_qr_manual',
      'label': 'Bank QR Transfer (พร้อมเพย์)',
      'icon': Icons.qr_code,
      'color': const Color(0xFF1A3E72),
    },
    {
      'id': 'stripe_card',
      'label': 'Credit / Debit Card',
      'icon': Icons.credit_card,
      'color': const Color(0xFF635BFF),
      'comingSoon': true,
    },
    {
      'id': 'truemoney',
      'label': 'TrueMoney',
      'icon': Icons.account_balance_wallet,
      'color': const Color(0xFFEA1921),
      'comingSoon': true,
    },
  ];

  Future<void> _payNow() async {
    if (_selectedMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final cart = context.read<CartProvider>();
      final session = context.read<SessionProvider>();
      final uuid = const Uuid();

      final now = DateTime.now();
      final paymentId = uuid.v4();
      final sessionId = session.currentSession?.sessionId ?? uuid.v4();
      final userId = session.currentUser?.userId ?? 'guest';
      final storeId = session.currentStore?.storeId ?? 'store_001';
      final storeName = session.currentStore?.name ?? 'REEBJAI Store';

      // Generate order ID
      final orderId = 'ORD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${(now.millisecondsSinceEpoch % 10000).toString().padLeft(4, '0')}';

      // ─── Bank QR Manual — redirect to QR screen ─────
      if (_selectedMethod == 'bank_qr_manual') {
        final payment = PaymentModel(
          paymentId: paymentId,
          sessionId: sessionId,
          userId: userId,
          storeId: storeId,
          amount: cart.total,
          method: 'bank_qr_manual',
          status: 'pending',
          createdAt: now,
          orderId: orderId,
          provider: 'bank_qr_manual',
          qrType: 'promptpay',
          updatedAt: now,
        );

        // Save payment record as pending
        await _firestoreService.createPayment(payment);

        // Save cart items
        await _firestoreService.saveCartItems(sessionId, cart.toMapList());

        if (!mounted) return;

        // Navigate to QR payment screen
        Navigator.pushNamed(
          context,
          AppRoutes.qrPayment,
          arguments: {'payment': payment},
        );
        return;
      }

      // ─── Process payment based on method ──────────
      bool paymentSuccess = false;
      String gatewayProvider = _selectedMethod!;
      String? gatewayTxnId;

      if (_selectedMethod == 'stripe_card') {
        // Stripe real payment
        paymentSuccess = await _stripeService.processPayment(
          amount: cart.total,
          description: 'REEBJAI Order - $storeName',
        );
        gatewayProvider = 'stripe';
        if (!paymentSuccess) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment cancelled')),
            );
          }
          return;
        }
      } else if (_selectedMethod == 'truemoney') {
        // Mocking Coming Soon behavior
        return;
      } else {
        // Mock payment for Mobile Banking
        await Future.delayed(const Duration(milliseconds: 800));
        paymentSuccess = true;
      }

      if (!paymentSuccess) return;

      // ─── Save payment record ──────────────────────
      final payment = PaymentModel(
        paymentId: paymentId,
        sessionId: sessionId,
        userId: userId,
        storeId: storeId,
        amount: cart.total,
        method: _selectedMethod!,
        status: 'paid',
        createdAt: now,
        paidAt: DateTime.now(),
        gatewayProvider: gatewayProvider,
        gatewayTransactionId: gatewayTxnId,
        orderId: orderId,
        provider: gatewayProvider,
      );
      await _firestoreService.createPayment(payment);

      // Save cart items to Firestore
      await _firestoreService.saveCartItems(sessionId, cart.toMapList());
      
      // Deduct stock per store
      final deductItems = cart.items
          .map((i) => {
                'productId': i.product.barcode.isNotEmpty ? i.product.barcode : i.product.productId,
                'quantity': i.quantity,
              })
          .toList();
      if (deductItems.isNotEmpty) {
        await _firestoreService.deductStoreProductStock(storeId, deductItems);
      }

      // Update session status
      await _firestoreService.updateSessionStatus(sessionId, 'paid');

      // Calculate points (1 point per 1 THB)
      final points = cart.total.toInt();

      // Create receipt
      final receiptItems = cart.items
          .map((i) => ReceiptItemModel(
                productId: i.product.productId,
                productName: i.product.name,
                price: i.product.price,
                quantity: i.quantity,
                subtotal: i.subtotal,
              ))
          .toList();

      final receipt = ReceiptModel(
        receiptId: uuid.v4(),
        orderId: orderId,
        sessionId: sessionId,
        userId: userId,
        storeId: storeId,
        storeName: storeName,
        paymentId: paymentId,
        paymentMethod: _selectedMethod!,
        items: receiptItems,
        totalAmount: cart.total,
        pointsEarned: points,
        createdAt: payment.paidAt!,
      );
      await _firestoreService.createReceipt(receipt);

      // Update user points
      await _firestoreService.updateUserPoints(userId, points);

      if (!mounted) return;
      session.setPayment(payment);
      session.setReceipt(receipt);

      // Send commands to ESP32: open gate for EXIT (ครั้งที่ 2: ออกจากร้าน)
      try {
        final board = context.read<BoardProvider>();
        board.openGate(
          reason: 'payment_complete',
          line1: 'Payment OK!',
          line2: '${cart.total.toStringAsFixed(0)} THB',
        );
      } catch (_) {} // graceful if board offline

      cart.clear();

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.receipt,
        (route) => route.settings.name == AppRoutes.welcome,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        centerTitle: true,
        title: const Text('Payment',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary
                  const Text('Order Summary',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.greyBorder),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        ...cart.items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(item.product.name,
                                        style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontSize: 14)),
                                  ),
                                  Text(
                                    '${item.subtotal.toStringAsFixed(0)} THB',
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            )),
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary)),
                              Text(
                                '${cart.total.toStringAsFixed(0)} THB',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Method
                  const Text('Payment Method',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 12),
                  ..._methods.map((m) => _MethodTile(
                        methodId: m['id'] as String,
                        label: m['label'] as String,
                        icon: m['icon'] as IconData,
                        color: m['color'] as Color,
                        isSelected: _selectedMethod == m['id'],
                        comingSoon: m['comingSoon'] == true,
                        onTap: () {
                          if (m['comingSoon'] == true) return;
                          setState(() => _selectedMethod = m['id'] as String);
                        },
                      )),
                ],
              ),
            ),
          ),

          // Pay Now
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            decoration: const BoxDecoration(
              color: AppColors.white,
              border:
                  Border(top: BorderSide(color: AppColors.greyBorder)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedMethod != null
                      ? (_selectedMethod == 'bank_qr_manual'
                          ? const Color(0xFF1A3E72)
                          : AppColors.primary)
                      : AppColors.greyBorder,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _isProcessing ? null : _payNow,
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2))
                    : Text(
                        _selectedMethod == 'bank_qr_manual'
                            ? 'ชำระผ่าน QR'
                            : 'Pay Now',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final String methodId;
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool comingSoon;
  final VoidCallback onTap;

  const _MethodTile({
    required this.methodId,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    this.comingSoon = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: comingSoon ? 0.6 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(
                color: isSelected ? color : AppColors.greyBorder,
                width: isSelected ? 2 : 1),
            borderRadius: BorderRadius.circular(12),
            color: isSelected ? color.withValues(alpha: 0.06) : AppColors.white,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 15, color: AppColors.textPrimary)),
                    if (comingSoon)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'มาเร็วๆ นี้',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
