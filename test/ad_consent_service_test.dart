import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_elite/services/ad_consent_gateway.dart';
import 'package:pomodoro_elite/services/ad_consent_service.dart';

class _FakeAdConsentGateway implements AdConsentGateway {
  bool canRequest = true;
  bool privacyRequired = false;
  bool throwOnUpdate = false;
  Completer<void>? updateCompleter;
  int updateCalls = 0;
  int formCalls = 0;
  int initializeCalls = 0;
  int privacyFormCalls = 0;

  @override
  Future<bool> canRequestAds() async => canRequest;

  @override
  Future<void> initializeMobileAds() async => initializeCalls++;

  @override
  Future<bool> isPrivacyOptionsRequired() async => privacyRequired;

  @override
  Future<void> loadAndShowConsentFormIfRequired() async => formCalls++;

  @override
  Future<void> requestConsentInfoUpdate() {
    updateCalls++;
    if (throwOnUpdate) return Future.error(StateError('network'));
    return updateCompleter?.future ?? Future.value();
  }

  @override
  Future<void> showPrivacyOptionsForm() async => privacyFormCalls++;
}

void main() {
  test('izin tamamlanınca Mobile Ads yalnızca bir kez başlatılır', () async {
    final gateway = _FakeAdConsentGateway();
    final service = AdConsentService(gateway: gateway);

    await service.gatherConsent();
    await service.gatherConsent();

    expect(service.adsReady, isTrue);
    expect(gateway.updateCalls, 2);
    expect(gateway.formCalls, 2);
    expect(gateway.initializeCalls, 1);
  });

  test('eş zamanlı izin istekleri tek akışta birleştirilir', () async {
    final gateway = _FakeAdConsentGateway()
      ..updateCompleter = Completer<void>();
    final service = AdConsentService(gateway: gateway);

    final first = service.gatherConsent();
    final second = service.gatherConsent();
    expect(gateway.updateCalls, 1);

    gateway.updateCompleter!.complete();
    await Future.wait([first, second]);

    expect(gateway.updateCalls, 1);
    expect(gateway.initializeCalls, 1);
    expect(service.adsReady, isTrue);
  });

  test('ağ hatasında kayıtlı UMP izni kontrol edilmeye devam edilir', () async {
    final gateway = _FakeAdConsentGateway()..throwOnUpdate = true;
    final service = AdConsentService(gateway: gateway);

    await service.gatherConsent();

    expect(service.adsReady, isTrue);
    expect(gateway.formCalls, 0);
    expect(gateway.initializeCalls, 1);
  });

  test('izin yoksa reklam SDK başlatılmaz', () async {
    final gateway = _FakeAdConsentGateway()..canRequest = false;
    final service = AdConsentService(gateway: gateway);

    await service.gatherConsent();

    expect(service.adsReady, isFalse);
    expect(gateway.initializeCalls, 0);
  });

  test('gizlilik formundan sonra iptal edilen izin hemen uygulanır', () async {
    final gateway = _FakeAdConsentGateway()
      ..privacyRequired = true
      ..canRequest = true;
    final service = AdConsentService(gateway: gateway);
    await service.gatherConsent();
    expect(service.adsReady, isTrue);
    expect(service.isPrivacyOptionsRequired, isTrue);

    gateway.canRequest = false;
    await service.showPrivacyOptionsForm();

    expect(gateway.privacyFormCalls, 1);
    expect(service.adsReady, isFalse);
  });
}
