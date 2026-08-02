import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import '../providers/ad_manager.dart';
import '../providers/auth_provider.dart';
import '../providers/purchase_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../services/ad_consent_service.dart';
import '../utils/app_fonts.dart';
import '../utils/live_page_route.dart';
import '../utils/text_normalization.dart';
import '../widgets/settings_components.dart';
import 'duration_settings_screen.dart';
import 'language_selection_screen.dart';
import 'premium_screen.dart';
import 'sound_settings_screen.dart';
import 'theme_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _isGuestConnectLoading = false;
  bool _allowPop = false;
  bool _isClosing = false;
  late AdManager _adManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBanner());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adManager = context.read<AdManager>();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      context.read<SettingsProvider>().stopPreview();
    }
  }

  @override
  void deactivate() {
    context.read<SettingsProvider>().stopPreview();
    super.deactivate();
  }

  @override
  void dispose() {
    try {
      _adManager.disposeSettingsBanner();
    } catch (error) {
      debugPrint('Settings banner dispose failed: $error');
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadBanner() async {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    await _adManager.loadSettingsBanner(MediaQuery.sizeOf(context).width);
  }

  /// Native AdWidget views must not stay mounted below another route. Disposing
  /// before every settings navigation also prevents theme changes on the next
  /// page from moving the old platform view over Flutter's surface.
  Future<void> _openSettingsPage(Widget page) async {
    _adManager.disposeSettingsBanner();
    // Let the Consumer remove AdWidget's native platform view before the next
    // route starts its transition. Otherwise it can survive for one frame and
    // intercept/repaint touches above the new route on some Android devices.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    await Navigator.of(context).push(
      livePageRoute<void>(
        builder: (_) => page,
      ),
    );
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBanner());
  }

  Future<void> _closeSettings() async {
    if (_isClosing) return;
    _isClosing = true;
    _adManager.disposeSettingsBanner();
    if (mounted) setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _connectGuestWithGoogle() async {
    if (_isGuestConnectLoading) return;
    setState(() => _isGuestConnectLoading = true);
    try {
      await context.read<AuthProvider>().signInWithGoogle();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('sign_in_error'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _isGuestConnectLoading = false);
    }
  }

  Future<void> _showPremiumLoginRequired() async {
    final shouldConnect = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (dialogContext) {
        final themeProvider = dialogContext.read<ThemeProvider>();
        final theme = themeProvider.currentTheme;
        final textColor = themeProvider.settingsTextColor;
        final surfaceColor = theme.settingsCardColor ?? const Color(0xFF172033);
        final borderColor = theme.settingsBorderColor ??
            const Color(0xFF38BDF8).withValues(alpha: 0.34);

        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SettingsSurface(
              color: surfaceColor,
              borderColor: borderColor,
              radius: 24,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF67E8F9), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(19),
                    ),
                    child: const Icon(
                      Icons.cloud_upload_rounded,
                      color: Colors.white,
                      size: 31,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'login_required'.tr(),
                    textAlign: TextAlign.center,
                    style: AppFonts.poppins(
                      context: dialogContext,
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'premium_login_required_desc'.tr(),
                    textAlign: TextAlign.center,
                    style: AppFonts.poppins(
                      context: dialogContext,
                      color: textColor.withValues(alpha: 0.68),
                      fontSize: 13,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      icon: const Icon(Icons.link_rounded, size: 19),
                      label: Text('guest_connect_google_title'.tr()),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: AppFonts.poppins(
                          context: dialogContext,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(
                      'cancel'.tr(),
                      style: AppFonts.poppins(
                        context: dialogContext,
                        color: textColor.withValues(alpha: 0.62),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (shouldConnect == true && mounted) {
      await _connectGuestWithGoogle();
    }
  }

  Future<void> _openPremium() async {
    if (context.read<AuthProvider>().isGuest) {
      await _showPremiumLoginRequired();
      return;
    }
    await _openSettingsPage(const PremiumScreen());
  }

  Future<void> _showPrivacyOptions() async {
    final consent = context.read<AdConsentService>();
    _adManager.disposeSettingsBanner();
    try {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      await consent.showPrivacyOptionsForm();
    } catch (error) {
      debugPrint('Privacy options form failed: $error');
    } finally {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadBanner());
      }
    }
  }

  Future<void> _rateApp() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.openStoreListing();
    }
  }

  Future<void> _showLogoutDialog({
    required AuthProvider auth,
    required Color surfaceColor,
    required Color itemColor,
    required Color borderColor,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: borderColor),
        ),
        title: Text(
          auth.isGuest ? 'exit_guest_mode_title'.tr() : 'log_out_title'.tr(),
          style: AppFonts.poppins(
            context: dialogContext,
            color: itemColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'log_out_confirm'.tr(),
          style: AppFonts.poppins(
            context: dialogContext,
            color: itemColor.withValues(alpha: 0.72),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'cancel'.tr(),
              style: AppFonts.poppins(
                context: dialogContext,
                color: itemColor.withValues(alpha: 0.65),
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('log_out'.tr()),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await auth.signOut();
        if (mounted) {
          _adManager.disposeSettingsBanner();
          setState(() => _allowPop = true);
          await WidgetsBinding.instance.endOfFrame;
        }
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      } catch (error, stackTrace) {
        debugPrint('Sign out failed: $error\n$stackTrace');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFFB91C1C),
              content: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'transaction_failed'.tr(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }
  }

  String _getLanguageName(String code) => switch (code) {
        'tr' => 'Türkçe',
        'en' => 'English',
        'es' => 'Español',
        'pt' => 'Português',
        'de' => 'Deutsch',
        'fr' => 'Français',
        'it' => 'Italiano',
        'ru' => 'Русский',
        'ja' => '日本語',
        'ko' => '한국어',
        'zh' => '中文',
        'hi' => 'हिन्दी',
        'ar' => 'العربية',
        'id' => 'Bahasa Indonesia',
        'vi' => 'Tiếng Việt',
        'bn' => 'বাংলা',
        'ur' => 'اردو',
        'pl' => 'Polski',
        'th' => 'ไทย',
        'nl' => 'Nederlands',
        'uk' => 'Українська',
        'el' => 'Ελληνικά',
        'sv' => 'Svenska',
        _ => 'English',
      };

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final auth = context.watch<AuthProvider>();
    final purchase = context.watch<PurchaseProvider>();
    final privacyRequired =
        context.watch<AdConsentService>().isPrivacyOptionsRequired;
    final theme = themeProvider.currentTheme;
    final backgroundColor = themeProvider.settingsBgColor;
    final itemColor = themeProvider.settingsTextColor;
    final cardColor = theme.settingsCardColor ?? const Color(0xFF202020);
    final borderColor =
        theme.settingsBorderColor ?? itemColor.withValues(alpha: 0.11);
    final accentColor = themeProvider.settingsAccentColor;

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeSettings();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: backgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: itemColor,
            onPressed: _closeSettings,
          ),
          title: Text(
            'settings_title'.tr(),
            style: AppFonts.poppins(
              context: context,
              color: itemColor,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final horizontal = constraints.maxWidth >= 600 ? 24.0 : 16.0;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 18),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!auth.isGuest) ...[
                        _ProfileHeader(
                          displayName: auth.displayName,
                          email: auth.user?.email ?? '',
                          avatarUrl: auth.avatarUrl,
                          textColor: itemColor,
                          accentColor: accentColor,
                        ),
                        const SizedBox(height: 12),
                      ] else ...[
                        _GuestConnectCard(
                          isLoading: _isGuestConnectLoading,
                          onTap: _connectGuestWithGoogle,
                        ),
                        const SizedBox(height: 12),
                      ],
                      _PremiumBanner(
                        isPremium: purchase.isPremium,
                        onTap: _openPremium,
                      ),
                      const SizedBox(height: 12),
                      SettingsSurface(
                        color: cardColor,
                        borderColor: borderColor,
                        child: Column(
                          children: [
                            SettingsNavigationTile(
                              icon: Icons.timer_outlined,
                              title: 'duration_settings'.tr(),
                              textColor: itemColor,
                              accentColor: accentColor,
                              onTap: () => _openSettingsPage(
                                const DurationSettingsScreen(),
                              ),
                            ),
                            SettingsDivider(color: borderColor),
                            SettingsNavigationTile(
                              icon: Icons.music_note_rounded,
                              title: 'sound_settings'.tr(),
                              subtitle: settings.isBackgroundMusicEnabled
                                  ? 'on'.tr()
                                  : 'off'.tr(),
                              textColor: itemColor,
                              accentColor: accentColor,
                              onTap: () => _openSettingsPage(
                                const SoundSettingsScreen(),
                              ),
                            ),
                            SettingsDivider(color: borderColor),
                            SettingsNavigationTile(
                              icon: Icons.palette_outlined,
                              title: 'theme_settings'.tr(),
                              subtitle: 'theme_name_${theme.id}'.tr(),
                              textColor: itemColor,
                              accentColor: accentColor,
                              onTap: () => _openSettingsPage(
                                const ThemeSelectionScreen(),
                              ),
                            ),
                            SettingsDivider(color: borderColor),
                            SettingsNavigationTile(
                              icon: Icons.language_rounded,
                              title: 'language_label'.tr(),
                              subtitle: _getLanguageName(
                                context.locale.languageCode,
                              ),
                              textColor: itemColor,
                              accentColor: accentColor,
                              onTap: () => _openSettingsPage(
                                const LanguageSelectionScreen(),
                              ),
                            ),
                            if (privacyRequired) ...[
                              SettingsDivider(color: borderColor),
                              SettingsNavigationTile(
                                icon: Icons.privacy_tip_outlined,
                                title: 'privacy_options'.tr(),
                                textColor: itemColor,
                                accentColor: accentColor,
                                onTap: _showPrivacyOptions,
                              ),
                            ],
                            SettingsDivider(color: borderColor),
                            SettingsNavigationTile(
                              icon: Icons.star_rounded,
                              title: 'rate_us'.tr(),
                              textColor: itemColor,
                              accentColor: accentColor,
                              iconColor: const Color(0xFFF59E0B),
                              onTap: _rateApp,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SettingsSurface(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                        borderColor:
                            const Color(0xFFEF4444).withValues(alpha: 0.55),
                        child: SettingsNavigationTile(
                          icon: Icons.logout_rounded,
                          title: auth.isGuest
                              ? 'exit_guest_mode'.tr()
                              : 'log_out'.tr(),
                          textColor: const Color(0xFFEF4444),
                          accentColor: const Color(0xFFEF4444),
                          trailing: const SizedBox.shrink(),
                          onTap: () => _showLogoutDialog(
                            auth: auth,
                            surfaceColor: cardColor,
                            itemColor: itemColor,
                            borderColor: borderColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      FutureBuilder<PackageInfo>(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) return const SizedBox.shrink();
                          return Center(
                            child: Text(
                              'v${snapshot.data!.version}',
                              style: AppFonts.poppins(
                                context: context,
                                color: itemColor.withValues(alpha: 0.46),
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                      Consumer<AdManager>(
                        builder: (context, adManager, _) => SettingsAdBanner(
                          enabled: adManager.canServeAds,
                          ad: adManager.settingsBannerAd,
                          isLoaded: adManager.isSettingsBannerLoaded,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.textColor,
    required this.accentColor,
  });

  final String displayName;
  final String email;
  final String? avatarUrl;
  final Color textColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: accentColor.withValues(alpha: 0.14),
            backgroundImage:
                avatarUrl == null ? null : NetworkImage(avatarUrl!),
            child: avatarUrl == null
                ? Icon(Icons.person_rounded, size: 25, color: accentColor)
                : null,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.poppins(
                    context: context,
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.poppins(
                      context: context,
                      color: textColor.withValues(alpha: 0.55),
                      fontSize: 12.5,
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

class _GuestConnectCard extends StatelessWidget {
  const _GuestConnectCard({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          strokeWidth: 2.3,
                          color: Colors.white,
                        )
                      : Image.asset('assets/icons/google.png'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'guest_connect_google_title'.tr(),
                        style: AppFonts.poppins(
                          context: context,
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'guest_connect_google_desc'.tr(),
                        style: AppFonts.poppins(
                          context: context,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11.5,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.isPremium, required this.onTap});

  final bool isPremium;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isPremium
              ? const [Color(0xFF64748B), Color(0xFF2563EB), Color(0xFF0891B2)]
              : const [Color(0xFF38BDF8), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.24),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.diamond_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        withoutLeadingPremiumEmoji(
                          (isPremium ? 'premium_active' : 'get_premium').tr(),
                        ),
                        maxLines: 2,
                        softWrap: true,
                        style: AppFonts.poppins(
                          context: context,
                          color: Colors.white,
                          fontSize: 15.5,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (!isPremium) ...[
                        const SizedBox(height: 2),
                        Text(
                          'premium_subtitle'.tr(),
                          style: AppFonts.poppins(
                            context: context,
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
