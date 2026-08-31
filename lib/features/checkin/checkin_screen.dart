import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';
import '../../models/session_model.dart';
import '../../services/firestore_service.dart';
import '../../services/session_provider.dart';
import '../../services/board_provider.dart';
import '../shared/qr_scanner_screen.dart';

class CheckInScreen extends StatefulWidget {
  const CheckInScreen({super.key});

  @override
  State<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends State<CheckInScreen> {
  bool _isProcessing = false;
  final _firestoreService = FirestoreService();

  /// Open camera and scan QR code
  Future<void> _scanQrCode() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(
          title: 'Store Check-In',
          subtitle: 'Scan store QR code to enter',
        ),
      ),
    );

    if (scannedCode == null || !mounted) return;
    await _processCheckIn(scannedCode);
  }


  /// Process check-in with the scanned QR code
  Future<void> _processCheckIn(String qrCode) async {
    setState(() => _isProcessing = true);

    try {
      final store = await _firestoreService.getStoreByQrCode(qrCode);

      if (store == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Store not found for code: $qrCode')),
        );
        return;
      }

      final sessionProvider = context.read<SessionProvider>();
      final userId = sessionProvider.currentUser?.userId ?? 'guest';

      final session = SessionModel(
        sessionId: const Uuid().v4(),
        userId: userId,
        storeId: store.storeId,
        checkInTime: DateTime.now(),
        status: 'active',
      );

      await _firestoreService.createSession(session);

      if (!mounted) return;
      sessionProvider.setStore(store);
      sessionProvider.setSession(session);

      // Send open_gate command to ESP32 (ครั้งที่ 1: เข้าร้าน)
      try {
        context.read<BoardProvider>().openGate(reason: 'checkin');
      } catch (_) {} // graceful if board offline

      Navigator.pushNamed(context, AppRoutes.checkInSuccess);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Check-in failed: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        centerTitle: true,
        title: const Text('Store Check-In',
            style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.qr_code_scanner,
                size: 120, color: AppColors.primary),
            const SizedBox(height: 24),
            const Text(
              'Scan store QR code to enter',
              style: TextStyle(
                  fontSize: 16, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Point your camera at the QR code\nat the store entrance',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.grey),
            ),
            const Spacer(),

            // Real scan button
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
                onPressed: _isProcessing ? null : _scanQrCode,
                icon: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: AppColors.white, strokeWidth: 2))
                    : const Icon(Icons.qr_code_scanner),
                label: Text(
                  _isProcessing ? 'Processing...' : 'Scan QR Code',
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
