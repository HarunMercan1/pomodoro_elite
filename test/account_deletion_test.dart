import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomodoro_elite/providers/auth_provider.dart';
import 'package:pomodoro_elite/services/guest_stats_migration_service.dart';
import 'package:pomodoro_elite/utils/text_normalization.dart';
import 'package:pomodoro_elite/widgets/delete_account_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _NoopMigrationGateway implements GuestStatsMigrationGateway {
  @override
  Future<void> applyBatch(
    String userId,
    GuestStatsMigrationBatch batch,
  ) async {}
}

class _RecordingMigrationService extends GuestStatsMigrationService {
  _RecordingMigrationService(this.events)
      : super(gateway: _NoopMigrationGateway());

  final List<String> events;

  @override
  Future<void> clearPendingBatches() async {
    events.add('clear_guest_queue');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'isGuest': false});
  });

  group('matchesDeleteConfirmation', () {
    test('accepts the localized word case-insensitively', () {
      expect(matchesDeleteConfirmation('SİL', 'SİL'), isTrue);
      expect(matchesDeleteConfirmation('sil', 'SİL'), isTrue);
      expect(matchesDeleteConfirmation('SIL', 'SİL'), isTrue);
      expect(matchesDeleteConfirmation('  löschen ', 'LÖSCHEN'), isTrue);
    });

    test('always accepts DELETE as a fallback', () {
      expect(matchesDeleteConfirmation('delete', 'SİL'), isTrue);
      expect(matchesDeleteConfirmation('DELETE', '削除'), isTrue);
    });

    test('rejects empty and partial input', () {
      expect(matchesDeleteConfirmation('', 'SİL'), isFalse);
      expect(matchesDeleteConfirmation('   ', 'SİL'), isFalse);
      expect(matchesDeleteConfirmation('SI', 'SİL'), isFalse);
      expect(matchesDeleteConfirmation('DELET', 'DELETE'), isFalse);
    });
  });

  group('AuthProvider.deleteAccount', () {
    AuthProvider createProvider({
      required List<String> events,
      required Future<void> Function() deleteRemoteAccount,
    }) {
      final provider = AuthProvider(
        supabaseClient: SupabaseClient(
          'https://example.supabase.co',
          'test-anon-key',
        ),
        guestStatsMigrationService: _RecordingMigrationService(events),
        onBeforeIdentityChange: () async => events.add('identity_change'),
        deleteRemoteAccount: deleteRemoteAccount,
      );
      addTearDown(provider.dispose);
      return provider;
    }

    test('deletes remotely first, then resets the app to a clean guest',
        () async {
      final events = <String>[];
      final provider = createProvider(
        events: events,
        deleteRemoteAccount: () async => events.add('rpc'),
      );

      await provider.deleteAccount();

      expect(events, ['rpc', 'identity_change', 'clear_guest_queue']);
      expect(provider.user, isNull);
      expect(provider.isGuest, isTrue);
      expect(provider.isAuthenticated, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isGuest'), isTrue);
    });

    test('leaves local state untouched when the server deletion fails',
        () async {
      final events = <String>[];
      final provider = createProvider(
        events: events,
        deleteRemoteAccount: () async {
          events.add('rpc');
          throw const PostgrestException(message: 'network down');
        },
      );

      await expectLater(
        provider.deleteAccount(),
        throwsA(isA<PostgrestException>()),
      );

      expect(events, ['rpc']);
      expect(provider.isGuest, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('isGuest'), isFalse);
    });
  });

  group('DeleteAccountDialog', () {
    Future<List<bool?>> pumpDialog(
      WidgetTester tester,
      Future<void> Function() onDelete,
    ) async {
      final results = <bool?>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                results.add(
                  await showDialog<bool>(
                    context: context,
                    builder: (_) => DeleteAccountDialog(
                      onDelete: onDelete,
                      surfaceColor: Colors.black,
                      itemColor: Colors.white,
                      borderColor: Colors.grey,
                    ),
                  ),
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return results;
    }

    FilledButton confirmButton(WidgetTester tester) => tester.widget(
          find.byKey(const ValueKey('delete_account_confirm_button')),
        );

    testWidgets('stays disabled until the confirmation word is typed',
        (tester) async {
      var deleteCalls = 0;
      await pumpDialog(tester, () async => deleteCalls++);

      expect(confirmButton(tester).onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('delete_account_confirm_field')),
        'DEL',
      );
      await tester.pump();
      expect(confirmButton(tester).onPressed, isNull);

      await tester.enterText(
        find.byKey(const ValueKey('delete_account_confirm_field')),
        'DELETE',
      );
      await tester.pump();
      expect(confirmButton(tester).onPressed, isNotNull);
      expect(deleteCalls, 0);
    });

    testWidgets('shows an error and stays open when deletion fails',
        (tester) async {
      final results = await pumpDialog(
        tester,
        () async => throw Exception('offline'),
      );

      await tester.enterText(
        find.byKey(const ValueKey('delete_account_confirm_field')),
        'DELETE',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('delete_account_confirm_button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DeleteAccountDialog), findsOneWidget);
      expect(find.byKey(const ValueKey('delete_account_error')), findsOneWidget);
      expect(results, isEmpty);
    });

    testWidgets('pops true after a successful deletion', (tester) async {
      var deleteCalls = 0;
      final results = await pumpDialog(tester, () async => deleteCalls++);

      await tester.enterText(
        find.byKey(const ValueKey('delete_account_confirm_field')),
        'delete',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('delete_account_confirm_button')),
      );
      await tester.pumpAndSettle();

      expect(deleteCalls, 1);
      expect(find.byType(DeleteAccountDialog), findsNothing);
      expect(results, [true]);
    });
  });
}
