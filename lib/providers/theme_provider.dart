import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';

/// Timer durumları
enum TimerState {
  idle, // Boşta
  focus, // Odaklanma
  pause, // Mola (short/long break)
  workPaused, // 🔥 YENİ: Çalışma duraklatıldı (Heisenberg özel ayrımı için)
  finish, // Tamamlandı
}

/// Bir durumun renk paleti
class ThemeStateColors {
  final Color bgColor; // Arka plan (tek renk)
  final List<Color>? gradientColors; // Arka plan (gradient opsiyonel)
  final Color accentColor; // Buton, progress bar
  final Color textColor; // Metin
  final Color? mainButtonColor; // Ana buton arka planı (null ise accentColor)
  final Color?
      mainButtonTextColor; // Ana buton ikon/yazı rengi (null ise beyaz)
  final Color?
      menuButtonColor; // Üst menü butonları arka planı (null ise accentColor)
  final Color? menuButtonTextColor; // 🔥 YENİ: Üst menü buton yazı rengi

  const ThemeStateColors({
    required this.bgColor,
    this.gradientColors,
    required this.accentColor,
    this.textColor = Colors.white,
    this.mainButtonColor,
    this.mainButtonTextColor,
    this.menuButtonColor,
    this.menuButtonTextColor,
  });

  /// Gradient var mı?
  bool get hasGradient => gradientColors != null && gradientColors!.length > 1;

  /// LinearGradient döndür (yoksa null)
  LinearGradient? get gradient => hasGradient
      ? LinearGradient(
          colors: gradientColors!,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : null;

  /// Accent rengin dim hali (progress bar arka planı)
  Color get accentDim => accentColor.withAlpha(51);

  /// Efektif Buton Arka Plan Rengi
  Color get effectiveButtonBg => mainButtonColor ?? accentColor;

  /// Efektif Buton Yazı Rengi
  Color get effectiveButtonTextColor => mainButtonTextColor ?? Colors.white;

  /// Efektif Menü Buton Arka Plan Rengi
  Color get effectiveMenuButtonColor => menuButtonColor ?? accentColor;

  /// 🔥 YENİ: Efektif Menü Buton Yazı Rengi
  Color get effectiveMenuButtonTextColor => menuButtonTextColor ?? Colors.white;
}

/// Ana tema modeli
class AppTheme {
  final String id;
  final String name;
  final String vibe;
  final ThemeStateColors idle; // Boşta
  final ThemeStateColors focus; // Odaklanma
  final ThemeStateColors breakState; // Mola
  final ThemeStateColors finish; // Bitiş
  final bool isLocked;
  final Color? settingsBgColor; // 🔥 YENİ: Ayarlar ekranı arka plan rengi
  final Color? settingsCardColor; // 🔥 YENİ: Ayarlar kart rengi
  final Color? settingsBorderColor; // 🔥 YENİ: Ayarlar border rengi
  final Color? settingsItemColor; // 🔥 YENİ: Ayarlar item rengi
  final ThemeStateColors?
      workPaused; // 🔥 YENİ: Çalışma duraklatıldığında özel renk (Null ise breakState kullanır)

  const AppTheme({
    required this.id,
    required this.name,
    required this.vibe,
    required this.idle,
    required this.focus,
    required this.breakState,
    required this.finish,
    this.isLocked = true,
    this.settingsBgColor,
    this.settingsCardColor,
    this.settingsBorderColor,
    this.settingsItemColor,
    this.workPaused,
  });

