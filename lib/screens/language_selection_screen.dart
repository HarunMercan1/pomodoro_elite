import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../utils/app_fonts.dart';
import '../widgets/settings_components.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  static const languages = <({String code, String name, String flag})>[
    (code: 'en', name: 'English', flag: '🇺🇸'),
    (code: 'tr', name: 'Türkçe', flag: '🇹🇷'),
    (code: 'es', name: 'Español', flag: '🇪🇸'),
    (code: 'pt', name: 'Português', flag: '🇵🇹'),
    (code: 'de', name: 'Deutsch', flag: '🇩🇪'),
    (code: 'fr', name: 'Français', flag: '🇫🇷'),
    (code: 'it', name: 'Italiano', flag: '🇮🇹'),
    (code: 'ru', name: 'Русский', flag: '🇷🇺'),
    (code: 'ja', name: '日本語', flag: '🇯🇵'),
    (code: 'ko', name: '한국어', flag: '🇰🇷'),
    (code: 'zh', name: '中文', flag: '🇨🇳'),
    (code: 'hi', name: 'हिन्दी', flag: '🇮🇳'),
    (code: 'ar', name: 'العربية', flag: '🇸🇦'),
    (code: 'id', name: 'Bahasa Indonesia', flag: '🇮🇩'),
    (code: 'vi', name: 'Tiếng Việt', flag: '🇻🇳'),
    (code: 'bn', name: 'বাংলা', flag: '🇧🇩'),
    (code: 'ur', name: 'اردو', flag: '🇵🇰'),
    (code: 'pl', name: 'Polski', flag: '🇵🇱'),
    (code: 'th', name: 'ไทย', flag: '🇹🇭'),
    (code: 'nl', name: 'Nederlands', flag: '🇳🇱'),
    (code: 'uk', name: 'Українська', flag: '🇺🇦'),
    (code: 'el', name: 'Ελληνικά', flag: '🇬🇷'),
    (code: 'sv', name: 'Svenska', flag: '🇸🇪'),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final theme = themeProvider.currentTheme;
    final backgroundColor = themeProvider.settingsBgColor;
    final itemColor = themeProvider.settingsTextColor;
    final cardColor = theme.settingsCardColor ?? const Color(0xFF202020);
    final borderColor =
        theme.settingsBorderColor ?? itemColor.withValues(alpha: 0.11);
    final accentColor = themeProvider.settingsAccentColor;
    final selectedCode = context.locale.languageCode;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: backgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          color: itemColor,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'language_label'.tr(),
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
            padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, 22),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: SettingsSurface(
                  color: cardColor,
                  borderColor: borderColor,
                  child: Column(
                    children: [
                      for (var index = 0;
                          index < languages.length;
                          index++) ...[
                        if (index > 0)
                          SettingsDivider(color: borderColor, indent: 66),
                        _LanguageTile(
                          language: languages[index],
                          isSelected: languages[index].code == selectedCode,
                          textColor: itemColor,
                          accentColor: accentColor,
                          onTap: () => context.setLocale(
                            Locale(languages[index].code),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.language,
    required this.isSelected,
    required this.textColor,
    required this.accentColor,
    required this.onTap,
  });

  final ({String code, String name, String flag}) language;
  final bool isSelected;
  final Color textColor;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: isSelected,
      button: true,
      child: Material(
        color: isSelected
            ? accentColor.withValues(alpha: 0.10)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accentColor.withValues(alpha: 0.13)
                        : textColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    language.flag,
                    style: const TextStyle(fontSize: 23),
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    language.name,
                    style: AppFonts.poppins(
                      context: context,
                      color: textColor,
                      fontSize: 14.5,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 170),
                  child: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          key: const ValueKey(true),
                          color: accentColor,
                          size: 22,
                        )
                      : const SizedBox(
                          key: ValueKey(false),
                          width: 22,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
