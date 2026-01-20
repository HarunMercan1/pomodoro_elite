import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../utils/ad_helper.dart';

/// Banner reklamları yöneten provider.
/// Her ekran için ayrı BannerAd nesnesi oluşturulur.
class AdManager extends ChangeNotifier {
  // Settings ekranı için banner
  BannerAd? _settingsBannerAd;
  bool _isSettingsBannerLoaded = false;

  // Duration Settings ekranı için banner
  BannerAd? _durationBannerAd;
  bool _isDurationBannerLoaded = false;

  AdSize? _adSize;

  // Settings banner getter'ları
  BannerAd? get settingsBannerAd => _settingsBannerAd;
  bool get isSettingsBannerLoaded => _isSettingsBannerLoaded;

  // Duration banner getter'ları
  BannerAd? get durationBannerAd => _durationBannerAd;
  bool get isDurationBannerLoaded => _isDurationBannerLoaded;

  AdSize? get adSize => _adSize;

  /// Ayarlar sayfası için adaptive banner reklamı yükler.
  Future<void> loadSettingsBanner(double width) async {
    if (_settingsBannerAd != null) return;

    debugPrint('🔄 Settings Banner yükleniyor... (width: $width)');

    final AdSize? adaptiveSize = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      width.truncate(),
    );

    _adSize = adaptiveSize ?? AdSize.banner;

    _settingsBannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: _adSize!,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Settings Banner yüklendi');
          _isSettingsBannerLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Settings Banner yüklenemedi: ${error.message}');
          ad.dispose();
          _settingsBannerAd = null;
          _isSettingsBannerLoaded = false;
          notifyListeners();
        },
      ),
    );
    _settingsBannerAd!.load();
  }

  /// Süre ayarları sayfası için adaptive banner reklamı yükler.
  Future<void> loadDurationBanner(double width) async {
    if (_durationBannerAd != null) return;

    debugPrint('🔄 Duration Banner yükleniyor... (width: $width)');

    final AdSize? adaptiveSize = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      width.truncate(),
    );

    final size = adaptiveSize ?? AdSize.banner;

    _durationBannerAd = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Duration Banner yüklendi');
          _isDurationBannerLoaded = true;
          notifyListeners();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Duration Banner yüklenemedi: ${error.message}');
          ad.dispose();
          _durationBannerAd = null;
          _isDurationBannerLoaded = false;
          notifyListeners();
        },
      ),
    );
    _durationBannerAd!.load();
  }

  /// Settings banner'ını manuel olarak temizle
  void disposeSettingsBanner() {
    _settingsBannerAd?.dispose();
    _settingsBannerAd = null;
    _isSettingsBannerLoaded = false;
    notifyListeners();
  }

  /// Duration banner'ını manuel olarak temizle
  void disposeDurationBanner() {
    _durationBannerAd?.dispose();
    _durationBannerAd = null;
    _isDurationBannerLoaded = false;
    notifyListeners();
  }

  // ============================================================
  // 🎁 REWARDED ADS (Tema kilidi için)
  // ============================================================

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  bool get isRewardedAdReady => _isRewardedAdReady;

  /// Rewarded reklam yükle
  void loadRewardedAd() {
    debugPrint('🔄 Rewarded Ad yükleniyor...');

    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ Rewarded Ad yüklendi');
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Rewarded Ad yüklenemedi: ${error.message}');
          _rewardedAd = null;
          _isRewardedAdReady = false;
          notifyListeners();
        },
      ),
    );
  }

  /// Rewarded reklam göster ve ödül callback'i çalıştır
  Future<bool> showRewardedAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onAdDismissed,
  }) async {
    if (_rewardedAd == null) {
      debugPrint('⚠️ Rewarded Ad hazır değil, yükleniyor...');
      loadRewardedAd();
      return false;
    }

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('📺 Rewarded Ad gösterildi');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('👋 Rewarded Ad kapatıldı');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdReady = false;
        loadRewardedAd(); // Sonraki için yeni reklam yükle
        onAdDismissed?.call();
        notifyListeners();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ Rewarded Ad gösterilemedi: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        _isRewardedAdReady = false;
        loadRewardedAd();
        notifyListeners();
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('🎁 Ödül kazanıldı: ${reward.amount} ${reward.type}');
        onRewardEarned();
      },
    );

    return true;
  }

  // ============================================================
  // 🎬 INTERSTITIAL ADS (Pomodoro sonrası)
  // ============================================================

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  int _pomodorosSinceLastAd = 0;

  bool get isInterstitialAdReady => _isInterstitialAdReady;

  /// Interstitial reklam yükle
  void loadInterstitialAd() {
    debugPrint('🔄 Interstitial Ad yükleniyor...');

    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('✅ Interstitial Ad yüklendi');
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          debugPrint('❌ Interstitial Ad yüklenemedi: ${error.message}');
          _interstitialAd = null;
          _isInterstitialAdReady = false;
          notifyListeners();
        },
      ),
    );
  }

  /// Pomodoro tamamlandığında çağır
  /// Her 3-4 pomodorodan sonra reklam gösterir
  Future<void> onPomodoroCompleted() async {
    _pomodorosSinceLastAd++;
    debugPrint('🍅 Pomodoro sayısı: $_pomodorosSinceLastAd');

    // Her 2 pomodorodan sonra reklam göster
    if (_pomodorosSinceLastAd >= 2) {
      await showInterstitialAd();
      _pomodorosSinceLastAd = 0;
    }
  }

  /// Interstitial reklam göster
  Future<bool> showInterstitialAd() async {
    if (_interstitialAd == null) {
      debugPrint('⚠️ Interstitial Ad hazır değil');
      loadInterstitialAd();
      return false;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('📺 Interstitial Ad gösterildi');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('👋 Interstitial Ad kapatıldı');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialAdReady = false;
        loadInterstitialAd(); // Sonraki için yükle
        notifyListeners();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('❌ Interstitial Ad gösterilemedi: ${error.message}');
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialAdReady = false;
        loadInterstitialAd();
        notifyListeners();
      },
    );

    await _interstitialAd!.show();
    return true;
  }

  @override
  void dispose() {
    disposeSettingsBanner();
    disposeDurationBanner();
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    super.dispose();
  }
}
