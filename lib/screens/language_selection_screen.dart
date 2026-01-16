import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({super.key});

  final List<Map<String, String>> languages = const [
    {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇵🇹'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
    {'code': 'it', 'name': 'Italiano', 'flag': '🇮🇹'},
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'ja', 'name': '日本語', 'flag': '🇯🇵'},
    {'code': 'ko', 'name': '한국어', 'flag': '🇰🇷'},
    {'code': 'zh', 'name': '中文', 'flag': '🇨🇳'},
    {'code': 'hi', 'name': 'हिन्दी', 'flag': '🇮🇳'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'id', 'name': 'Bahasa Indonesia', 'flag': '🇮🇩'},
    {'code': 'vi', 'name': 'Tiếng Việt', 'flag': '🇻🇳'},
    {'code': 'bn', 'name': 'বাংলা', 'flag': '🇧🇩'},
    {'code': 'ur', 'name': 'اردو', 'flag': '🇵🇰'},
    {'code': 'pl', 'name': 'Polski', 'flag': '🇵🇱'},
    {'code': 'th', 'name': 'ไทย', 'flag': '🇹🇭'},
    {'code': 'nl', 'name': 'Nederlands', 'flag': '🇳🇱'},
    {'code': 'uk', 'name': 'Українська', 'flag': '🇺🇦'},
    {'code': 'el', 'name': 'Ελληνικά', 'flag': '🇬🇷'},
    {'code': 'sv', 'name': 'Svenska', 'flag': '🇸🇪'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'language_label'.tr(),
          style: const TextStyle(
              fontFamily: 'Poppins', fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: languages.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final lang = languages[index];
          final isSelected = context.locale.languageCode == lang['code'];

          return Card(
            elevation: isSelected ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: isSelected
                  ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                  : BorderSide.none,
            ),
            color: isSelected
                ? Theme.of(context).primaryColor.withOpacity(0.1)
                : null,
            child: InkWell(
              onTap: () {
                context.setLocale(Locale(lang['code']!));
                // Opsiyonel: Seçimden sonra geri dönmek isterseniz:
                // Navigator.pop(context);
              },
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Row(
                  children: [
                    Text(
                      lang['flag']!,
                      style: const TextStyle(fontSize: 32),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Text(
                        lang['name']!,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).primaryColor,
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
