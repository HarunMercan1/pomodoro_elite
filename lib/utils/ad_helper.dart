import 'package:flutter/foundation.dart';

/// Android AdMob kimliklerini yapı türüne göre güvenli biçimde seçer.
/// Debug derlemeleri daima Google'ın resmi test kimliklerini kullanır.
class AdHelper {
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String productionAppId =
      'ca-app-pub-3820038977003119~9164182684';

  static const String _testAdaptiveBannerId =
      'ca-app-pub-3940256099942544/9214589741';
  static const String _testMediumRectangleId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _testRewardedId =
      'ca-app-pub-3940256099942544/5224354917';
  static const String _testInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';

  static const String _productionAdaptiveBannerId =
      'ca-app-pub-3820038977003119/5632131784';
  static const String _productionMediumRectangleId =
      'ca-app-pub-3820038977003119/7568534212';
  static const String _productionRewardedId =
      'ca-app-pub-3820038977003119/5113967474';
  static const String _productionInterstitialId =
      'ca-app-pub-3820038977003119/5476945465';

  static bool get isTestMode => kDebugMode;

  static String bannerAdUnitIdFor({required bool isDebug}) =>
      isDebug ? _testAdaptiveBannerId : _productionAdaptiveBannerId;

  static String largeBannerAdUnitIdFor({required bool isDebug}) =>
      isDebug ? _testMediumRectangleId : _productionMediumRectangleId;

  static String rewardedAdUnitIdFor({required bool isDebug}) =>
      isDebug ? _testRewardedId : _productionRewardedId;

  static String interstitialAdUnitIdFor({required bool isDebug}) =>
      isDebug ? _testInterstitialId : _productionInterstitialId;

  static String appIdFor({required bool isDebug}) =>
      isDebug ? testAppId : productionAppId;

  static String get bannerAdUnitId => bannerAdUnitIdFor(isDebug: isTestMode);
  static String get largeBannerAdUnitId =>
      largeBannerAdUnitIdFor(isDebug: isTestMode);
  static String get rewardedAdUnitId =>
      rewardedAdUnitIdFor(isDebug: isTestMode);
  static String get interstitialAdUnitId =>
      interstitialAdUnitIdFor(isDebug: isTestMode);
  static String get appId => appIdFor(isDebug: isTestMode);
}
