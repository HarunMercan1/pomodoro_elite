import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../core/constants/revenuecat_constants.dart';
import '../providers/purchase_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_fonts.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  static const _diamond = Color(0xFF38BDF8);
  static const _sapphire = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final purchaseProvider = context.watch<PurchaseProvider>();
    final offers = _extractOffers(purchaseProvider.offerings);
    final textColor = themeProvider.settingsTextColor;
    final mutedColor = textColor.withValues(alpha: 0.62);
    final isBusy = purchaseProvider.isLoading;

    return Scaffold(
      backgroundColor: themeProvider.settingsBgColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: themeProvider.settingsBgColor,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: textColor,
        ),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            purchaseProvider.isPremium
                ? 'premium_active'.tr()
                : 'get_premium'.tr(),
            style: AppFonts.poppins(
              context: context,
              color: _diamond,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: -110,
            left: -90,
            child: _GlowOrb(color: _diamond.withValues(alpha: 0.13)),
          ),
          Positioned(
            top: 260,
            right: -130,
            child: _GlowOrb(
              color: const Color(0xFF818CF8).withValues(alpha: 0.10),
              size: 280,
            ),
          ),
          SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontal = constraints.maxWidth >= 700 ? 32.0 : 18.0;
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding:
                          EdgeInsets.fromLTRB(horizontal, 12, horizontal, 36),
                      sliver: SliverToBoxAdapter(
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 680),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _PremiumHero(
                                  isPremium: purchaseProvider.isPremium,
                                  textColor: textColor,
                                ),
                                const SizedBox(height: 18),
                                if (!purchaseProvider.isPremium) ...[
                                  _PremiumPurchaseCard(
                                    package: offers.premium,
                                    isBusy: isBusy,
                                    textColor: textColor,
                                    mutedColor: mutedColor,
                                    onPurchase: offers.premium == null
                                        ? null
                                        : () => _purchase(
                                              context,
                                              offers.premium!,
                                            ),
                                  ),
                                  const SizedBox(height: 8),
                                  Center(
                                    child: TextButton.icon(
                                      onPressed: isBusy
                                          ? null
                                          : () => _restore(context),
                                      icon: const Icon(
                                        Icons.restore_rounded,
                                        size: 18,
                                      ),
                                      label: Text('restore_purchases_btn'.tr()),
                                      style: TextButton.styleFrom(
                                        foregroundColor: mutedColor,
                                        textStyle: AppFonts.poppins(
                                          context: context,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (offers.support.isNotEmpty) ...[
                                  const SizedBox(height: 26),
                                  _SectionHeading(
                                    title: 'support_developer'.tr(),
                                    subtitle: 'support_desc'.tr(),
                                    textColor: textColor,
                                    mutedColor: mutedColor,
                                  ),
                                  const SizedBox(height: 16),
                                  ...offers.support.map(
                                    (offer) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _SupportCard(
                                        offer: offer,
                                        enabled: !isBusy,
                                        textColor: textColor,
                                        onTap: () =>
                                            _purchase(context, offer.package),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          if (isBusy && offers.premium != null)
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: themeProvider.settingsBgColor.withValues(alpha: 0.18),
                ),
              ),
            ),
        ],
      ),
    );
  }

  _PremiumOffers _extractOffers(Offerings? offerings) {
    Package? premium;
    final support = <_SupportOffer>[];
    final seenProducts = <String>{};

    for (final package
        in offerings?.current?.availablePackages ?? <Package>[]) {
      final packageId = package.identifier;
      final productId = package.storeProduct.identifier;
      if (!seenProducts.add(productId)) continue;

      if (RevenueCatConstants.isPremiumPackage(
        packageIdentifier: packageId,
        productIdentifier: productId,
      )) {
        premium = package;
        continue;
      }

      if (!RevenueCatConstants.isSupportPackage(
        packageIdentifier: packageId,
        productIdentifier: productId,
      )) {
        continue;
      }

      final detectedTier = RevenueCatConstants.supportTierFor(
        packageIdentifier: packageId,
        productIdentifier: productId,
      );
      support.add(_SupportOffer(package: package, tier: detectedTier));
    }

    support.sort(
      (a, b) => a.package.storeProduct.price.compareTo(
        b.package.storeProduct.price,
      ),
    );

    // RevenueCat özel package identifier'ı kullanıyorsa bile fiyat sırası
    // Yıldız -> Süper -> Mega isimlerini deterministik tutar.
    for (var index = 0; index < support.length; index++) {
      support[index] = support[index].withFallbackTier(
        switch (index) {
          0 => SupportTier.star,
          1 => SupportTier.superStar,
          _ => SupportTier.megaStar,
        },
      );
    }

    support.sort((a, b) => a.tier.index.compareTo(b.tier.index));
    return _PremiumOffers(premium: premium, support: support);
  }

  Future<void> _purchase(BuildContext context, Package package) async {
    final outcome =
        await context.read<PurchaseProvider>().purchasePackage(package);
    if (!context.mounted) return;

    final presentation = switch (outcome) {
      PurchaseOutcome.purchased => (
          'thanks_title',
          'purchase_success',
          Icons.check_circle_rounded,
          const Color(0xFF22C55E),
        ),
      PurchaseOutcome.restored => (
          'purchase_restored_title',
          'purchase_restored_after_owned',
          Icons.verified_rounded,
          const Color(0xFF22C55E),
        ),
      PurchaseOutcome.cancelled => (
          'purchase_cancelled_title',
          'purchase_cancelled',
          Icons.close_rounded,
          const Color(0xFF94A3B8),
        ),
      PurchaseOutcome.pending => (
          'purchase_pending_title',
          'purchase_pending_desc',
          Icons.hourglass_top_rounded,
          const Color(0xFFF59E0B),
        ),
      PurchaseOutcome.alreadyOwnedButInactive => (
          'play_account_sync_title',
          'play_account_sync_desc',
          Icons.sync_problem_rounded,
          const Color(0xFFF59E0B),
        ),
      PurchaseOutcome.ownedByAnotherAppAccount => (
          'purchase_account_conflict_title',
          'purchase_account_conflict_desc',
          Icons.manage_accounts_rounded,
          const Color(0xFFF59E0B),
        ),
      PurchaseOutcome.storeUnavailable => (
          'store_unavailable_title',
          'store_unavailable_desc',
          Icons.cloud_off_rounded,
          const Color(0xFFF59E0B),
        ),
      PurchaseOutcome.failed => (
          'transaction_failed',
          'purchase_failed_desc',
          Icons.error_outline_rounded,
          const Color(0xFFF43F5E),
        ),
    };

    _showResultDialog(
      context,
      title: presentation.$1.tr(),
      message: presentation.$2.tr(),
      icon: presentation.$3,
      color: presentation.$4,
    );
  }

  Future<void> _restore(BuildContext context) async {
    final success = await context.read<PurchaseProvider>().restorePurchases();
    if (!context.mounted) return;

    _showResultDialog(
      context,
      title: success ? 'success_title'.tr() : 'not_found_title'.tr(),
      message: success ? 'restore_success'.tr() : 'restore_not_found'.tr(),
      icon: success ? Icons.restore_rounded : Icons.search_off_rounded,
      color: success ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
    );
  }

  void _showResultDialog(
    BuildContext context, {
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final theme = dialogContext.read<ThemeProvider>();
        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.settingsBgColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: color.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.16),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 36),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppFonts.poppins(
                    context: dialogContext,
                    color: theme.settingsTextColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppFonts.poppins(
                    context: dialogContext,
                    color: theme.settingsTextColor.withValues(alpha: 0.68),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'ok_btn'.tr(),
                      style: AppFonts.poppins(
                        context: dialogContext,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero({required this.isPremium, required this.textColor});

  final bool isPremium;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final features = <(IconData, String)>[
      (Icons.block_rounded, 'premium_feature_ads'.tr()),
      (Icons.palette_rounded, 'premium_feature_themes'.tr()),
      (Icons.bolt_rounded, 'premium_feature_updates'.tr()),
      (Icons.favorite_rounded, 'premium_feature_support'.tr()),
    ];

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF64748B),
            Color(0xFF1D4ED8),
            Color(0xFF082F49),
          ],
          stops: [0.0, 0.46, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        border:
            Border.all(color: const Color(0xFFE2E8F0).withValues(alpha: 0.46)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.28),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: const Color(0xFFE2E8F0).withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(-5, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF67E8F9),
                      Color(0xFF38BDF8),
                      Color(0xFF2563EB)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF38BDF8).withValues(alpha: 0.38),
                      blurRadius: 22,
                    ),
                  ],
                ),
                child: const Icon(Icons.diamond_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium
                          ? 'premium_active'.tr()
                          : 'premium_subtitle'.tr(),
                      style: AppFonts.poppins(
                        context: context,
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      isPremium ? 'premium_thanks'.tr() : 'premium_desc'.tr(),
                      style: AppFonts.poppins(
                        context: context,
                        color: const Color(0xFFCBD5E1),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              // Natural-height pills let long translations wrap instead of
              // truncating. Two columns stay compact on phones; only extremely
              // narrow accessibility layouts fall back to a single column.
              final columns = constraints.maxWidth >= 240 ? 2 : 1;
              const spacing = 9.0;
              final itemWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final feature in features)
                    SizedBox(
                      width: itemWidth,
                      child: _FeaturePill(
                        icon: feature.$1,
                        label: feature.$2,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF7DD3FC), size: 17),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppFonts.poppins(
                context: context,
                color: const Color(0xFFE2E8F0),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumPurchaseCard extends StatelessWidget {
  const _PremiumPurchaseCard({
    required this.package,
    required this.isBusy,
    required this.textColor,
    required this.mutedColor,
    required this.onPurchase,
  });

  final Package? package;
  final bool isBusy;
  final Color textColor;
  final Color mutedColor;
  final VoidCallback? onPurchase;

  @override
  Widget build(BuildContext context) {
    if (package == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: textColor.withValues(alpha: 0.045),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: textColor.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: _PremiumScreenState._diamond),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'packages_loading'.tr(),
                style: AppFonts.poppins(
                    context: context, color: mutedColor, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_PremiumScreenState._diamond, _PremiumScreenState._sapphire],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: _PremiumScreenState._diamond.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBusy ? null : onPurchase,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: isBusy
                      ? const Padding(
                          padding: EdgeInsets.all(13),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.diamond_rounded,
                          color: Colors.white, size: 27),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'get_unlimited_premium'.tr(),
                        style: AppFonts.poppins(
                          context: context,
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        package!.storeProduct.priceString,
                        style: AppFonts.poppins(
                          context: context,
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.subtitle,
    required this.textColor,
    required this.mutedColor,
  });

  final String title;
  final String subtitle;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFCBD5E1), Color(0xFF38BDF8)],
                ),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: AppFonts.poppins(
                  context: context,
                  color: textColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            subtitle,
            style: AppFonts.poppins(
              context: context,
              color: mutedColor,
              fontSize: 13,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.offer,
    required this.enabled,
    required this.textColor,
    required this.onTap,
  });

  final _SupportOffer offer;
  final bool enabled;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _TierVisual.forTier(offer.tier);
    return AnimatedOpacity(
      opacity: enabled ? 1 : 0.55,
      duration: const Duration(milliseconds: 180),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              visual.colors.first.withValues(alpha: 0.16),
              visual.colors.last.withValues(alpha: 0.045),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border:
              Border.all(color: visual.colors.first.withValues(alpha: 0.40)),
          boxShadow: [
            BoxShadow(
              color: visual.colors.last.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: BorderRadius.circular(22),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: visual.colors,
                      ),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: visual.colors.last.withValues(alpha: 0.30),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(visual.icon, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          visual.translationKey.tr(),
                          style: AppFonts.poppins(
                            context: context,
                            color: textColor,
                            fontSize: 15.5,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: visual.colors.first.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  visual.colors.first.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Text(
                            offer.package.storeProduct.priceString,
                            style: AppFonts.poppins(
                              context: context,
                              color: visual.priceColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.color, this.size = 240});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color, blurRadius: 90, spreadRadius: 32)
          ],
        ),
      ),
    );
  }
}

