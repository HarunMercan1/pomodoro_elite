import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/ad_helper.dart';

class AdManager extends ChangeNotifier {
  bool _isPremium = false;
  bool _adServingAllowed = false;
  bool _disposed = false;

  bool get _canLoadAds => !_isPremium && _adServingAllowed && !_disposed;

  BannerAd? _settingsBannerAd;
  BannerAd? _durationBannerAd;
  BannerAd? _soundBannerAd;
  bool _isSettingsBannerLoaded = false;
  bool _isDurationBannerLoaded = false;
  bool _isSoundBannerLoaded = false;
  AdSize? _adSize;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  bool _isRewardedAdLoading = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  bool _isInterstitialAdLoading = false;
  int _pomodorosSinceLastAd = 0;

  BannerAd? get settingsBannerAd => _settingsBannerAd;
  bool get isSettingsBannerLoaded => _isSettingsBannerLoaded;
  BannerAd? get durationBannerAd => _durationBannerAd;
  bool get isDurationBannerLoaded => _isDurationBannerLoaded;
  BannerAd? get soundBannerAd => _soundBannerAd;
  bool get isSoundBannerLoaded => _isSoundBannerLoaded;
  AdSize? get adSize => _adSize;
  bool get isRewardedAdReady => _isRewardedAdReady;
  bool get isInterstitialAdReady => _isInterstitialAdReady;

  void updatePremiumStatus(bool isPremium) {
    if (_isPremium == isPremium) return;
    _isPremium = isPremium;
    if (isPremium) _disposeAllAds();
  }

  void updateAdServingAllowed(bool allowed) {
    if (_adServingAllowed == allowed) return;
    _adServingAllowed = allowed;
    if (!allowed) _disposeAllAds();
  }

  Future<void> loadSettingsBanner(double width) async {
    if (!_canLoadAds || _settingsBannerAd != null) return;

    final adaptiveSize = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.portrait,
      width.truncate(),
    );
    if (!_canLoadAds) return;

