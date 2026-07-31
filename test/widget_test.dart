import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_elite/widgets/time_option_button.dart';

void main() {
  testWidgets('time option renders and handles taps', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TimeOptionButton(
            title: 'Focus',
            minutes: 25,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Focus'), findsOneWidget);
    expect(find.textContaining('25'), findsOneWidget);

    await tester.tap(find.text('Focus'));
    expect(tapped, isTrue);
  });
}