class _PremiumOffers {
  const _PremiumOffers({required this.premium, required this.support});

  final Package? premium;
  final List<_SupportOffer> support;
}

class _SupportOffer {
  const _SupportOffer({required this.package, required SupportTier? tier})
      : _tier = tier;

  final Package package;
  final SupportTier? _tier;

  SupportTier get tier => _tier ?? SupportTier.star;

  _SupportOffer withFallbackTier(SupportTier fallback) => _SupportOffer(
        package: package,
        tier: _tier ?? fallback,
      );
}

class _TierVisual {
  const _TierVisual({
    required this.translationKey,
    required this.icon,
    required this.colors,
    required this.priceColor,
  });

  final String translationKey;
  final IconData icon;
  final List<Color> colors;
  final Color priceColor;

  static _TierVisual forTier(SupportTier tier) => switch (tier) {
        SupportTier.star => const _TierVisual(
            translationKey: 'star_supporter',
            icon: Icons.star_rounded,
            colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
            priceColor: Color(0xFFFBBF24),
          ),
        SupportTier.superStar => const _TierVisual(
            translationKey: 'super_supporter',
            icon: Icons.auto_awesome_rounded,
            colors: [Color(0xFF60A5FA), Color(0xFF4F46E5)],
            priceColor: Color(0xFF818CF8),
          ),
        SupportTier.megaStar => const _TierVisual(
            translationKey: 'mega_supporter',
            icon: Icons.diamond_rounded,
            colors: [Color(0xFF67E8F9), Color(0xFF0284C7)],
            priceColor: Color(0xFF22D3EE),
          ),
      };
}
