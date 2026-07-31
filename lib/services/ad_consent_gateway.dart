import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// UMP ve Mobile Ads SDK çağrılarını test edilebilir bir arayüz arkasında tutar.
abstract interface class AdConsentGateway {
  Future<void> requestConsentInfoUpdate();

  Future<void> loadAndShowConsentFormIfRequired();

  Future<bool> canRequestAds();

  Future<bool> isPrivacyOptionsRequired();

  Future<void> showPrivacyOptionsForm();

  Future<void> initializeMobileAds();
}

class GoogleMobileAdsConsentGateway implements AdConsentGateway {
  static const _umpTestDeviceId = String.fromEnvironment(
    'UMP_TEST_DEVICE_ID',
  );

  @override
  Future<void> requestConsentInfoUpdate() {
    final completer = Completer<void>();
    final debugSettings = kDebugMode && _umpTestDeviceId.isNotEmpty
        ? ConsentDebugSettings(
            debugGeography: DebugGeography.debugGeographyEea,
            testIdentifiers: const [_umpTestDeviceId],
          )
        : null;

    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(consentDebugSettings: debugSettings),
      () => completer.complete(),
      (error) => completer.completeError(error),
    );
    return completer.future;
  }

  @override
  Future<void> loadAndShowConsentFormIfRequired() {
    final completer = Completer<void>();
    ConsentForm.loadAndShowConsentFormIfRequired((error) {
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(error);
      }
    });
    return completer.future;
  }

  @override
  Future<bool> canRequestAds() => ConsentInformation.instance.canRequestAds();

  @override
  Future<bool> isPrivacyOptionsRequired() async {
    final status =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
    return status == PrivacyOptionsRequirementStatus.required;
  }

  @override
  Future<void> showPrivacyOptionsForm() {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((error) {
      if (error == null) {
        completer.complete();
      } else {
        completer.completeError(error);
      }
    });
    return completer.future;
  }

  @override
  Future<void> initializeMobileAds() async {
    await MobileAds.instance.initialize();
  }
}
