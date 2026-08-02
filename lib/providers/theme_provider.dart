import 'dart:async';

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

/// Tema vurgusunun tonunu koruyarak belirli bir yüzeyde görünür kılar.
class ThemeContrast {
  const ThemeContrast._();

  static double ratio(Color first, Color second) =>
      _contrastRatio(first, second);

  static Color ensure({
    required Color foreground,
    required Color background,
    double minimumRatio = 3,
  }) {
    if (_contrastRatio(foreground, background) >= minimumRatio) {
      return foreground;
    }

    final hsl = HSLColor.fromColor(foreground);
    final lighter = _nearestContrastingLightness(
      hsl: hsl,
      background: background,
      targetLightness: 1,
      minimumRatio: minimumRatio,
    );
    final darker = _nearestContrastingLightness(
      hsl: hsl,
      background: background,
      targetLightness: 0,
      minimumRatio: minimumRatio,
    );

    if (lighter == null) return darker ?? foreground;
    if (darker == null) return lighter;

    final lighterDistance =
        (HSLColor.fromColor(lighter).lightness - hsl.lightness).abs();
    final darkerDistance =
        (HSLColor.fromColor(darker).lightness - hsl.lightness).abs();
    return lighterDistance <= darkerDistance ? lighter : darker;
  }

  static Color? _nearestContrastingLightness({
    required HSLColor hsl,
    required Color background,
    required double targetLightness,
    required double minimumRatio,
  }) {
    final target = hsl.withLightness(targetLightness).toColor();
    if (_contrastRatio(target, background) < minimumRatio) return null;

    var failingLightness = hsl.lightness;
    var passingLightness = targetLightness;

    for (var i = 0; i < 20; i++) {
      final midpoint = (failingLightness + passingLightness) / 2;
      final candidate = hsl.withLightness(midpoint).toColor();
      if (_contrastRatio(candidate, background) >= minimumRatio) {
        passingLightness = midpoint;
      } else {
        failingLightness = midpoint;
      }
    }

    return hsl.withLightness(passingLightness).toColor();
  }

  static double _contrastRatio(Color first, Color second) {
    final resolvedFirst = first.a < 1 ? Color.alphaBlend(first, second) : first;
    final firstLuminance = resolvedFirst.computeLuminance();
    final secondLuminance = second.computeLuminance();
    final lighter =
        firstLuminance > secondLuminance ? firstLuminance : secondLuminance;
    final darker =
        firstLuminance > secondLuminance ? secondLuminance : firstLuminance;
    return (lighter + 0.05) / (darker + 0.05);
  }
}

