import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all locales define the same supporter tier keys', () {
    final translationDirectory = Directory('assets/translations');
    final translationFiles = translationDirectory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'));

    for (final file in translationFiles) {
      final translations =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(translations['star_supporter'], isNotEmpty, reason: file.path);
      expect(translations['super_supporter'], isNotEmpty, reason: file.path);
      expect(translations['mega_supporter'], isNotEmpty, reason: file.path);
      expect(
        translations.containsKey('super_star_supporter'),
        isFalse,
        reason: file.path,
      );
    }
  });

  test('Turkish supporter names match the product catalog', () {
    final translations = jsonDecode(
      File('assets/translations/tr.json').readAsStringSync(),
    ) as Map<String, dynamic>;

    expect(translations['star_supporter'], 'Yıldız Destekçi');
    expect(translations['super_supporter'], 'Süper Destekçi');
    expect(translations['mega_supporter'], 'Mega Destekçi');
  });
}
