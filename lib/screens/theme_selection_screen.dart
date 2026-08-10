import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/theme_provider.dart';
import '../providers/ad_manager.dart';
import '../providers/auth_provider.dart';
import '../utils/app_fonts.dart';
import 'premium_screen.dart';

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdManager>().loadRewardedAd();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final adManager = context.watch<AdManager>();

    return Scaffold(
      backgroundColor: themeProvider.settingsBgColor,
      appBar: AppBar(
        title: Text(
          'theme_settings'.tr(),
          style: AppFonts.poppins(
            context: context,
            fontWeight: FontWeight.bold,
            color: themeProvider.settingsTextColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: themeProvider.settingsTextColor,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Scrollbar(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            itemCount: AppThemes.all.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final theme = AppThemes.all[index];
              final isSelected = themeProvider.currentThemeId == theme.id;
              final isUnlocked = themeProvider.isThemeAvailable(theme.id);

              return _ThemeCard(
                theme: theme,
                isSelected: isSelected,
                isUnlocked: isUnlocked,
                onTap: () async => _handleThemeTap(
                  context,
                  theme,
                  isUnlocked,
                  themeProvider,
                  adManager,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleThemeTap(
    BuildContext context,
    AppTheme theme,
    bool isUnlocked,
    ThemeProvider themeProvider,
    AdManager adManager,
  ) {
    if (isUnlocked) {
      return themeProvider.selectTheme(theme.id);
    } else {
      _showUnlockDialog(context, theme, themeProvider, adManager);
      return Future<void>.value();
    }
  }

  void _showUnlockDialog(
    BuildContext context,
    AppTheme theme,
    ThemeProvider themeProvider,
    AdManager adManager,
  ) {
    if (context.read<ThemeProvider>().hasPremiumAccess) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.62),
      builder: (sheetContext) => _LockedThemeSheet(
        theme: theme,
        isAdReady: adManager.isRewardedAdReady,
        onClose: () => Navigator.pop(sheetContext),
        onPremiumTap: () {
          Navigator.pop(sheetContext);
          final isGuest = context.read<AuthProvider>().isGuest;
          if (isGuest) {
            showDialog<void>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text('login_required'.tr()),
                content: Text('premium_login_required_desc'.tr()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: Text('ok_btn'.tr()),
                  ),
                ],
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const PremiumScreen(),
              ),
            );
          }
        },
        onWatchAdTap: () async {
          Navigator.pop(sheetContext);
          final success = await adManager.showRewardedAd(
            onRewardEarned: () async {
              await themeProvider.unlockTheme(theme.id);
              if (context.mounted) {
                final snackBackground = theme.focus.effectiveMenuButtonColor;
                final snackForeground =
                    theme.focus.effectiveMenuButtonTextColor;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    content: Row(
                      children: [
                        Icon(Icons.lock_open_rounded, color: snackForeground),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${'theme_name_${theme.id}'.tr()} ${"theme_unlocked_72h".tr()}',
                            style: TextStyle(color: snackForeground),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: snackBackground,
                  ),
                );
              }
            },
          );
          if (!success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                content: Row(
                  children: [
                    const Icon(
                      Icons.hourglass_empty_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ad_loading'.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF7C2D12),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }
}

class _LockedThemeSheet extends StatelessWidget {
  final AppTheme theme;
  final bool isAdReady;
  final VoidCallback onClose;
  final VoidCallback onPremiumTap;
  final Future<void> Function() onWatchAdTap;

  const _LockedThemeSheet({
    required this.theme,
    required this.isAdReady,
    required this.onClose,
    required this.onPremiumTap,
    required this.onWatchAdTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseSurface = theme.settingsCardColor ?? theme.idle.bgColor;
    final pageSurface = theme.settingsBgColor ?? theme.idle.bgColor;
    final surface = Color.lerp(baseSurface, pageSurface, 0.28) ?? baseSurface;
    final primaryText = _foregroundFor(surface);
    final secondaryText = primaryText.withValues(alpha: 0.66);
    final accent = ThemeContrast.ensure(
      foreground: theme.focus.accentColor,
      background: surface,
      minimumRatio: 3.2,
    );
    final accentText = _foregroundFor(accent);

    return Material(
      color: surface,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          9,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: primaryText.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: primaryText.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: primaryText.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Icon(
                        Icons.lock_outline_rounded,
                        color: accent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'theme_name_${theme.id}'.tr(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.poppins(
                              context: context,
                              color: primaryText,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'theme_vibe_${theme.id}'.tr(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppFonts.poppins(
                              context: context,
                              color: secondaryText,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryText.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: onClose,
                        color: secondaryText,
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.close_rounded, size: 21),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ThemeHeroPreview(theme: theme),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: primaryText.withValues(alpha: 0.055),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryText.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: accent,
                        size: 19,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'unlock_theme_msg'.tr(),
                          style: AppFonts.poppins(
                            context: context,
                            color: secondaryText,
                            fontSize: 12,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: onPremiumTap,
                    icon: const Icon(Icons.diamond_outlined, size: 21),
                    label: Text(
                      'unlock_premium'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: accentText,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: onWatchAdTap,
                    icon: Icon(
                      isAdReady
                          ? Icons.play_circle_fill_rounded
                          : Icons.hourglass_top_rounded,
                    ),
                    label: Text(
                      'watch_ad'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryText,
                      backgroundColor: primaryText.withValues(alpha: 0.035),
                      side: BorderSide(
                        color: primaryText.withValues(alpha: 0.16),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeHeroPreview extends StatelessWidget {
  final AppTheme theme;

  const _ThemeHeroPreview({required this.theme});

  @override
  Widget build(BuildContext context) {
    final focus = theme.focus;
    final background = _previewBackground(focus);
    final foreground = ThemeContrast.ensure(
      foreground: focus.textColor,
      background: background,
      minimumRatio: 4.5,
    );
    final accent = ThemeContrast.ensure(
      foreground: focus.accentColor,
      background: background,
      minimumRatio: 3,
    );
    final previewGradient = focus.gradient ??
        LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            focus.bgColor,
            Color.lerp(focus.bgColor, focus.accentColor, 0.28) ?? focus.bgColor,
          ],
        );

    return Container(
      height: 148,
      decoration: BoxDecoration(
        gradient: previewGradient,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: foreground.withValues(alpha: 0.13)),
        boxShadow: [
          BoxShadow(
            color: focus.accentColor.withValues(alpha: 0.16),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -72,
            right: -48,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: foreground.withValues(alpha: 0.07),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: foreground.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bolt_rounded,
                              color: accent,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'focus'.tr(),
                              style: AppFonts.poppins(
                                context: context,
                                color: foreground.withValues(alpha: 0.88),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '25:00',
                        style: AppFonts.poppins(
                          context: context,
                          color: foreground,
                          fontSize: 31,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: SizedBox(
                          width: 126,
                          height: 4,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              ColoredBox(
                                color: foreground.withValues(alpha: 0.16),
                              ),
                              FractionallySizedBox(
                                widthFactor: 0.68,
                                alignment: Alignment.centerLeft,
                                child: ColoredBox(color: accent),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: foreground.withValues(alpha: 0.08),
                    border: Border.all(
                      color: accent.withValues(alpha: 0.72),
                      width: 2,
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: _foregroundFor(accent),
                      size: 29,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppTheme theme;
  final bool isSelected;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = _ThemeCardPalette.fromTheme(theme);
    final themeName = 'theme_name_${theme.id}'.tr();
    final themeVibe = 'theme_vibe_${theme.id}'.tr();

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$themeName, $themeVibe',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          splashColor: palette.accent.withValues(alpha: 0.12),
          highlightColor: palette.accent.withValues(alpha: 0.06),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            constraints: const BoxConstraints(minHeight: 88),
            padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [palette.surfaceStart, palette.surfaceEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isSelected
                    ? palette.accent
                    : palette.border.withValues(alpha: 0.38),
                width: isSelected ? 1.8 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: palette.accent.withValues(alpha: 0.20),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Row(
              children: [
                _ThemeSwatch(theme: theme, size: 62),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        themeName,
                        style: AppFonts.poppins(
                          context: context,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: palette.primaryText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        themeVibe,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.28,
                          color: palette.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _ThemeStatusIcon(
                  isSelected: isSelected,
                  isUnlocked: isUnlocked,
                  palette: palette,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeSwatch extends StatelessWidget {
  final AppTheme theme;
  final double size;

  const _ThemeSwatch({
    required this.theme,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final idle = _previewBackground(theme.idle);
    final focus = _previewBackground(theme.focus);
    final rest = _previewBackground(theme.breakState);
    final foreground = ThemeContrast.ensure(
      foreground: theme.focus.textColor,
      background: focus,
      minimumRatio: 4.5,
    );
    final accent = ThemeContrast.ensure(
      foreground: theme.focus.accentColor,
      background: focus,
      minimumRatio: 3,
    );

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [idle, focus, rest],
          stops: const [0, 0.56, 1],
        ),
        borderRadius: BorderRadius.circular(size * 0.30),
        border: Border.all(
          color: foreground.withValues(alpha: 0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.focus.accentColor.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -size * 0.28,
            right: -size * 0.24,
            child: Container(
              width: size * 0.82,
              height: size * 0.82,
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.09),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Container(
              width: size * 0.56,
              height: size * 0.56,
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.07),
                shape: BoxShape.circle,
                border: Border.all(
                  color: accent.withValues(alpha: 0.86),
                  width: size * 0.045,
                ),
              ),
              child: Icon(
                Icons.timer_outlined,
                color: foreground,
                size: size * 0.25,
              ),
            ),
          ),
          Positioned(
            left: size * 0.20,
            right: size * 0.20,
            bottom: size * 0.11,
            child: Container(
              height: size * 0.045,
              decoration: BoxDecoration(
                color: foreground.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeStatusIcon extends StatelessWidget {
  final bool isSelected;
  final bool isUnlocked;
  final _ThemeCardPalette palette;

  const _ThemeStatusIcon({
    required this.isSelected,
    required this.isUnlocked,
    required this.palette,
  });

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Icon(
        Icons.check_circle_rounded,
        color: palette.accent,
        size: 28,
        shadows: [
          Shadow(
            color: palette.accent.withValues(alpha: 0.42),
            blurRadius: 10,
          ),
        ],
      );
    }

    if (!isUnlocked) {
      return Icon(
        Icons.lock_rounded,
        color: palette.primaryText.withValues(alpha: 0.78),
        size: 22,
      );
    }

    return Icon(
      Icons.chevron_right_rounded,
      color: palette.primaryText.withValues(alpha: 0.56),
      size: 26,
    );
  }
}

class _ThemeCardPalette {
  final Color surfaceStart;
  final Color surfaceEnd;
  final Color primaryText;
  final Color secondaryText;
  final Color accent;
  final Color border;

  const _ThemeCardPalette({
    required this.surfaceStart,
    required this.surfaceEnd,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.border,
  });

  factory _ThemeCardPalette.fromTheme(AppTheme theme) {
    final surfaceStart = theme.settingsCardColor ?? theme.idle.bgColor;
    final surfaceEnd =
        Color.lerp(surfaceStart, theme.focus.bgColor, 0.13) ?? surfaceStart;
    final surfaceSample =
        Color.lerp(surfaceStart, surfaceEnd, 0.5) ?? surfaceStart;
    final primaryText = _foregroundFor(surfaceSample);
    final accentBackground =
        ThemeContrast.ratio(theme.idle.accentColor, surfaceStart) <=
                ThemeContrast.ratio(theme.idle.accentColor, surfaceEnd)
            ? surfaceStart
            : surfaceEnd;
    final accent = ThemeContrast.ensure(
      foreground: theme.idle.accentColor,
      background: accentBackground,
      minimumRatio: 3.2,
    );

    return _ThemeCardPalette(
      surfaceStart: surfaceStart,
      surfaceEnd: surfaceEnd,
      primaryText: primaryText,
      secondaryText: primaryText.withValues(alpha: 0.75),
      accent: accent,
      border: theme.settingsBorderColor ?? accent,
    );
  }
}

Color _previewBackground(ThemeStateColors state) {
  final gradient = state.gradientColors;
  if (gradient == null || gradient.length < 2) return state.bgColor;
  return Color.lerp(gradient.first, gradient.last, 0.5) ?? state.bgColor;
}

Color _foregroundFor(Color background) {
  return background.computeLuminance() > 0.179
      ? const Color(0xFF101318)
      : const Color(0xFFFFFFFF);
}
