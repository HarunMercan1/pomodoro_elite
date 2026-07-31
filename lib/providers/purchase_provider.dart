import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/constants/revenuecat_constants.dart';

class PurchaseProvider extends ChangeNotifier {
  bool _isPremium = false;
  bool _isLoading = true;
  Offerings? _offerings;

  bool get isPremium => _isPremium;
  bool get isLoading => _isLoading;
  Offerings? get offerings => _offerings;

  PurchaseProvider() {
    _initRevenueCat();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        logIn(user.id);
      } else {
        logOut();
      }
    });
  }

  Future<void> _initRevenueCat() async {
    try {
      if (Platform.isAndroid) {
        await Purchases.configure(PurchasesConfiguration(RevenueCatConstants.googleApiKey));
      } else if (Platform.isIOS) {
        await Purchases.configure(PurchasesConfiguration(RevenueCatConstants.appleApiKey));
      }
      
      await _checkPremiumStatus();
      await fetchOfferings();
    } catch (e) {
      debugPrint("RevenueCat Init Error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logIn(String userId) async {
    try {
      await Purchases.logIn(userId);
      await _checkPremiumStatus();
    } catch (e) {
      debugPrint("RevenueCat Login Error: $e");
    }
  }

  Future<void> logOut() async {
    try {
      await Purchases.logOut();
      await _checkPremiumStatus();
    } catch (e) {
      debugPrint("RevenueCat Logout Error: $e");
    }
  }

  Future<void> _checkPremiumStatus() async {
    try {
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      _isPremium = customerInfo.entitlements.all[RevenueCatConstants.premiumEntitlementId]?.isActive ?? false;
      notifyListeners();
    } catch (e) {
      debugPrint("Check Premium Error: $e");
    }
  }

  Future<void> fetchOfferings() async {
    try {
      _offerings = await Purchases.getOfferings();
      notifyListeners();
    } catch (e) {
      debugPrint("Fetch Offerings Error: $e");
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      _isLoading = true;
      notifyListeners();
      await Purchases.purchasePackage(package);
      CustomerInfo customerInfo = await Purchases.getCustomerInfo();
      
      _isPremium = customerInfo.entitlements.all[RevenueCatConstants.premiumEntitlementId]?.isActive ?? false;
      _isLoading = false;
      notifyListeners();
      return true;
    } on PlatformException catch (e) {
      var errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        debugPrint("Product already purchased, attempting to restore...");
        return await restorePurchases();
      }
      debugPrint("Purchase Package Error: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint("Purchase Package Error: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      CustomerInfo customerInfo = await Purchases.restorePurchases();
      _isPremium = customerInfo.entitlements.all[RevenueCatConstants.premiumEntitlementId]?.isActive ?? false;
      
      _isLoading = false;
      notifyListeners();
      return _isPremium;
    } catch (e) {
      debugPrint("Restore Purchases Error: $e");
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
