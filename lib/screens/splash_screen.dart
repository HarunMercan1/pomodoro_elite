import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../utils/notification_service.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    _initApp(); // Yüklemeleri başlat
  }

  // --- HATA KORUMALI BAŞLATMA ---
  Future<void> _initApp() async {
    try {
      await NotificationService().init();
    } catch (e) {
      debugPrint("❌ Bildirim hatası: $e");
    }

    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint("❌ Wakelock hatası: $e");
    }

    try {
      // Animasyon keyfi için biraz bekle
      await Future.delayed(const Duration(milliseconds: 2500));
    } catch (e) {
      debugPrint("❌ Bekleme hatası: $e");
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 1000),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7);
    final primaryColor = Theme.of(context).primaryColor;
    final textColor =
        isDark ? Colors.white.withOpacity(0.9) : const Color(0xFF2D3142);

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // İKON
                Icon(
                  Icons.timer_outlined,
                  size: 90,
                  color: primaryColor,
                ),

                const SizedBox(height: 30),

                // POMODORO YAZISI (İnce ve Geniş)
                Text(
                  "app_name".tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: textColor,
                    letterSpacing: 8.0,
                  ),
                ),

                const SizedBox(height: 5),

                // ELITE YAZISI (Kalın ve ARTIK GENİŞ)
                Text(
                  "app_subtitle".tr(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 32,
                    fontWeight: FontWeight.w900, // Ekstra kalın
                    color: primaryColor,
                    height: 1.1,
                    letterSpacing: 8.0,
                  ),
                ),

                const SizedBox(height: 15), // Boşluğu biraz artırdık

                // --- İMZA ---
                Text(
                  "developed_by".tr(),
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: textColor.withOpacity(0.5),
                    letterSpacing: 1.5,
                  ),
                ),

                const SizedBox(height: 80),

                // LOADER
                SizedBox(
                  width: 30,
                  height: 30,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: primaryColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
