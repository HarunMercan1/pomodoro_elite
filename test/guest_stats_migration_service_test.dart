import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_elite/services/guest_stats_migration_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeMigrationGateway implements GuestStatsMigrationGateway {
  bool failNext = false;
  final attempts = <GuestStatsMigrationBatch>[];
  final appliedIds = <String>{};

  @override
  Future<void> applyBatch(
    String userId,
    GuestStatsMigrationBatch batch,
  ) async {
    attempts.add(batch);
    if (failNext) {
      failNext = false;
      throw StateError('network response lost');
    }
    appliedIds.add(batch.id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'daily_stats': jsonEncode({'2026-07-30': 25, '2026-07-31': 50}),
      'daily_session_counts': jsonEncode({'2026-07-30': 1, '2026-07-31': 2}),
      'total_sessions': 3,
      'total_minutes': 75,
    });
  });

  test('guest snapshot migrates all totals and daily history', () async {
    final gateway = _FakeMigrationGateway();
    final service = GuestStatsMigrationService(gateway: gateway);

    await service.prepareGuestSnapshot();
    expect(await service.hasPendingBatches(), isTrue);
    await service.migratePending('user-1');

    expect(gateway.appliedIds, hasLength(1));
    expect(gateway.attempts.single.totalMinutes, 75);
    expect(gateway.attempts.single.totalSessions, 3);
    expect(gateway.attempts.single.dailyStats, hasLength(2));
    expect(await service.hasPendingBatches(), isFalse);
  });

  test('lost response retries the exact same idempotency batch', () async {
    final gateway = _FakeMigrationGateway()..failNext = true;
    final service = GuestStatsMigrationService(gateway: gateway);
    await service.prepareGuestSnapshot();

    await expectLater(
      service.migratePending('user-1'),
      throwsA(isA<StateError>()),
    );
    expect(await service.hasPendingBatches(), isTrue);

    await service.migratePending('user-1');

    expect(gateway.attempts, hasLength(2));
    expect(gateway.attempts[0].id, gateway.attempts[1].id);
    expect(gateway.appliedIds, hasLength(1));
  });

  test('sessions completed while migration is pending use a separate batch',
      () async {
    final gateway = _FakeMigrationGateway()..failNext = true;
    final service = GuestStatsMigrationService(gateway: gateway);
    await service.prepareGuestSnapshot();
    await expectLater(
      service.migratePending('user-1'),
      throwsA(isA<StateError>()),
    );

    await service.enqueueSessionDelta(
      minutes: 25,
      dateKey: '2026-07-31',
      currentStreak: 2,
    );
    await service.migratePending('user-1');

    expect(gateway.appliedIds, hasLength(2));
    final successfulAttempts = gateway.attempts.skip(1).toList();
    expect(successfulAttempts[0].id, isNot(successfulAttempts[1].id));
    expect(successfulAttempts[1].totalMinutes, 25);
  });

  test('a bound migration cannot leak into another account', () async {
    final gateway = _FakeMigrationGateway()..failNext = true;
    final service = GuestStatsMigrationService(gateway: gateway);
    await service.prepareGuestSnapshot();
    await expectLater(
      service.migratePending('user-1'),
      throwsA(isA<StateError>()),
    );

    await expectLater(
      service.migratePending('user-2'),
      throwsA(isA<StateError>()),
    );
  });

  test('clearing stats also clears every pending migration batch', () async {
    final service = GuestStatsMigrationService(
      gateway: _FakeMigrationGateway(),
    );
    await service.prepareGuestSnapshot();
    expect(await service.hasPendingBatches(), isTrue);

    await service.clearPendingBatches();

    expect(await service.hasPendingBatches(), isFalse);
  });
}
