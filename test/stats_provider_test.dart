import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_elite/providers/stats_provider.dart';
import 'package:pomodoro_elite/services/guest_stats_migration_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _NoopMigrationGateway implements GuestStatsMigrationGateway {
  @override
  Future<void> applyBatch(
    String userId,
    GuestStatsMigrationBatch batch,
  ) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('the same timer session is recorded only once across app restarts',
      () async {
    final supabase = SupabaseClient(
      'https://example.supabase.co',
      'test-anon-key',
    );
    final migrationService = GuestStatsMigrationService(
      gateway: _NoopMigrationGateway(),
    );
    final firstProvider = StatsProvider(
      supabaseClient: supabase,
      guestStatsMigrationService: migrationService,
    );
    await _waitUntilLoaded(firstProvider);

    await firstProvider.addSession(25, sessionId: 'timer-session-1');
    await firstProvider.addSession(25, sessionId: 'timer-session-1');

    expect(firstProvider.totalMinutes, 25);
    expect(firstProvider.totalSessions, 1);
    expect(firstProvider.todayMinutes, 25);
    expect(firstProvider.todaySessions, 1);
    firstProvider.dispose();

    final restoredProvider = StatsProvider(
      supabaseClient: supabase,
      guestStatsMigrationService: migrationService,
    );
    addTearDown(restoredProvider.dispose);
    await _waitUntilLoaded(restoredProvider);
    await restoredProvider.addSession(25, sessionId: 'timer-session-1');

    expect(restoredProvider.totalMinutes, 25);
    expect(restoredProvider.totalSessions, 1);
  });
}

Future<void> _waitUntilLoaded(StatsProvider provider) async {
  if (!provider.isLoading) return;
  final completer = Completer<void>();
  void listener() {
    if (!provider.isLoading && !completer.isCompleted) completer.complete();
  }

  provider.addListener(listener);
  try {
    await completer.future.timeout(const Duration(seconds: 2));
  } finally {
    provider.removeListener(listener);
  }
}
