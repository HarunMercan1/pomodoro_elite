import 'dart:io';

/// AdMob reklam ID'lerini yöneten yardımcı sınıf.
///
/// Test modunda Google'ın resmi test ID'lerini kullanır.
/// Production modunda gerçek ID'leri kullanır.
class AdHelper {
  /// Test modu aktif mi?
  ///
  /// ⚠️ ÖNEMLİ: Production'da bu FALSE olmalı!
  /// Test modunda iken gerçek ID kullanmak hesabının banlanmasına neden olabilir.
  static const bool isTestMode = true; // 🧪 TEST MODU - Geliştirme için

  // ============================================================
  // 🧪 GOOGLE'IN RESMİ TEST ID'LERİ
  // Bu ID'ler development sırasında güvenle kullanılabilir.
  // ============================================================

  static const String _testAppIdAndroid =
      'ca-app-pub-3940256099942544~3347511713';
  static const String _testBannerIdAndroid =
      'ca-app-pub-3940256099942544/6300978111';

  static const String _testAppIdIOS = 'ca-app-pub-3940256099942544~1458002511';
  static const String _testBannerIdIOS =
      'ca-app-pub-3940256099942544/2934735716';

  // ============================================================
  // 🔥 GERÇEK ID'LER - AdMob'dan alınan ID'ler
  // ============================================================

  // Gerçek App ID
  static const String _realAppIdAndroid =
      'ca-app-pub-3820038977003119~9164182684';

  // Gerçek Banner Ad Unit ID
  static const String _realBannerIdAndroid =
      'ca-app-pub-3820038977003119/5632131784';

  // iOS için (gelecekte kullanılabilir)
  static const String _realAppIdIOS = 'ca-app-pub-3820038977003119~9164182684';
  static const String _realBannerIdIOS =
      'ca-app-pub-3820038977003119/5632131784';

  // ============================================================
  // 🎁 REWARDED AD ID'LERİ (Tema kilidi açmak için)
  // ============================================================

  // Test rewarded ad IDs
  static const String _testRewardedIdAndroid =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testRewardedIdIOS =
      'ca-app-pub-3940256099942544/1712485313';

  // Gerçek Rewarded Ad Unit ID
  static const String _realRewardedIdAndroid =
      'ca-app-pub-3820038977003119/5113967474';
  static const String _realRewardedIdIOS =
      'ca-app-pub-3820038977003119/5113967474';

  // ============================================================
  // 🎬 INTERSTITIAL AD ID'LERİ (Pomodoro sonrası)
  // ============================================================

  // Test interstitial ad IDs
  static const String _testInterstitialIdAndroid =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _testInterstitialIdIOS =
      'ca-app-pub-3940256099942544/4411468910';

  // Gerçek Interstitial Ad Unit ID
  static const String _realInterstitialIdAndroid =
      'ca-app-pub-3820038977003119/5476945465';
  static const String _realInterstitialIdIOS =
      'ca-app-pub-3820038977003119/5476945465';

  // ============================================================
  // GETTER METODLARI
  // ============================================================

  /// Banner reklam ID'sini döndürür.
  /// Test moduna göre uygun ID'yi seçer.
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return isTestMode ? _testBannerIdAndroid : _realBannerIdAndroid;
    } else if (Platform.isIOS) {
      return isTestMode ? _testBannerIdIOS : _realBannerIdIOS;
    } else {
      throw UnsupportedError('Bu platform desteklenmiyor');
    }
  }

  /// Rewarded reklam ID'sini döndürür.
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return isTestMode ? _testRewardedIdAndroid : _realRewardedIdAndroid;
    } else if (Platform.isIOS) {
      return isTestMode ? _testRewardedIdIOS : _realRewardedIdIOS;
    } else {
      throw UnsupportedError('Bu platform desteklenmiyor');
    }
  }

  /// Interstitial reklam ID'sini döndürür.
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return isTestMode
          ? _testInterstitialIdAndroid
          : _realInterstitialIdAndroid;
    } else if (Platform.isIOS) {
      return isTestMode ? _testInterstitialIdIOS : _realInterstitialIdIOS;
    } else {
      throw UnsupportedError('Bu platform desteklenmiyor');
    }
  }

  /// App ID'yi döndürür (bilgi amaçlı).
  static String get appId {
    if (Platform.isAndroid) {
      return isTestMode ? _testAppIdAndroid : _realAppIdAndroid;
    } else if (Platform.isIOS) {
      return isTestMode ? _testAppIdIOS : _realAppIdIOS;
    } else {
      throw UnsupportedError('Bu platform desteklenmiyor');
    }
  }
}
