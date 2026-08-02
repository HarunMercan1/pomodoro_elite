import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/ad_manager.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/timer_provider.dart';
import '../utils/app_fonts.dart';
import '../widgets/settings_components.dart';

class SoundSettingsScreen extends StatefulWidget {
  const SoundSettingsScreen({super.key});

  @override
  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen> {
  double? _currentSliderValue;
  bool _allowPop = false;
  bool _isClosing = false;
  late AdManager _adManager;
  late SettingsProvider _settingsProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context
          .read<AdManager>()
          .loadSoundBanner(MediaQuery.sizeOf(context).width);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _adManager = context.read<AdManager>();
    _settingsProvider = context.read<SettingsProvider>();
  }

  @override
  void dispose() {
    _settingsProvider.stopPreview();
    try {
      _adManager.disposeSoundBanner();
    } catch (error) {
      debugPrint('Sound banner dispose failed: $error');
    }
    super.dispose();
  }

  Future<void> _closeScreen() async {
    if (_isClosing) return;
    _isClosing = true;
    _settingsProvider.stopPreview();
    _adManager.disposeSoundBanner();
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
    final sliderValue = _currentSliderValue ?? settings.backgroundVolume;
    final isLocked = timerProvider.isRunning;

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
            'sound_settings'.tr(),
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
                          message: 'music_lock_msg'.tr(),
                          textColor: itemColor,
                        ),
                        const SizedBox(height: 14),
                      ],
                      IgnorePointer(
                        ignoring: isLocked,
                        child: AnimatedOpacity(
                          opacity: isLocked ? 0.48 : 1,
                          duration: const Duration(milliseconds: 180),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SettingsSectionLabel(
                                title: 'background_music'.tr(),
                                color: itemColor,
                              ),
                              SettingsSurface(
                                color: cardColor,
                                borderColor: borderColor,
                                child: Column(
                                  children: [
                                    SettingsNavigationTile(
                                      icon: Icons.graphic_eq_rounded,
                                      title: 'enable_music'.tr(),
                                      subtitle:
                                          settings.isBackgroundMusicEnabled
                                              ? 'on'.tr()
                                              : 'off'.tr(),
                                      textColor: itemColor,
                                      accentColor: accentColor,
                                      trailing: Switch(
                                        value:
                                            settings.isBackgroundMusicEnabled,
                                        activeColor: accentColor,
                                        onChanged:
                                            settings.toggleBackgroundMusic,
                                      ),
                                      onTap: () =>
                                          settings.toggleBackgroundMusic(
                                        !settings.isBackgroundMusicEnabled,
                                      ),
                                    ),
                                    if (settings.isBackgroundMusicEnabled) ...[
                                      SettingsDivider(color: borderColor),
                                      _VolumeControl(
                                        value: sliderValue,
                                        itemColor: itemColor,
                                        accentColor: accentColor,
                                        onChanged: (value) {
                                          setState(
                                            () => _currentSliderValue = value,
                                          );
                                          settings.setVolumeLive(value);
                                          timerProvider
                                              .updateMusicVolume(value);
                                        },
                                        onChangeEnd: (_) {
                                          settings.saveVolumeToPrefs();
                                          if (mounted) {
                                            setState(
                                              () => _currentSliderValue = null,
                                            );
                                          }
                                        },
                                      ),
                                      for (final entry in settings
                                          .backgroundMusics.entries) ...[
                                        SettingsDivider(
                                          color: borderColor,
                                          indent: 62,
                                        ),
                                        _MusicListTile(
                                          titleKey: entry.value,
                                          fileName: entry.key,
                                          settings: settings,
                                          accentColor: accentColor,
                                          itemColor: itemColor,
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              SettingsSectionLabel(
                                title: 'notification_sound'.tr(),
                                color: itemColor,
                              ),
                              SettingsSurface(
                                color: cardColor,
                                borderColor: borderColor,
                                child: Column(
                                  children: [
                                    for (var index = 0;
                                        index <
                                            settings.notificationSounds.length;
                                        index++) ...[
                                      if (index > 0)
                                        SettingsDivider(
                                          color: borderColor,
                                          indent: 62,
                                        ),
                                      _NotificationSoundTile(
                                        title: settings
                                            .notificationSounds.entries
                                            .elementAt(index)
                                            .value
                                            .tr(),
                                        isSelected: settings
                                                .notificationSound ==
                                            settings.notificationSounds.entries
                                                .elementAt(index)
                                                .key,
                                        itemColor: itemColor,
                                        accentColor: accentColor,
                                        onTap: () =>
                                            settings.setNotificationSound(
                                          settings.notificationSounds.entries
                                              .elementAt(index)
                                              .key,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Consumer<AdManager>(
                        builder: (context, adManager, _) => SettingsAdBanner(
                          enabled: adManager.canServeAds,
                          ad: adManager.soundBannerAd,
                          isLoaded: adManager.isSoundBannerLoaded,
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

class _VolumeControl extends StatelessWidget {
  const _VolumeControl({
    required this.value,
    required this.itemColor,
    required this.accentColor,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double value;
  final Color itemColor;
  final Color accentColor;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 9),
      child: Row(
        children: [
          Icon(Icons.volume_down_rounded, size: 21, color: itemColor),
          const SizedBox(width: 5),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                activeTrackColor: accentColor,
                inactiveTrackColor: accentColor.withValues(alpha: 0.16),
                thumbColor: accentColor,
                overlayColor: accentColor.withValues(alpha: 0.12),
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8.5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              ),
              child: Slider(
                value: value.clamp(0, 1),
                min: 0,
                max: 1,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
              ),
            ),
          ),
          const SizedBox(width: 5),
          Container(
            constraints: const BoxConstraints(minWidth: 46),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              '${(value * 100).round()}%',
              textAlign: TextAlign.center,
              style: AppFonts.poppins(
                context: context,
                color: accentColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationSoundTile extends StatelessWidget {
  const _NotificationSoundTile({
    required this.title,
    required this.isSelected,
    required this.itemColor,
    required this.accentColor,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final Color itemColor;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? accentColor.withValues(alpha: 0.075)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: accentColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppFonts.poppins(
                    context: context,
                    color: itemColor,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 160),
                child: isSelected
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: const ValueKey(true),
                        color: accentColor,
                        size: 22,
                      )
                    : Icon(
                        Icons.circle_outlined,
                        key: const ValueKey(false),
                        color: itemColor.withValues(alpha: 0.28),
                        size: 21,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MusicListTile extends StatefulWidget {
  const _MusicListTile({
    required this.titleKey,
    required this.fileName,
    required this.settings,
    required this.accentColor,
    required this.itemColor,
  });

  final String titleKey;
  final String fileName;
  final SettingsProvider settings;
  final Color accentColor;
  final Color itemColor;

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

  @override
  void didUpdateWidget(covariant _MusicListTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fileName != widget.fileName ||
        oldWidget.settings != widget.settings) {
      _checkDownloadStatus();
    }
  }

  Future<void> _checkDownloadStatus() async {
    final exists = await widget.settings.isMusicDownloaded(widget.fileName);
    if (mounted) setState(() => _isDownloaded = exists);
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.settings.backgroundMusic == widget.fileName;
    final isDownloading = widget.settings.isDownloading(widget.fileName);

    return Material(
      color: isSelected
          ? widget.accentColor.withValues(alpha: 0.075)
          : Colors.transparent,
      child: InkWell(
        onTap: isDownloading ? null : _selectOrDownload,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                height: 36,
                child: Center(
                  child: _buildStatusIcon(isSelected, isDownloading),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.titleKey.tr(),
                  style: AppFonts.poppins(
                    context: context,
                    color: widget.itemColor,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.equalizer_rounded,
                  color: widget.accentColor,
                  size: 21,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectOrDownload() async {
    final isSelected = widget.settings.backgroundMusic == widget.fileName;
    if (isSelected) return;
    if (_isDownloaded == true) {
      await widget.settings.setBackgroundMusic(widget.fileName);
      return;
    }
    await widget.settings.downloadMusic(widget.fileName);
    await _checkDownloadStatus();
    if (_isDownloaded == true) {
      await widget.settings.setBackgroundMusic(widget.fileName);
    }
  }

  Widget _buildStatusIcon(bool isSelected, bool isDownloading) {
    if (isDownloading || _isDownloaded == null) {
      return SizedBox(
        width: 21,
        height: 21,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: widget.accentColor,
        ),
      );
    }
    if (_isDownloaded == false) {
      return Icon(
        Icons.cloud_download_rounded,
        color: widget.itemColor.withValues(alpha: 0.62),
        size: 22,
      );
    }
    return Icon(
      isSelected
          ? Icons.radio_button_checked_rounded
          : Icons.radio_button_off_rounded,
      color: isSelected
          ? widget.accentColor
          : widget.itemColor.withValues(alpha: 0.42),
      size: 22,
    );
  }
}
