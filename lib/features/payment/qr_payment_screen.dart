import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/utils/promptpay_qr_generator.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/payment_model.dart';
import '../../services/firestore_service.dart';
import '../../services/session_provider.dart';
import '../../services/cart_provider.dart';
import '../../services/board_provider.dart';
import '../../models/receipt_model.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';


/// QR Payment Screen — shows PromptPay QR, amount, and orderId.
/// Customer scans QR with banking app, transfers money,
/// then taps "I've transferred" to upload slip.
class QrPaymentScreen extends StatefulWidget {
  const QrPaymentScreen({super.key});

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen>
    with SingleTickerProviderStateMixin {
  bool _isVerifying = false;
  late AnimationController _pulseController;

  // ─── PromptPay config มาจาก AppConfig ──────

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _pickAndVerifySlip() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 60,
    );

    if (image == null) return;

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final payment = args['payment'] as PaymentModel;

    setState(() => _isVerifying = true);

    try {
      // 1. Convert image to base64
      final bytes = await File(image.path).readAsBytes();
      final String base64Data = base64Encode(bytes);
      // EasySlip v2 documentation explicitly shows base64 payload supports data URI prefix
      final String base64Image = "data:image/jpeg;base64,$base64Data";

      // 2. Call EasySlip API v2
      final response = await http.post(
        Uri.parse('https://api.easyslip.com/v2/verify/bank'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.easySlipApiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'base64': base64Image,
          'matchAccount': true,
          'matchAmount': payment.amount,
          'checkDuplicate': true,
        }),
      );

      final result = jsonDecode(response.body);

      if (result['success'] == true) {
        final data = result['data'];
        final bool isAmountMatched = data['isAmountMatched'] ?? true;

        if (isAmountMatched) {
          // ─── Verification SUCCESS ─────────────────────
          await _onVerificationSuccess(payment, base64Image);
        } else {
          // Amount mismatch
          if (!mounted) return;
          _showErrorDialog(
            title: 'ยอดเงินไม่ถูกต้อง',
            message: 'ยอดเงินในสลิป (฿${data['amountInSlip']}) ไม่ตรงกับยอดที่สั่ง (฿${payment.amount})',
          );
        }
      } else {
        // Verification failed (SLIP_NOT_FOUND, etc)
        final error = result['error'] ?? {};
        final String errorCode = error['code']?.toString() ?? 'UNKNOWN_ERROR';
        final String errorMessage = error['message']?.toString() ?? 'กรุณาตรวจสอบว่าเลือกรูปสลิปที่ถูกต้อง';
        
        if (!mounted) return;
        _showErrorDialog(
          title: 'ไม่สามารถตรวจสอบสลิปได้',
          message: '[$errorCode]: $errorMessage',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  /// Internal handler for verified slip
  Future<void> _onVerificationSuccess(PaymentModel payment, String base64Image) async {
    final firestoreService = FirestoreService();
    final session = context.read<SessionProvider>();
    final cart = context.read<CartProvider>();
    final uuid = const Uuid();
    final now = DateTime.now();

    // 1. Update Payment status to 'paid' in Firestore
    await firestoreService.updatePaymentStatus(
      payment.paymentId,
      'paid',
      paidAt: now,
    );

    // Save slip image to payment document immediately
    await firestoreService.updatePaymentSlip(payment.paymentId, base64Image);

    // 2. Update Session status
    final sessionId = session.currentSession?.sessionId ?? uuid.v4();
    await firestoreService.updateSessionStatus(sessionId, 'paid');

    // 3. Create Receipt
    final points = payment.amount.toInt();
    final orderId = payment.orderId ?? payment.paymentId.substring(0, 8);
    final storeId = session.currentStore?.storeId ?? 'store_001';
    final storeName = session.currentStore?.name ?? 'REEBJAI Store';
    final userId = session.currentUser?.userId ?? 'guest';

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
      paymentId: payment.paymentId,
      paymentMethod: payment.method,
      items: receiptItems,
      totalAmount: payment.amount,
      pointsEarned: points,
      createdAt: now,
    );
    await firestoreService.createReceipt(receipt);

    // 4. Update user points
    await firestoreService.updateUserPoints(userId, points);

    // 5. Update local state and deduct stock
    final deductItems = cart.items
        .map((i) => {
              'productId': i.product.barcode.isNotEmpty ? i.product.barcode : i.product.productId,
              'quantity': i.quantity,
            })
        .toList();
    if (deductItems.isNotEmpty) {
      await firestoreService.deductStoreProductStock(storeId, deductItems);
    }
    
    if (!mounted) return;
    session.setPayment(payment.copyWith(status: 'paid', paidAt: now));
    session.setReceipt(receipt);

    // 6. Open gate for EXIT
    try {
      final board = context.read<BoardProvider>();
      board.openGate(
        reason: 'payment_complete',
        line1: 'Verify OK!',
        line2: '${payment.amount.toStringAsFixed(0)} THB',
      );
    } catch (_) {}

    cart.clear();

    // 7. Success dialog then navigate
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ ตรวจสอบสลิปสำเร็จ กำลังเตรียมใบเสร็จ'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.receipt,
      (route) => route.settings.name == AppRoutes.welcome,
    );
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ตกลง'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final payment = args['payment'] as PaymentModel;
    final amount = payment.amount;
    final orderId = payment.orderId ?? payment.paymentId.substring(0, 8);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        centerTitle: true,
        title: const Text('Transfer Payment',
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
                children: [
                  const SizedBox(height: 8),

                  // ─── Order Info ──────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Order ID',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(orderId,
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Amount',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12)),
                            const SizedBox(height: 2),
                            Text('฿${amount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ─── QR Code Section ────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // PromptPay logo + label
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A3E72),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'PromptPay',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('พร้อมเพย์',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14)),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Show actual QR image from assets
                        Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFF1A3E72), width: 3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: QrImageView(
                              data: PromptPayQrGenerator.generate(
                                AppConfig.receiverPromptPay,
                                payment.amount,
                              ),
                              version: QrVersions.auto,
                              size: 260.0,
                              backgroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF1A3E72),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF1A3E72),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // PromptPay details
                        Text(AppConfig.receiverName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),

