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
    // 4. Heisenberg (Breaking Bad) - Kontrastlı
    // ============================================================
    AppTheme(
      id: 'heisenberg',
      name: 'Heisenberg',
      vibe: 'Kristal Mavi, Sarı Tulum',
      settingsBgColor: Color(0xFF00363A), // Daha Koyu Teal (Zemin)
      settingsCardColor: Color(0xFF005662), // Ayırt edilebilir Teal (Kart)
      settingsBorderColor: Color(0xFF00E676), // Neon Yeşil Border (Vurgu)
      settingsItemColor: Color(0xFFFFD600), // Sarı Yazı (Okunabilir)
      idle: ThemeStateColors(
        bgColor: Color(0xFF006064), // Koyu Cyan Zemin
        gradientColors: [Color(0xFF00363A), Color(0xFF006064)],
        accentColor: Color(0xFF00E5FF), // Parlak Cyan (Buton/Slider)
        mainButtonColor: Color(0xFF00E5FF),
        mainButtonTextColor: Color(0xFF00363A), // Koyu yazı
        menuButtonColor: Color(0xFF004D40), // Koyu buton
        menuButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFFFFD600), // Sarı (Tulum)
        gradientColors: [Color(0xFFFbc02D), Color(0xFFFFAB00)],
        accentColor: Color(0xFF263238), // Koyu Gri/Mavi (Kontrast)
        textColor: Color(0xFF263238),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFFFD600),
        menuButtonColor: Color(0xFFFFF9C4), // Açık Sarı
        menuButtonTextColor: Color(0xFF263238),
      ),
      // 🔥 BREAK: Focus ile aynı (Sarı)
      breakState: ThemeStateColors(
        bgColor: Color(0xFFFFD600),
        gradientColors: [Color(0xFFFbc02D), Color(0xFFFFAB00)],
        accentColor: Color(0xFF263238),
        textColor: Color(0xFF263238),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFFFD600),
        menuButtonColor: Color(0xFFFFF9C4),
        menuButtonTextColor: Color(0xFF263238),
      ),
      // 🔥 WORK PAUSED: Koyu Laboratuvar Yeşili
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF1B5E20),
        gradientColors: [Color(0xFF003300), Color(0xFF1B5E20)],
        accentColor: Color(0xFF69F0AE), // Açık Yeşil
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF1B5E20),
        menuButtonColor: Color(0xFF2E7D32),
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
    // 5. Deep Ocean (Derinlik) - Kontrastlı
    // ============================================================
    AppTheme(
      id: 'deep_ocean',
      name: 'Deep Ocean',
      vibe: 'Derinlik, Odak',
      settingsBgColor: Color(0xFF000A12), // Neredeyse Siyah Lacivert (Zemin)
      settingsCardColor: Color(0xFF011E32), // Koyu Lacivert (Kart)
      settingsBorderColor: Color(0xFF00E5FF), // Neon Turkuaz (Border)
      settingsItemColor: Color(0xFF80DEEA), // Açık Aqua (Yazı)
      idle: ThemeStateColors(
        bgColor: Color(0xFF001018), // Derin okyanus dibi
        gradientColors: [Color(0xFF000000), Color(0xFF001018)],
        accentColor: Color(0xFF00B8D4), // Canlı Turkuaz
        mainButtonColor: Color(0xFF00B8D4),
        mainButtonTextColor: Color(0xFF000A12),
        menuButtonColor: Color(0xFF002F3A),
        menuButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF01579B), // Orta Mavi
        gradientColors: [Color(0xFF002F6C), Color(0xFF0277BD)],
        accentColor: Color(0xFF81D4FA), // Açık Mavi (Kontrast)
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF01579B),
        menuButtonColor: Color(0xFF0288D1),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 BREAK: Focus ile aynı (Mavi)
      breakState: ThemeStateColors(
        bgColor: Color(0xFF01579B),
        gradientColors: [Color(0xFF002F6C), Color(0xFF0277BD)],
        accentColor: Color(0xFF81D4FA),
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF01579B),
        menuButtonColor: Color(0xFF0288D1),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 WORK PAUSED: Koyu Yeşilimsi Mavi
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF004D40),
        gradientColors: [Color(0xFF00251A), Color(0xFF004D40)],
        accentColor: Color(0xFF1DE9B6), // Neon Teal
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
    // 6. Mystic Forest (Doğa) - Kontrastlı
    // ============================================================
    AppTheme(
      id: 'mystic_forest',
      name: 'Mystic Forest',
      vibe: 'Doğa, Huzur',
      settingsBgColor: Color(0xFF0D2111), // Çok koyu zemin
      settingsCardColor: Color(0xFF1B5E20), // Belirgin Orman Yeşili Kart
      settingsBorderColor: Color(0xFF76FF03), // Canlı Yeşil Border
      settingsItemColor: Color(0xFFFFFFFF), // Beyaz Yazı (Netlik için)
      idle: ThemeStateColors(
        bgColor: Color(0xFF1B5E20), // Koyu Yeşil
        gradientColors: [Color(0xFF003300), Color(0xFF1B5E20)],
        accentColor: Color(0xFF69F0AE), // Açık Nane Yeşili
        mainButtonColor: Color(0xFF69F0AE),
        mainButtonTextColor: Color(0xFF003300),
        menuButtonColor: Color(0xFF2E7D32),
        menuButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF2E7D32), // Orta Yeşil
        gradientColors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
        accentColor: Color(0xFF00E676), // Parlak Yeşil
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF1B5E20),
        menuButtonColor: Color(0xFF43A047),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 BREAK: Focus ile aynı (Yeşil)
      breakState: ThemeStateColors(
        bgColor: Color(0xFF2E7D32),
        gradientColors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
        accentColor: Color(0xFF00E676),
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF1B5E20),
        menuButtonColor: Color(0xFF43A047),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 WORK PAUSED: Koyu Kahve
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF3E2723),
        gradientColors: [Color(0xFF1B0000), Color(0xFF3E2723)],
        accentColor: Color(0xFFD7CCC8), // Açık Bej
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF3E2723),
        menuButtonColor: Color(0xFF4E342E),
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
    // 7. Cyberpunk 2077 (Neon) - Kontrastlı
    // ============================================================
    AppTheme(
      id: 'cyberpunk',
      name: 'Cyberpunk 2077',
      vibe: 'Neon, Gelecek',
      settingsBgColor: Color(0xFF000000), // Tam Siyah (Zemin)
      settingsCardColor: Color(0xFF1A1A1A), // Koyu Gri (Kart)
      settingsBorderColor: Color(0xFFD500F9), // Neon Pembe Border
      settingsItemColor: Color(0xFF00E5FF), // Neon Cyan Yazı (Ayrım İçin)
      idle: ThemeStateColors(
        bgColor: Color(0xFF0F0F0F), // Mat Siyah
        gradientColors: [Color(0xFF000000), Color(0xFF141414)],
        accentColor: Color(0xFFFFEA00), // Neon Sarı
        mainButtonColor: Color(0xFFFFEA00),
        mainButtonTextColor: Colors.black,
        menuButtonColor: Color(0xFF333333),
        menuButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF212121), // Koyu Gri (Arka Plan - Pembe değil)
        gradientColors: [Color(0xFF000000), Color(0xFF212121)],
        accentColor: Color(0xFFD500F9), // Neon Pembe (Vurgu)
        textColor: Color(0xFFD500F9), // Neon Yazı
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFD500F9),
        menuButtonColor: Color(0xFF4A0072),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 BREAK: Focus ile aynı (Pembe Vurgulu Koyu)
      breakState: ThemeStateColors(
        bgColor: Color(0xFF212121),
        gradientColors: [Color(0xFF000000), Color(0xFF212121)],
        accentColor: Color(0xFFD500F9),
        textColor: Color(0xFFD500F9),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFD500F9),
        menuButtonColor: Color(0xFF4A0072),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 WORK PAUSED: Mat Koyu Gri
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF121212),
        gradientColors: [Color(0xFF000000), Color(0xFF121212)],
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
    // 8. Royal Gold (Lüks) - Kontrastlı
    // ============================================================
    AppTheme(
      id: 'royal_gold',
      name: 'Royal Gold',
      vibe: 'Lüks, Başarı',
      settingsBgColor: Color(0xFF000000), // Mat Siyah Zemin
      settingsCardColor: Color(0xFF1C1C1C), // Koyu Gri Kart
      settingsBorderColor: Color(0xFFFFD700), // Altın Border
      settingsItemColor: Color(0xFFFFD700), // Altın Yazı
      idle: ThemeStateColors(
        bgColor: Color(0xFF000000),
        gradientColors: [Color(0xFF000000), Color(0xFF121212)],
        accentColor: Color(0xFFFFD700), // Altın
        mainButtonColor: Color(0xFFFFD700),
        mainButtonTextColor: Colors.black,
        menuButtonColor: Color(0xFF333333),
        menuButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF1A1A1A), // Koyu Antrasit (Arka Plan)
        gradientColors: [Color(0xFF000000), Color(0xFF1A1A1A)],
        accentColor: Color(0xFFFFAB00), // Amber/Altın (Vurgu)
        textColor: Color(0xFFFFD700), // Altın Yazı
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFFF6F00),
        menuButtonColor: Color(0xFF424242),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 BREAK: Focus ile aynı (Altın Vurgulu Siyah)
      breakState: ThemeStateColors(
        bgColor: Color(0xFF1A1A1A),
        gradientColors: [Color(0xFF000000), Color(0xFF1A1A1A)],
        accentColor: Color(0xFFFFAB00),
        textColor: Color(0xFFFFD700),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFFF6F00),
        menuButtonColor: Color(0xFF424242),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 WORK PAUSED: Mat Gri
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF2E2E2E), // Biraz daha açık gri
        gradientColors: [Color(0xFF1F1F1F), Color(0xFF2E2E2E)],
        accentColor: Color(0xFFBDBDBD),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF424242),
        menuButtonColor: Color(0xFF616161),
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
    // 9. Sunset Lofi (Chill) - Kontrastlı
    // ============================================================
    AppTheme(
      id: 'sunset_lofi',
      name: 'Sunset Lofi',
      vibe: 'Estetik, Chill',
      settingsBgColor: Color(0xFF1A0520), // Çok Koyu Mürdüm (Zemin)
      settingsCardColor: Color(0xFF38006B), // Ayrık Mor Kart
      settingsBorderColor: Color(0xFFFF6D00), // Turuncu Border
      settingsItemColor: Color(0xFFFFAB40), // Açık Turuncu Yazı
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
        bgColor: Color(0xFF4A148C), // Koyu Mor (Arka Plan)
        gradientColors: [Color(0xFF311B92), Color(0xFF4A148C)],
        accentColor: Color(0xFFFF6D00), // Turuncu Vurgu
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF6A1B9A),
        menuButtonColor: Color(0xFF7B1FA2),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 BREAK: Focus ile aynı (Mor/Turuncu Vurgulu)
      breakState: ThemeStateColors(
        bgColor: Color(0xFF4A148C),
        gradientColors: [Color(0xFF311B92), Color(0xFF4A148C)],
        accentColor: Color(0xFFFF6D00),
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF6A1B9A),
        menuButtonColor: Color(0xFF7B1FA2),
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
    // 10. Nordic Snow (Minimal) - Kontrastlı (Kar ve Buz)
    // ============================================================
    AppTheme(
      id: 'nordic_snow',
      name: 'Nordic Snow',
      vibe: 'Buz, Ferahlık',
      settingsBgColor: Color(0xFFF5FDFF), // Neredeyse Beyaz Buz Mavisi (Zemin)
      settingsCardColor: Color(0xFFFFFFFF), // Saf Beyaz (Kart)
      settingsBorderColor: Color(0xFF40C4FF), // Canlı Gök Mavisi (Border)
      settingsItemColor:
          Color(0xFF01579B), // Derin Mavi (Yazı - Yüksek Okunabilirlik)
      idle: ThemeStateColors(
        bgColor: Color(0xFFECEFF1), // Çok Açık Gri-Mavi
        gradientColors: [Color(0xFFCFD8DC), Color(0xFFECEFF1)],
        accentColor: Color(0xFF00B0FF), // Parlak Mavi
        mainButtonColor: Color(0xFF00B0FF),
        mainButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFFE1F5FE), // Çok Açık Mavi (Zemin)
        gradientColors: [Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
        accentColor: Color(0xFF01579B), // Koyu Mavi (Vurgular)
        textColor: Color(0xFF01579B), // Koyu Mavi Yazı (Kontrast)
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF0277BD),
        menuButtonColor: Color(0xFF0288D1),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 BREAK: Focus ile aynı (Açık tonlar)
      breakState: ThemeStateColors(
        bgColor: Color(0xFFE1F5FE),
        gradientColors: [Color(0xFFB3E5FC), Color(0xFFE1F5FE)],
        accentColor: Color(0xFF01579B),
        textColor: Color(0xFF01579B),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF0277BD),
        menuButtonColor: Color(0xFF0288D1),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 WORK PAUSED: Soğuk Gri
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF90A4AE),
        gradientColors: [Color(0xFF607D8B), Color(0xFF90A4AE)],
        accentColor: Color(0xFFCFD8DC),
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF455A64),
        menuButtonColor: Color(0xFF546E7A),
        menuButtonTextColor: Colors.white,
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
    // 11. Volcano (Enerji) - Kontrastlı (Magma ve Kül)
    // ============================================================
    AppTheme(
      id: 'volcano',
      name: 'Volcano',
      vibe: 'Yüksek Enerji',
      settingsBgColor:
          Color(0xFF1B1B1B), // Koyu Kül Grisi (Zemin - Kırmızı Değil!)
      settingsCardColor: Color(0xFF2D1E1E), // Hafif Kızıl Kahve Gri (Kart)
      settingsBorderColor: Color(0xFFD50000), // Magma Kırmızısı (Border)
      settingsItemColor: Color(0xFFFF6D00), // Parlak Turuncu (Yazı)
      idle: ThemeStateColors(
        bgColor: Color(0xFF212121), // Mat Koyu Gri
        gradientColors: [Color(0xFF101010), Color(0xFF212121)],
        accentColor: Color(0xFFFF3D00), // Lav Turuncusu
        mainButtonColor: Color(0xFFFF3D00),
        mainButtonTextColor: Colors.white,
        menuButtonColor: Color(0xFF424242),
        menuButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF1B0000), // Çok Koyu Zemin (Magma Akışı gibi)
        gradientColors: [Color(0xFF000000), Color(0xFF3E2723)],
        accentColor: Color(0xFFD50000), // Kırmızı Vurgular
        textColor: Color(0xFFFFAB91), // Açık Salmon/Turuncu Yazı
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFD50000),
        menuButtonColor: Color(0xFFBF360C),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 BREAK: Focus ile aynı (Magma)
      breakState: ThemeStateColors(
        bgColor: Color(0xFF1B0000),
        gradientColors: [Color(0xFF000000), Color(0xFF3E2723)],
        accentColor: Color(0xFFD50000),
        textColor: Color(0xFFFFAB91),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFD50000),
        menuButtonColor: Color(0xFFBF360C),
        menuButtonTextColor: Colors.white,
      ),
      // 🔥 WORK PAUSED: Donmuş Lav (Mat Gri/Kahve)
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF4E342E),
        gradientColors: [Color(0xFF3E2723), Color(0xFF5D4037)],
        accentColor: Color(0xFFBCAAA4),
        textColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF3E2723),
        menuButtonColor: Color(0xFF6D4C41),
        menuButtonTextColor: Colors.white,
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
