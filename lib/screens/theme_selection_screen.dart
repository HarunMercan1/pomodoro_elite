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
      backgroundColor: themeProvider.bgColor,
      appBar: AppBar(
        title: Text(
          'theme_settings'.tr(),
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: themeProvider.textColor,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: themeProvider.textColor),
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
            // Tema önizleme - 3 durum rengi
            Row(
              children: [
                _ColorPreviewCircle(
                  label: 'Focus',
                  color: theme.focus.accentColor,
                ),
                _ColorPreviewCircle(
                  label: 'Break',
                  color: theme.breakState.accentColor,
                ),
                _ColorPreviewCircle(
                  label: 'Finish',
                  color: theme.finish.accentColor,
                ),
              ],
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

              // final success = await adManager.showRewardedAd(
              //   onRewardEarned: () async {
              await themeProvider.unlockTheme(theme.id);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.lock_open, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('${theme.name} ${'theme_unlocked'.tr()}'),
                      ],
                    ),
                    backgroundColor: theme.focus.bgColor,
                  ),
                );
              }
              //   },
              // );

              // if (!success && context.mounted) {
              //   ScaffoldMessenger.of(context).showSnackBar(
              //     SnackBar(
              //       content: Row(
              //         children: [
              //           const Icon(Icons.hourglass_empty, color: Colors.white),
              //           const SizedBox(width: 8),
              //           Text('ad_loading'.tr()),
              //         ],
              //       ),
              //       backgroundColor: Colors.orange,
              //       duration: const Duration(seconds: 2),
              //     ),
              //   );
              // }
            },
            icon: const Icon(Icons.play_circle_outline),
            // 🔥 TEST MODU: Reklamı atla, direkt aç
            // label: Text('watch_ad'.tr()),
            label: const Text('TEST: Hemen Aç'),
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

class _ColorPreviewCircle extends StatelessWidget {
  final String label;
  final Color color;

  const _ColorPreviewCircle({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
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
            color: theme.idle.hasGradient ? null : theme.idle.bgColor,
            gradient: theme.idle.gradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected ? theme.focus.accentColor : Colors.grey.shade700,
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
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.focus.textColor,
                      ),
                    ),
                    Text(
                      theme.vibe,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.focus.textColor.withAlpha(150),
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
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  ),
                )
              else if (!isUnlocked)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withAlpha(51),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: Colors.amber,
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
