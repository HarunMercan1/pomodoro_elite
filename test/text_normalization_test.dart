import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_elite/utils/text_normalization.dart';

void main() {
  test('premium diamond is removed without leaving a broken surrogate', () {
    expect(
      withoutLeadingPremiumEmoji('💎 Premium Kullanıcısınız'),
      'Premium Kullanıcısınız',
    );
  });

  test('premium crown and missing whitespace are normalized', () {
    expect(withoutLeadingPremiumEmoji('👑Premium'), 'Premium');
  });

  test('plain translated copy is preserved', () {
    expect(withoutLeadingPremiumEmoji('  Premium  '), 'Premium');
  });
}
