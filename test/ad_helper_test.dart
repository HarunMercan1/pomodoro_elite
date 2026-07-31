import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_elite/utils/ad_helper.dart';

void main() {
  test('debug derleme resmi Google test reklam kimliklerini kullanır', () {
    expect(
      AdHelper.bannerAdUnitIdFor(isDebug: true),
      'ca-app-pub-3940256099942544/9214589741',
    );
    expect(
      AdHelper.largeBannerAdUnitIdFor(isDebug: true),
      'ca-app-pub-3940256099942544/6300978111',
    );
    expect(
      AdHelper.rewardedAdUnitIdFor(isDebug: true),
      'ca-app-pub-3940256099942544/5224354917',
    );
    expect(
      AdHelper.interstitialAdUnitIdFor(isDebug: true),
      'ca-app-pub-3940256099942544/1033173712',
    );
  });

  test('release derleme production reklam kimliklerini korur', () {
    expect(
      AdHelper.bannerAdUnitIdFor(isDebug: false),
      'ca-app-pub-3820038977003119/5632131784',
    );
    expect(
      AdHelper.largeBannerAdUnitIdFor(isDebug: false),
      'ca-app-pub-3820038977003119/7568534212',
    );
    expect(
      AdHelper.rewardedAdUnitIdFor(isDebug: false),
      'ca-app-pub-3820038977003119/5113967474',
    );
    expect(
      AdHelper.interstitialAdUnitIdFor(isDebug: false),
      'ca-app-pub-3820038977003119/5476945465',
    );
  });

  test('Android App ID debug ve release kaynaklarında ayrılmıştır', () {
    final manifest =
        File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    final productionResource =
        File('android/app/src/main/res/values/admob.xml').readAsStringSync();
    final debugResource =
        File('android/app/src/debug/res/values/admob.xml').readAsStringSync();

    expect(manifest, contains('android:value="@string/admob_app_id"'));
    expect(debugResource, contains(AdHelper.testAppId));
    expect(debugResource, isNot(contains(AdHelper.productionAppId)));
    expect(productionResource, contains(AdHelper.productionAppId));
    expect(productionResource, isNot(contains(AdHelper.testAppId)));
  });
}
