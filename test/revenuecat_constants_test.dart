import 'package:flutter_test/flutter_test.dart';

import 'package:pomodoro_elite/core/constants/revenuecat_constants.dart';

void main() {
  group('RevenueCat product classification', () {
    test('recognizes the currently configured mega product as support', () {
      final isSupport = RevenueCatConstants.isSupportPackage(
        packageIdentifier: 'mega_star',
        productIdentifier: 'ip_mega_star',
      );

      expect(isSupport, isTrue);
    });

    test('recognizes the canonical mega product ID as support', () {
      final isSupport = RevenueCatConstants.isSupportPackage(
        packageIdentifier: r'$rc_custom_mega',
        productIdentifier: 'tip_mega_star',
      );

      expect(isSupport, isTrue);
    });

    test('classifies tip_mega_star as Mega instead of Star', () {
      final tier = RevenueCatConstants.supportTierFor(
        packageIdentifier: 'tip_mega_star',
        productIdentifier: 'tip_mega_star',
      );

      expect(tier, SupportTier.megaStar);
    });

    test('does not classify premium lifetime as a support product', () {
      final isSupport = RevenueCatConstants.isSupportPackage(
        packageIdentifier: r'$rc_lifetime',
        productIdentifier: 'premium_lifetime',
      );

      expect(isSupport, isFalse);
    });
  });
}
