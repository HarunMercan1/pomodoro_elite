//sound_settings_screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/settings_provider.dart';
import '../providers/timer_provider.dart';

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

    // Slider değeri: Yerel değer varsa onu, yoksa Provider'dakini al
    double sliderValue = _currentSliderValue ?? settings.backgroundVolume;

    // Sayaç çalışıyorsa kilitle
    final bool isLocked = timerProvider.isRunning;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "sound_settings".tr(),
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
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
                      "music_lock_msg".tr(), // "Müzik değiştirmek için sayacı durdurun."
                      style: TextStyle(
                        fontFamily: 'Poppins',
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
                      color: Theme.of(context).cardColor.withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Padding(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          children: [
                            // Aç/Kapa Switch
                            SwitchListTile(
                              title: Text("enable_music".tr(), style: const TextStyle(fontFamily: 'Poppins')),
                              value: settings.isBackgroundMusicEnabled,
                              activeColor: Theme.of(context).primaryColor,
                              onChanged: (val) => settings.toggleBackgroundMusic(val),
                            ),

                            // Müzik Açıksa Gösterilecekler
                            if (settings.isBackgroundMusicEnabled) ...[
                              const Divider(),

                              // Ses Seviyesi Slider
                              Row(
                                children: [
                                  const Icon(Icons.volume_mute_rounded, size: 20),
                                  Expanded(
                                    child: Slider(
                                      value: sliderValue,
                                      min: 0.0,
                                      max: 1.0,
                                      activeColor: Theme.of(context).primaryColor,
                                      // Canlı Değişim (Hızlı)
                                      onChanged: (val) {
                                        setState(() => _currentSliderValue = val);
                                        settings.setVolumeLive(val);
                                        timerProvider.updateMusicVolume(val);
                                      },
                                      // Kayıt (Güvenli)
                                      onChangeEnd: (val) {
                                        settings.saveVolumeToPrefs();
                                        _currentSliderValue = null;
                                      },
                                    ),
                                  ),
                                  const Icon(Icons.volume_up_rounded, size: 20),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Müzik Listesi
                              ...settings.backgroundMusics.entries.map((entry) {
                                final isSelected = settings.backgroundMusic == entry.key;
                                return ListTile(
                                  // entry.value artık JSON anahtarı (örn: sound_rain1). .tr() ile çeviriyoruz.
                                  title: Text(entry.value.tr(), style: const TextStyle(fontFamily: 'Poppins')),
                                  leading: Icon(
                                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                                    color: isSelected ? Theme.of(context).primaryColor : null,
                                  ),
                                  onTap: () => settings.setBackgroundMusic(entry.key),
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
                      color: Theme.of(context).cardColor.withOpacity(0.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: Column(
                        children: settings.notificationSounds.entries.map((entry) {
                          final isSelected = settings.notificationSound == entry.key;
                          return ListTile(
                            // entry.value JSON anahtarıdır (örn: sound_zil1). .tr() ile çeviriyoruz.
                            title: Text(entry.value.tr(), style: const TextStyle(fontFamily: 'Poppins')),
                            trailing: isSelected
                                ? Icon(Icons.check_circle, color: Theme.of(context).primaryColor)
                                : null,
                            onTap: () => settings.setNotificationSound(entry.key),
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
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).dividerColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}