  /// Duruma göre renk paleti
  ThemeStateColors getStateColors(TimerState state) {
    switch (state) {
      case TimerState.idle:
        return idle;
      case TimerState.focus:
        return focus;
      case TimerState.pause:
        return breakState;
      case TimerState.workPaused:
        return workPaused ?? breakState; // Özel tanım yoksa Mola rengini kullan
      case TimerState.finish:
        return finish;
    }
  }
}

/// 11 Tema Paleti
class AppThemes {
  static const List<AppTheme> all = [
    // ============================================================
    // 1. ELITE (Varsayılan - UNLOCKED)
    // ============================================================
    AppTheme(
      id: 'elite',
      name: 'Elite',
      vibe: 'Orijinal, Klasik',
      isLocked: false,
      settingsCardColor: Color(0xFF202020),
      settingsBorderColor: Color(0x0FFFFFFF), // White with 0.06 opacity
      // 🔥 IDLE: Beyaz buton, lacivert yazı
      idle: ThemeStateColors(
        bgColor: Color(0xFF141414),
        gradientColors: [Color(0xFF141414), Color(0xFF141414)],
        accentColor: Color(0xFF1A2980),
        mainButtonColor: Color(0xFF1A2980),
        mainButtonTextColor: Colors.white,
        menuButtonColor: Colors.white, // Beyaz buton arka planı
        menuButtonTextColor: Color(0xFF1A2980), // Lacivert yazı
      ),
      // 🔥 FOCUS: Lacivert buton, beyaz yazı
      focus: ThemeStateColors(
        bgColor: AppColors.themeBlue,
        gradientColors: AppColors.runningGradient,
        accentColor: AppColors.ringCyan,
        mainButtonColor: Colors.white,
        mainButtonTextColor: AppColors.themeBlue,
        menuButtonColor: Color(0xFF1A2980), // Lacivert buton arka planı
        menuButtonTextColor: Colors.white, // Beyaz yazı
      ),
      // 🔥 BREAK: Kahverengi buton, beyaz yazı
      breakState: ThemeStateColors(
        bgColor: AppColors.themeBronze,
        gradientColors: AppColors.pausedGradient,
        accentColor: AppColors.themeBronze,
        textColor: AppColors.themeBronze,
        mainButtonColor: Colors.white,
        mainButtonTextColor: AppColors.themeBronze,
        menuButtonColor: AppColors.themeBronze, // Kahverengi buton arka planı
        menuButtonTextColor: Colors.white, // Beyaz yazı
      ),
      // 🔥 WORK PAUSED: Kahverengi buton, beyaz yazı
      workPaused: ThemeStateColors(
        bgColor: AppColors.themeBronze,
        gradientColors: AppColors.pausedGradient,
        accentColor: AppColors.themeBronze,
        textColor: AppColors.themeBronze,
        mainButtonColor: Colors.white,
        mainButtonTextColor: AppColors.themeBronze,
        menuButtonColor: AppColors.themeBronze, // Kahverengi buton arka planı
        menuButtonTextColor: Colors.white, // Beyaz yazı
      ),
      finish: ThemeStateColors(
        bgColor: AppColors.themeGreen,
        gradientColors: AppColors.finishedGradient,
        accentColor: AppColors.ringDarkGreen,
        mainButtonColor: Colors.white,
        mainButtonTextColor: AppColors.themeGreen,
      ),
    ),

    // ============================================================
    // 2. Klasik (Eski Classic Elite)
    // ============================================================
    AppTheme(
      id: 'classic_elite',
      name: 'Klasik',
      vibe: 'Güven, Sade',
      // 🔥 Ayarlar ekranı renkleri - Açık mavi tonlarında
      settingsBgColor: Color(0xFFE3F2FD), // Açık mavi-beyaz arka plan
      settingsCardColor: Color(0xFFBBDEFB), // Açık mavi kart (beyaz-mavi arası)
      settingsBorderColor: Color(0x661565C0), // Mavi border
      settingsItemColor: Color(0xFF0D47A1), // Koyu mavi metin
      // 🔥 IDLE: Koyu arka plan (sayaç ekranı)
      idle: ThemeStateColors(
        bgColor: Color(0xFF121212), // Koyu arka plan
        gradientColors: [Color(0xFF121212), Color(0xFF1E1E1E)],
        accentColor: Color(0xFF1565C0), // Koyu mavi halka
        textColor: Colors.white,
        mainButtonColor: Color(0xFF1565C0),
        mainButtonTextColor: Colors.white,
        menuButtonColor: Colors.white, // Beyaz buton
        menuButtonTextColor: Color(0xFF1565C0), // Koyu mavi yazı
      ),
      // 🔥 FOCUS: Sayaç akarken - daha koyu mavi buton ve halka
      focus: ThemeStateColors(
        bgColor: Color(0xFFBBDEFB), // Daha koyu açık mavi
        gradientColors: [Color(0xFFBBDEFB), Color(0xFF90CAF9)],
        accentColor: Color(0xFF0D47A1), // Koyu mavi halka (butonla aynı)
        textColor: Color(0xFF0D47A1),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF1565C0),
        menuButtonColor: Color(0xFF0D47A1), // Daha koyu mavi buton
        menuButtonTextColor: Colors.white, // Beyaz yazı
      ),
      // 🔥 BREAK: Sayaç akarken - focus ile aynı
      breakState: ThemeStateColors(
        bgColor: Color(0xFFBBDEFB), // Daha koyu açık mavi
        gradientColors: [Color(0xFFBBDEFB), Color(0xFF90CAF9)],
        accentColor: Color(0xFF0D47A1), // Koyu mavi halka (butonla aynı)
        textColor: Color(0xFF0D47A1),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF1565C0),
        menuButtonColor: Color(0xFF0D47A1), // Daha koyu mavi buton
        menuButtonTextColor: Colors.white, // Beyaz yazı
      ),
      // 🔥 WORK PAUSED: Gri-mavi arka plan, gri-mavi buton
      workPaused: ThemeStateColors(
        bgColor: Color(0xFFECEFF1), // Gri-mavi (çok fark edilir)
        gradientColors: [Color(0xFFECEFF1), Color(0xFFCFD8DC)],
        accentColor: Color(0xFF455A64), // Gri-mavi halka
        textColor: Color(0xFF37474F),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF455A64),
        menuButtonColor: Color(0xFF455A64), // Gri-mavi buton
        menuButtonTextColor: Colors.white, // Beyaz yazı
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF43A047),
        gradientColors: [Color(0xFF388E3C), Color(0xFF66BB6A)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF2E7D32),
        menuButtonColor: Colors.white, // Beyaz buton
        menuButtonTextColor: Color(0xFF2E7D32), // Yeşil yazı
      ),
    ),

    // ============================================================
    // 3. Stranger Things (Gerilim)
    // ============================================================
    AppTheme(
      id: 'stranger_things',
      name: 'Stranger Things',
      vibe: 'Gerilim, Gizem, 80ler',
      settingsCardColor: Color(0xFF1A0000),
      settingsBorderColor: Color(0x33B71C1C), // Deep red with opacity
      idle: ThemeStateColors(
        bgColor: Color(0xFF000000),
        gradientColors: [Color(0xFF000000), Color(0xFF1A0000)],
        accentColor: Color(0xFFD32F2F),
        mainButtonColor: Color(0xFFD32F2F),
        mainButtonTextColor: Colors.white,
        menuButtonColor: Color(0xFFD32F2F),
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFFB71C1C),
        gradientColors: [Color(0xFF000000), Color(0xFFB71C1C)],
        accentColor: Color(0xFFFF5252),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFB71C1C),
        menuButtonColor: Color(0xFFD32F2F),
      ),
      // 🔥 BREAK: Focus ile aynı (sayaç akarken kırmızı)
      breakState: ThemeStateColors(
        bgColor: Color(0xFFB71C1C),
        gradientColors: [Color(0xFF000000), Color(0xFFB71C1C)],
        accentColor: Color(0xFFFF5252),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFB71C1C),
        menuButtonColor: Color(0xFFD32F2F),
      ),
      // 🔥 WORK PAUSED: Gri tonları (sayaç durduğunda)
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF212121),
        gradientColors: [Color(0xFF424242), Color(0xFF212121)],
        accentColor: Colors.grey,
        textColor: Colors.white70,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Colors.black,
        menuButtonColor: Colors.grey,
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF000000),
        gradientColors: [Color(0xFF1A1A1A), Color(0xFFFFFF00)],
        accentColor: Colors.black,
        textColor: Colors.black,
        mainButtonColor: Colors.black,
        mainButtonTextColor: Color(0xFFFFD600),
      ),
    ),

    // ============================================================
    // 4. Heisenberg (Breaking Bad)
    // ============================================================
    AppTheme(
      id: 'heisenberg',
      name: 'Heisenberg',
      vibe: 'Kristal Mavi, Sarı Tulum',
      settingsCardColor: Color(0xFF004D40),
      settingsBorderColor: Color(0x3300E676), // Green/Teal accent
      idle: ThemeStateColors(
        bgColor: Color(0xFF00BCD4),
        gradientColors: [Color(0xFF00838F), Color(0xFF00E5FF)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF006064),
        menuButtonColor: Color(0xFFB2EBF2),
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFFFBC02D),
        gradientColors: [Color(0xFFF9A825), Color(0xFFFFF176)],
        accentColor: Color(0xFF3E2723),
        textColor: Color(0xFF3E2723),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFF9A825),
        menuButtonColor: Color(0xFFFFF59D),
      ),
      workPaused: ThemeStateColors(
        // Eski Idle (Yeşil) renklerini buraya aldık
        bgColor: Color(0xFF004D40),
        gradientColors: [Color(0xFF004D40), Color(0xFF00695C)],
        accentColor: Color(0xFF00E676),
        mainButtonColor: Color(0xFF00E676),
        mainButtonTextColor: Colors.white,
      ),
      breakState: ThemeStateColors(
        bgColor: Color(0xFFFBC02D),
        gradientColors: [Color(0xFFF9A825), Color(0xFFFFF176)],
        accentColor: Color(0xFF3E2723),
        textColor: Color(0xFF3E2723),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFFbc02D),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF2E7D32),
        gradientColors: [Color(0xFF1B5E20), Color(0xFF4CAF50)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF1B5E20),
      ),
    ),

    // ============================================================
    // 5. Deep Ocean (Derinlik)
    // ============================================================
    AppTheme(
      id: 'deep_ocean',
      name: 'Deep Ocean',
      vibe: 'Derinlik, Odak',
      settingsCardColor: Color(0xFF003c5c),
      settingsBorderColor: Color(0x2600E5FF), // Cyan accent
      idle: ThemeStateColors(
        bgColor: Color(0xFF01579B),
        gradientColors: [Color(0xFF000000), Color(0xFF01579B)],
        accentColor: Color(0xFF00E5FF),
        mainButtonColor: Color(0xFF00E5FF),
        mainButtonTextColor: Colors.black,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF0277BD),
        gradientColors: [Color(0xFF01579B), Color(0xFF29B6F6)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF01579B),
        menuButtonColor: Color(0xFFB3E5FC),
      ),
      breakState: ThemeStateColors(
        bgColor: Color(0xFF00695C),
        gradientColors: [Color(0xFF004D40), Color(0xFF4DB6AC)],
        accentColor: Color(0xFFB2DFDB),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF00695C),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF00C853),
        gradientColors: [Color(0xFF00C853), Color(0xFF69F0AE)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF00C853),
      ),
    ),

    // ============================================================
    // 6. Mystic Forest (Doğa)
    // ============================================================
    AppTheme(
      id: 'mystic_forest',
      name: 'Mystic Forest',
      vibe: 'Doğa, Huzur',
      settingsCardColor: Color(0xFF1B5E20),
      settingsBorderColor: Color(0x26AED581), // Light Green
      idle: ThemeStateColors(
        bgColor: Color(0xFF1B5E20),
        gradientColors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        accentColor: Color(0xFFAED581),
        mainButtonColor: Color(0xFFAED581),
        mainButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF2E7D32),
        gradientColors: [Color(0xFF1B5E20), Color(0xFF66BB6A)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF1B5E20),
        menuButtonColor: Color(0xFFC8E6C9),
      ),
      breakState: ThemeStateColors(
        bgColor: Color(0xFF5D4037),
        gradientColors: [Color(0xFF3E2723), Color(0xFF8D6E63)],
        accentColor: Color(0xFFD7CCC8),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF5D4037),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF76FF03),
        gradientColors: [Color(0xFF33691E), Color(0xFF76FF03)],
        accentColor: Colors.white,
        textColor: Colors.black,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF33691E),
      ),
    ),

    // ============================================================
    // 7. Cyberpunk 2077 (Neon)
    // ============================================================
    AppTheme(
      id: 'cyberpunk',
      name: 'Cyberpunk 2077',
      vibe: 'Neon, Gelecek',
      settingsCardColor: Color(0xFF212121),
      settingsBorderColor: Color(0x4DFBC02D), // Yellow accent
      idle: ThemeStateColors(
        bgColor: Color(0xFF080808),
        gradientColors: [Color(0xFF000000), Color(0xFF111111)],
        accentColor: Color(0xFFFBC02D),
        mainButtonColor: Color(0xFFFBC02D),
        mainButtonTextColor: Colors.black,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFFEA005E),
        gradientColors: [Color(0xFF31004a), Color(0xFFEA005E)],
        accentColor: Color(0xFFFFFF00), // Changed from Cyan to Neon Yellow
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFEA005E),
        menuButtonColor: Color(0xFFF8BBD0),
      ),
      breakState: ThemeStateColors(
        bgColor: Color(0xFF212121),
        gradientColors: [Color(0xFF000000), Color(0xFF333333)],
        accentColor: Color(0xFF00E676),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF212121),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF00E5FF),
        gradientColors: [Color(0xFF006064), Color(0xFF00E5FF)],
        accentColor: Colors.white,
        textColor: Colors.black,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF006064),
      ),
    ),

    // ============================================================
    // 8. Royal Gold (Lüks)
    // ============================================================
    AppTheme(
      id: 'royal_gold',
      name: 'Royal Gold',
      vibe: 'Lüks, Başarı',
      settingsCardColor: Color(0xFF1A1A1A),
      settingsBorderColor: Color(0x4DFFD700), // Gold accent
      idle: ThemeStateColors(
        bgColor: Color(0xFF121212),
        gradientColors: [Color(0xFF000000), Color(0xFF121212)],
        accentColor: Color(0xFFFFD700),
        mainButtonColor: Color(0xFFFFD700),
        mainButtonTextColor: Colors.black,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF372C01),
        gradientColors: [Color(0xFF000000), Color(0xFFFFB300)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFA00000),
        menuButtonColor: Color(0xFFFFECB3),
      ),
      breakState: ThemeStateColors(
        bgColor: Color(0xFF424242),
        gradientColors: [Color(0xFF212121), Color(0xFF757575)],
        accentColor: Color(0xFFE0E0E0),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF424242),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFFFFD700),
        gradientColors: [Color(0xFFFFA000), Color(0xFFFFD700)],
        accentColor: Colors.white,
        textColor: Colors.black,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFFF6F00),
      ),
    ),

    // ============================================================
    // 9. Sunset Lofi (Chill)
    // ============================================================
    AppTheme(
      id: 'sunset_lofi',
      name: 'Sunset Lofi',
      vibe: 'Estetik, Chill',
      settingsCardColor: Color(0xFF2D1B2E),
      settingsBorderColor: Color(0x33FF6B6B), // Pink accent
      idle: ThemeStateColors(
        bgColor: Color(0xFF2D1B2E),
        gradientColors: [Color(0xFF1A1A2E), Color(0xFF2D1B2E)],
        accentColor: Color(0xFFFF6B6B),
        mainButtonColor: Color(0xFFFF6B6B),
        mainButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF6A1B9A),
        gradientColors: [Color(0xFF4527A0), Color(0xFFFF6B6B)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF6A1B9A),
        menuButtonColor: Color(0xFFE1BEE7),
      ),
      breakState: ThemeStateColors(
        bgColor: Color(0xFF3E2723),
        gradientColors: [Color(0xFF2D1B2E), Color(0xFF5D4037)],
        accentColor: Color(0xFFFFB74D),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF3E2723),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF009688),
        gradientColors: [Color(0xFF004D40), Color(0xFF4DB6AC)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF004D40),
      ),
    ),

    // ============================================================
    // 10. Nordic Snow (Minimal) - Beyaz/Buz Mavisi
    // ============================================================
    AppTheme(
      id: 'nordic_snow',
      name: 'Nordic Snow',
      vibe: 'Ferah, Minimal',
      settingsCardColor: Colors.white, // 🔥 Tam Beyaz
      settingsBorderColor: Color(0xFFCFD8DC), // Hafif Gri-Mavi Border
      settingsItemColor:
          Color(0xFF37474F), // 🔥 YENİ: Kart içi metin rengi (Koyu Gri)
      idle: ThemeStateColors(
        bgColor: Color(0xFF37474F),
        gradientColors: [Color(0xFF263238), Color(0xFF455A64)],
        accentColor: Color(0xFF90CAF9),
        mainButtonColor: Color(0xFF90CAF9),
        mainButtonTextColor: Colors.black,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFFE3F2FD),
        gradientColors: [Color(0xFFE1F5FE), Color(0xFFBBDEFB)],
        accentColor: Color(0xFF0277BD),
        textColor: Color(0xFF01579B),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF0277BD),
        menuButtonColor: Color(0xFF0277BD),
      ),
      breakState: ThemeStateColors(
        bgColor: Color(0xFFECEFF1),
        gradientColors: [Color(0xFFCFD8DC), Color(0xFFECEFF1)],
        accentColor: Color(0xFF607D8B),
        textColor: Color(0xFF455A64),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF607D8B),
        menuButtonColor: Color(0xFF37474F),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFFA5D6A7),
        gradientColors: [Color(0xFF81C784), Color(0xFFA5D6A7)],
        accentColor: Colors.white,
        textColor: Color(0xFF1B5E20),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF2E7D32),
      ),
    ),

    // ============================================================
    // 11. Volcano (Enerji)
    // ============================================================
    AppTheme(
      id: 'volcano',
      name: 'Volcano',
      vibe: 'Yüksek Enerji',
      settingsCardColor: Color(0xFF210500),
      settingsBorderColor: Color(0x33FF5722), // Orange accent
      idle: ThemeStateColors(
        bgColor: Color(0xFF212121),
        gradientColors: [Color(0xFF000000), Color(0xFF212121)],
        accentColor: Color(0xFFFF5722),
        mainButtonColor: Color(0xFFFF5722),
        mainButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFFBF360C),
        gradientColors: [Color(0xFFB71C1C), Color(0xFFFF5722)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFBF360C),
        menuButtonColor: Color(0xFFFFCCBC),
      ),
      breakState: ThemeStateColors(
        bgColor: Color(0xFF3E2723),
        gradientColors: [Color(0xFF212121), Color(0xFF5D4037)],
        accentColor: Color(0xFFBDBDBD),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF3E2723),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFFFFAB00),
        gradientColors: [Color(0xFFFF6F00), Color(0xFFFFD740)],
        accentColor: Colors.white,
        textColor: Colors.black,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFFF6F00),
      ),
    ),
  ];

  static AppTheme getById(String id) {
    return all.firstWhere(
      (theme) => theme.id == id,
      orElse: () => all.first,
    );
  }
}

