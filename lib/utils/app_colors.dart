import 'package:flutter/material.dart';

class AppColors {
  // --- SABİT RENKLER ---
  static const Color darkNavy = Color(0xFF1A2980);
  static const Color white = Colors.white;
  static const Color transparentWhite = Color(0x26FFFFFF);

  // --- TEMA ANA RENKLERİ ---
  static const Color themeBlue = Color(0xFF1A2980); // Çalışırken
  static const Color themeBronze = Color(0xFF5D4037); // Durunca
  static const Color themeGreen = Color(0xFF1B5E20); // Bitince (Koyu Yeşil)

  // --- HALKA RENKLERİ ---
  static const Color ringCyan = Color(0xFF00E5FF); // Mavi modda Turkuaz
  static const Color ringWhite = Colors.white; // Durunca Beyaz
  // YENİ: Neon değil, tam kararında Koyu Yeşil (Green 700)
  static const Color ringDarkGreen = Color(0xFF388E3C);

  // --- GRADYANLAR ---
  static const List<Color> runningGradient = [
    Color(0xFF1A2980),
    Color(0xFF26D0CE)
  ];

  static const List<Color> pausedGradient = [
    Color(0xFFE6DADA), // Açık Krem
    Color(0xFFC7A17A), // Yumuşak Altın
  ];

  static const List<Color> finishedGradient = [
    Color(0xFF093028),
    Color(0xFF237A57)
  ];

  // ============================================================
  // MANTIK MERKEZİ
  // ============================================================

  static List<Color> getBackgroundGradient(
      bool isRunning, bool isPaused, bool isAlarm, Color defaultColor) {
    if (isAlarm) return finishedGradient;
    if (isPaused) return pausedGradient;
    if (isRunning) return runningGradient;
    return [defaultColor, defaultColor];
  }

  // 2. Halka Rengi (GÜNCELLENDİ) 🟢
  static Color getRingColor(
      bool isRunning, bool isPaused, bool isAlarm, Color defaultColor) {
    if (isAlarm) return ringDarkGreen; // ARTIK KOYU YEŞİL
    if (isPaused) return themeBronze; // Durunca Kahverengi
    if (isRunning) return ringCyan; // Çalışırken Turkuaz
    return defaultColor;
  }

  // 3. Sayaç Yazı Rengi
  static Color getTimerTextColor(
      bool isRunning, bool isPaused, bool isAlarm, Color defaultColor) {
    if (isAlarm) return white; // Bitince Beyaz
    if (isPaused) return themeBronze; // Durunca Kahverengi
    if (isRunning) return white; // Çalışırken Beyaz
    return defaultColor;
  }

  // 4. Ana Buton Arka Planı
  static Color getMainButtonBackgroundColor(
      bool isRunning, bool isPaused, bool isAlarm, Color defaultColor) {
    if (isAlarm || isPaused || isRunning) return white;
    return defaultColor;
  }

  // 5. Ana Buton İçerik Rengi
  static Color getMainButtonContentColor(
      bool isRunning, bool isPaused, bool isAlarm) {
    if (isAlarm) return themeGreen; // Yeşil Yazı
    if (isPaused) return themeBronze; // Kahverengi Yazı
    if (isRunning) return themeBlue; // Lacivert Yazı
    return white;
  }

  // 6. Üst Butonların Rengi
  static Color? getTopButtonActiveColor(
      bool isRunning, bool isPaused, bool isAlarm) {
    if (isAlarm) return themeGreen;
    if (isPaused) return themeBronze;
    if (isRunning) return themeBlue;
    return null;
  }

  // 7. Sıfırla Yazısı
  static Color getResetTextColor(
      bool isActive, bool isPaused, Color defaultColor) {
    if (isPaused) return themeBronze.withValues(alpha: 0.8);
    if (isActive) return white.withValues(alpha: 0.9);
    return defaultColor;
  }
}
