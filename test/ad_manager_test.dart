import 'package:flutter_test/flutter_test.dart';

import 'package:pomodoro_elite/providers/ad_manager.dart';

void main() {
  test('ads stay disabled until premium entitlement is resolved', () {
    final manager = AdManager();
    addTearDown(manager.dispose);

    manager.updateAdServingAllowed(true);
    manager.updatePremiumStatus(isPremium: false, isLoading: true);

    expect(manager.canServeAds, isFalse);

    manager.updatePremiumStatus(isPremium: false, isLoading: false);
    expect(manager.canServeAds, isTrue);

    manager.updatePremiumStatus(isPremium: true, isLoading: false);
    expect(manager.canServeAds, isFalse);
  });

  test('resolved non-premium users still require ad consent', () {
    final manager = AdManager();
    addTearDown(manager.dispose);

    manager.updatePremiumStatus(isPremium: false, isLoading: false);
    expect(manager.canServeAds, isFalse);

    manager.updateAdServingAllowed(true);
    expect(manager.canServeAds, isTrue);

    manager.updateAdServingAllowed(false);
    expect(manager.canServeAds, isFalse);
  });
}
