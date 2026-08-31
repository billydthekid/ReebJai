import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/payment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/session_provider.dart';
import '../../services/cart_provider.dart';
import '../../services/board_provider.dart';
import '../../models/receipt_model.dart';
import 'package:uuid/uuid.dart';

/// Payment Pending Verification Screen
/// - Listens to Firestore for real-time status changes.
/// - When admin confirms → auto-navigate to receipt screen.
/// - When admin rejects → show rejected message.
class PaymentPendingScreen extends StatefulWidget {
  const PaymentPendingScreen({super.key});

  @override
  State<PaymentPendingScreen> createState() => _PaymentPendingScreenState();
}

class _PaymentPendingScreenState extends State<PaymentPendingScreen>
    with SingleTickerProviderStateMixin {
  final _firestoreService = FirestoreService();
  StreamSubscription? _paymentSub;
  String _status = 'pending_verification';
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Start listening after the first frame (so arguments are available)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  void _startListening() {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final payment = args['payment'] as PaymentModel;

    _paymentSub = _firestoreService.streamPayment(payment.paymentId).listen(
      (updatedPayment) {
        if (updatedPayment == null) return;

        if (!mounted) return;
        setState(() => _status = updatedPayment.status);

        if (updatedPayment.status == 'paid') {
          _onPaymentConfirmed(updatedPayment);
        }
      },
    );
  }

  Future<void> _onPaymentConfirmed(PaymentModel payment) async {
    await _paymentSub?.cancel();

    try {
      final session = context.read<SessionProvider>();
      final cart = context.read<CartProvider>();
      final uuid = const Uuid();

      final sessionId =
          session.currentSession?.sessionId ?? uuid.v4();
      final userId = session.currentUser?.userId ?? 'guest';
      final storeId = session.currentStore?.storeId ?? 'store_001';
      final storeName = session.currentStore?.name ?? 'REEBJAI Store';

      // Update session status
      await _firestoreService.updateSessionStatus(sessionId, 'paid');

      // Calculate points (1 point per 1 THB)
      final points = payment.amount.toInt();

      // Create receipt
      final cartItems = cart.items;
      final receiptItems = cartItems
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
        orderId: payment.orderId ?? payment.paymentId.substring(0, 8),
        sessionId: sessionId,
        userId: userId,
        storeId: storeId,
        storeName: storeName,
        paymentId: payment.paymentId,
        paymentMethod: payment.method,
        items: receiptItems,
        totalAmount: payment.amount,
        pointsEarned: points,
        createdAt: payment.confirmedAt ?? DateTime.now(),
      );
      await _firestoreService.createReceipt(receipt);

      // Update user points
      await _firestoreService.updateUserPoints(userId, points);

      if (!mounted) return;
      session.setPayment(payment);
      session.setReceipt(receipt);

      // Open gate for EXIT (ครั้งที่ 2)
      try {
        final board = context.read<BoardProvider>();
        board.openGate(
          reason: 'payment_complete',
          line1: 'Payment OK!',
          line2: '${payment.amount.toStringAsFixed(0)} THB',
        );
      } catch (_) {}

      cart.clear();

      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.receipt,
        (route) => route.settings.name == AppRoutes.welcome,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _paymentSub?.cancel();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPending = _status == 'pending_verification' || _status == 'pending';
    final isRejected = _status == 'rejected';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isPending
            ? const Color(0xFFFF9800)
            : isRejected
                ? AppColors.primary
                : AppColors.success,
        foregroundColor: AppColors.white,
        centerTitle: true,
        title: Text(
          isPending
              ? 'รอตรวจสอบ'
              : isRejected
                  ? 'ไม่ผ่านการตรวจสอบ'
                  : 'ชำระเงินสำเร็จ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isPending) ...[
                // Spinning icon
                AnimatedBuilder(
                  animation: _spinController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _spinController.value * 2 * 3.14159,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFFFF9800),
                            width: 3,
                          ),
                        ),
                        child: const Icon(
                          Icons.hourglass_top,
                          color: Color(0xFFFF9800),
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                const Text(
                  'รอตรวจสอบการชำระเงิน',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'แอดมินกำลังตรวจสอบการโอนเงินของคุณ\nกรุณารอสักครู่...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),

                // Status info box
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFFFF9800).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFFF9800).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(Icons.access_time,
                            color: Color(0xFFE65100), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pending Verification',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFE65100),
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'หน้านี้จะอัปเดตอัตโนมัติเมื่อแอดมินตรวจเสร็จ',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (isRejected) ...[
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                  child: const Icon(Icons.close,
                      color: AppColors.primary, size: 48),
                ),
                const SizedBox(height: 32),
                const Text(
                  'การชำระเงินถูกปฏิเสธ',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'แอดมินปฏิเสธการชำระเงินของคุณ\nกรุณาลองใหม่อีกครั้ง',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.payment,
                        (route) => route.settings.name == AppRoutes.cart,
                      );
                    },
                    child: const Text('ลองใหม่',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
