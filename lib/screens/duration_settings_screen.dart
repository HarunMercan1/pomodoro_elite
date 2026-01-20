//duration_settings_screen

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../providers/settings_provider.dart';
import '../providers/timer_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/ad_manager.dart';
import '../utils/app_fonts.dart';

class DurationSettingsScreen extends StatefulWidget {
  const DurationSettingsScreen({super.key});

  @override
  State<DurationSettingsScreen> createState() => _DurationSettingsScreenState();
}

class _DurationSettingsScreenState extends State<DurationSettingsScreen> {
  // Slider değerlerini anlık olarak tutacak yerel değişkenler
  double? _tempWorkTime;
  double? _tempShortBreak;
  double? _tempLongBreak;

  late AdManager _adManager;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adManager = context.read<AdManager>();
  }

  @override
  void dispose() {
    try {
      _adManager.disposeDurationBanner();
    } catch (e) {
      debugPrint("DurationSettingsScreen Dispose Hatası: $e");
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 🔥 Duration ekranı için adaptive banner reklamı yükle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final width = MediaQuery.of(context).size.width;
      context.read<AdManager>().loadDurationBanner(width);
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    // TimerProvider'ı izliyoruz (watch) ki sayaç durumu değişince ekran güncellensin
    final timerProvider = context.watch<TimerProvider>();

    // --- KİLİT KONTROLÜ ---
    final bool isLocked = timerProvider.isRunning;

    // Eğer yerel değişkenler null ise (ilk açılış), provider'dan al
    double currentWork = _tempWorkTime ?? settings.workTime.toDouble();
    double currentShort = _tempShortBreak ?? settings.shortBreakTime.toDouble();
    double currentLong = _tempLongBreak ?? settings.longBreakTime.toDouble();

    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.settingsBgColor,
      appBar: AppBar(
        title: Text(
          "duration_settings".tr(),
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
      body: LayoutBuilder(builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= 600;
        final double hPadding = isTablet ? 32 : 20;
        final double contentPaddingV = isTablet ? 20 : 15;
        final double titleSize = isTablet ? 20 : 16;
        final double timeTextSize = isTablet ? 20 : 16;
        final double sliderHeight = isTablet ? 12.0 : 6.0;

        return Column(
          children: [
            // --- UYARI MESAJI (Sadece kilitliyse görünür) ---
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
                        "change_lock_msg".tr(),
                        style: AppFonts.poppins(
                          context: context,
                          fontSize: 12, // Uyarı mesajı sabit kalabilir
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
                ignoring: isLocked, // Kilitliyse dokunmayı engelle
                child: Opacity(
                  opacity: isLocked ? 0.5 : 1.0, // Kilitliyse soluklaştır
                  child: ListView(
                    padding: EdgeInsets.all(hPadding),
                    children: [
                      // 1. Odaklanma Süresi
                      _buildDurationSlider(
                        context,
                        label: "focus".tr(),
                        value: currentWork,
                        min: 10,
                        max: 180,
                        onChanged: (val) {
                          setState(() => _tempWorkTime = val);
                        },
                        onChangeEnd: (val) {
                          int newValue = val.toInt();
                          settings.setWorkTime(newValue);
                          timerProvider.updateDurationFromSettings(
                              newValue, TimerMode.work);
                          _tempWorkTime = null;
                        },
                        titleSize: titleSize,
                        timeTextSize: timeTextSize,
                        sliderHeight: sliderHeight,
                        contentPaddingV: contentPaddingV,
                      ),

                      const SizedBox(height: 20),

                      // 2. Kısa Mola
                      _buildDurationSlider(
                        context,
                        label: "short_break".tr(),
                        value: currentShort,
                        min: 1,
                        max: 60,
                        onChanged: (val) {
                          setState(() => _tempShortBreak = val);
                        },
                        onChangeEnd: (val) {
                          int newValue = val.toInt();
                          settings.setShortBreakTime(newValue);
                          timerProvider.updateDurationFromSettings(
                              newValue, TimerMode.shortBreak);
                          _tempShortBreak = null;
                        },
                        titleSize: titleSize,
                        timeTextSize: timeTextSize,
                        sliderHeight: sliderHeight,
                        contentPaddingV: contentPaddingV,
                      ),

                      const SizedBox(height: 20),

                      // 3. Uzun Mola
                      _buildDurationSlider(
                        context,
                        label: "long_break".tr(),
                        value: currentLong,
                        min: 5,
                        max:
                            120, // 📢 DÜZELTME: Maksimum 120 dk (Uzun mola da esnek olsun)
                        onChanged: (val) {
                          setState(() => _tempLongBreak = val);
                        },
                        onChangeEnd: (val) {
                          int newValue = val.toInt();
                          settings.setLongBreakTime(newValue);
                          timerProvider.updateDurationFromSettings(
                              newValue, TimerMode.longBreak);
                          _tempLongBreak = null;
                        },
                        titleSize: titleSize,
                        timeTextSize: timeTextSize,
                        sliderHeight: sliderHeight,
                        contentPaddingV: contentPaddingV,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 🔥 BANNER REKLAM ALANI
            Consumer<AdManager>(
              builder: (context, adManager, child) {
                if (adManager.isDurationBannerLoaded &&
                    adManager.durationBannerAd != null) {
                  return Container(
                    width: adManager.durationBannerAd!.size.width.toDouble(),
                    height: adManager.durationBannerAd!.size.height.toDouble(),
                    margin: const EdgeInsets.only(bottom: 10),
                    child: AdWidget(ad: adManager.durationBannerAd!),
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

  Widget _buildDurationSlider(
    BuildContext context, {
    required String label,
    required double value,
    required double min,
    required double max,
    required Function(double) onChanged,
    required Function(double) onChangeEnd,
    double titleSize = 16,
    double timeTextSize = 16,
    double sliderHeight = 6.0,
    double contentPaddingV = 15.0,
  }) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = themeProvider.currentTheme;
    final cardColor = theme.settingsCardColor ?? const Color(0xFF202020);
    final borderColor =
        theme.settingsBorderColor ?? Colors.white.withOpacity(0.06);
    final itemColor = theme.settingsItemColor ?? themeProvider.idleTextColor;
    final sliderColor =
        themeProvider.idleAccentColor; // Tema bazlı slider rengi

    return Card(
      elevation: 0,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: borderColor, width: 1),
      ),
      child: Padding(
        padding:
            EdgeInsets.symmetric(vertical: contentPaddingV, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: AppFonts.poppins(
                    context: context,
                    fontWeight: FontWeight.w500,
                    fontSize: titleSize,
                    color: itemColor,
                  ),
                ),
                // 🔥 TIKLANABİLİR SÜRE METNİ (Manuel Giriş)
                GestureDetector(
                  onTap: () => _showDurationDialog(
                      context, label, value, min, max, onChangeEnd),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sliderColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: sliderColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      "${value.toInt()} ${'minutes_label'.tr().toLowerCase()}",
                      style: AppFonts.poppins(
                        context: context,
                        fontWeight: FontWeight.bold,
                        color: sliderColor,
                        fontSize: timeTextSize,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: sliderHeight,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 12.0),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 24.0),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                activeColor: sliderColor,
                inactiveColor: sliderColor.withOpacity(0.2),
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 Manuel Süre Giriş Dialogu
  void _showDurationDialog(BuildContext context, String title,
      double currentVal, double min, double max, Function(double) onConfirm) {
    final TextEditingController controller =
        TextEditingController(text: currentVal.toInt().toString());
    String? errorText; // Hata mesajı için değişken

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF202020),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(
                      color: Colors.white.withOpacity(0.06), width: 1)),
              title: Text("$title - ${'minutes_label'.tr()}",
                  style:
                      AppFonts.poppins(context: context, color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    style:
                        AppFonts.poppins(context: context, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "min_max_warning".tr(args: [
                        min.toInt().toString(),
                        max.toInt().toString()
                      ]), // örn: "10 - 180 arası"
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.5)),
                      errorText: errorText, // 🔥 Hata mesajını göster
                      errorStyle: const TextStyle(color: Colors.redAccent),
                      enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white.withOpacity(0.3))),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context).primaryColor)),
                      errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.redAccent)),
                      focusedErrorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.redAccent)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("cancel".tr(),
                      style: TextStyle(color: Colors.white.withOpacity(0.7))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor),
                  onPressed: () {
                    final int? val = int.tryParse(controller.text);
                    if (val != null && val >= min && val <= max) {
                      onConfirm(val.toDouble());
                      Navigator.pop(context);
                    } else {
                      // Hata varsa UI'ı güncelle
                      setState(() {
                        errorText = "min_max_warning".tr(args: [
                          min.toInt().toString(),
                          max.toInt().toString()
                        ]);
                      });
                    }
                  },
                  child: Text("save".tr(),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