/// Ana tema modeli
class AppTheme {
  final String id;
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
      settingsBgColor: Color(0xFF030B17),
      settingsCardColor: Color(0xFF071C2F),
      settingsBorderColor: Color(0xFF22D3EE),
      settingsItemColor: Color(0xFFD7F9FF),
      idle: ThemeStateColors(
        bgColor: Color(0xFF03131F),
        gradientColors: [Color(0xFF020A12), Color(0xFF04283A)],
        accentColor: Color(0xFF22D3EE),
        textColor: Color(0xFFF0FDFF),
        mainButtonColor: Color(0xFF22D3EE),
        mainButtonTextColor: Color(0xFF02131C),
        menuButtonColor: Color(0xFF083344),
        menuButtonTextColor: Color(0xFFF0FDFF),
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF075985),
        gradientColors: [Color(0xFF063B62), Color(0xFF0B6B9B)],
        accentColor: Color(0xFFA5F3FC),
        textColor: Color(0xFFFFFFFF),
        mainButtonColor: Color(0xFFFFFFFF),
        mainButtonTextColor: Color(0xFF01579B),
        menuButtonColor: Color(0xFF075076),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      // 🔥 BREAK: Focus ile aynı (Mavi)
      breakState: ThemeStateColors(
        bgColor: Color(0xFF0F766E),
        gradientColors: [Color(0xFF064E5B), Color(0xFF0F766E)],
        accentColor: Color(0xFF99F6E4),
        textColor: Color(0xFFFFFFFF),
        mainButtonColor: Color(0xFFFFFFFF),
        mainButtonTextColor: Color(0xFF0F5B55),
        menuButtonColor: Color(0xFF115E59),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      // 🔥 WORK PAUSED: Koyu Yeşilimsi Mavi
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF29434E),
        gradientColors: [Color(0xFF132C35), Color(0xFF29434E)],
        accentColor: Color(0xFF80CBC4),
        textColor: Color(0xFFE6F6FA),
        mainButtonColor: Color(0xFFE6F6FA),
        mainButtonTextColor: Color(0xFF1B3943),
        menuButtonColor: Color(0xFF29434E),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF26A69A),
        gradientColors: [Color(0xFF26A69A), Color(0xFF66D19E)],
        accentColor: Color(0xFF003D38),
        textColor: Color(0xFF002F2C),
        mainButtonColor: Color(0xFF003D38),
        mainButtonTextColor: Color(0xFFE5FFF9),
        menuButtonColor: Color(0xFF00574F),
        menuButtonTextColor: Color(0xFFFFFFFF),
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
      settingsBgColor: Color(0xFF07170C),
      settingsCardColor: Color(0xFF102D18),
      settingsBorderColor: Color(0xFF5DAE65),
      settingsItemColor: Color(0xFFECFDF0),
      idle: ThemeStateColors(
        bgColor: Color(0xFF123D20),
        gradientColors: [Color(0xFF071A0C), Color(0xFF123D20)],
        accentColor: Color(0xFF8FE3A1),
        textColor: Color(0xFFF0FFF4),
        mainButtonColor: Color(0xFF8FE3A1),
        mainButtonTextColor: Color(0xFF0B2912),
        menuButtonColor: Color(0xFF174B27),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF236B32),
        gradientColors: [Color(0xFF124A23), Color(0xFF236B32)],
        accentColor: Color(0xFFA7F3B2),
        textColor: Color(0xFFF3FFF4),
        mainButtonColor: Color(0xFFF3FFF4),
        mainButtonTextColor: Color(0xFF164E27),
        menuButtonColor: Color(0xFF164E27),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      // 🔥 BREAK: Focus ile aynı (Yeşil)
      breakState: ThemeStateColors(
        bgColor: Color(0xFF416B45),
        gradientColors: [Color(0xFF294A2E), Color(0xFF416B45)],
        accentColor: Color(0xFFD5E8A3),
        textColor: Color(0xFFFFFFFF),
        mainButtonColor: Color(0xFFF6FFE8),
        mainButtonTextColor: Color(0xFF294A2E),
        menuButtonColor: Color(0xFF31573A),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      // 🔥 WORK PAUSED: Koyu Kahve
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF443126),
        gradientColors: [Color(0xFF251A13), Color(0xFF443126)],
        accentColor: Color(0xFFD7BFAE),
        textColor: Color(0xFFFFF4E8),
        mainButtonColor: Color(0xFFFFF4E8),
        mainButtonTextColor: Color(0xFF3B291F),
        menuButtonColor: Color(0xFF4E382B),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF7CB342),
        gradientColors: [Color(0xFF7CB342), Color(0xFFB2FF59)],
        accentColor: Color(0xFF183E1D),
        textColor: Color(0xFF10240D),
        mainButtonColor: Color(0xFF183E1D),
        mainButtonTextColor: Color(0xFFF1FFE8),
        menuButtonColor: Color(0xFF245B28),
        menuButtonTextColor: Color(0xFFFFFFFF),
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
      settingsBgColor: Color(0xFF08070D),
      settingsCardColor: Color(0xFF15121E),
      settingsBorderColor: Color(0xFFFF2BD6),
      settingsItemColor: Color(0xFF67E8F9),
      idle: ThemeStateColors(
        bgColor: Color(0xFF06070A),
        gradientColors: [Color(0xFF06070A), Color(0xFF14121A)],
        accentColor: Color(0xFFFFE600),
        textColor: Color(0xFFF9FAFB),
        mainButtonColor: Color(0xFFFFE600),
        mainButtonTextColor: Color(0xFF111111),
        menuButtonColor: Color(0xFF262334),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF160B22),
        gradientColors: [Color(0xFF160B22), Color(0xFF301044)],
        accentColor: Color(0xFFFF2BD6),
        textColor: Color(0xFFF8F7FF),
        mainButtonColor: Color(0xFFFFEA00),
        mainButtonTextColor: Color(0xFF111111),
        menuButtonColor: Color(0xFF49115B),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      // 🔥 BREAK: Focus ile aynı (Pembe Vurgulu Koyu)
      breakState: ThemeStateColors(
        bgColor: Color(0xFF071B24),
        gradientColors: [Color(0xFF071B24), Color(0xFF102A36)],
        accentColor: Color(0xFF00E5FF),
        textColor: Color(0xFFE8FCFF),
        mainButtonColor: Color(0xFF00E5FF),
        mainButtonTextColor: Color(0xFF071B24),
        menuButtonColor: Color(0xFF123D4A),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      // 🔥 WORK PAUSED: Mat Koyu Gri
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF111318),
        gradientColors: [Color(0xFF111318), Color(0xFF23262F)],
        accentColor: Color(0xFF8B93A7),
        textColor: Color(0xFFD5D9E3),
        mainButtonColor: Color(0xFFD5D9E3),
        mainButtonTextColor: Color(0xFF1B1E26),
        menuButtonColor: Color(0xFF343844),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF00B8D4),
        gradientColors: [Color(0xFF00B8D4), Color(0xFF72F6FF)],
        accentColor: Color(0xFF001B22),
        textColor: Color(0xFF001B22),
        mainButtonColor: Color(0xFF001B22),
        mainButtonTextColor: Color(0xFFB8FAFF),
        menuButtonColor: Color(0xFF004C5C),
        menuButtonTextColor: Color(0xFFFFFFFF),
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
      settingsBgColor: Color(0xFF0A0906),
      settingsCardColor: Color(0xFF1B1810),
      settingsBorderColor: Color(0xFFC9A227),
      settingsItemColor: Color(0xFFF8E7A1),
      idle: ThemeStateColors(
        bgColor: Color(0xFF080704),
        gradientColors: [Color(0xFF080704), Color(0xFF1C170A)],
        accentColor: Color(0xFFE2B93B),
        textColor: Color(0xFFFFF8E1),
        mainButtonColor: Color(0xFFE2B93B),
        mainButtonTextColor: Color(0xFF1F1700),
        menuButtonColor: Color(0xFF302A1A),
        menuButtonTextColor: Color(0xFFFFF8E1),
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF171207),
        gradientColors: [Color(0xFF171207), Color(0xFF2B210D)],
        accentColor: Color(0xFFFFD166),
        textColor: Color(0xFFFFE9A6),
        mainButtonColor: Color(0xFFFFD166),
        mainButtonTextColor: Color(0xFF241900),
        menuButtonColor: Color(0xFF4A3A16),
        menuButtonTextColor: Color(0xFFFFF8E1),
      ),
      // 🔥 BREAK: Focus ile aynı (Altın Vurgulu Siyah)
      breakState: ThemeStateColors(
        bgColor: Color(0xFF211016),
        gradientColors: [Color(0xFF211016), Color(0xFF3A1720)],
        accentColor: Color(0xFFF0C75E),
        textColor: Color(0xFFFFF3D0),
        mainButtonColor: Color(0xFFFFF3D0),
        mainButtonTextColor: Color(0xFF4A1F28),
        menuButtonColor: Color(0xFF5A2531),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      // 🔥 WORK PAUSED: Mat Gri
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF1D1C19),
        gradientColors: [Color(0xFF1D1C19), Color(0xFF34312A)],
        accentColor: Color(0xFFAAA18B),
        textColor: Color(0xFFE7E2D6),
        mainButtonColor: Color(0xFFE7E2D6),
        mainButtonTextColor: Color(0xFF28251F),
        menuButtonColor: Color(0xFF48443B),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFFD6A72C),
        gradientColors: [Color(0xFFD6A72C), Color(0xFFFFE08A)],
        accentColor: Color(0xFF3A2700),
        textColor: Color(0xFF2B1D00),
        mainButtonColor: Color(0xFF3A2700),
        mainButtonTextColor: Color(0xFFFFF4C7),
        menuButtonColor: Color(0xFF5A3C00),
        menuButtonTextColor: Color(0xFFFFFFFF),
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
      settingsBgColor: Color(0xFF170E24),
      settingsCardColor: Color(0xFF2B193D),
      settingsBorderColor: Color(0xFFFF8A65),
      settingsItemColor: Color(0xFFFFE0D6),
      idle: ThemeStateColors(
        bgColor: Color(0xFF211535),
        gradientColors: [Color(0xFF211535), Color(0xFF3D2357)],
        accentColor: Color(0xFFFF8A5B),
        textColor: Color(0xFFFFF5F2),
        mainButtonColor: Color(0xFFFF8A5B),
        mainButtonTextColor: Color(0xFF27121C),
        menuButtonColor: Color(0xFF4D2D68),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF4A1F5F),
        gradientColors: [Color(0xFF4A1F5F), Color(0xFF7A2E62)],
        accentColor: Color(0xFFFFB45E),
        textColor: Color(0xFFFFFFFF),
        mainButtonColor: Color(0xFFFFF4EC),
        mainButtonTextColor: Color(0xFF6D2457),
        menuButtonColor: Color(0xFF6B285B),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      // 🔥 BREAK: Focus ile aynı (Mor/Turuncu Vurgulu)
      breakState: ThemeStateColors(
        bgColor: Color(0xFF252A5A),
        gradientColors: [Color(0xFF252A5A), Color(0xFF3E477D)],
        accentColor: Color(0xFFF2A65A),
        textColor: Color(0xFFFFFFFF),
        mainButtonColor: Color(0xFFFCE8DA),
        mainButtonTextColor: Color(0xFF343B6B),
        menuButtonColor: Color(0xFF343B6B),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      // 🔥 WORK PAUSED: Mat Kahve/Mürdüm
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF2D2028),
        gradientColors: [Color(0xFF2D2028), Color(0xFF49333D)],
        accentColor: Color(0xFFD7A59A),
        textColor: Color(0xFFF3DEE6),
        mainButtonColor: Color(0xFFF3DEE6),
        mainButtonTextColor: Color(0xFF3C2932),
        menuButtonColor: Color(0xFF523843),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF004D40),
        gradientColors: [Color(0xFF004D40), Color(0xFF00796B)],
        accentColor: Color(0xFFA7F3D0),
        textColor: Color(0xFFFFFFFF),
        mainButtonColor: Color(0xFFFFFFFF),
        mainButtonTextColor: Color(0xFF00594E),
        menuButtonColor: Color(0xFF005E54),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
    ),

    // ============================================================
    // 10. Nordic Snow - Koyu Lacivert & Buz Mavisi
    // ============================================================
    AppTheme(
      id: 'nordic_snow',
      settingsBgColor: Color(0xFF071521),
      settingsCardColor: Color(0xFF102A3D),
      settingsBorderColor: Color(0xFF7DD3FC),
      settingsItemColor: Color(0xFFE6F6FF),
      idle: ThemeStateColors(
        bgColor: Color(0xFF071827),
        gradientColors: [Color(0xFF071827), Color(0xFF0E3048)],
        accentColor: Color(0xFF7DD3FC),
        textColor: Color(0xFFE6F6FF),
        mainButtonColor: Color(0xFFE6F6FF),
        mainButtonTextColor: Color(0xFF09243A),
        menuButtonColor: Color(0xFF173E59),
        menuButtonTextColor: Color(0xFFE6F6FF),
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFFDFF4FF),
        gradientColors: [Color(0xFFDFF4FF), Color(0xFFA9DDF4)],
        accentColor: Color(0xFF075985),
        textColor: Color(0xFF0B2942),
        mainButtonColor: Color(0xFF0B3A5A),
        mainButtonTextColor: Color(0xFFFFFFFF),
        menuButtonColor: Color(0xFFF7FCFF),
        menuButtonTextColor: Color(0xFF0B2942),
      ),
      // Nordic Snow odak ve mola sırasında aynı açık buz paletini kullanır.
      breakState: ThemeStateColors(
        bgColor: Color(0xFFDFF4FF),
        gradientColors: [Color(0xFFDFF4FF), Color(0xFFA9DDF4)],
        accentColor: Color(0xFF075985),
        textColor: Color(0xFF0B2942),
        mainButtonColor: Color(0xFF0B3A5A),
        mainButtonTextColor: Color(0xFFFFFFFF),
        menuButtonColor: Color(0xFFF7FCFF),
        menuButtonTextColor: Color(0xFF0B2942),
      ),
      // ⏸️ WORK PAUSED: Soğuk gri-mavi
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF263742),
        gradientColors: [Color(0xFF263742), Color(0xFF415563)],
        accentColor: Color(0xFFAFC5CF),
        textColor: Color(0xFFEFF7FA),
        mainButtonColor: Color(0xFFEFF7FA),
        mainButtonTextColor: Color(0xFF2C404D),
        menuButtonColor: Color(0xFF344955),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF075E54),
        gradientColors: [Color(0xFF075E54), Color(0xFF0F766E)],
        accentColor: Color(0xFFCCFBF1),
        textColor: Color(0xFFFFFFFF),
        mainButtonColor: Color(0xFFFFFFFF),
        mainButtonTextColor: Color(0xFF075E54),
        menuButtonColor: Color(0xFF0B5C55),
        menuButtonTextColor: Color(0xFFFFFFFF),
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
      settingsBgColor: Color(0xFF160C09),
      settingsCardColor: Color(0xFF2A1712),
      settingsBorderColor: Color(0xFFFF7043),
      settingsItemColor: Color(0xFFFFD2C4),
      idle: ThemeStateColors(
        bgColor: Color(0xFF160A07),
        gradientColors: [Color(0xFF160A07), Color(0xFF32150D)],
        accentColor: Color(0xFFFF6B35),
        textColor: Color(0xFFFFF1EB),
        mainButtonColor: Color(0xFFFF6B35),
        mainButtonTextColor: Color(0xFF1A0B06),
        menuButtonColor: Color(0xFF4A2118),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF170403),
        gradientColors: [Color(0xFF170403), Color(0xFF48120B)],
        accentColor: Color(0xFFFF5733),
        textColor: Color(0xFFFFD8CC),
        mainButtonColor: Color(0xFFFFF2ED),
        mainButtonTextColor: Color(0xFFA7200D),
        menuButtonColor: Color(0xFF7F1D10),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      // 🔥 BREAK: Focus ile aynı (Magma)
      breakState: ThemeStateColors(
        bgColor: Color(0xFF2B1206),
        gradientColors: [Color(0xFF2B1206), Color(0xFF5A2A0A)],
        accentColor: Color(0xFFFFB547),
        textColor: Color(0xFFFFE2C6),
        mainButtonColor: Color(0xFFFFCF8A),
        mainButtonTextColor: Color(0xFF351506),
        menuButtonColor: Color(0xFF6A300E),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      // 🔥 WORK PAUSED: Donmuş Lav (Mat Gri/Kahve)
      workPaused: ThemeStateColors(
        bgColor: Color(0xFF292524),
        gradientColors: [Color(0xFF292524), Color(0xFF4A403C)],
        accentColor: Color(0xFFC9B5AA),
        textColor: Color(0xFFF2E9E5),
        mainButtonColor: Color(0xFFF2E9E5),
        mainButtonTextColor: Color(0xFF332D2A),
        menuButtonColor: Color(0xFF504641),
        menuButtonTextColor: Color(0xFFFFFFFF),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFFFFB000),
        gradientColors: [Color(0xFFFFB000), Color(0xFFFFD54F)],
        accentColor: Color(0xFF4A1600),
        textColor: Color(0xFF351200),
        mainButtonColor: Color(0xFF4A1600),
        mainButtonTextColor: Color(0xFFFFF3D0),
        menuButtonColor: Color(0xFF6B2600),
        menuButtonTextColor: Color(0xFFFFFFFF),
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
  late final Future<void> _initialization;

  String _currentThemeId = 'elite';
  bool _hasPremiumAccess = false;
  bool _hasResolvedPremiumStatus = false;
  bool _themeDataLoaded = false;
  // 🔥 Kalıcı ücretsiz temalar
  static const Set<String> _permanentlyFreeThemes = {'elite', 'classic_elite'};

  // 🔥 Tema kilit açma süresi (72 saat = 3 gün)
  static const int _unlockDurationHours = 72;

  // 🔥 Her temanın kilit açma bitiş zamanı (tema_id -> bitiş zamanı)
  final Map<String, DateTime> _themeUnlockExpiry = {};
  TimerState _timerState = TimerState.idle;

  ThemeProvider() {
    _initialization = _loadThemeData();
  }

  // ============================================================
  // GETTERLAR
  // ============================================================

  String get currentThemeId => _currentThemeId;
  bool get hasPremiumAccess => _hasPremiumAccess;
  Future<void> get initialized => _initialization;
  AppTheme get currentTheme => AppThemes.getById(_currentThemeId);
  TimerState get timerState => _timerState;

  /// RevenueCat premium durumunu tema erişimiyle senkronize eder.
  ///
  /// İlk kesin sonuç ayrıca tutulur; daha sonraki satın alma/geri yükleme
  /// işlemleri sırasında oluşan geçici loading durumu seçili temayı sıfırlamaz.
  void updatePremiumStatus({
    required bool isPremium,
    required bool isLoading,
  }) {
    final premiumStatusChanged = _hasPremiumAccess != isPremium;
    _hasPremiumAccess = isPremium;

    if (!isLoading) {
      _hasResolvedPremiumStatus = true;
    }

    var selectedThemeChanged = false;
    if (_themeDataLoaded && _hasResolvedPremiumStatus && !isLoading) {
      selectedThemeChanged = _resetCurrentThemeIfUnavailable();
    }

    if (premiumStatusChanged || selectedThemeChanged) {
      notifyListeners();
    }
  }

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

  /// Settings için: Kart zemininde en az 3:1 kontrast veren tema vurgusu.
  ///
  /// Paletin tonunu ve doygunluğunu korur; yalnızca gerektiğinde HSL açıklığını
  /// erişilebilir en yakın değere taşır. Böylece ana tema sabitleri değişmeden
  /// ikon, slider ve seçim vurguları koyu/açık kartlarda görünür kalır.
  Color get settingsAccentColor {
    final cardColor = currentTheme.settingsCardColor ?? const Color(0xFF202020);
    final resolvedCardColor = cardColor.a < 1
        ? Color.alphaBlend(cardColor, settingsBgColor)
        : cardColor;

    return ThemeContrast.ensure(
      foreground: currentTheme.idle.accentColor,
      background: resolvedCardColor,
      minimumRatio: 3,
    );
  }

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
          '🎨 Timer durumu: $state → BG: ${bgColor.toARGB32().toRadixString(16)}');
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
      newState = TimerState.workPaused;
    } else if (mode == 'shortBreak' || mode == 'longBreak') {
      newState = isRunning ? TimerState.pause : TimerState.idle;
    } else {
      newState = isRunning ? TimerState.focus : TimerState.idle;
    }

    setTimerState(newState);
  }

  // ============================================================
  // TEMA YÖNETİMİ (HER TEMA İÇİN 72 SAATLİK GEÇİCİ KİLİT AÇMA)
  // ============================================================

  /// Tema açık mı kontrol et
  bool isThemeUnlocked(String themeId) {
    // Kalıcı ücretsiz temalar her zaman açık
    if (_permanentlyFreeThemes.contains(themeId)) {
      return true;
    }

    // Bu tema için süre kontrolü
    final expiry = _themeUnlockExpiry[themeId];
    if (expiry == null) return false;

    return DateTime.now().isBefore(expiry);
  }

  /// Tema geçici olarak açıksa veya kullanıcı premium ise erişilebilir.
  bool isThemeAvailable(String themeId) {
    return _hasPremiumAccess || isThemeUnlocked(themeId);
  }

  /// 🔥 Belirli bir tema için kalan süre
  Duration getRemainingTimeForTheme(String themeId) {
    final expiry = _themeUnlockExpiry[themeId];
    if (expiry == null) return Duration.zero;

    final remaining = expiry.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  /// 🔥 Kalan süreyi okunabilir formatta döndür
  String getRemainingTimeFormattedForTheme(String themeId) {
    final remaining = getRemainingTimeForTheme(themeId);
    if (remaining == Duration.zero) return '';

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    if (hours > 0) {
      return '${hours}s ${minutes}dk';
    }
    return '${minutes}dk';
  }

  Future<void> _loadThemeData() async {
    _prefs = await SharedPreferences.getInstance();

    _currentThemeId = _prefs.getString('current_theme') ?? 'elite';

    // 🔥 Tüm tema kilit açma sürelerini yükle
    final keys = _prefs.getKeys().where((k) => k.startsWith('theme_unlock_'));
    for (final key in keys) {
      final themeId = key.replaceFirst('theme_unlock_', '');
      final expiryString = _prefs.getString(key);
      if (expiryString != null) {
        final expiry = DateTime.tryParse(expiryString);
        if (expiry != null) {
          _themeUnlockExpiry[themeId] = expiry;
        }
      }
    }

    _themeDataLoaded = true;

    // RevenueCat sonucu beklenirken kayıtlı premium temayı yanlışlıkla silme.
    if (_hasResolvedPremiumStatus) {
      _resetCurrentThemeIfUnavailable();
    }

    notifyListeners();
  }

  Future<void> selectTheme(String themeId) async {
    await _initialization;

    if (!isThemeAvailable(themeId)) {
      debugPrint('❌ Tema kilidi açık değil: $themeId');
      return;
    }

    _currentThemeId = themeId;
    await _prefs.setString('current_theme', themeId);

    debugPrint('🎨 Tema seçildi: $themeId');
    notifyListeners();
  }

  bool _resetCurrentThemeIfUnavailable() {
    if (isThemeAvailable(_currentThemeId)) return false;

    _currentThemeId = 'elite';
    // Bellekteki değer senkron değişir; disk yazımı provider ağacındaki
    // entitlement yayılımını bekletmek zorunda değildir.
    unawaited(_prefs.setString('current_theme', 'elite'));
    return true;
  }

  /// 🔥 Belirli bir temayı 72 saat boyunca aç
  Future<void> unlockTheme(String themeId) async {
    await _initialization;

    final expiry = DateTime.now().add(Duration(hours: _unlockDurationHours));
    _themeUnlockExpiry[themeId] = expiry;
    await _prefs.setString('theme_unlock_$themeId', expiry.toIso8601String());

    debugPrint(
        '🔓 $themeId teması $_unlockDurationHours saat açıldı. Bitiş: $expiry');
    notifyListeners();
  }
}