    _adSize = adaptiveSize ?? AdSize.banner;
    late final BannerAd banner;
    banner = BannerAd(
      adUnitId: AdHelper.bannerAdUnitId,
      size: _adSize!,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!_canLoadAds || _settingsBannerAd != banner) {
            banner.dispose();
            if (_settingsBannerAd == banner) _settingsBannerAd = null;
            return;
          }
          _isSettingsBannerLoaded = true;
          _safeNotify();
        },
        onAdFailedToLoad: (_, error) {
          debugPrint('Settings banner yüklenemedi: ${error.message}');
          banner.dispose();
          if (_settingsBannerAd == banner) _settingsBannerAd = null;
          _isSettingsBannerLoaded = false;
          _safeNotify();
        },
      ),
    );
    _settingsBannerAd = banner;
    await banner.load();
  }

  Future<void> loadDurationBanner(double width) async {
    if (!_canLoadAds || _durationBannerAd != null) return;
    late final BannerAd banner;
    banner = BannerAd(
      adUnitId: AdHelper.largeBannerAdUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!_canLoadAds || _durationBannerAd != banner) {
            banner.dispose();
            if (_durationBannerAd == banner) _durationBannerAd = null;
            return;
          }
          _isDurationBannerLoaded = true;
          _safeNotify();
        },
        onAdFailedToLoad: (_, error) {
          debugPrint('Duration banner yüklenemedi: ${error.message}');
          banner.dispose();
          if (_durationBannerAd == banner) _durationBannerAd = null;
          _isDurationBannerLoaded = false;
          _safeNotify();
        },
      ),
    );
    _durationBannerAd = banner;
    await banner.load();
  }

  Future<void> loadSoundBanner(double width) async {
    if (!_canLoadAds || _soundBannerAd != null) return;
    late final BannerAd banner;
    banner = BannerAd(
      adUnitId: AdHelper.largeBannerAdUnitId,
      size: AdSize.mediumRectangle,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (!_canLoadAds || _soundBannerAd != banner) {
            banner.dispose();
            if (_soundBannerAd == banner) _soundBannerAd = null;
            return;
          }
          _isSoundBannerLoaded = true;
          _safeNotify();
        },
        onAdFailedToLoad: (_, error) {
          debugPrint('Sound banner yüklenemedi: ${error.message}');
          banner.dispose();
          if (_soundBannerAd == banner) _soundBannerAd = null;
          _isSoundBannerLoaded = false;
          _safeNotify();
        },
      ),
    );
    _soundBannerAd = banner;
    await banner.load();
  }

  void loadRewardedAd() {
    if (!_canLoadAds || _rewardedAd != null || _isRewardedAdLoading) return;
    _isRewardedAdLoading = true;
    RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _isRewardedAdLoading = false;
          if (!_canLoadAds) {
            ad.dispose();
            return;
          }
          _rewardedAd = ad;
          _isRewardedAdReady = true;
          _safeNotify();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Rewarded ad yüklenemedi: ${error.message}');
          _isRewardedAdLoading = false;
          _isRewardedAdReady = false;
          _safeNotify();
        },
      ),
    );
  }

  Future<bool> showRewardedAd({
    required VoidCallback onRewardEarned,
    VoidCallback? onAdDismissed,
  }) async {
    if (!_canLoadAds) return false;
    final ad = _rewardedAd;
    if (ad == null) {
      loadRewardedAd();
      return false;
    }

    _rewardedAd = null;
    _isRewardedAdReady = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        loadRewardedAd();
        onAdDismissed?.call();
        _safeNotify();
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        debugPrint('Rewarded ad gösterilemedi: ${error.message}');
        shownAd.dispose();
        loadRewardedAd();
        _safeNotify();
      },
    );
    ad.show(onUserEarnedReward: (_, __) => onRewardEarned());
    return true;
  }

  void loadInterstitialAd() {
    if (!_canLoadAds || _interstitialAd != null || _isInterstitialAdLoading) {
      return;
    }
    _isInterstitialAdLoading = true;
    InterstitialAd.load(
      adUnitId: AdHelper.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isInterstitialAdLoading = false;
          if (!_canLoadAds) {
            ad.dispose();
            return;
          }
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _safeNotify();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Interstitial ad yüklenemedi: ${error.message}');
          _isInterstitialAdLoading = false;
          _isInterstitialAdReady = false;
          _safeNotify();
        },
      ),
    );
  }

  Future<void> onPomodoroCompleted() async {
    if (!_canLoadAds) return;
    _pomodorosSinceLastAd++;
    if (_pomodorosSinceLastAd >= 2) {
      final shown = await showInterstitialAd();
      if (shown) _pomodorosSinceLastAd = 0;
    }
  }

  Future<bool> showInterstitialAd() async {
    if (!_canLoadAds) return false;
    final ad = _interstitialAd;
    if (ad == null) {
      loadInterstitialAd();
      return false;
    }

    _interstitialAd = null;
    _isInterstitialAdReady = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shownAd) {
        shownAd.dispose();
        loadInterstitialAd();
        _safeNotify();
      },
      onAdFailedToShowFullScreenContent: (shownAd, error) {
        debugPrint('Interstitial ad gösterilemedi: ${error.message}');
        shownAd.dispose();
        loadInterstitialAd();
        _safeNotify();
      },
    );
    ad.show();
    return true;
  }

  void disposeSettingsBanner() {
    _settingsBannerAd?.dispose();
    _settingsBannerAd = null;
    _isSettingsBannerLoaded = false;
    _safeNotify();
  }

  void disposeDurationBanner() {
    _durationBannerAd?.dispose();
    _durationBannerAd = null;
    _isDurationBannerLoaded = false;
    _safeNotify();
  }

  void disposeSoundBanner() {
    _soundBannerAd?.dispose();
    _soundBannerAd = null;
    _isSoundBannerLoaded = false;
    _safeNotify();
  }

  void _disposeAllAds() {
    _settingsBannerAd?.dispose();
    _durationBannerAd?.dispose();
    _soundBannerAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd?.dispose();
    _settingsBannerAd = null;
    _durationBannerAd = null;
    _soundBannerAd = null;
    _rewardedAd = null;
    _interstitialAd = null;
    _isSettingsBannerLoaded = false;
    _isDurationBannerLoaded = false;
    _isSoundBannerLoaded = false;
    _isRewardedAdReady = false;
    _isRewardedAdLoading = false;
    _isInterstitialAdReady = false;
    _isInterstitialAdLoading = false;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _disposeAllAds();
    super.dispose();
  }
}
