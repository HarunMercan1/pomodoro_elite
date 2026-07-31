import 'dart:io';

import 'package:flutter/services.dart';

import '../core/constants/revenuecat_constants.dart';

abstract interface class PlayStoreOwnershipGateway {
  /// Returns true only when Google Play currently reports the lifetime
  /// non-consumable as an active PURCHASED item for the device's store account.
  Future<bool> hasActivePremiumPurchase();
}

class MethodChannelPlayStoreOwnershipGateway
    implements PlayStoreOwnershipGateway {
  static const MethodChannel _channel = MethodChannel(
    'com.mercansoftware.pomodoro_elite/play_store_ownership',
  );

  @override
  Future<bool> hasActivePremiumPurchase() async {
    if (!Platform.isAndroid) return false;

    final productIds = await _channel.invokeListMethod<String>(
      'getOwnedInAppProductIds',
    );

    return productIds?.contains(RevenueCatConstants.premiumProductId) ?? false;
  }
}
