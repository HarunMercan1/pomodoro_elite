import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ad_manager.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/timer_provider.dart';
import '../utils/app_fonts.dart';
import '../widgets/settings_components.dart';

class DurationSettingsScreen extends StatefulWidget {
  const DurationSettingsScreen({super.key});

  @override
  State<DurationSettingsScreen> createState() => _DurationSettingsScreenState();
}

class _DurationSettingsScreenState extends State<DurationSettingsScreen> {
  double? _tempWorkTime;
  double? _tempShortBreak;
  double? _tempLongBreak;
  bool _allowPop = false;
  bool _isClosing = false;
  late AdManager _adManager;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<AdManager>()
          .loadDurationBanner(MediaQuery.sizeOf(context).width);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adManager = context.read<AdManager>();
  }

  @override
  void dispose() {
    try {
      _adManager.disposeDurationBanner();
    } catch (error) {
      debugPrint('Duration banner dispose failed: $error');
    }
    super.dispose();
  }

  Future<void> _closeScreen() async {
    if (_isClosing) return;
    _isClosing = true;
    _adManager.disposeDurationBanner();
    if (mounted) setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final timerProvider = context.watch<TimerProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final theme = themeProvider.currentTheme;
    final backgroundColor = themeProvider.settingsBgColor;
    final itemColor = themeProvider.settingsTextColor;
    final cardColor = theme.settingsCardColor ?? const Color(0xFF202020);
    final borderColor =
        theme.settingsBorderColor ?? itemColor.withValues(alpha: 0.11);
    final accentColor = themeProvider.settingsAccentColor;
    final isLocked = timerProvider.isRunning;
    final currentWork = _tempWorkTime ?? settings.workTime.toDouble();
    final currentShort = _tempShortBreak ?? settings.shortBreakTime.toDouble();
    final currentLong = _tempLongBreak ?? settings.longBreakTime.toDouble();

    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _closeScreen();
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
            onPressed: _closeScreen,
          ),
          title: Text(
            'duration_settings'.tr(),
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
                      if (isLocked) ...[
                        SettingsLockNotice(
                          message: 'change_lock_msg'.tr(),
                          textColor: itemColor,
                        ),
                        const SizedBox(height: 12),
                      ],
                      IgnorePointer(
                        ignoring: isLocked,
                        child: AnimatedOpacity(
                          opacity: isLocked ? 0.48 : 1,
                          duration: const Duration(milliseconds: 180),
                          child: SettingsSurface(
                            color: cardColor,
                            borderColor: borderColor,
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Column(
                              children: [
                                _buildDurationSlider(
                                  context,
                                  label: 'focus'.tr(),
                                  icon: Icons.center_focus_strong_rounded,
                                  value: currentWork,
                                  min: 10,
                                  max: 180,
                                  itemColor: itemColor,
                                  accentColor: accentColor,
                                  onChanged: (value) =>
                                      setState(() => _tempWorkTime = value),
                                  onChangeEnd: (value) {
                                    final minutes = value.toInt();
                                    settings.setWorkTime(minutes);
                                    timerProvider.updateDurationFromSettings(
                                      minutes,
                                      TimerMode.work,
                                    );
                                    if (mounted) {
                                      setState(() => _tempWorkTime = null);
                                    }
                                  },
                                ),
                                SettingsDivider(color: borderColor, indent: 16),
                                _buildDurationSlider(
                                  context,
                                  label: 'short_break'.tr(),
                                  icon: Icons.coffee_rounded,
                                  value: currentShort,
                                  min: 1,
                                  max: 60,
                                  itemColor: itemColor,
                                  accentColor: accentColor,
                                  onChanged: (value) =>
                                      setState(() => _tempShortBreak = value),
                                  onChangeEnd: (value) {
                                    final minutes = value.toInt();
                                    settings.setShortBreakTime(minutes);
                                    timerProvider.updateDurationFromSettings(
                                      minutes,
                                      TimerMode.shortBreak,
                                    );
                                    if (mounted) {
                                      setState(() => _tempShortBreak = null);
                                    }
                                  },
                                ),
                                SettingsDivider(color: borderColor, indent: 16),
                                _buildDurationSlider(
                                  context,
                                  label: 'long_break'.tr(),
                                  icon: Icons.self_improvement_rounded,
                                  value: currentLong,
                                  min: 5,
                                  max: 120,
                                  itemColor: itemColor,
                                  accentColor: accentColor,
                                  onChanged: (value) =>
                                      setState(() => _tempLongBreak = value),
                                  onChangeEnd: (value) {
                                    final minutes = value.toInt();
                                    settings.setLongBreakTime(minutes);
                                    timerProvider.updateDurationFromSettings(
                                      minutes,
                                      TimerMode.longBreak,
                                    );
                                    if (mounted) {
                                      setState(() => _tempLongBreak = null);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Consumer<AdManager>(
                        builder: (context, adManager, _) => SettingsAdBanner(
                          enabled: adManager.canServeAds,
                          ad: adManager.durationBannerAd,
                          isLoaded: adManager.isDurationBannerLoaded,
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

  Widget _buildDurationSlider(
    BuildContext context, {
    required String label,
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required Color itemColor,
    required Color accentColor,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(15, 13, 12, 9),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: accentColor),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  label,
                  style: AppFonts.poppins(
                    context: context,
                    color: itemColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: accentColor.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(11),
                child: InkWell(
                  borderRadius: BorderRadius.circular(11),
                  onTap: () => _showDurationDialog(
                    context,
                    title: label,
                    currentValue: value,
                    min: min,
                    max: max,
                    onConfirm: onChangeEnd,
                  ),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 36),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.30),
                      ),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      '${value.toInt()} ${'minutes_label'.tr().toLowerCase()}',
                      textAlign: TextAlign.center,
                      style: AppFonts.poppins(
                        context: context,
                        color: accentColor,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              activeTrackColor: accentColor,
              inactiveTrackColor: accentColor.withValues(alpha: 0.16),
              thumbColor: accentColor,
              overlayColor: accentColor.withValues(alpha: 0.12),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 19),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDurationDialog(
    BuildContext context, {
    required String title,
    required double currentValue,
    required double min,
    required double max,
    required ValueChanged<double> onConfirm,
  }) async {
    final controller =
        TextEditingController(text: currentValue.toInt().toString());
    final themeProvider = context.read<ThemeProvider>();
    final theme = themeProvider.currentTheme;
    final itemColor = themeProvider.settingsTextColor;
    final accentColor = themeProvider.settingsAccentColor;
    final cardColor = theme.settingsCardColor ?? const Color(0xFF202020);
    final borderColor =
        theme.settingsBorderColor ?? itemColor.withValues(alpha: 0.12);
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          void submit() {
            final value = int.tryParse(controller.text.trim());
            if (value == null || value < min || value > max) {
              setDialogState(
                () => errorText = 'min_max_warning'.tr(args: [
                  min.toInt().toString(),
                  max.toInt().toString(),
                ]),
              );
              return;
            }
            onConfirm(value.toDouble());
            Navigator.pop(dialogContext);
          }

          return AlertDialog(
            backgroundColor: cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: borderColor),
            ),
            title: Text(
              '$title · ${'minutes_label'.tr()}',
              style: AppFonts.poppins(
                context: context,
                color: itemColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => submit(),
              style: AppFonts.poppins(context: context, color: itemColor),
              decoration: InputDecoration(
                errorText: errorText,
                hintText: 'min_max_warning'.tr(args: [
                  min.toInt().toString(),
                  max.toInt().toString(),
                ]),
                hintStyle: TextStyle(
                  color: itemColor.withValues(alpha: 0.48),
                ),
                filled: true,
                fillColor: itemColor.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(13),
                  borderSide: BorderSide(color: accentColor, width: 1.5),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'cancel'.tr(),
                  style: TextStyle(color: itemColor.withValues(alpha: 0.65)),
                ),
              ),
              FilledButton(
                onPressed: submit,
                style: FilledButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: ThemeData.estimateBrightnessForColor(
                            accentColor,
                          ) ==
                          Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
                child: Text('save'.tr()),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
  }
}
