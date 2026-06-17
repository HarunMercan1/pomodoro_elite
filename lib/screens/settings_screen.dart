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

import 'package:pomodoro_elite/screens/language_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
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
                              padding: const EdgeInsets.only(bottom: 24.0, top: 8.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: itemColor.withOpacity(0.1),
                                    backgroundImage: context.watch<AuthProvider>().avatarUrl != null
                                        ? NetworkImage(context.watch<AuthProvider>().avatarUrl!)
                                        : null,
                                    child: context.watch<AuthProvider>().avatarUrl == null
                                        ? Icon(Icons.person, size: 30, color: itemColor)
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.watch<AuthProvider>().displayName,
                                          style: AppFonts.poppins(
                                            context: context,
                                            color: itemColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        Text(
                                          context.watch<AuthProvider>().user?.email ?? '',
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
                          // BİZİ DEĞERLENDİRİN BUTONU
                          Card(
                            color: cardColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(color: borderColor, width: 1),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              leading: Icon(Icons.star_rate_rounded, color: Colors.amber, size: iconSize),
                              title: Text(
                                'Rate Us',
                                style: AppFonts.poppins(
                                  context: context,
                                  color: itemColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: titleSize,
                                ),
                              ),
                              trailing: Icon(Icons.arrow_forward_ios, size: trailingIconSize, color: itemColor),
                              onTap: () async {
                                final InAppReview inAppReview = InAppReview.instance;
                                if (await inAppReview.isAvailable()) {
                                  inAppReview.requestReview();
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
                              side: const BorderSide(color: Colors.redAccent, width: 1),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              leading: const Icon(Icons.logout, color: Colors.redAccent),
                              title: Text(
                                context.watch<AuthProvider>().isGuest ? 'Exit Guest Mode' : 'Log Out',
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
                                    backgroundColor: themeProvider.settingsBgColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    title: Text(
                                      context.read<AuthProvider>().isGuest ? 'Exit Guest Mode?' : 'Log Out?',
                                      style: AppFonts.poppins(context: context, color: itemColor, fontWeight: FontWeight.bold),
                                    ),
                                    content: Text(
                                      'Are you sure you want to log out?',
                                      style: AppFonts.poppins(context: context, color: itemColor.withOpacity(0.8)),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancel', style: AppFonts.poppins(context: context, color: itemColor.withOpacity(0.6))),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                                        onPressed: () {
                                          context.read<AuthProvider>().signOut();
                                          Navigator.of(context).popUntil((route) => route.isFirst);
                                        },
                                        child: Text('Log Out', style: AppFonts.poppins(context: context, color: Colors.white)),
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

                  const SizedBox(height: 30),
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
