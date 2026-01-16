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
        return 'Українська';
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
      backgroundColor: themeProvider.bgColor,
      appBar: AppBar(
        title: Text(
          'settings_title'.tr(),
          style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              color: themeProvider.textColor),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: themeProvider.textColor,
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // 🔥 Body: Column ile wrap edildi - Liste + Banner
      body: Column(
        children: [
          // Ayarlar Listesi (Scrollable)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // SÜRE AYARLARI
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: const Icon(Icons.timer_outlined),
                    title: Text("duration_settings".tr(),
                        style: const TextStyle(fontFamily: 'Poppins')),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 18),
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
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: const Icon(Icons.music_note_rounded),
                    title: Text("sound_settings".tr(),
                        style: const TextStyle(fontFamily: 'Poppins')),
                    subtitle: Text(
                      // DÜZELTME 1: "Açık/Kapalı" yerine çeviri anahtarlarını kullandık
                      settings.isBackgroundMusicEnabled
                          ? "on".tr()
                          : "off".tr(),
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing:
                        const Icon(Icons.arrow_forward_ios_rounded, size: 18),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SoundSettingsScreen()),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // DİL AYARI
                // DİL AYARI
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: const Icon(Icons.language),
                    title: Text('language_label'.tr(),
                        style: const TextStyle(fontFamily: 'Poppins')),
                    subtitle: Text(
                      _getLanguageName(context.locale.languageCode),
                      style:
                          const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LanguageSelectionScreen(),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // 🎨 TEMA AYARI (NEW)
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: const Icon(Icons.palette_outlined),
                        title: Text('theme_settings'.tr(),
                            style: const TextStyle(fontFamily: 'Poppins')),
                        subtitle: Text(
                          themeProvider.currentTheme.name,
                          style: const TextStyle(
                              fontFamily: 'Poppins', fontSize: 12),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                    );
                  },
                ),

                const SizedBox(height: 20),

                const SizedBox(height: 30),

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
      ),
    );
  }
}
