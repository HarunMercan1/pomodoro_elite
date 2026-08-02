import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/app_fonts.dart';

/// Shared, theme-aware building blocks for the settings flow.
///
/// Keeping the layout primitives here makes the settings pages feel like one
/// coherent surface while each page remains responsible for its own state.
class SettingsSurface extends StatelessWidget {
  const SettingsSurface({
    super.key,
    required this.color,
    required this.borderColor,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.radius = 20,
  });

  final Color color;
  final Color borderColor;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SettingsNavigationTile extends StatelessWidget {
  const SettingsNavigationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.textColor,
    required this.accentColor,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.iconColor,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 11,
    ),
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color textColor;
  final Color accentColor;
  final Color? iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? accentColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: contentPadding,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: effectiveIconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: effectiveIconColor, size: 21),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppFonts.poppins(
                        context: context,
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppFonts.poppins(
                          context: context,
                          color: textColor.withValues(alpha: 0.62),
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              trailing ??
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: textColor.withValues(alpha: 0.52),
                    size: 16,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsDivider extends StatelessWidget {
  const SettingsDivider({super.key, required this.color, this.indent = 67});

  final Color color;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: indent,
      endIndent: 14,
      color: color.withValues(alpha: color.a * 0.52),
    );
  }
}

class SettingsSectionLabel extends StatelessWidget {
  const SettingsSectionLabel({
    super.key,
    required this.title,
    required this.color,
  });

  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
      child: Text(
        title,
        style: AppFonts.poppins(
          context: context,
          color: color.withValues(alpha: 0.68),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class SettingsLockNotice extends StatelessWidget {
  const SettingsLockNotice({
    super.key,
    required this.message,
    required this.textColor,
  });

  final String message;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    const warning = Color(0xFFF59E0B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: warning.withValues(alpha: 0.42)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppFonts.poppins(
                context: context,
                color: textColor,
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Constrains a native banner to its real dimensions so it cannot bleed into
/// another route or get pinned to the screen edge on narrow devices.
class SettingsAdBanner extends StatelessWidget {
  const SettingsAdBanner({
    super.key,
    required this.ad,
    required this.isLoaded,
    this.enabled = true,
  });

  final BannerAd? ad;
  final bool isLoaded;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final banner = ad;
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    if (!enabled || !isLoaded || banner == null || !isCurrentRoute) {
      return const SizedBox.shrink();
    }

    final width = banner.size.width.toDouble();
    final height = banner.size.height.toDouble();
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(top: 12, bottom: 8),
      child: ClipRect(
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Center(
            child: SizedBox(
              key: ValueKey(banner),
              width: width,
              height: height,
              child: AdWidget(ad: banner),
            ),
          ),
        ),
      ),
    );
  }
}
