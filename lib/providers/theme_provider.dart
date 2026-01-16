import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_colors.dart';

/// Timer durumları
enum TimerState {
  idle, // Boşta
  focus, // Odaklanma
  pause, // Mola (short/long break)
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
  final Color? menuButtonColor; // Üst menü butonları (null ise accentColor)

  const ThemeStateColors({
    required this.bgColor,
    this.gradientColors,
    required this.accentColor,
    this.textColor = Colors.white,
    this.mainButtonColor,
    this.mainButtonTextColor,
    this.menuButtonColor,
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

  /// Efektif Menü Buton Rengi
  Color get effectiveMenuButtonColor => menuButtonColor ?? accentColor;
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

  const AppTheme({
    required this.id,
    required this.name,
    required this.vibe,
    required this.idle,
    required this.focus,
    required this.breakState,
    required this.finish,
    this.isLocked = true,
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
      case TimerState.finish:
        return finish;
    }
  }
}

/// 11 Tema Paleti
class AppThemes {
  static const List<AppTheme> all = [
    // ============================================================
    // 1. ELITE (Varsayılan - UNLOCKED) - Orijinal AppColors Referanslı
    // ============================================================
    AppTheme(
      id: 'elite',
      name: 'Elite',
      vibe: 'Orijinal, Klasik',
      isLocked: false,
      idle: ThemeStateColors(
        bgColor: Color(0xFF141414), // Siyah Başlangıç
        // 🔥 KRİTİK DÜZELTME: "Lamba gibi" yanmayı önlemek için Solid yerine Gradient
        // Siyah -> Siyah gradient veriyoruz ki diğer durumlara geçerken yumuşak (interpolate) geçiş yapsın.
        gradientColors: [Color(0xFF141414), Color(0xFF141414)],
        accentColor:
            Color(0xFF1A2980), // Dark Navy (AppColors.darkNavy) - Mor DEĞİL
        mainButtonColor: Color(0xFF1A2980), // Dark Navy
        mainButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: AppColors.themeBlue,
        gradientColors: AppColors.runningGradient,
        accentColor: AppColors.ringCyan,
        mainButtonColor: Colors.white,
        mainButtonTextColor: AppColors.themeBlue, // Lacivert
        menuButtonColor: AppColors.themeBlue, // Menü: Lacivert
      ),
      breakState: ThemeStateColors(
        bgColor: AppColors.themeBronze,
        gradientColors: AppColors.pausedGradient,
        accentColor: AppColors.themeBronze,
        textColor: AppColors.themeBronze,
        mainButtonColor: Colors.white,
        mainButtonTextColor: AppColors.themeBronze, // Kahve
      ),
      finish: ThemeStateColors(
        bgColor: AppColors.themeGreen,
        gradientColors: AppColors.finishedGradient,
        accentColor: AppColors.ringDarkGreen,
        mainButtonColor: Colors.white,
        mainButtonTextColor: AppColors.themeGreen, // Yeşil
      ),
    ),

    // ============================================================
    // 2. Klasik (Eski Classic Elite) - Koyu Arka Plan, Mavi Butonlar
    // ============================================================
    AppTheme(
      id: 'classic_elite',
      name: 'Klasik',
      vibe: 'Güven, Sade',
      idle: ThemeStateColors(
        bgColor:
            Color(0xFF121212), // Koyu Arka Plan (Ayarlar Mavi olmasın diye)
        gradientColors: [Color(0xFF121212), Color(0xFF1E1E1E)],
        accentColor: Color(0xFF64B5F6),
        mainButtonColor: Color(0xFF1565C0), // Koyu Mavi Buton
        mainButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF1565C0), // Koyu Mavi
        gradientColors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF1565C0),
        menuButtonColor: Color(0xFF90CAF9),
      ),
      breakState: ThemeStateColors(
        bgColor: Color(0xFFE3F2FD), // Çok Açık Mavi (White değil)
        gradientColors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
        accentColor: Color(0xFF1565C0),
        textColor: Color(0xFF1565C0),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF1565C0),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF43A047),
        gradientColors: [Color(0xFF388E3C), Color(0xFF66BB6A)],
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF2E7D32),
      ),
    ),

    // ============================================================
    // 3. Stranger Things (Gerilim) - Kırmızı/Siyah
    // ============================================================
    AppTheme(
      id: 'stranger_things',
      name: 'Stranger Things',
      vibe: 'Gerilim, Gizem, 80ler',
      idle: ThemeStateColors(
        bgColor: Color(0xFF000000),
        gradientColors: [Color(0xFF000000), Color(0xFF1A0000)],
        accentColor: Color(0xFFD32F2F),
        mainButtonColor: Color(0xFFD32F2F),
        mainButtonTextColor: Colors.white,
        menuButtonColor: Color(0xFFD32F2F), // IDLE: Kırmızı Menü
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFFB71C1C),
        gradientColors: [Color(0xFF000000), Color(0xFFB71C1C)],
        accentColor: Color(0xFFFF5252),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFB71C1C),
        menuButtonColor: Color(0xFFD32F2F), // FOCUS: Kırmızı Menü (Pembe değil)
      ),
      breakState: ThemeStateColors(
        bgColor: Color(0xFF212121),
        gradientColors: [Color(0xFF424242), Color(0xFF212121)],
        accentColor: Colors.grey,
        textColor: Colors.white70,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Colors.black,
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF000000),
        gradientColors: [Color(0xFF1A1A1A), Color(0xFFFFFF00)], // Sarı ışıklar
        accentColor: Colors.black,
        textColor: Colors.black,
        mainButtonColor: Colors.black,
        mainButtonTextColor: Color(0xFFFFD600),
      ),
    ),

    // ============================================================
    // 4. Heisenberg (Breaking Bad) - Turkuaz/Sarı
    // ============================================================
    AppTheme(
      id: 'heisenberg',
      name: 'Heisenberg',
      vibe: 'Kristal Mavi, Sarı Tulum',
      idle: ThemeStateColors(
        bgColor: Color(0xFF004D40),
        gradientColors: [Color(0xFF004D40), Color(0xFF00695C)],
        accentColor: Color(0xFF00E676),
        mainButtonColor: Color(0xFF00E676),
        mainButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF00BCD4),
        gradientColors: [Color(0xFF00838F), Color(0xFF00E5FF)], // Kristal Mavi
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF006064),
        menuButtonColor: Color(0xFFB2EBF2),
      ),
      breakState: ThemeStateColors(
        bgColor: Color(0xFFFBC02D), // Sarı Tulum
        gradientColors: [Color(0xFFF9A825), Color(0xFFFFF176)],
        accentColor: Color(0xFF3E2723),
        textColor: Color(0xFF3E2723),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFFbc02D),
      ),
      finish: ThemeStateColors(
        bgColor: Color(0xFF2E7D32),
        gradientColors: [Color(0xFF1B5E20), Color(0xFF4CAF50)], // Para Yeşili
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF1B5E20),
      ),
    ),

    // ============================================================
    // 5. Deep Ocean (Derinlik) - Koyu Mavi/Teal
    // ============================================================
    AppTheme(
      id: 'deep_ocean',
      name: 'Deep Ocean',
      vibe: 'Derinlik, Odak',
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
    // 6. Mystic Forest (Doğa) - Yeşil Tonları
    // ============================================================
    AppTheme(
      id: 'mystic_forest',
      name: 'Mystic Forest',
      vibe: 'Doğa, Huzur',
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
        bgColor: Color(0xFF5D4037), // Toprak
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
    // 7. Cyberpunk 2077 (Neon) - Pembe/Sarı
    // ============================================================
    AppTheme(
      id: 'cyberpunk',
      name: 'Cyberpunk 2077',
      vibe: 'Neon, Gelecek',
      idle: ThemeStateColors(
        bgColor: Color(0xFF080808),
        gradientColors: [Color(0xFF000000), Color(0xFF111111)],
        accentColor: Color(0xFFFBC02D), // Cyber Sarı
        mainButtonColor: Color(0xFFFBC02D),
        mainButtonTextColor: Colors.black,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFFEA005E),
        gradientColors: [Color(0xFF31004a), Color(0xFFEA005E)], // Neon Pembe
        accentColor: Color(0xFF00E5FF),
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
    // 8. Royal Gold (Lüks) - Siyah/Altın
    // ============================================================
    AppTheme(
      id: 'royal_gold',
      name: 'Royal Gold',
      vibe: 'Lüks, Başarı',
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
        gradientColors: [Color(0xFF212121), Color(0xFF757575)], // Gümüş
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
    // 9. Sunset Lofi (Chill) - Mor/Turuncu
    // ============================================================
    AppTheme(
      id: 'sunset_lofi',
      name: 'Sunset Lofi',
      vibe: 'Estetik, Chill',
      idle: ThemeStateColors(
        bgColor: Color(0xFF2D1B2E),
        gradientColors: [Color(0xFF1A1A2E), Color(0xFF2D1B2E)],
        accentColor: Color(0xFFFF6B6B),
        mainButtonColor: Color(0xFFFF6B6B),
        mainButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFF6A1B9A),
        gradientColors: [
          Color(0xFF4527A0),
          Color(0xFFFF6B6B)
        ], // Mor -> Turuncu
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
        textColor: Color(0xFF01579B), // Koyu Mavi Text
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF0277BD),
        menuButtonColor: Color(0xFF81D4FA),
      ),
      breakState: ThemeStateColors(
        bgColor: Color(0xFFECEFF1),
        gradientColors: [Color(0xFFCFD8DC), Color(0xFFECEFF1)],
        accentColor: Color(0xFF607D8B),
        textColor: Color(0xFF455A64),
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFF607D8B),
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
    // 11. Volcano (Enerji) - Kırmızı/Turuncu
    // ============================================================
    AppTheme(
      id: 'volcano',
      name: 'Volcano',
      vibe: 'Yüksek Enerji',
      idle: ThemeStateColors(
        bgColor: Color(0xFF212121),
        gradientColors: [Color(0xFF000000), Color(0xFF212121)],
        accentColor: Color(0xFFFF5722),
        mainButtonColor: Color(0xFFFF5722),
        mainButtonTextColor: Colors.white,
      ),
      focus: ThemeStateColors(
        bgColor: Color(0xFFBF360C),
        gradientColors: [Color(0xFFB71C1C), Color(0xFFFF5722)], // Magma
        accentColor: Colors.white,
        mainButtonColor: Colors.white,
        mainButtonTextColor: Color(0xFFBF360C),
        menuButtonColor: Color(0xFFFFCCBC),
      ),
      breakState: ThemeStateColors(
        bgColor: Color(0xFF3E2723), // Kül
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
      newState = TimerState.pause;
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
