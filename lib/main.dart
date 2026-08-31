import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_routes.dart';
import 'services/cart_provider.dart';
import 'services/session_provider.dart';
import 'services/board_provider.dart';
import 'services/stripe_service.dart';
import 'features/welcome/welcome_screen.dart';
import 'features/register/register_screen.dart';
import 'features/checkin/checkin_screen.dart';
import 'features/checkin/checkin_success_screen.dart';
import 'features/scan/scan_screen.dart';
import 'features/cart/cart_screen.dart';
import 'features/payment/payment_screen.dart';
import 'features/payment/qr_payment_screen.dart';
import 'features/payment/payment_pending_screen.dart';
import 'features/receipt/receipt_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  StripeService().initialize();
  runApp(const ReebjaiApp());
}

class ReebjaiApp extends StatelessWidget {
  const ReebjaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => BoardProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'REEBJAI',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          primaryColor: AppColors.primary,
          scaffoldBackgroundColor: AppColors.white,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.white,
            elevation: 0,
          ),
          drawerTheme: const DrawerThemeData(
            backgroundColor: AppColors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.welcome,
        routes: {
          AppRoutes.welcome: (_) => const WelcomeScreen(),
          AppRoutes.register: (_) => const RegisterScreen(),
          AppRoutes.checkIn: (_) => const CheckInScreen(),
          AppRoutes.checkInSuccess: (_) => const CheckInSuccessScreen(),
          AppRoutes.scan: (_) => const ScanScreen(),
          AppRoutes.cart: (_) => const CartScreen(),
          AppRoutes.payment: (_) => const PaymentScreen(),
          AppRoutes.receipt: (_) => const ReceiptScreen(),
          // ─── QR Manual Payment ─────────────────────
          AppRoutes.qrPayment: (_) => const QrPaymentScreen(),
          AppRoutes.paymentPending: (_) => const PaymentPendingScreen(),
        },
      ),
    );
  }
}