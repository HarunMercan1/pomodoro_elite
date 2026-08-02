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
    // If premium, it shouldn't even reach here, but just in case:
    if (context.read<ThemeProvider>().hasPremiumAccess) return;
    showDialog(
      context: context,
      builder: (ctx) {
        final dialogSurface = theme.settingsCardColor ?? theme.idle.bgColor;
        final dialogText = _foregroundFor(dialogSurface);
        final dialogMuted = dialogText.withValues(alpha: 0.75);
        final dialogAccent = ThemeContrast.ensure(
          foreground: theme.idle.accentColor,
          background: dialogSurface,
        );

        return AlertDialog(
          backgroundColor: dialogSurface,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
          contentPadding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
          actionsPadding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: dialogAccent.withValues(alpha: 0.58),
            ),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: dialogAccent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: _foregroundFor(dialogAccent),
                  size: 22,
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
                      style: TextStyle(
                        color: dialogText,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'theme_vibe_${theme.id}'.tr(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: dialogMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: _ThemeStatePreview(theme: theme, size: 78)),
              const SizedBox(height: 18),
              Text(
                'unlock_theme_msg'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(color: dialogMuted, fontSize: 14),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.maxFinite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      final isGuest = context.read<AuthProvider>().isGuest;
                      if (isGuest) {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('login_required'.tr()),
                            content: Text('premium_login_required_desc'.tr()),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('ok_btn'.tr()),
                              ),
                            ],
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PremiumScreen(),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.workspace_premium_rounded),
                    label: Text(
                      'unlock_premium'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC400),
                      foregroundColor: const Color(0xFF211800),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final success = await adManager.showRewardedAd(
                        onRewardEarned: () async {
                          await themeProvider.unlockTheme(theme.id);
                          if (context.mounted) {
                            final snackBackground =
                                theme.focus.effectiveMenuButtonColor;
                            final snackForeground =
                                theme.focus.effectiveMenuButtonTextColor;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                content: Row(
                                  children: [
                                    Icon(Icons.lock_open_rounded,
                                        color: snackForeground),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${'theme_name_${theme.id}'.tr()} ${"theme_unlocked_72h".tr()}',
                                        style:
                                            TextStyle(color: snackForeground),
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
                                const Icon(Icons.hourglass_empty_rounded,
                                    color: Colors.white),
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
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: Text('watch_ad'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.focus.effectiveButtonBg,
                      foregroundColor: theme.focus.effectiveButtonTextColor,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(foregroundColor: dialogMuted),
                    child: Text('cancel'.tr()),
                  ),
                ],
              ),
            ),
          ],
        );
      },
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
                _ThemeStatePreview(theme: theme, size: 62),
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

class _ThemeStatePreview extends StatelessWidget {
  final AppTheme theme;
  final double size;

  const _ThemeStatePreview({
    required this.theme,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final idle = _previewBackground(theme.idle);
    final focus = _previewBackground(theme.focus);
    final rest = _previewBackground(theme.breakState);
    final center = Color.lerp(focus, rest, 0.5) ?? focus;
    final iconColor = ThemeContrast.ensure(
      foreground: theme.focus.textColor,
      background: center,
      minimumRatio: 4.5,
    );

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            colors: [
              idle,
              theme.idle.accentColor,
              focus,
              theme.focus.accentColor,
              rest,
              theme.breakState.accentColor,
              idle,
            ],
          ),
          border: Border.all(
            color: iconColor.withValues(alpha: 0.28),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.idle.accentColor.withValues(alpha: 0.30),
              blurRadius: 16,
              spreadRadius: -2,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: ClipOval(
            child: Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, -0.4),
                      radius: 1.05,
                      colors: [
                        Colors.white.withValues(alpha: 0.34),
                        center.withValues(alpha: 0.76),
                        idle,
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -12,
                  right: -9,
                  child: Container(
                    width: size * 0.56,
                    height: size * 0.56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          theme.focus.accentColor.withValues(alpha: 0.72),
                          theme.focus.accentColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -10,
                  bottom: -15,
                  child: Container(
                    width: size * 0.62,
                    height: size * 0.62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          theme.breakState.accentColor.withValues(alpha: 0.64),
                          theme.breakState.accentColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: size * 0.47,
                    height: size * 0.47,
                    decoration: BoxDecoration(
                      color: center.withValues(alpha: 0.52),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: iconColor.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Icon(
                      Icons.auto_awesome_rounded,
                      color: iconColor,
                      size: size * 0.24,
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
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: palette.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.check_rounded,
          color: palette.accentText,
          size: 20,
        ),
      );
    }

    if (!isUnlocked) {
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: palette.primaryText.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.lock_outline_rounded,
          color: palette.primaryText.withValues(alpha: 0.82),
          size: 19,
        ),
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
  final Color accentText;
  final Color border;

  const _ThemeCardPalette({
    required this.surfaceStart,
    required this.surfaceEnd,
    required this.primaryText,
    required this.secondaryText,
    required this.accent,
    required this.accentText,
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
      accentText: _foregroundFor(accent),
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
