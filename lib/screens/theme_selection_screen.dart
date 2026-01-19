import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../providers/theme_provider.dart';
import '../providers/ad_manager.dart';

class ThemeSelectionScreen extends StatefulWidget {
  const ThemeSelectionScreen({super.key});

  @override
  State<ThemeSelectionScreen> createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdManager>().loadRewardedAd();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final adManager = context.watch<AdManager>();

    return Scaffold(
      backgroundColor: themeProvider.settingsBgColor, // 🔥 Tema bazlı arka plan
      appBar: AppBar(
        title: Text(
          'theme_settings'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: themeProvider.settingsTextColor, // 🔥 Tema bazlı metin
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: themeProvider.settingsTextColor, // 🔥 Tema bazlı ikon
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: AppThemes.all.length,
        itemBuilder: (context, index) {
          final theme = AppThemes.all[index];
          final isSelected = themeProvider.currentThemeId == theme.id;
          final isUnlocked = themeProvider.isThemeUnlocked(theme.id);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ThemeCard(
              theme: theme,
              isSelected: isSelected,
              isUnlocked: isUnlocked,
              onTap: () => _handleThemeTap(
                context,
                theme,
                isUnlocked,
                themeProvider,
                adManager,
              ),
            ),
          );
        },
      ),
    );
  }

  void _handleThemeTap(
    BuildContext context,
    AppTheme theme,
    bool isUnlocked,
    ThemeProvider themeProvider,
    AdManager adManager,
  ) {
    if (isUnlocked) {
      themeProvider.selectTheme(theme.id);
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text('${theme.name} ${'theme_applied'.tr()}'),
      //     backgroundColor: theme.focus.bgColor,
      //     duration: const Duration(seconds: 1),
      //   ),
      // );
    } else {
      _showUnlockDialog(context, theme, themeProvider, adManager);
    }
  }

  void _showUnlockDialog(
    BuildContext context,
    AppTheme theme,
    ThemeProvider themeProvider,
    AdManager adManager,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.lock_outline, color: Colors.amber, size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    theme.vibe,
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tema önizleme - Gradient bar
            Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    theme.idle.accentColor,
                    theme.focus.bgColor,
                    theme.finish.bgColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.focus.bgColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'unlock_theme_msg'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'cancel'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);

              final success = await adManager.showRewardedAd(
                onRewardEarned: () async {
                  await themeProvider.unlockTheme(theme.id);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(Icons.lock_open, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('${theme.name} ${"theme_unlocked".tr()}'),
                          ],
                        ),
                        backgroundColor: theme.focus.bgColor,
                      ),
                    );
                  }
                },
              );

              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.hourglass_empty, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('ad_loading'.tr()),
                      ],
                    ),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.play_circle_outline),
            label: Text('watch_ad'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.focus.effectiveButtonBg,
              foregroundColor: theme.focus.effectiveButtonTextColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final AppTheme theme;
  final bool isSelected;
  final bool isUnlocked;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.theme,
    required this.isSelected,
    required this.isUnlocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(Colors.black, theme.idle.accentColor, 0.3)!,
                Color.lerp(Colors.black, theme.focus.bgColor, 0.7)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.focus.accentColor
                  : theme.idle.accentColor.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: theme.focus.accentColor.withAlpha(77),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              // Renk önizleme - 3 durum
              _ColorPreviewBar(theme: theme),
              const SizedBox(width: 16),

              // Tema adı ve vibe
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme.name,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      theme.vibe,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withAlpha(180),
                      ),
                    ),
                  ],
                ),
              ),

              // Durum ikonu
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.focus.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    // 🔥 Arka plan açiksa siyah, koyuysa beyaz ikon
                    color: theme.focus.accentColor.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                    size: 18,
                  ),
                )
              else if (!isUnlocked)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.focus.textColor.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock,
                    color: theme.focus.textColor,
                    size: 18,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColorPreviewBar extends StatelessWidget {
  final AppTheme theme;

  const _ColorPreviewBar({required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 32,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            theme.idle.accentColor, // Başlangıç rengi
            theme.focus.accentColor, // Çalışma rengi
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
