import 'dart:async';

import 'package:flutter/foundation.dart';

import 'ad_consent_gateway.dart';

/// Google UMP iznini toplar ve reklam SDK'sını yalnızca izin durumu kesinleşince
/// başlatır. Böylece uygulama açılırken izinsiz/erken reklam isteği gönderilmez.
class AdConsentService extends ChangeNotifier {
  AdConsentService({AdConsentGateway? gateway})
      : _gateway = gateway ?? GoogleMobileAdsConsentGateway();

  final AdConsentGateway _gateway;
  Future<void>? _gatheringFuture;
  Future<void>? _mobileAdsInitialization;
  bool _adsReady = false;
  bool _isGathering = false;
  bool _privacyOptionsRequired = false;
  bool _disposed = false;

  bool get adsReady => _adsReady;
  bool get isGathering => _isGathering;
  bool get isPrivacyOptionsRequired => _privacyOptionsRequired;

  Future<void> gatherConsent() {
    return _gatheringFuture ??= _gatherConsent().whenComplete(() {
      _gatheringFuture = null;
    });
  }

  Future<void> _gatherConsent() async {
    _setGathering(true);
    try {
      try {
        await _gateway.requestConsentInfoUpdate().timeout(
              const Duration(seconds: 12),
            );
        await _gateway.loadAndShowConsentFormIfRequired().timeout(
              const Duration(seconds: 30),
            );
      } catch (error) {
        // Ağ veya form hatasında UMP'nin önceki oturumdan sakladığı geçerli
        // consent durumu kullanılabilir; canRequestAds kontrolü yine yapılır.
        debugPrint('UMP izin akışı tamamlanamadı: $error');
      }

      await _refreshPrivacyOptionsRequirement();
      await _refreshAdReadiness();
    } finally {
      _setGathering(false);
    }
  }

  Future<void> showPrivacyOptionsForm() async {
    await _gateway.showPrivacyOptionsForm();
    await _refreshPrivacyOptionsRequirement();
    await _refreshAdReadiness();
  }

  Future<void> _refreshPrivacyOptionsRequirement() async {
    try {
      final required = await _gateway.isPrivacyOptionsRequired();
      if (_privacyOptionsRequired != required) {
        _privacyOptionsRequired = required;
        _safeNotify();
      }
    } catch (error) {
      debugPrint('UMP gizlilik seçenekleri durumu okunamadı: $error');
    }
  }

  Future<void> _refreshAdReadiness() async {
    bool canRequestAds = false;
    try {
      canRequestAds = await _gateway.canRequestAds();
    } catch (error) {
      debugPrint('UMP reklam izni durumu okunamadı: $error');
    }

    if (canRequestAds) {
      _mobileAdsInitialization ??= _gateway.initializeMobileAds();
      try {
        await _mobileAdsInitialization;
      } catch (error) {
        _mobileAdsInitialization = null;
        debugPrint('Mobile Ads başlatılamadı: $error');
        canRequestAds = false;
      }
    }

    if (_adsReady != canRequestAds) {
      _adsReady = canRequestAds;
      _safeNotify();
    }
  }

  void _setGathering(bool value) {
    if (_isGathering == value) return;
    _isGathering = value;
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
