//sound_settings_screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/settings_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/app_fonts.dart';

class SoundSettingsScreen extends StatefulWidget {
  const SoundSettingsScreen({super.key});

  @override
  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen> {
  // Slider'ın akıcı olması için yerel değişken
  double? _currentSliderValue;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final timerProvider = context.watch<TimerProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = themeProvider.currentTheme;

    // 🔥 Tema Renkleri
    final cardColor = theme.settingsCardColor ?? const Color(0xFF202020);
    final borderColor =
        theme.settingsBorderColor ?? Colors.white.withOpacity(0.06);
    final itemColor = theme.settingsItemColor ?? themeProvider.idleTextColor;
    final sliderColor =
        themeProvider.idleAccentColor; // Tema bazlı slider/switch rengi

    // Slider değeri: Yerel değer varsa onu, yoksa Provider'dakini al
    double sliderValue = _currentSliderValue ?? settings.backgroundVolume;

    // Sayaç çalışıyorsa kilitle
    final bool isLocked = timerProvider.isRunning;

    return Scaffold(
      backgroundColor: themeProvider.settingsBgColor,
      appBar: AppBar(
        title: Text(
          "sound_settings".tr(),
          style: AppFonts.poppins(
            context: context,
            fontWeight: FontWeight.w600,
            color: themeProvider.settingsTextColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: themeProvider.settingsTextColor,
          onPressed: () {
            settings.stopPreview(); // Çıkarken sesi sustur
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // --- KİLİT UYARI MESAJI ---
          if (isLocked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orangeAccent),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "music_lock_msg"
                          .tr(), // "Müzik değiştirmek için sayacı durdurun."
                      style: AppFonts.poppins(
                        context: context,
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // --- AYARLAR LİSTESİ (KİLİTLENEBİLİR ALAN) ---
          Expanded(
            child: IgnorePointer(
              ignoring: isLocked, // Kilitliyse tıklanmasın
              child: Opacity(
                opacity: isLocked ? 0.5 : 1.0, // Kilitliyse soluk görünsün
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    // --- 1. BÖLÜM: MÜZİK ---
                    _buildSectionHeader(context, "background_music".tr()),

                    Card(
                      elevation: 0,
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: borderColor, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: [
                            // Aç/Kapa Switch
                            SwitchListTile(
                              title: Text(
                                "enable_music".tr(),
                                style: AppFonts.poppins(
                                  context: context,
                                  color: itemColor,
                                ),
                              ),
                              value: settings.isBackgroundMusicEnabled,
                              activeColor: sliderColor,
                              onChanged: (val) =>
                                  settings.toggleBackgroundMusic(val),
                            ),

                            // Müzik Açıksa Gösterilecekler
                            if (settings.isBackgroundMusicEnabled) ...[
                              Divider(color: itemColor.withOpacity(0.1)),

                              // Ses Seviyesi Slider
                              Row(
                                children: [
                                  Icon(Icons.volume_mute_rounded,
                                      size: 20, color: itemColor),
                                  Expanded(
                                    child: Slider(
                                      value: sliderValue,
                                      min: 0.0,
                                      max: 1.0,
                                      activeColor: sliderColor,
                                      onChanged: (val) {
                                        setState(
                                            () => _currentSliderValue = val);
                                        settings.setVolumeLive(val);
                                        timerProvider.updateMusicVolume(val);
                                      },
                                      onChangeEnd: (val) {
                                        settings.saveVolumeToPrefs();
                                        _currentSliderValue = null;
                                      },
                                    ),
                                  ),
                                  Icon(Icons.volume_up_rounded,
                                      size: 20, color: itemColor),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Müzik Listesi
                              ...settings.backgroundMusics.entries.map((entry) {
                                final isSelected =
                                    settings.backgroundMusic == entry.key;
                                return ListTile(
                                  title: Text(
                                    entry.value.tr(),
                                    style: AppFonts.poppins(
                                      context: context,
                                      color: itemColor,
                                    ),
                                  ),
                                  leading: Icon(
                                    isSelected
                                        ? Icons.radio_button_checked
                                        : Icons.radio_button_off,
                                    color: isSelected
                                        ? sliderColor
                                        : itemColor.withOpacity(0.5),
                                  ),
                                  onTap: () =>
                                      settings.setBackgroundMusic(entry.key),
                                );
                              }).toList(),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    // --- 2. BÖLÜM: BİLDİRİM SESLERİ ---
                    _buildSectionHeader(context, "notification_sound".tr()),

                    Card(
                      elevation: 0,
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: borderColor, width: 1),
                      ),
                      child: Column(
                        children:
                            settings.notificationSounds.entries.map((entry) {
                          final isSelected =
                              settings.notificationSound == entry.key;
                          return ListTile(
                            title: Text(
                              entry.value.tr(),
                              style: AppFonts.poppins(
                                context: context,
                                color: itemColor,
                              ),
                            ),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: sliderColor)
                                : null,
                            onTap: () =>
                                settings.setNotificationSound(entry.key),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: AppFonts.poppins(
          context: context,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).dividerColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
