import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final translationDirectory = Directory('assets/translations');
  final translationFiles = translationDirectory
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  Map<String, dynamic> readTranslations(File file) {
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  test('all supported locales have exactly the same non-empty keys', () {
    const supportedLocales = {
      'ar',
      'bn',
      'de',
      'el',
      'en',
      'es',
      'fr',
      'hi',
      'id',
      'it',
      'ja',
      'ko',
      'nl',
      'pl',
      'pt',
      'ru',
      'sv',
      'th',
      'tr',
      'uk',
      'ur',
      'vi',
      'zh',
    };

    final localeCodes = translationFiles
        .map((file) => file.uri.pathSegments.last.replaceAll('.json', ''))
        .toSet();
    expect(localeCodes, supportedLocales);

    final mainSource = File('lib/main.dart').readAsStringSync();
    final configuredLocales = RegExp(
      r"Locale\('([a-z]{2})'\)",
    ).allMatches(mainSource).map((match) => match.group(1)!).toSet();
    expect(configuredLocales, supportedLocales);

    final english = readTranslations(
      translationFiles.singleWhere((file) => file.path.endsWith('en.json')),
    );
    final expectedKeys = english.keys.toSet();

    for (final file in translationFiles) {
      final translations = readTranslations(file);
      expect(translations.keys.toSet(), expectedKeys, reason: file.path);

      for (final entry in translations.entries) {
        expect(entry.value, isA<String>(), reason: '${file.path}: ${entry.key}');
        expect(
          (entry.value as String).trim(),
          isNotEmpty,
          reason: '${file.path}: ${entry.key}',
        );
      }
    }
  });

  test('placeholder counts match the English source', () {
    final english = readTranslations(
      translationFiles.singleWhere((file) => file.path.endsWith('en.json')),
    );

    int placeholderCount(Object? value) {
      return RegExp(r'\{\}').allMatches(value as String).length;
    }

    for (final file in translationFiles) {
      final translations = readTranslations(file);
      for (final key in english.keys) {
        expect(
          placeholderCount(translations[key]),
          placeholderCount(english[key]),
          reason: '${file.path}: $key',
        );
      }
    }
  });

  test('literal translation keys used by Dart code exist', () {
    final english = readTranslations(
      translationFiles.singleWhere((file) => file.path.endsWith('en.json')),
    );
    final availableKeys = english.keys.toSet();
    final dartFiles = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
    final translationCall = RegExp(
      r'''['"]([a-zA-Z0-9_]+)['"]\.tr\(''',
    );

    for (final file in dartFiles) {
      final source = file.readAsStringSync();
      for (final match in translationCall.allMatches(source)) {
        final key = match.group(1)!;
        expect(availableKeys, contains(key), reason: '${file.path}: $key');
      }
    }
  });

  test('dynamic timer and theme keys exist in every locale', () {
    const timerKeys = {
      'ready',
      'start_message',
      'congrats',
      'work_completed_title',
      'work_completed_msg',
      'break_over_title',
      'break_over_msg',
    };
    const themeIds = {
      'elite',
      'classic_elite',
      'stranger_things',
      'heisenberg',
      'deep_ocean',
      'mystic_forest',
      'cyberpunk',
      'royal_gold',
      'sunset_lofi',
      'nordic_snow',
      'volcano',
    };

    for (final file in translationFiles) {
      final translations = readTranslations(file);
      for (final key in timerKeys) {
        expect(translations, contains(key), reason: '${file.path}: $key');
      }
      for (final themeId in themeIds) {
        expect(
          translations,
          contains('theme_name_$themeId'),
          reason: '${file.path}: theme_name_$themeId',
        );
        expect(
          translations,
          contains('theme_vibe_$themeId'),
          reason: '${file.path}: theme_vibe_$themeId',
        );
      }
    }
  });

  test('new user-facing copy is translated instead of falling back to English',
      () {
    const localizedKeys = {
      'focus_grow_achieve',
      'premium_subtitle',
      'star_supporter',
      'super_supporter',
      'mega_supporter',
      'theme_unlocked_72h',
    };
    final english = readTranslations(
      translationFiles.singleWhere((file) => file.path.endsWith('en.json')),
    );

    for (final file
        in translationFiles.where((file) => !file.path.endsWith('en.json'))) {
      final translations = readTranslations(file);
      for (final key in localizedKeys) {
        expect(
          translations[key],
          isNot(english[key]),
          reason: '${file.path}: $key',
        );
      }
    }
  });

  test('UI code does not embed Turkish user-facing copy', () {
    final turkish = readTranslations(
      translationFiles.singleWhere((file) => file.path.endsWith('tr.json')),
    );
    final translatedValues = turkish.values
        .whereType<String>()
        .map((value) => value.trim().toLowerCase())
        .where((value) => value.length >= 3)
        .toSet();
    final visibleSourceFiles = <File>[
      ...Directory('lib/screens').listSync(recursive: true).whereType<File>(),
      ...Directory('lib/widgets').listSync(recursive: true).whereType<File>(),
      File('lib/utils/notification_service.dart'),
    ].where((file) => file.path.endsWith('.dart'));
    final stringLiteral = RegExp(r'''(['"])([^'"\r\n]*)\1''');
    final turkishCharacters = RegExp(r'[çğıöşüÇĞİÖŞÜ]');
    const allowedInternalOrEndonymValues = {
      'elite',
      'Türkçe',
      'Français',
      'süper yıldız',
      'yıldız',
    };

    for (final file in visibleSourceFiles) {
      final lines = file.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        final line = lines[index];
        final code = line.split('//').first;
        if (code.contains('debugPrint')) continue;

        for (final match in stringLiteral.allMatches(code)) {
          final literal = match.group(2)!.trim();
          final location = '${file.path}:${index + 1}';

          if (turkishCharacters.hasMatch(literal)) {
            expect(
              allowedInternalOrEndonymValues,
              contains(literal),
              reason: '$location embeds Turkish text: $literal',
            );
          }

          expect(
            translatedValues,
            allowedInternalOrEndonymValues.contains(literal)
                ? anything
                : isNot(contains(literal.toLowerCase())),
            reason: '$location embeds a Turkish translation value: $literal',
          );
        }
      }
    }
  });
}
