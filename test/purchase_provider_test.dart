import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:pomodoro_elite/providers/purchase_provider.dart';
import 'package:pomodoro_elite/services/revenuecat_gateway.dart';

void main() {
  group('PurchaseProvider identity synchronization', () {
    late StreamController<String?> authChanges;

    setUp(() {
      authChanges = StreamController<String?>.broadcast();
    });

    tearDown(() async {
      await authChanges.close();
    });

    test('configures RevenueCat with the restored Supabase user', () async {
      final gateway = _FakeRevenueCatGateway(
        premiumByUser: {'user-a': true},
      );
      final provider = PurchaseProvider(
        revenueCat: gateway,
        currentUserId: () => 'user-a',
        userIdChanges: authChanges.stream,
      );
      addTearDown(provider.dispose);

      await provider.initialized;

      expect(gateway.configuredUserIds, ['user-a']);
      expect(gateway.loginCalls, isEmpty);
      expect(provider.isPremium, isTrue);
      expect(provider.isReady, isTrue);
    });

    test('waits for configure before processing an auth event', () async {
      final configureCompleter = Completer<void>();
      final gateway = _FakeRevenueCatGateway(
        configureCompleter: configureCompleter,
        premiumByUser: {'user-a': true},
      );
      final provider = PurchaseProvider(
        revenueCat: gateway,
        currentUserId: () => null,
        userIdChanges: authChanges.stream,
      );
      addTearDown(provider.dispose);

      authChanges.add('user-a');
      await Future<void>.delayed(Duration.zero);

      expect(gateway.loginCalls, isEmpty);

      configureCompleter.complete();
      await provider.initialized;
      await provider.pendingIdentitySync;

      expect(gateway.loginCalls, ['user-a']);
      expect(provider.isPremium, isTrue);
    });

    test('ignores stale login result and applies the latest user', () async {
      final userALogin = Completer<RevenueCatCustomerState>();
      final userALoginStarted = Completer<void>();
      final gateway = _FakeRevenueCatGateway(
        premiumByUser: {'user-b': false},
        loginResults: {'user-a': userALogin.future},
        loginStarted: {'user-a': userALoginStarted},
      );
      final provider = PurchaseProvider(
        revenueCat: gateway,
        currentUserId: () => null,
        userIdChanges: authChanges.stream,
      );
      addTearDown(provider.dispose);

      await provider.initialized;
      authChanges.add('user-a');
      await userALoginStarted.future;

      authChanges.add('user-b');
      userALogin.complete(
        const RevenueCatCustomerState(isPremium: true),
      );

      await Future<void>.delayed(Duration.zero);
      await provider.pendingIdentitySync;

      expect(gateway.loginCalls, ['user-a', 'user-b']);
      expect(provider.isPremium, isFalse);
    });

    test('logs out RevenueCat when Supabase signs out', () async {
      final gateway = _FakeRevenueCatGateway(
        premiumByUser: {'user-a': true},
      );
      final provider = PurchaseProvider(
        revenueCat: gateway,
        currentUserId: () => 'user-a',
        userIdChanges: authChanges.stream,
      );
      addTearDown(provider.dispose);

      await provider.initialized;
      expect(provider.isPremium, isTrue);

      authChanges.add(null);
      await Future<void>.delayed(Duration.zero);
      await provider.pendingIdentitySync;

      expect(gateway.logoutCalls, 1);
      expect(provider.isPremium, isFalse);
    });

    test('leaves loading state when identity synchronization fails', () async {
      final gateway = _FakeRevenueCatGateway(
        loginErrors: {'user-a': StateError('login failed')},
      );
      final provider = PurchaseProvider(
        revenueCat: gateway,
        currentUserId: () => null,
        userIdChanges: authChanges.stream,
      );
      addTearDown(provider.dispose);

      await provider.initialized;
      authChanges.add('user-a');
      await Future<void>.delayed(Duration.zero);
      await provider.pendingIdentitySync;

      expect(provider.isLoading, isFalse);
      expect(provider.isPremium, isFalse);
      expect(provider.lastError, contains('identity sync error'));
    });
  });
}

class _FakeRevenueCatGateway implements RevenueCatGateway {
  final Completer<void>? configureCompleter;
  final Map<String, bool> premiumByUser;
  final Map<String, Future<RevenueCatCustomerState>> loginResults;
  final Map<String, Completer<void>> loginStarted;
  final Map<String, Object> loginErrors;

  final List<String?> configuredUserIds = [];
  final List<String> loginCalls = [];
  int logoutCalls = 0;

  String? _currentUserId;
  RevenueCatCustomerStateListener? _listener;

  _FakeRevenueCatGateway({
    this.configureCompleter,
    this.premiumByUser = const {},
    this.loginResults = const {},
    this.loginStarted = const {},
    this.loginErrors = const {},
  });

  RevenueCatCustomerState get _currentState => RevenueCatCustomerState(
        isPremium:
            _currentUserId != null && (premiumByUser[_currentUserId] ?? false),
      );

  @override
  Future<void> configure({String? appUserId}) async {
    configuredUserIds.add(appUserId);
    await configureCompleter?.future;
    _currentUserId = appUserId;
  }

  @override
  Future<RevenueCatCustomerState> getCustomerState() async => _currentState;

  @override
  Future<RevenueCatCustomerState> logIn(String userId) async {
    loginCalls.add(userId);
    loginStarted[userId]?.complete();
    final error = loginErrors[userId];
    if (error != null) throw error;
    final state = await (loginResults[userId] ??
        Future<RevenueCatCustomerState>.value(
          RevenueCatCustomerState(
            isPremium: premiumByUser[userId] ?? false,
          ),
        ));
    _currentUserId = userId;
    return state;
  }

  @override
  Future<RevenueCatCustomerState> logOut() async {
    logoutCalls++;
    _currentUserId = null;
    return const RevenueCatCustomerState(isPremium: false);
  }

  @override
  Future<Offerings?> getOfferings() async => null;

  @override
  Future<RevenueCatCustomerState> purchasePackage(Package package) {
    throw UnimplementedError();
  }

  @override
  Future<RevenueCatCustomerState> restorePurchases() async => _currentState;

  @override
  void addCustomerStateListener(RevenueCatCustomerStateListener listener) {
    _listener = listener;
  }

  @override
  void removeCustomerStateListener(RevenueCatCustomerStateListener listener) {
    if (_listener == listener) _listener = null;
  }
}