/// Tema ve Durum Yöneticisi
class ThemeProvider with ChangeNotifier {
  late SharedPreferences _prefs;

  String _currentThemeId = 'elite';
  Set<String> _unlockedThemes = {'elite', 'classic_elite'};
  TimerState _timerState = TimerState.idle;

  ThemeProvider() {
    _loadThemeData();
  }

  // ============================================================
  // GETTERLAR
  // ============================================================

  String get currentThemeId => _currentThemeId;
  AppTheme get currentTheme => AppThemes.getById(_currentThemeId);
  Set<String> get unlockedThemes => _unlockedThemes;
  TimerState get timerState => _timerState;

  /// Mevcut durumun renk paleti
  ThemeStateColors get stateColors => currentTheme.getStateColors(_timerState);

  /// Hızlı erişim: Arka plan rengi
  Color get bgColor => stateColors.bgColor;

  /// Hızlı erişim: Accent rengi (buton, progress bar)
  Color get accentColor => stateColors.accentColor;

  /// Hızlı erişim: Accent dim (progress bar arka planı)
  Color get accentDimColor => stateColors.accentDim;

  /// Hızlı erişim: Metin rengi
  Color get textColor => stateColors.textColor;

  // ============================================================
  // SETTINGS EKRANI İÇİN SABİT RENKLER (Timer durumundan bağımsız)
  // ============================================================

