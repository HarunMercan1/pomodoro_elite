import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/settings_provider.dart';
// import '../providers/stats_provider.dart';
import '../providers/ad_manager.dart';
import 'duration_settings_screen.dart';
import 'sound_settings_screen.dart';
import 'theme_selection_screen.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_fonts.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:pomodoro_elite/screens/language_selection_screen.dart';
import 'package:pomodoro_elite/screens/premium_screen.dart';
import '../providers/purchase_provider.dart';
import '../services/ad_consent_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _isGuestConnectLoading = false;

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
        final theme = dialogContext.read<ThemeProvider>();
        final textColor = theme.settingsTextColor;
        final surfaceColor =
            theme.currentTheme.settingsCardColor ?? const Color(0xFF121A2A);

        return Dialog(
          elevation: 0,
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.38),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.24),
                  blurRadius: 36,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF67E8F9), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.34),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.cloud_upload_rounded,
                    color: Colors.white,
                    size: 38,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'login_required'.tr(),
                  textAlign: TextAlign.center,
                  style: AppFonts.poppins(
                    context: dialogContext,
                    color: textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'premium_login_required_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: AppFonts.poppins(
                    context: dialogContext,
                    color: textColor.withValues(alpha: 0.68),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    icon: const Icon(Icons.link_rounded),
                    label: Text('guest_connect_google_title'.tr()),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: AppFonts.poppins(
                        context: dialogContext,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
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
        );
      },
    );

    if (shouldConnect == true && mounted) {
      await _connectGuestWithGoogle();
    }
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'pt':
        return 'Português';
      case 'de':
        return 'Deutsch';
      case 'fr':
        return 'Français';
      case 'it':
        return 'Italiano';
      case 'ru':
        return 'Русский';
      case 'ja':
        return '日本語';
      case 'ko':
        return '한국어';
      case 'zh':
        return '中文';
      case 'hi':
        return 'हिन्दी';
      case 'ar':
        return 'العربية';
      case 'id':
        return 'Bahasa Indonesia';
      case 'vi':
        return 'Tiếng Việt';
      case 'bn':
        return 'বাংলা';
      case 'ur':
        return 'اردو';
      case 'pl':
        return 'Polski';
      case 'th':
        return 'ไทย';
      case 'nl':
        return 'Nederlands';
      case 'uk':
        return 'Укра\u0457нська';
      case 'el':
        return 'Ελληνικά';
      case 'sv':
        return 'Svenska';
      default:
        return 'English';
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 🔥 Adaptive banner reklamı yükle (ekran genişliği ile)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final width = MediaQuery.of(context).size.width;
      context.read<AdManager>().loadSettingsBanner(width);
    });
  }

  late AdManager _adManager;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adManager = context.read<AdManager>();
  }

  @override
  void dispose() {
    try {
      _adManager.disposeSettingsBanner();
    } catch (e) {
      debugPrint("SettingsScreen Dispose Hatası: $e");
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void deactivate() {
    context.read<SettingsProvider>().stopPreview();
    super.deactivate();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      context.read<SettingsProvider>().stopPreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.settingsBgColor,
      appBar: AppBar(
        title: Text(
          'settings_title'.tr(),
          style: AppFonts.poppins(
              context: context,
              fontWeight: FontWeight.w600,
              color: themeProvider.settingsTextColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: themeProvider.settingsTextColor,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // 🔥 Body: Column ile wrap edildi - Liste + Banner
      body: LayoutBuilder(builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final double hPadding = isTablet ? 40 : 20;
        final double vPadding = isTablet ? 30 : 20;
        final double titleSize = isTablet ? 20 : 16; // 16 -> 20
        final double subtitleSize = isTablet ? 14 : 12; // 12 -> 14
        final double iconSize = isTablet ? 28 : 24; // Default -> 28
        final double trailingIconSize = isTablet ? 20 : 18; // 18 -> 20

        return Column(
          children: [
            // Ayarlar Listesi (Scrollable)
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                    horizontal: hPadding, vertical: vPadding),
                children: [
                  // 🔥 Dinamik Kart Rengi Hesaplama
                  // Her tema artık kendi settingsCardColor ve settingsBorderColor değerlerini taşıyor.
                  Builder(
                    builder: (context) {
                      final theme = themeProvider.currentTheme;
                      final cardColor =
                          theme.settingsCardColor ?? const Color(0xFF202020);
                      final borderColor = theme.settingsBorderColor ??
                          Colors.white.withOpacity(0.06);
                      // 🔥 İçerik Rengi: Eğer tema özel renk belirttiyse onu kullan, yoksa genel textColor
                      final itemColor = theme.settingsItemColor ??
                          themeProvider.idleTextColor;

                      return Column(
                        children: [
                          // 🔥 KULLANICI PROFİLİ
                          if (!context.watch<AuthProvider>().isGuest)
                            Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 24.0, top: 8.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: itemColor.withOpacity(0.1),
                                    backgroundImage: context
                                                .watch<AuthProvider>()
                                                .avatarUrl !=
                                            null
                                        ? NetworkImage(context
                                            .watch<AuthProvider>()
                                            .avatarUrl!)
                                        : null,
                                    child: context
                                                .watch<AuthProvider>()
                                                .avatarUrl ==
                                            null
                                        ? Icon(Icons.person,
                                            size: 30, color: itemColor)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context
                                              .watch<AuthProvider>()
                                              .displayName,
                                          style: AppFonts.poppins(
                                            context: context,
                                            color: itemColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Text(
                                          context
                                                  .watch<AuthProvider>()
                                                  .user
                                                  ?.email ??
                                              '',
                                          style: AppFonts.poppins(
                                            context: context,
                                            color: itemColor.withOpacity(0.5),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          if (context.watch<AuthProvider>().isGuest)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: 18,
                                top: 4,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF38BDF8),
                                      Color(0xFF2563EB),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF38BDF8)
                                          .withValues(alpha: 0.22),
                                      blurRadius: 18,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _isGuestConnectLoading
                                        ? null
                                        : _connectGuestWithGoogle,
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 15,
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 42,
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.16),
                                              borderRadius:
                                                  BorderRadius.circular(13),
                                            ),
                                            child: _isGuestConnectLoading
                                                ? const Padding(
                                                    padding: EdgeInsets.all(11),
                                                    child:
                                                        CircularProgressIndicator(
                                                      strokeWidth: 2.4,
                                                      color: Colors.white,
                                                    ),
                                                  )
                                                : Padding(
                                                    padding:
                                                        const EdgeInsets.all(9),
                                                    child: Image.asset(
                                                      'assets/icons/google.png',
                                                      fit: BoxFit.contain,
                                                    ),
                                                  ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'guest_connect_google_title'
                                                      .tr(),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppFonts.poppins(
                                                    context: context,
                                                    color: Colors.white,
                                                    fontSize: titleSize,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  'guest_connect_google_desc'
                                                      .tr(),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: AppFonts.poppins(
                                                    context: context,
                                                    color: Colors.white
                                                        .withValues(
                                                            alpha: 0.78),
                                                    fontSize: subtitleSize,
                                                    height: 1.25,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // PREMIUM BUTONU
                          Container(
                            decoration: BoxDecoration(
                              gradient:
                                  context.watch<PurchaseProvider>().isPremium
                                      ? const LinearGradient(
                                          colors: [
                                            Color(0xFF64748B),
                                            Color(0xFF2563EB),
                                            Color(0xFF0891B2),
                                          ],
                                          stops: [0.0, 0.52, 1.0],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        )
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFF38BDF8),
                                            Color(0xFF3B82F6)
                                          ], // Diamond Cyan/Blue
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: context
                                        .watch<PurchaseProvider>()
                                        .isPremium
                                    ? const Color(0xFF38BDF8).withOpacity(0.5)
                                    : Colors.transparent,
                                width: 1,
                              ),
                              boxShadow:
                                  context.watch<PurchaseProvider>().isPremium
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF38BDF8)
                                                .withValues(alpha: 0.34),
                                            blurRadius: 20,
                                            offset: const Offset(0, 8),
                                          ),
                                          BoxShadow(
                                            color: const Color(0xFFE2E8F0)
                                                .withValues(alpha: 0.12),
                                            blurRadius: 8,
                                            offset: const Offset(-3, -2),
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: const Color(0xFF38BDF8)
                                                .withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  final isGuest =
                                      context.read<AuthProvider>().isGuest;
                                  if (isGuest) {
                                    _showPremiumLoginRequired();
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const PremiumScreen()),
                                    );
                                  }
                                },
                                child: ListTile(
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: isTablet ? 8 : 0),
                                  leading: Icon(
                                    Icons.diamond_rounded,
                                    color: Colors.white,
                                    size: iconSize,
                                  ),
                                  title: Text(
                                    context.watch<PurchaseProvider>().isPremium
                                        ? 'premium_active'
                                            .tr()
                                            .replaceAll(RegExp(r'👑\s*'), '')
                                        : 'get_premium'
                                            .tr()
                                            .replaceAll(RegExp(r'👑\s*'), ''),
                                    style: AppFonts.poppins(
                                      context: context,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: titleSize,
                                    ),
                                  ),
                                  subtitle: context
                                          .watch<PurchaseProvider>()
                                          .isPremium
                                      ? null
                                      : Text(
                                          'premium_subtitle'.tr(),
                                          style: AppFonts.poppins(
                                            context: context,
                                            fontSize: subtitleSize,
                                            color:
                                                Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                  trailing: Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: trailingIconSize,
                                      color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // SÜRE AYARLARI
                          Card(
                            color: cardColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: borderColor, width: 1),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: isTablet ? 8 : 0),
                              leading: Icon(Icons.timer_outlined,
                                  color: itemColor, size: iconSize),
                              title: Text(
                                "duration_settings".tr(),
                                style: AppFonts.poppins(
                                  context: context,
                                  color: itemColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: titleSize,
                                ),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios_rounded,
                                  size: trailingIconSize, color: itemColor),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const DurationSettingsScreen()),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // SES AYARLARI
                          Card(
                            color: cardColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: borderColor, width: 1),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: isTablet ? 8 : 0),
                              leading: Icon(Icons.music_note_rounded,
                                  color: itemColor, size: iconSize),
                              title: Text(
                                "sound_settings".tr(),
                                style: AppFonts.poppins(
                                  context: context,
                                  color: itemColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: titleSize,
                                ),
                              ),
                              subtitle: Text(
                                settings.isBackgroundMusicEnabled
                                    ? "on".tr()
                                    : "off".tr(),
                                style: AppFonts.poppins(
                                  context: context,
                                  fontSize: subtitleSize,
                                  color: itemColor.withAlpha(179),
                                ),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios_rounded,
                                  size: trailingIconSize, color: itemColor),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SoundSettingsScreen()),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // 🎨 TEMA AYARI
                          Card(
                            color: cardColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: borderColor, width: 1),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: isTablet ? 8 : 0),
                              leading: Icon(Icons.palette_outlined,
                                  color: itemColor, size: iconSize),
                              title: Text(
                                'theme_settings'.tr(),
                                style: AppFonts.poppins(
                                  context: context,
                                  color: itemColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: titleSize,
                                ),
                              ),
                              subtitle: Text(
                                'theme_name_${themeProvider.currentTheme.id}'
                                    .tr(),
                                style: AppFonts.poppins(
                                  context: context,
                                  fontSize: subtitleSize,
                                  color: itemColor.withAlpha(179),
                                ),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios,
                                  size: trailingIconSize, color: itemColor),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ThemeSelectionScreen(),
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // DİL AYARI
                          Card(
                            color: cardColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: borderColor, width: 1),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: isTablet ? 8 : 0),
                              leading: Icon(Icons.language,
                                  color: itemColor, size: iconSize),
                              title: Text(
                                'language_label'.tr(),
                                style: AppFonts.poppins(
                                  context: context,
                                  color: itemColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: titleSize,
                                ),
                              ),
                              subtitle: Text(
                                _getLanguageName(context.locale.languageCode),
                                style: AppFonts.poppins(
                                  context: context,
                                  fontSize: subtitleSize,
                                  color: itemColor.withAlpha(179),
                                ),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios,
                                  size: trailingIconSize, color: itemColor),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const LanguageSelectionScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                          if (context
                              .watch<AdConsentService>()
                              .isPrivacyOptionsRequired) ...[
                            const SizedBox(height: 12),
                            Card(
                              color: cardColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: borderColor, width: 1),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: isTablet ? 8 : 0,
                                ),
                                leading: Icon(
                                  Icons.privacy_tip_outlined,
                                  color: itemColor,
                                  size: iconSize,
                                ),
                                title: Text(
                                  'privacy_options'.tr(),
                                  style: AppFonts.poppins(
                                    context: context,
                                    color: itemColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: titleSize,
                                  ),
                                ),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: trailingIconSize,
                                  color: itemColor,
                                ),
                                onTap: () async {
                                  final consent =
                                      context.read<AdConsentService>();
                                  final adManager = context.read<AdManager>();
                                  final width =
                                      MediaQuery.sizeOf(context).width;
                                  try {
                                    await consent.showPrivacyOptionsForm();
                                    if (mounted && consent.adsReady) {
                                      await adManager.loadSettingsBanner(width);
                                    }
                                  } catch (error) {
                                    debugPrint(
                                      'Privacy options form failed: $error',
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                          // BİZİ DEĞERLENDİRİN BUTONU
                          Card(
                            color: cardColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: borderColor, width: 1),
                            ),
                            child: ListTile(
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              leading: Icon(Icons.star_rate_rounded,
                                  color: Colors.amber, size: iconSize),
                              title: Text(
                                'rate_us'.tr(),
                                style: AppFonts.poppins(
                                  context: context,
                                  color: itemColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: titleSize,
                                ),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios,
                                  size: trailingIconSize, color: itemColor),
                              onTap: () async {
                                final InAppReview inAppReview =
                                    InAppReview.instance;
                                if (await inAppReview.isAvailable()) {
                                  // requestReview kotaya takılıp sessizce başarısız olabileceği için
                                  // ayarlardan tıklandığında her zaman doğrudan mağaza sayfasını açıyoruz.
                                  inAppReview.openStoreListing();
                                }
                              },
                            ),
                          ),

                          const SizedBox(height: 20),

                          // LOGOUT BUTONU
                          Card(
                            color: Colors.redAccent.withOpacity(0.1),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(
                                  color: Colors.redAccent, width: 1),
                            ),
                            child: ListTile(
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 16),
                              leading: const Icon(Icons.logout,
                                  color: Colors.redAccent),
                              title: Text(
                                context.watch<AuthProvider>().isGuest
                                    ? 'exit_guest_mode'.tr()
                                    : 'log_out'.tr(),
                                style: AppFonts.poppins(
                                  context: context,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    backgroundColor:
                                        themeProvider.settingsBgColor,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    title: Text(
                                      context.read<AuthProvider>().isGuest
                                          ? 'exit_guest_mode_title'.tr()
                                          : 'log_out_title'.tr(),
                                      style: AppFonts.poppins(
                                          context: context,
                                          color: itemColor,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    content: Text(
                                      'log_out_confirm'.tr(),
                                      style: AppFonts.poppins(
                                          context: context,
                                          color: itemColor.withOpacity(0.8)),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('cancel'.tr(),
                                            style: AppFonts.poppins(
                                                context: context,
                                                color: itemColor
                                                    .withOpacity(0.6))),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent),
                                        onPressed: () {
                                          context
                                              .read<AuthProvider>()
                                              .signOut();
                                          Navigator.of(context).popUntil(
                                              (route) => route.isFirst);
                                        },
                                        child: Text('log_out'.tr(),
                                            style: AppFonts.poppins(
                                                context: context,
                                                color: Colors.white)),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // App Version Display
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        final version = snapshot.data!.version;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20.0),
                          child: Center(
                            child: Text(
                              'v$version',
                              style: AppFonts.poppins(
                                context: context,
                                color: themeProvider.settingsTextColor
                                    .withValues(alpha: 0.5),
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),

            // 🔥 BANNER REKLAM ALANI
            Consumer<AdManager>(
              builder: (context, adManager, child) {
                if (adManager.isSettingsBannerLoaded &&
                    adManager.settingsBannerAd != null) {
                  return Container(
                    width: adManager.settingsBannerAd!.size.width.toDouble(),
                    height: adManager.settingsBannerAd!.size.height.toDouble(),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: AdWidget(ad: adManager.settingsBannerAd!),
                  );
                }
                // Reklam yüklenmediyse boş alan
                return const SizedBox(height: 50);
              },
            ),
          ],
        );
      }),
    );
  }
}
