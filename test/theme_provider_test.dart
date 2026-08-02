import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodoro_elite/providers/theme_provider.dart';

const _refinedThemeIds = <String>[
  'deep_ocean',
  'mystic_forest',
  'cyberpunk',
  'royal_gold',
  'sunset_lofi',
  'nordic_snow',
  'volcano',
];

double _contrastRatio(Color first, Color second) {
  final firstLuminance = first.computeLuminance();
  final secondLuminance = second.computeLuminance();
  final lighter =
      firstLuminance > secondLuminance ? firstLuminance : secondLuminance;
  final darker =
      firstLuminance > secondLuminance ? secondLuminance : firstLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}

String _colorLabel(Color color) =>
    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

Color _readableForeground(Color background) =>
    background.computeLuminance() > 0.179
        ? const Color(0xFF101318)
        : const Color(0xFFFFFFFF);

String _themeColorSignature(AppTheme theme) {
  String color(Color? value) => value == null ? '-' : _colorLabel(value);

  String state(ThemeStateColors value) => [
        color(value.bgColor),
        value.gradientColors?.map(color).join('/') ?? '-',
        color(value.accentColor),
        color(value.textColor),
        color(value.effectiveButtonBg),
        color(value.effectiveButtonTextColor),
        color(value.effectiveMenuButtonColor),
        color(value.effectiveMenuButtonTextColor),
      ].join(',');

  return [
    color(theme.settingsBgColor),
    color(theme.settingsCardColor),
    color(theme.settingsBorderColor),
    color(theme.settingsItemColor),
    state(theme.idle),
    state(theme.focus),
    state(theme.breakState),
    state(theme.workPaused!),
    state(theme.finish),
  ].join('|');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('theme catalog keeps the existing theme identities and order', () {
    expect(
      AppThemes.all.map((theme) => theme.id),
      const [
        'elite',
        'classic_elite',
        'stranger_things',
        'heisenberg',
        ..._refinedThemeIds,
      ],
    );
  });

  test('the first four approved palettes stay unchanged', () {
    const expectedSignatures = <String, String>{
      'elite': '-|#FF202020|#0FFFFFFF|-|'
          '#FF141414,#FF141414/#FF141414,#FF1A2980,#FFFFFFFF,#FF1A2980,#FFFFFFFF,#FFFFFFFF,#FF1A2980|'
          '#FF1A2980,#FF1A2980/#FF26D0CE,#FF00E5FF,#FFFFFFFF,#FFFFFFFF,#FF1A2980,#FF1A2980,#FFFFFFFF|'
          '#FF1A2980,#FF1A2980/#FF26D0CE,#FF00E5FF,#FFFFFFFF,#FFFFFFFF,#FF1A2980,#FF1A2980,#FFFFFFFF|'
          '#FF5D4037,#FFE6DADA/#FFC7A17A,#FF5D4037,#FF5D4037,#FFFFFFFF,#FF5D4037,#FF5D4037,#FFFFFFFF|'
          '#FF1B5E20,#FF093028/#FF237A57,#FF388E3C,#FFFFFFFF,#FFFFFFFF,#FF1B5E20,#FF388E3C,#FFFFFFFF',
      'classic_elite': '#FFE3F2FD|#FFBBDEFB|#661565C0|#FF0D47A1|'
          '#FF121212,#FF121212/#FF1E1E1E,#FF1565C0,#FFFFFFFF,#FF1565C0,#FFFFFFFF,#FFFFFFFF,#FF1565C0|'
          '#FFBBDEFB,#FFBBDEFB/#FF90CAF9,#FF0D47A1,#FF0D47A1,#FFFFFFFF,#FF1565C0,#FF0D47A1,#FFFFFFFF|'
          '#FFBBDEFB,#FFBBDEFB/#FF90CAF9,#FF0D47A1,#FF0D47A1,#FFFFFFFF,#FF1565C0,#FF0D47A1,#FFFFFFFF|'
          '#FFECEFF1,#FFECEFF1/#FFCFD8DC,#FF455A64,#FF37474F,#FFFFFFFF,#FF455A64,#FF455A64,#FFFFFFFF|'
          '#FF43A047,#FF388E3C/#FF66BB6A,#FFFFFFFF,#FFFFFFFF,#FFFFFFFF,#FF2E7D32,#FFFFFFFF,#FF2E7D32',
      'stranger_things': '-|#FF1A0000|#33B71C1C|-|'
          '#FF000000,#FF000000/#FF1A0000,#FFD32F2F,#FFFFFFFF,#FFD32F2F,#FFFFFFFF,#FFD32F2F,#FFFFFFFF|'
          '#FFB71C1C,#FF000000/#FFB71C1C,#FFFF5252,#FFFFFFFF,#FFFFFFFF,#FFB71C1C,#FFD32F2F,#FFFFFFFF|'
          '#FFB71C1C,#FF000000/#FFB71C1C,#FFFF5252,#FFFFFFFF,#FFFFFFFF,#FFB71C1C,#FFD32F2F,#FFFFFFFF|'
          '#FF212121,#FF424242/#FF212121,#FF9E9E9E,#B3FFFFFF,#FFFFFFFF,#FF000000,#FF9E9E9E,#FFFFFFFF|'
          '#FF000000,#FF1A1A1A/#FFFFFF00,#FF000000,#FF000000,#FF000000,#FFFFD600,#FF000000,#FFFFFFFF',
      'heisenberg': '#FF00363A|#FF005662|#FF00E676|#FFFFD600|'
          '#FF006064,#FF00363A/#FF006064,#FF00E5FF,#FFFFFFFF,#FF00E5FF,#FF00363A,#FF004D40,#FFFFFFFF|'
          '#FFFFD600,#FFFBC02D/#FFFFAB00,#FF263238,#FF263238,#FFFFFFFF,#FFFFD600,#FFFFF9C4,#FF263238|'
          '#FFFFD600,#FFFBC02D/#FFFFAB00,#FF263238,#FF263238,#FFFFFFFF,#FFFFD600,#FFFFF9C4,#FF263238|'
          '#FF1B5E20,#FF003300/#FF1B5E20,#FF69F0AE,#FFFFFFFF,#FFFFFFFF,#FF1B5E20,#FF2E7D32,#FFFFFFFF|'
          '#FF004D40,#FF00251A/#FF004D40,#FFFFFFFF,#FFFFFFFF,#FFFFFFFF,#FF004D40,#FFFFFFFF,#FFFFFFFF',
    };

    for (final entry in expectedSignatures.entries) {
      expect(
        _themeColorSignature(AppThemes.getById(entry.key)),
        entry.value,
        reason: '${entry.key} palette constants changed',
      );
    }
  });

  test('refined theme settings colors keep text readable', () {
    for (final themeId in _refinedThemeIds) {
      final theme = AppThemes.getById(themeId);
      final text = theme.settingsItemColor!;
      final surfaces = [theme.settingsBgColor!, theme.settingsCardColor!];

      for (final surface in surfaces) {
        final ratio = _contrastRatio(text, surface);
        expect(
          ratio,
          greaterThanOrEqualTo(4.5),
          reason:
              '$themeId settings text ${_colorLabel(text)} / ${_colorLabel(surface)} = ${ratio.toStringAsFixed(2)}',
        );
      }
    }
  });

  test('settings accent has at least 3:1 contrast on every theme card',
      () async {
    final provider = ThemeProvider();
    addTearDown(provider.dispose);
    provider.updatePremiumStatus(isPremium: true, isLoading: false);
    await provider.initialized;

    for (final theme in AppThemes.all) {
      await provider.selectTheme(theme.id);
      final card = theme.settingsCardColor ?? const Color(0xFF202020);
      final background =
          card.a < 1 ? Color.alphaBlend(card, provider.settingsBgColor) : card;
      final ratio = _contrastRatio(provider.settingsAccentColor, background);

      expect(
        ratio,
        greaterThanOrEqualTo(3),
        reason:
            '${theme.id} settings accent ${_colorLabel(provider.settingsAccentColor)} / ${_colorLabel(background)} = ${ratio.toStringAsFixed(2)}',
      );
    }
  });

  test('theme selection cards keep labels and selected accents readable', () {
    for (final theme in AppThemes.all) {
      final surfaceStart = theme.settingsCardColor ?? theme.idle.bgColor;
      final surfaceEnd =
          Color.lerp(surfaceStart, theme.focus.bgColor, 0.13) ?? surfaceStart;
      final surfaceSample =
          Color.lerp(surfaceStart, surfaceEnd, 0.5) ?? surfaceStart;
      final primaryText = _readableForeground(surfaceSample);
      final secondaryText = primaryText.withValues(alpha: 0.75);
      final accentBackground =
          _contrastRatio(theme.idle.accentColor, surfaceStart) <=
                  _contrastRatio(theme.idle.accentColor, surfaceEnd)
              ? surfaceStart
              : surfaceEnd;
      final accent = ThemeContrast.ensure(
        foreground: theme.idle.accentColor,
        background: accentBackground,
        minimumRatio: 3.2,
      );

      for (final surface in [surfaceStart, surfaceEnd]) {
        final titleRatio = _contrastRatio(primaryText, surface);
        expect(
          titleRatio,
          greaterThanOrEqualTo(4.5),
          reason:
              '${theme.id} theme card title / ${_colorLabel(surface)} = ${titleRatio.toStringAsFixed(2)}',
        );

        final compositedSecondary = Color.alphaBlend(secondaryText, surface);
        final subtitleRatio = _contrastRatio(compositedSecondary, surface);
        expect(
          subtitleRatio,
          greaterThanOrEqualTo(4.5),
          reason:
              '${theme.id} theme card subtitle / ${_colorLabel(surface)} = ${subtitleRatio.toStringAsFixed(2)}',
        );

        final accentRatio = _contrastRatio(accent, surface);
        expect(
          accentRatio,
          greaterThanOrEqualTo(3),
          reason:
              '${theme.id} theme card accent / ${_colorLabel(surface)} = ${accentRatio.toStringAsFixed(2)}',
        );

        final chevron = Color.alphaBlend(
          primaryText.withValues(alpha: 0.56),
          surface,
        );
        expect(
          _contrastRatio(chevron, surface),
          greaterThanOrEqualTo(3),
          reason: '${theme.id} theme card chevron is too faint',
        );
      }
    }
  });

  test('theme preview dots stay visible without changing theme constants', () {
    for (final theme in AppThemes.all) {
      for (final state in [theme.idle, theme.focus, theme.breakState]) {
        final gradient = state.gradientColors;
        final background = gradient == null || gradient.length < 2
            ? state.bgColor
            : Color.lerp(gradient.first, gradient.last, 0.5)!;
        final dot = ThemeContrast.ensure(
          foreground: state.accentColor,
          background: background,
        );

        expect(
          _contrastRatio(dot, background),
          greaterThanOrEqualTo(3),
          reason: '${theme.id} preview dot is not visible',
        );
      }
    }
  });

  test('refined theme states meet text, control, and accent contrast', () {
    for (final themeId in _refinedThemeIds) {
      final theme = AppThemes.getById(themeId);
      final states = <String, ThemeStateColors>{
        'idle': theme.idle,
        'focus': theme.focus,
        'break': theme.breakState,
        'workPaused': theme.workPaused!,
        'finish': theme.finish,
      };

      for (final entry in states.entries) {
        final state = entry.value;
        final backgrounds = <Color>{
          state.bgColor,
          ...?state.gradientColors,
        };

        for (final background in backgrounds) {
          final textRatio = _contrastRatio(state.textColor, background);
          expect(
            textRatio,
            greaterThanOrEqualTo(4.5),
            reason:
                '$themeId ${entry.key} text ${_colorLabel(state.textColor)} / ${_colorLabel(background)} = ${textRatio.toStringAsFixed(2)}',
          );

          final accentRatio = _contrastRatio(state.accentColor, background);
          expect(
            accentRatio,
            greaterThanOrEqualTo(3),
            reason:
                '$themeId ${entry.key} accent ${_colorLabel(state.accentColor)} / ${_colorLabel(background)} = ${accentRatio.toStringAsFixed(2)}',
          );
        }

        final buttonRatio = _contrastRatio(
          state.effectiveButtonTextColor,
          state.effectiveButtonBg,
        );
        expect(
          buttonRatio,
          greaterThanOrEqualTo(4.5),
          reason:
              '$themeId ${entry.key} main button = ${buttonRatio.toStringAsFixed(2)}',
        );

        final menuRatio = _contrastRatio(
          state.effectiveMenuButtonTextColor,
          state.effectiveMenuButtonColor,
        );
        expect(
          menuRatio,
          greaterThanOrEqualTo(4.5),
          reason:
              '$themeId ${entry.key} menu button = ${menuRatio.toStringAsFixed(2)}',
        );
      }
    }
  });

  test('premium users can select a theme without a temporary unlock', () async {
    final provider = ThemeProvider();
    addTearDown(provider.dispose);

    provider.updatePremiumStatus(isPremium: true, isLoading: false);
    await provider.selectTheme('cyberpunk');

    expect(provider.currentThemeId, 'cyberpunk');
    expect(provider.isThemeAvailable('cyberpunk'), isTrue);
  });

  test('persisted premium theme survives entitlement initialization', () async {
    SharedPreferences.setMockInitialValues({
      'current_theme': 'cyberpunk',
    });
    final provider = ThemeProvider();
    addTearDown(provider.dispose);

    provider.updatePremiumStatus(isPremium: true, isLoading: false);
    await provider.initialized;

    expect(provider.currentThemeId, 'cyberpunk');
  });

  test('persisted theme is not reset while RevenueCat is still loading',
      () async {
    SharedPreferences.setMockInitialValues({
      'current_theme': 'cyberpunk',
    });
    final provider = ThemeProvider();
    addTearDown(provider.dispose);

    provider.updatePremiumStatus(isPremium: false, isLoading: true);
    await provider.initialized;

    expect(provider.currentThemeId, 'cyberpunk');

    provider.updatePremiumStatus(isPremium: true, isLoading: false);

    expect(provider.currentThemeId, 'cyberpunk');
  });

  test('selected premium theme survives an in-progress identity switch',
      () async {
    final provider = ThemeProvider();
    addTearDown(provider.dispose);

    provider.updatePremiumStatus(isPremium: true, isLoading: false);
    await provider.selectTheme('cyberpunk');

    provider.updatePremiumStatus(isPremium: false, isLoading: true);

    expect(provider.currentThemeId, 'cyberpunk');

    provider.updatePremiumStatus(isPremium: true, isLoading: false);

    expect(provider.currentThemeId, 'cyberpunk');
  });

  test('persisted locked theme resets after non-premium status resolves',
      () async {
    SharedPreferences.setMockInitialValues({
      'current_theme': 'cyberpunk',
    });
    final provider = ThemeProvider();
    addTearDown(provider.dispose);

    provider.updatePremiumStatus(isPremium: false, isLoading: false);
    await provider.initialized;

    expect(provider.currentThemeId, 'elite');
  });

  test('non-premium users still cannot select a locked theme', () async {
    final provider = ThemeProvider();
    addTearDown(provider.dispose);

    provider.updatePremiumStatus(isPremium: false, isLoading: false);
    await provider.selectTheme('cyberpunk');

    expect(provider.currentThemeId, 'elite');
    expect(provider.isThemeAvailable('cyberpunk'), isFalse);
  });
}
