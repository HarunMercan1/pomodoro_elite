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
      body: LayoutBuilder(builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final double hPadding = isTablet ? 32 : 20;
        final double sectionTitleSize = isTablet ? 18 : 14;
        final double titleSize = isTablet ? 18 : 14; // Default -> 18
        final double switchScale = isTablet ? 1.2 : 1.0;
        final double contentPaddingV = isTablet ? 12 : 0;

        return Column(
          children: [
            // --- KİLİT UYARI MESAJI ---
            if (isLocked)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: EdgeInsets.fromLTRB(hPadding, 0, hPadding, 10),
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
                          fontSize:
                              12, // Uyarı yazısı sabit kalsın veya çok az büyüsün
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
                    padding: EdgeInsets.all(hPadding),
                    children: [
                      // --- 1. BÖLÜM: MÜZİK ---
                      _buildSectionHeader(
                          context, "background_music".tr(), sectionTitleSize),

                      Card(
                        elevation: 0,
                        color: cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: borderColor, width: 1),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isTablet ? 24 : 15),
                          child: Column(
                            children: [
                              // Aç/Kapa Switch - Row ile düzenlendi (Taşmayı önlemek için)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "enable_music".tr(),
                                      style: AppFonts.poppins(
                                        context: context,
                                        color: itemColor,
                                        fontSize: titleSize,
                                      ),
                                    ),
                                  ),
                                  Transform.scale(
                                    scale:
                                        switchScale, // Sadece switch büyütülüyor
                                    child: Switch(
                                      value: settings.isBackgroundMusicEnabled,
                                      activeColor: sliderColor,
                                      onChanged: (val) =>
                                          settings.toggleBackgroundMusic(val),
                                    ),
                                  ),
                                ],
                              ),

                              // Müzik Açıksa Gösterilecekler
                              if (settings.isBackgroundMusicEnabled) ...[
                                Divider(color: itemColor.withOpacity(0.1)),

                                // Ses Seviyesi Slider
                                Row(
                                  children: [
                                    Icon(Icons.volume_mute_rounded,
                                        size: isTablet ? 28 : 20,
                                        color: itemColor),
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
                                        size: isTablet ? 28 : 20,
                                        color: itemColor),
                                  ],
                                ),

                                const SizedBox(height: 10),

                                // Müzik Listesi - Custom Widget Kullanımı
                                ...settings.backgroundMusics.entries
                                    .map((entry) {
                                  return _MusicListTile(
                                    titleKey: entry.value,
                                    fileName: entry.key,
                                    settings: settings,
                                    sliderColor: sliderColor,
                                    itemColor: itemColor,
                                    fontSize: titleSize,
                                    contentPadding: EdgeInsets.symmetric(
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // --- 2. BÖLÜM: BİLDİRİM SESLERİ ---
                      _buildSectionHeader(
                          context, "notification_sound".tr(), sectionTitleSize),

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
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: contentPaddingV),
                              title: Text(
                                entry.value.tr(),
                                style: AppFonts.poppins(
                                  context: context,
                                  color: itemColor,
                                  fontSize: titleSize,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle,
                                      color: sliderColor,
                                      size: isTablet ? 28 : 24)
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
        );
      }),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, double fontSize) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: AppFonts.poppins(
          context: context,
          fontSize: fontSize, // 14 -> isTablet ? 18 : 14
          fontWeight: FontWeight.bold,
          color: Theme.of(context).dividerColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// --- YARDIMCI WIDGET: MÜZİK LİSTESİ ÖĞESİ ---
class _MusicListTile extends StatefulWidget {
  final String titleKey;
  final String fileName;
  final SettingsProvider settings;
  final Color sliderColor;
  final Color itemColor;
  final double fontSize;
  final EdgeInsetsGeometry contentPadding;

  const _MusicListTile({
    required this.titleKey,
    required this.fileName,
    required this.settings,
    required this.sliderColor,
    required this.itemColor,
    required this.fontSize,
    required this.contentPadding,
  });

  @override
  State<_MusicListTile> createState() => _MusicListTileState();
}

class _MusicListTileState extends State<_MusicListTile> {
  bool? _isDownloaded;

  @override
  void initState() {
    super.initState();
    _checkDownloadStatus();
  }

  Future<void> _checkDownloadStatus() async {
    final exists = await widget.settings.isMusicDownloaded(widget.fileName);
    if (mounted) {
      setState(() {
        _isDownloaded = exists;
      });
    }
  }

  @override
  void didUpdateWidget(covariant _MusicListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-check just in case state changed externally or widget rebuilt
    _checkDownloadStatus();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.settings.backgroundMusic == widget.fileName;
    // Provider'dan indirme durumu (Global Map)
    final isDownloading = widget.settings.isDownloading(widget.fileName);

    return ListTile(
      contentPadding: widget.contentPadding,
      title: Text(
        widget.titleKey.tr(),
        style: AppFonts.poppins(
          context: context,
          color: widget.itemColor,
          fontSize: widget.fontSize,
        ),
      ),
      leading: _buildLeadingIcon(isSelected, isDownloading),
      onTap: () async {
        // Eğer zaten seçiliyse ve indirilmişse bir şey yapmaya gerek yok veya durdur
        if (isSelected) return;

        if (_isDownloaded == true) {
          // İndirilmişse direkt seç ve çal
          await widget.settings.setBackgroundMusic(widget.fileName);
        } else {
          // İndirilmemişse indir
          await widget.settings.downloadMusic(widget.fileName);
          // İndirme bittiğinde tekrar kontrol et
          await _checkDownloadStatus();
          // Eğer başarılı indiyse otomatik seçebilirsiniz:
          if (_isDownloaded == true) {
            await widget.settings.setBackgroundMusic(widget.fileName);
          }
        }
      },
    );
  }

  Widget _buildLeadingIcon(bool isSelected, bool isDownloading) {
    if (isDownloading) {
      return SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: widget.sliderColor,
        ),
      );
    }

    if (_isDownloaded == false) {
      return Icon(
        Icons.cloud_download_rounded,
        color: widget.itemColor.withOpacity(0.7),
      );
    }

    return Icon(
      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
      color:
          isSelected ? widget.sliderColor : widget.itemColor.withOpacity(0.5),
    );
  }
}
