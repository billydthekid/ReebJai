import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_routes.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.book_outlined, color: Colors.white),
            padding: const EdgeInsets.only(right: 16),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('วิธีการใช้งาน',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('1. สแกนเช็คอินสาขาที่จุดทางเข้า'),
                      SizedBox(height: 8),
                      Text('2. สแกนบาร์โค้ดสินค้าที่ต้องการเข้าตะกร้า'),
                      SizedBox(height: 8),
                      Text('3. ชำระเงินผ่านช่องทางที่สะดวก'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ตกลง'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // App Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A0A00),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.shopping_cart,
                        color: Colors.white, size: 56),
                    Positioned(
                      top: 20,
                      child: Icon(Icons.bolt,
                          color: Colors.yellow[600], size: 40),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Tagline
              const Text(
                'Scan • Walk • Pay',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Smart Convenience Store Checkout',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 14,
                ),
              ),
              const Spacer(flex: 3),
              // Customer App Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.register),
                  child: const Text(
                    'Customer App',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
