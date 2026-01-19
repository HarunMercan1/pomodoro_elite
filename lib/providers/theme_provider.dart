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
      // 🔥 BREAK: Focus ile aynı (Mavi) - Kullanıcı isteği
      breakState: ThemeStateColors(
        bgColor: AppColors.themeBlue,
        gradientColors: AppColors.runningGradient,
        accentColor: AppColors.ringCyan,
        mainButtonColor: Colors.white,
        mainButtonTextColor: AppColors.themeBlue,
        menuButtonColor: Color(0xFF1A2980),
        menuButtonTextColor: Colors.white,
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
    // ============================================================
    // 4. Heisenberg (Breaking Bad) - Doygun & Mat
    // ============================================================
    AppTheme(
      id: 'heisenberg',
      name: 'Heisenberg',
      vibe: 'Kristal Mavi, Sarı Tulum',
      settingsBgColor: Color(0xFF004D40), // Koyu Teal
      settingsCardColor: Color(0xFF00695C), // Biraz daha açık Teal
      settingsBorderColor: Color(0xFF00E676), // Neon Yeşil Aksan
      settingsItemColor: Color(0xFFFFD600), // Sarı yazı
      idle: ThemeStateColors(
        bgColor: Color(0xFF00838F), // Doygun Cyan
        gradientColors: [Color(0xFF006064), Color(0xFF00838F)],
        accentColor: Color(0xFF00E5FF), // Parlak Cyan
        mainButtonColor: Color(0xFF00E5FF),
        mainButtonTextColor: Color(0xFF006064),
        menuButtonColor: Color(0xFF006064),
        menuButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFFFBC02D), // Doygun Sarı
        gradientColors: [Color(0xFFF57F17), Color(0xFFFBC02D)],
        accentColor: Color(0xFF3E2723), // Koyu Kahve (Kontrast)
        textColor: Color(0xFF3E2723),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFF57F17),
        menuButtonColor: Color(0xFFFFF176),
        menuButtonTextColor: Color(0xFF3E2723),
      ),
      // 🔥 BREAK: Focus ile aynı (Sarı)
      breakState: ThemeStateColors(
        bgColor: Color(0xFFFBC02D),
        gradientColors: [Color(0xFFF57F17), Color(0xFFFBC02D)],
        accentColor: Color(0xFF3E2723),
        textColor: Color(0xFF3E2723),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFF57F17),
        menuButtonColor: Color(0xFFFFF176),
        menuButtonTextColor: Color(0xFF3E2723),
      ),
      // 🔥 WORK PAUSED: Mat Yeşil (Laboratuvar)
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF2E7D32),
        gradientColors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
        accentColor: Color(0xFFA5D6A7),
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF1B5E20),
        menuButtonColor: Color(0xFF1B5E20),
        menuButtonTextColor: Colors.white,
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF004D40),
        gradientColors: [Color(0xFF00251A), Color(0xFF004D40)],
        accentColor: Colors.white,
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF004D40),
      ),
    ),

    // ============================================================
    // 5. Deep Ocean (Derinlik)
    // ============================================================
    // ============================================================
    // 5. Deep Ocean (Derinlik) - Doygun & Mat
    // ============================================================
    AppTheme(
      id: 'deep_ocean',
      name: 'Deep Ocean',
      vibe: 'Derinlik, Odak',
      settingsBgColor: Color(0xFF001021), // Çok koyu lacivert
      settingsCardColor: Color(0xFF012A4A), // Koyu okyanus mavisi
      settingsBorderColor: Color(0xFF00BFA5), // Turkuaz border
      settingsItemColor: Color(0xFF80DEEA), // Açık turkuaz yazı
      idle: ThemeStateColors(
        bgColor: Color(0xFF01579B), // Doygun Lacivert
        gradientColors: [Color(0xFF002F6C), Color(0xFF01579B)],
        accentColor: Color(0xFF00E5FF), // Parlak Cyan
        mainButtonColor: Color(0xFF00E5FF),
        mainButtonTextColor: Color(0xFF002F6C),
        menuButtonColor: Color(0xFF002F6C),
        menuButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF0277BD), // Okyanus Mavisi
        gradientColors: [Color(0xFF01579B), Color(0xFF0288D1)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF01579B),
        menuButtonColor: Color(0xFF0288D1),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 BREAK: Focus ile aynı (Mavi)
      breakState: ThemeStateColors(
        bgColor: Color(0xFF0277BD),
        gradientColors: [Color(0xFF01579B), Color(0xFF0288D1)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF01579B),
        menuButtonColor: Color(0xFF0288D1),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 WORK PAUSED: Mat Petrol Yeşili
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF004D40),
        gradientColors: [Color(0xFF00251A), Color(0xFF004D40)],
        accentColor: Color(0xFF4DB6AC),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF004D40),
        menuButtonColor: Color(0xFF00695C),
        menuButtonTextColor: Colors.white,
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF00C853),
        gradientColors: [Color(0xFF009688), Color(0xFF00C853)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF00C853),
      ),
    ),

    // ============================================================
    // 6. Mystic Forest (Doğa)
    // ============================================================
    // ============================================================
    // 6. Mystic Forest (Doğa) - Doygun & Mat
    // ============================================================
    AppTheme(
      id: 'mystic_forest',
      name: 'Mystic Forest',
      vibe: 'Doğa, Huzur',
      settingsBgColor: Color(0xFF1B5E20), // Koyu Yeşil
      settingsCardColor: Color(0xFF2E7D32), // Orman Yeşili
      settingsBorderColor: Color(0xFFAED581), // Açık Yeşil
      settingsItemColor: Color(0xFFDCEDC8), // Soluk Yeşil Yazı
      idle: ThemeStateColors(
        bgColor: Color(0xFF2E7D32),
        gradientColors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
        accentColor: Color(0xFF76FF03), // Canlı Yeşil
        mainButtonColor: Color(0xFF76FF03),
        mainButtonTextColor: Color(0xFF1B5E20),
        menuButtonColor: Color(0xFF1B5E20),
        menuButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF388E3C), // Doygun Yaprak Yeşili
        gradientColors: [Color(0xFF1B5E20), Color(0xFF43A047)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF1B5E20),
        menuButtonColor: Color(0xFF4CAF50),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 BREAK: Focus ile aynı (Yeşil)
      breakState: ThemeStateColors(
        bgColor: Color(0xFF388E3C),
        gradientColors: [Color(0xFF1B5E20), Color(0xFF43A047)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF1B5E20),
        menuButtonColor: Color(0xFF4CAF50),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 WORK PAUSED: Mat Toprak Kahve
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF4E342E),
        gradientColors: [Color(0xFF3E2723), Color(0xFF5D4037)],
        accentColor: Color(0xFFA1887F),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF3E2723),
        menuButtonColor: Color(0xFF5D4037),
        menuButtonTextColor: Colors.white,
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF64DD17),
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
    // ============================================================
    // 7. Cyberpunk 2077 (Neon) - Doygun & Mat
    // ============================================================
    AppTheme(
      id: 'cyberpunk',
      name: 'Cyberpunk 2077',
      vibe: 'Neon, Gelecek',
      settingsBgColor: Color(0xFF140018), // Çok koyu morumsu siyah
      settingsCardColor: Color(0xFF280036), // Koyu Neon Mor
      settingsBorderColor: Color(0xFFD500F9), // Neon Pembe Border
      settingsItemColor: Color(0xFFFFFF00), // Neon Sarı Yazı
      idle: ThemeStateColors(
        bgColor: Color(0xFF0F0F0F), // Mat Siyah
        gradientColors: [Color(0xFF050505), Color(0xFF141414)],
        accentColor: Color(0xFFFFEA00), // Neon Sarı
        mainButtonColor: Color(0xFFFFEA00),
        mainButtonTextColor: Colors.black,
        menuButtonColor: Color(0xFF333333),
        menuButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFFD500F9), // Neon Pembe
        gradientColors: [Color(0xFF4A0072), Color(0xFFD500F9)],
        accentColor: Color(0xFFFFFF00), // Neon Sarı
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFD500F9),
        menuButtonColor: Color(0xFF7B1FA2),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 BREAK: Focus ile aynı (Neon Pembe)
      breakState: ThemeStateColors(
        bgColor: Color(0xFFD500F9),
        gradientColors: [Color(0xFF4A0072), Color(0xFFD500F9)],
        accentColor: Color(0xFFFFFF00),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFD500F9),
        menuButtonColor: Color(0xFF7B1FA2),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 WORK PAUSED: Mat Koyu Gri
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF212121),
        gradientColors: [Color(0xFF121212), Color(0xFF2C2C2C)],
        accentColor: Color(0xFF757575),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF212121),
        menuButtonColor: Color(0xFF424242),
        menuButtonTextColor: Colors.white,
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
    // ============================================================
    // 8. Royal Gold (Lüks) - Doygun & Mat
    // ============================================================
    AppTheme(
      id: 'royal_gold',
      name: 'Royal Gold',
      vibe: 'Lüks, Başarı',
      settingsBgColor: Color(0xFF121212), // Mat Siyah
      settingsCardColor: Color(0xFF262626), // Koyu Gri
      settingsBorderColor: Color(0xFFFFD700), // Altın Border
      settingsItemColor: Color(0xFFFFD700), // Altın Yazı
      idle: ThemeStateColors(
        bgColor: Color(0xFF000000),
        gradientColors: [Color(0xFF000000), Color(0xFF1C1C1C)],
        accentColor: Color(0xFFFFD700), // Altın
        mainButtonColor: Color(0xFFFFD700),
        mainButtonTextColor: Colors.black,
        menuButtonColor: Color(0xFF333333),
        menuButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFFFF8F00), // Doygun Amber/Altın
        gradientColors: [Color(0xFFBF360C), Color(0xFFFF8F00)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFBF360C),
        menuButtonColor: Color(0xFFD84315),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 BREAK: Focus ile aynı (Altın)
      breakState: ThemeStateColors(
        bgColor: Color(0xFFFF8F00),
        gradientColors: [Color(0xFFBF360C), Color(0xFFFF8F00)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFBF360C),
        menuButtonColor: Color(0xFFD84315),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 WORK PAUSED: Mat Antrasit
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF212121),
        gradientColors: [Color(0xFF121212), Color(0xFF2D2D2D)],
        accentColor: Color(0xFF757575),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF212121),
        menuButtonColor: Color(0xFF424242),
        menuButtonTextColor: Colors.white,
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
    // ============================================================
    // 9. Sunset Lofi (Chill) - Doygun & Mat
    // ============================================================
    AppTheme(
      id: 'sunset_lofi',
      name: 'Sunset Lofi',
      vibe: 'Estetik, Chill',
      settingsBgColor: Color(0xFF2A0F36), // Çok koyu mürdüm
      settingsCardColor: Color(0xFF4A148C), // Koyu Mor
      settingsBorderColor: Color(0xFFFF6D00), // Doygun Turuncu
      settingsItemColor: Color(0xFFFFD180), // Açık Turuncu Yazı
      idle: ThemeStateColors(
        bgColor: Color(0xFF311B92), // Derin Mor
        gradientColors: [Color(0xFF1A1A2E), Color(0xFF311B92)],
        accentColor: Color(0xFFFF6D00), // Doygun Turuncu
        mainButtonColor: Color(0xFFFF6D00),
        mainButtonTextColor: Colors.white,
        menuButtonColor: Color(0xFF4527A0),
        menuButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF6A1B9A), // Canlı Mor
        gradientColors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
        accentColor: Color(0xFFFFAB40), // Açık Turuncu
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF6A1B9A),
        menuButtonColor: Color(0xFF8E24AA),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 BREAK: Focus ile aynı (Mor)
      breakState: ThemeStateColors(
        bgColor: Color(0xFF6A1B9A),
        gradientColors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
        accentColor: Color(0xFFFFAB40),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF6A1B9A),
        menuButtonColor: Color(0xFF8E24AA),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 WORK PAUSED: Mat Kahve/Mürdüm
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF3E2723),
        gradientColors: [Color(0xFF2D1B2E), Color(0xFF3E2723)],
        accentColor: Color(0xFF8D6E63),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF3E2723),
        menuButtonColor: Color(0xFF4E342E),
        menuButtonTextColor: Colors.white,
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
    // ============================================================
    // 10. Nordic Snow (Minimal) - Doygun & Mat (Buz)
    // ============================================================
    AppTheme(
      id: 'nordic_snow',
      name: 'Nordic Snow',
      vibe: 'Ferah, Minimal',
      settingsBgColor: Color(0xFFECEFF1), // Çok açık gri-mavi
      settingsCardColor: Color(0xFFFFFFFF), // Beyaz
      settingsBorderColor: Color(0xFF0288D1), // Canlı Mavi Border
      settingsItemColor: Color(0xFF01579B), // Koyu Mavi Yazı
      idle: ThemeStateColors(
        bgColor: Color(0xFF455A64), // Mat Koyu Gri-Mavi
        gradientColors: [Color(0xFF37474F), Color(0xFF546E7A)],
        accentColor: Color(0xFF29B6F6), // Canlı Açık Mavi
        mainButtonColor: Color(0xFF29B6F6),
        mainButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF0277BD), // Doygun Buz Mavisi
        gradientColors: [Color(0xFF01579B), Color(0xFF039BE5)],
        accentColor: Colors.white,
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF0277BD),
        menuButtonColor: Color(0xFF4FC3F7),
      ),
      // 🔥 BREAK: Focus ile aynı (Buz Mavisi)
      breakState: ThemeStateColors(
        bgColor: Color(0xFF0277BD),
        gradientColors: [Color(0xFF01579B), Color(0xFF039BE5)],
        accentColor: Colors.white,
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF0277BD),
        menuButtonColor: Color(0xFF4FC3F7),
      ),
      // 🔥 WORK PAUSED: Mat Gri
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF546E7A),
        gradientColors: [Color(0xFF455A64), Color(0xFF607D8B)],
        accentColor: Color(0xFFB0BEC5),
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF546E7A),
        menuButtonColor: Color(0xFF78909C),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF43A047),
        gradientColors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
        accentColor: Colors.white,
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF2E7D32),
      ),
    ),

    // ============================================================
    // 11. Volcano (Enerji)
    // ============================================================
    // ============================================================
    // 11. Volcano (Enerji) - Doygun & Mat
    // ============================================================
    AppTheme(
      id: 'volcano',
      name: 'Volcano',
      vibe: 'Yüksek Enerji',
      settingsBgColor: Color(0xFF1B0000), // Çok koyu kızıl
      settingsCardColor: Color(0xFF3E2723), // Koyu Kahve/Kızıl
      settingsBorderColor: Color(0xFFD50000), // Magma Kırmızısı
      settingsItemColor: Color(0xFFFF3D00), // Lav Turuncusu Yazı
      idle: ThemeStateColors(
        bgColor: Color(0xFF212121), // Mat Koyu Gri
        gradientColors: [Color(0xFF000000), Color(0xFF212121)],
        accentColor: Color(0xFFFF3D00), // Lav Turuncusu
        mainButtonColor: Color(0xFFFF3D00),
        mainButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFFD50000), // Magma Kırmızısı
        gradientColors: [Color(0xFFB71C1C), Color(0xFFD50000)],
        accentColor: Color(0xFFFFEA00), // Parlak Sarı
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFD50000),
        menuButtonColor: Color(0xFFFF8A65),
      ),
      // 🔥 BREAK: Focus ile aynı (Manyetik Kırmızı)
      breakState: ThemeStateColors(
        bgColor: Color(0xFFD50000),
        gradientColors: [Color(0xFFB71C1C), Color(0xFFD50000)],
        accentColor: Color(0xFFFFEA00),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFD50000),
        menuButtonColor: Color(0xFFFF8A65),
      ),
      // 🔥 WORK PAUSED: Mat Kül
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF37474F),
        gradientColors: [Color(0xFF263238), Color(0xFF455A64)],
        accentColor: Color(0xFF90A4AE),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF37474F),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFFFFD600),
        gradientColors: [Color(0xFFFFAB00), Color(0xFFFFD600)],
        accentColor: Colors.white,
        textColor: Colors.black,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFE65100),
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
