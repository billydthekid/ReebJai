import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../services/firestore_service.dart';
import '../../services/cart_provider.dart';
import '../../services/session_provider.dart';
import '../shared/qr_scanner_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final _firestoreService = FirestoreService();
  bool _isProcessing = false;

  /// Open camera and scan barcode
  Future<void> _scanBarcode() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(
          title: 'Scan Product',
          subtitle: 'Scan product barcode',
        ),
      ),
    );

    if (scannedCode == null || !mounted) return;
    await _processProduct(scannedCode);
  }

  /// Process scanned barcode
  Future<void> _processProduct(String barcode) async {
    setState(() => _isProcessing = true);

    try {
      final session = context.read<SessionProvider>();
      final storeId = session.currentStore?.storeId ?? '';
      
      final product = await _firestoreService.getProductByBarcode(storeId, barcode);
      if (!mounted) return;

      if (product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Product not found: $barcode')),
        );
        return;
      }

      context.read<CartProvider>().addProduct(product);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Scan failed: $e')));
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
        title: const Text('Scan Product',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (cart.items.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.cart),
                  icon: Badge(
                    label: Text('${cart.itemCount}'),
                    child: const Icon(Icons.shopping_cart, color: AppColors.white),
                  ),
                ),
              ),
            ),
        ],
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.document_scanner_outlined,
                size: 120, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              'Scan product barcode',
              style: TextStyle(
                  fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Point your camera at the barcode\non the product',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.grey),
            ),

            // Show current cart count
            if (cart.items.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${cart.itemCount} items in cart',
                  style: const TextStyle(
                      color: AppColors.success, fontWeight: FontWeight.w600),
                ),
              ),
            ],

            const Spacer(),

            // Scan button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: _isProcessing ? null : _scanBarcode,
                icon: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2))
                    : const Icon(Icons.qr_code_scanner),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Scan Barcode',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
