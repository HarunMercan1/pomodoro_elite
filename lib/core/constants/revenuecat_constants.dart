enum SupportTier { star, superStar, megaStar }

class RevenueCatConstants {
  static const String appleApiKey = ''; // iOS için eklendiğinde doldurulacak
  static const String googleApiKey = 'goog_qFApiHaYysiCThjiXMohpGxBopg';

  // RevenueCat Entitlement ID for Premium
  static const String premiumEntitlementId = 'premium_lifetime';

  // Google Play one-time product IDs.
  static const String premiumProductId = 'premium_lifetime';
  static const String starSupportProductId = 'tip_star';
  static const String superStarSupportProductId = 'tip_super_star';

  static const String megaStarSupportProductId = 'tip_mega_star';
  static const String legacyMegaStarSupportProductId = 'ip_mega_star';

  static const Set<String> supportProductIds = {
    starSupportProductId,
    superStarSupportProductId,
    megaStarSupportProductId,
    legacyMegaStarSupportProductId,
  };

  static bool isPremiumPackage({
    required String packageIdentifier,
    required String productIdentifier,
  }) {
    final packageId = packageIdentifier.toLowerCase();
    final productId = productIdentifier.toLowerCase();

    return packageId == r'$rc_lifetime' ||
        packageId.contains('premium') ||
        productId == premiumProductId ||
        productId.contains('premium');
  }

  static bool isSupportPackage({
    required String packageIdentifier,
    required String productIdentifier,
  }) {
    final packageId = packageIdentifier.toLowerCase();
    final productId = productIdentifier.toLowerCase();

    return supportProductIds.contains(productId) ||
        packageId.contains('tip') ||
        packageId.contains('support') ||
        packageId.contains('mega') ||
        productId.contains('tip') ||
        productId.contains('support') ||
        productId.contains('mega');
  }

  static bool isMegaSupportPackage({
    required String packageIdentifier,
    required String productIdentifier,
  }) {
    return supportTierFor(
          packageIdentifier: packageIdentifier,
          productIdentifier: productIdentifier,
        ) ==
        SupportTier.megaStar;
  }

  static SupportTier? supportTierFor({
    required String packageIdentifier,
    required String productIdentifier,
  }) {
    final packageId = packageIdentifier.toLowerCase();
    final productId = productIdentifier.toLowerCase();
    final identity = '$packageId $productId';

    // En özel eşleşmeler önce kontrol edilir. Aksi halde "tip_mega_star"
    // içindeki "star" ifadesi Mega paketini yanlışlıkla Yıldız yapabilir.
    if (identity.contains('mega') ||
        productId == legacyMegaStarSupportProductId) {
      return SupportTier.megaStar;
    }
    if (identity.contains('super')) return SupportTier.superStar;
    if (productId == starSupportProductId ||
        packageId == starSupportProductId ||
        identity.contains('tip_star')) {
      return SupportTier.star;
    }
    return null;
  }
}