  /// Settings için: Tema bazlı arka plan rengi (yoksa idle bgColor)
  Color get settingsBgColor =>
      currentTheme.settingsBgColor ?? currentTheme.idle.bgColor;

  /// Settings için: Tema bazlı metin rengi (yoksa idle textColor)
  Color get settingsTextColor =>
      currentTheme.settingsItemColor ?? currentTheme.idle.textColor;

  /// Settings için: Her zaman idle arka plan rengi
  Color get idleBgColor => currentTheme.idle.bgColor;

  /// Settings için: Her zaman idle metin rengi
  Color get idleTextColor => currentTheme.idle.textColor;

  /// Settings için: Her zaman idle accent rengi
  Color get idleAccentColor => currentTheme.idle.accentColor;

  // ============================================================
  // DURUM YÖNETİMİ
  // ============================================================

  /// Timer durumunu güncelle
  void setTimerState(TimerState state) {
    if (_timerState != state) {
      _timerState = state;
      debugPrint(
          '🎨 Timer durumu: $state → BG: ${bgColor.value.toRadixString(16)}');
      notifyListeners();
    }
  }

  /// Timer mode ve durumdan TimerState hesapla
  void updateFromTimer({
    required bool isRunning,
    required bool isPaused,
    required bool isAlarmPlaying,
    required String mode, // 'work', 'shortBreak', 'longBreak'
  }) {
    TimerState newState;

    if (isAlarmPlaying) {
      newState = TimerState.finish;
    } else if (isPaused) {
      // 🔥 TÜM MODLAR İÇİN: Duraklatıldığında temanın "workPaused" rengini kullan
      // (Her tema kendi workPaused rengini tanımlar: ST -> Gri, Klasik -> Gri-Mavi)
      newState = TimerState.workPaused;
    } else if (mode == 'shortBreak' || mode == 'longBreak') {
      newState = isRunning ? TimerState.pause : TimerState.idle;
    } else {
      // work mode
      newState = isRunning ? TimerState.focus : TimerState.idle;
    }

    setTimerState(newState);
  }

