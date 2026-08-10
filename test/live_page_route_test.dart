import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pomodoro_elite/utils/live_page_route.dart';

void main() {
  test('live routes keep native animation without compositor snapshots', () {
    final route = livePageRoute<void>(
      builder: (_) => const SizedBox.shrink(),
    );

    expect(route, isA<MaterialPageRoute<void>>());
    final materialRoute = route as MaterialPageRoute<void>;
    expect(materialRoute.allowSnapshotting, isFalse);
  });
}
