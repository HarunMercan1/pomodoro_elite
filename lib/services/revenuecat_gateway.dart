import 'dart:io';

import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/constants/revenuecat_constants.dart';

class RevenueCatCustomerState {
  final bool isPremium;

  const RevenueCatCustomerState({required this.isPremium});
}

typedef RevenueCatCustomerStateListener = void Function(
  RevenueCatCustomerState customerState,
);

abstract interface class RevenueCatGateway {
  Future<void> configure({String? appUserId});

  Future<RevenueCatCustomerState> getCustomerState();

  Future<RevenueCatCustomerState> logIn(String userId);

  Future<RevenueCatCustomerState> logOut();

  Future<Offerings?> getOfferings();

  Future<RevenueCatCustomerState> purchasePackage(Package package);

  Future<RevenueCatCustomerState> restorePurchases();

  void addCustomerStateListener(RevenueCatCustomerStateListener listener);

  void removeCustomerStateListener(RevenueCatCustomerStateListener listener);
}

class PurchasesRevenueCatGateway implements RevenueCatGateway {
  final Map<RevenueCatCustomerStateListener, CustomerInfoUpdateListener>
      _listenerAdapters = {};

  @override
  Future<void> configure({String? appUserId}) async {
    if (!Platform.isAndroid) {
      throw UnsupportedError('RevenueCat is configured for Android only.');
    }

    final configuration = PurchasesConfiguration(
      RevenueCatConstants.googleApiKey,
    )..appUserID = appUserId;

    await Purchases.configure(configuration);
  }

  @override
  Future<RevenueCatCustomerState> getCustomerState() async {
    return _toCustomerState(await Purchases.getCustomerInfo());
  }

  @override
  Future<RevenueCatCustomerState> logIn(String userId) async {
    final result = await Purchases.logIn(userId);
    return _toCustomerState(result.customerInfo);
  }

  @override
  Future<RevenueCatCustomerState> logOut() async {
    return _toCustomerState(await Purchases.logOut());
  }

  @override
  Future<Offerings?> getOfferings() => Purchases.getOfferings();

  @override
  Future<RevenueCatCustomerState> purchasePackage(Package package) async {
    final result = await Purchases.purchase(
      PurchaseParams.package(package),
    );
    return _toCustomerState(result.customerInfo);
  }

  @override
  Future<RevenueCatCustomerState> restorePurchases() async {
    return _toCustomerState(await Purchases.restorePurchases());
  }

  @override
  void addCustomerStateListener(RevenueCatCustomerStateListener listener) {
    void adapter(CustomerInfo customerInfo) {
      listener(_toCustomerState(customerInfo));
    }

    _listenerAdapters[listener] = adapter;
    Purchases.addCustomerInfoUpdateListener(adapter);
  }

  @override
  void removeCustomerStateListener(RevenueCatCustomerStateListener listener) {
    final adapter = _listenerAdapters.remove(listener);
    if (adapter != null) {
      Purchases.removeCustomerInfoUpdateListener(adapter);
    }
  }

  RevenueCatCustomerState _toCustomerState(CustomerInfo customerInfo) {
    final entitlement =
        customerInfo.entitlements.all[RevenueCatConstants.premiumEntitlementId];

    return RevenueCatCustomerState(
      isPremium: entitlement?.isActive ?? false,
    );
  }
}