  // ============================================================
  // TEMA YÖNETİMİ
  // ============================================================

  bool isThemeUnlocked(String themeId) {
    return _unlockedThemes.contains(themeId);
  }

  Future<void> _loadThemeData() async {
    _prefs = await SharedPreferences.getInstance();

    _currentThemeId = _prefs.getString('current_theme') ?? 'elite';

    final unlockedList =
        _prefs.getStringList('unlocked_themes') ?? ['elite', 'classic_elite'];
    _unlockedThemes = unlockedList.toSet();
    _unlockedThemes.add('elite'); // Varsayılan her zaman açık

    notifyListeners();
  }

  Future<void> selectTheme(String themeId) async {
    if (!_unlockedThemes.contains(themeId)) {
      debugPrint('❌ Tema kilidi açık değil: $themeId');
      return;
    }

    _currentThemeId = themeId;
    await _prefs.setString('current_theme', themeId);

    debugPrint('🎨 Tema seçildi: $themeId');
    notifyListeners();
  }

  Future<void> unlockTheme(String themeId) async {
    if (_unlockedThemes.contains(themeId)) return;

    _unlockedThemes.add(themeId);
    await _prefs.setStringList('unlocked_themes', _unlockedThemes.toList());

    debugPrint('🔓 Tema açıldı: $themeId');
    notifyListeners();
  }
}