                        // Copyable PromptPay ID
                        GestureDetector(
                          onTap: () {
                            Clipboard.setData(
                                const ClipboardData(text: AppConfig.receiverPromptPay));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Copied PromptPay ID to clipboard'),
                                  duration: Duration(seconds: 1)),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(AppConfig.receiverPromptPay,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF1A3E72),
                                        letterSpacing: 1.2)),
                                const SizedBox(width: 8),
                                const Icon(Icons.copy,
                                    size: 16, color: Color(0xFF1A3E72)),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        const Text('PromptPay (พร้อมเพย์)',
                            style: const TextStyle(
                                color: AppColors.textSecondary, fontSize: 13)),

                        const SizedBox(height: 16),

                        // Amount again (large)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color:
                                    const Color(0xFFFF9800).withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.info_outline,
                                  color: Color(0xFFE65100), size: 18),
                              const SizedBox(width: 8),
                              Text('โอนจำนวน ฿${amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: Color(0xFFE65100),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ─── Instructions ───────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.greyBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('วิธีชำระเงิน',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                fontSize: 15)),
                        const SizedBox(height: 12),
                        _buildStep('1', 'เปิดแอปธนาคาร / Mobile Banking'),
                        _buildStep('2', 'สแกน QR Code ด้านบน'),
                        _buildStep('3', 'ระบบระบุยอด ฿${amount.toStringAsFixed(2)} ให้โดยอัตโนมัติ'),
                        _buildStep('4', 'ตรวจสอบยอดเงินและยืนยันการโอน'),
                        _buildStep('5', 'กดปุ่ม "อัปโหลดสลิป & จ่ายเงิน" ด้านล่าง'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── Bottom button ────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.lerp(
                        AppColors.success,
                        const Color(0xFF388E3C),
                        _pulseController.value,
                      ),
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                    ),
                    onPressed: _isVerifying ? null : _pickAndVerifySlip,
                    icon: _isVerifying
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.cloud_upload, size: 24),
                    label: Text(
                      _isVerifying ? 'กำลังตรวจสอบสลิป...' : 'อัปโหลดสลิป & จ่ายเงิน',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(number,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(text,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
