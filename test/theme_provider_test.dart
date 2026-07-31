import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pomodoro_elite/providers/theme_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
