import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/ad_helper.dart';

class AdManager extends ChangeNotifier {
  bool _isPremium = false;
  bool _isPremiumStatusLoading = true;
  bool _adServingAllowed = false;
  bool _disposed = false;

  bool get _canLoadAds =>
      !_isPremiumStatusLoading &&
      !_isPremium &&
      _adServingAllowed &&
      !_disposed;

  /// Reklamların entitlement sonucu kesinleşip izin verildiğinde görünmesini
  /// sağlar. Premium durumu yüklenirken native reklam yüzeyi oluşturulmaz.
  bool get canServeAds => _canLoadAds;

  BannerAd? _settingsBannerAd;
  BannerAd? _durationBannerAd;
  BannerAd? _soundBannerAd;
  bool _isSettingsBannerLoaded = false;
  bool _isDurationBannerLoaded = false;
  bool _isSoundBannerLoaded = false;
  double? _settingsBannerRequestedWidth;
  double? _durationBannerRequestedWidth;
  double? _soundBannerRequestedWidth;
  AdSize? _adSize;

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  bool _isRewardedAdLoading = false;
  bool _rewardedAdRequested = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  bool _isInterstitialAdLoading = false;
  bool _interstitialAdRequested = false;
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

  void updatePremiumStatus({
    required bool isPremium,
    required bool isLoading,
  }) {
    if (_isPremium == isPremium && _isPremiumStatusLoading == isLoading) {
      return;
    }
    _isPremium = isPremium;
    _isPremiumStatusLoading = isLoading;

    if (!_canLoadAds) {
      _disposeAllAds();
    } else {
      _safeNotify();
      _resumeRequestedAds();
    }
  }

  void updateAdServingAllowed(bool allowed) {
    if (_adServingAllowed == allowed) return;
    _adServingAllowed = allowed;
    if (!allowed) {
      _disposeAllAds();
    } else if (_canLoadAds) {
      _safeNotify();
      _resumeRequestedAds();
    }
  }

  Future<void> loadSettingsBanner(double width) async {
    _settingsBannerRequestedWidth = width;
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
    _durationBannerRequestedWidth = width;
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
    _soundBannerRequestedWidth = width;
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
    _rewardedAdRequested = true;
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
    _interstitialAdRequested = true;
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
    _settingsBannerRequestedWidth = null;
    _settingsBannerAd?.dispose();
    _settingsBannerAd = null;
    _isSettingsBannerLoaded = false;
    _safeNotify();
  }

  void disposeDurationBanner() {
    _durationBannerRequestedWidth = null;
    _durationBannerAd?.dispose();
    _durationBannerAd = null;
    _isDurationBannerLoaded = false;
    _safeNotify();
  }

  void disposeSoundBanner() {
    _soundBannerRequestedWidth = null;
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

  void _resumeRequestedAds() {
    if (!_canLoadAds) return;

    final settingsWidth = _settingsBannerRequestedWidth;
    if (settingsWidth != null) {
      unawaited(loadSettingsBanner(settingsWidth));
    }

    final durationWidth = _durationBannerRequestedWidth;
    if (durationWidth != null) {
      unawaited(loadDurationBanner(durationWidth));
    }

    final soundWidth = _soundBannerRequestedWidth;
    if (soundWidth != null) {
      unawaited(loadSoundBanner(soundWidth));
    }

    if (_rewardedAdRequested) loadRewardedAd();
    if (_interstitialAdRequested) loadInterstitialAd();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _settingsBannerRequestedWidth = null;
    _durationBannerRequestedWidth = null;
    _soundBannerRequestedWidth = null;
    _rewardedAdRequested = false;
    _interstitialAdRequested = false;
    _disposeAllAds();
    super.dispose();
  }
}
