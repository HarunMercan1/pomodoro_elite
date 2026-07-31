import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/revenuecat_gateway.dart';

enum PurchaseOutcome {
  purchased,
  restored,
  cancelled,
  pending,
  alreadyOwnedButInactive,
  ownedByAnotherAppAccount,
  storeUnavailable,
  failed,
}

class PurchaseProvider extends ChangeNotifier {
  final RevenueCatGateway _revenueCat;

  late final Future<void> _initialization;
  late final StreamSubscription<String?> _authSubscription;

  Future<void> _identityQueue = Future<void>.value();
  String? _desiredUserId;
  String? _syncedUserId;
  bool _isConfigured = false;
  bool _isInitializing = true;
  bool _isIdentitySyncInProgress = false;
  int _pendingIdentitySyncCount = 0;
  bool _isPurchaseInProgress = false;
  bool _isPremium = false;
  bool _isDisposed = false;
  String? _lastError;
  Offerings? _offerings;

  bool get isPremium => _isPremium;
  bool get isLoading =>
      _isInitializing || _isIdentitySyncInProgress || _isPurchaseInProgress;
  bool get isReady => _isConfigured && !_isInitializing;
  String? get lastError => _lastError;
  Offerings? get offerings => _offerings;
  Future<void> get initialized => _initialization;

  @visibleForTesting
  Future<void> get pendingIdentitySync => _identityQueue;

  PurchaseProvider({
    RevenueCatGateway? revenueCat,
    SupabaseClient? supabaseClient,
    Stream<String?>? userIdChanges,
    String? Function()? currentUserId,
  }) : _revenueCat = revenueCat ?? PurchasesRevenueCatGateway() {
    final needsSupabase = userIdChanges == null || currentUserId == null;
    final auth = needsSupabase
        ? (supabaseClient ?? Supabase.instance.client).auth
        : null;
    final readCurrentUserId = currentUserId ?? () => auth!.currentUser?.id;
    final authUserIdChanges = userIdChanges ??
        auth!.onAuthStateChange.map((data) => data.session?.user.id);

    _desiredUserId = readCurrentUserId();
    _initialization = _initialize(_desiredUserId);
    _authSubscription = authUserIdChanges.distinct().listen(
      _handleAuthUserChanged,
      onError: (Object error, StackTrace stackTrace) {
        _lastError = 'Supabase auth stream error: $error';
        debugPrint(_lastError);
      },
    );
  }

  Future<void> _initialize(String? initialUserId) async {
    try {
      // Configure receives the restored Supabase user immediately. This avoids
      // creating an anonymous RevenueCat customer and logging in concurrently.
      await _revenueCat.configure(appUserId: initialUserId);
      if (_isDisposed) return;

      _isConfigured = true;
      _syncedUserId = initialUserId;
      _revenueCat.addCustomerStateListener(_handleCustomerStateUpdate);

      await _synchronizeLatestIdentity();
      await _refreshCustomerState();
      await _fetchOfferingsInternal();
    } catch (error, stackTrace) {
      _lastError = 'RevenueCat initialization error: $error';
      debugPrint('$_lastError\n$stackTrace');
    } finally {
      _isInitializing = false;
      _notifyListeners();
    }
  }

  void _handleAuthUserChanged(String? userId) {
    if (_isDisposed || userId == _desiredUserId) return;

    _desiredUserId = userId;

    // Never expose the previous account's entitlement while identities are
    // changing. The new CustomerInfo will restore premium if applicable.
    _isPremium = false;
    _pendingIdentitySyncCount++;
    _isIdentitySyncInProgress = true;
    _notifyListeners();

    _identityQueue = _identityQueue.then((_) async {
      await _initialization;
      if (!_isConfigured || _isDisposed) return;

      try {
        await _synchronizeLatestIdentity();
        _lastError = null;
      } catch (error, stackTrace) {
        _lastError = 'RevenueCat identity sync error: $error';
        debugPrint('$_lastError\n$stackTrace');
      }
    }).whenComplete(() {
      _pendingIdentitySyncCount--;
      _isIdentitySyncInProgress = _pendingIdentitySyncCount > 0;
      _notifyListeners();
    });
  }

  Future<void> _synchronizeLatestIdentity() async {
    while (_isConfigured && !_isDisposed) {
      final targetUserId = _desiredUserId;
      if (targetUserId == _syncedUserId) return;

      final RevenueCatCustomerState customerState;
      if (targetUserId == null) {
        customerState = await _revenueCat.logOut();
      } else {
        customerState = await _revenueCat.logIn(targetUserId);
      }

      _syncedUserId = targetUserId;

      // An auth event may have arrived while the SDK operation was in flight.
      // Ignore the stale result and continue directly to the newest identity.
      if (targetUserId != _desiredUserId) continue;

      _applyCustomerState(customerState);
      return;
    }
  }

  Future<void> _refreshCustomerState() async {
    final customerState = await _revenueCat.getCustomerState();
    if (_desiredUserId == _syncedUserId) {
      _applyCustomerState(customerState);
    }
  }

  void _handleCustomerStateUpdate(RevenueCatCustomerState customerState) {
    if (_desiredUserId != _syncedUserId || _isDisposed) return;
    _applyCustomerState(customerState);
  }

  void _applyCustomerState(RevenueCatCustomerState customerState) {
    if (_isPremium == customerState.isPremium) return;
    _isPremium = customerState.isPremium;
    _notifyListeners();
  }

  Future<void> _fetchOfferingsInternal() async {
    try {
      _offerings = await _revenueCat.getOfferings();
      _notifyListeners();
    } catch (error, stackTrace) {
      _lastError = 'RevenueCat offerings error: $error';
      debugPrint('$_lastError\n$stackTrace');
    }
  }

  Future<void> fetchOfferings() async {
    await _initialization;
    if (!_isConfigured || _isDisposed) return;
    await _fetchOfferingsInternal();
  }

  Future<PurchaseOutcome> purchasePackage(Package package) async {
    await _initialization;
    if (!_isConfigured || _isDisposed || _isPurchaseInProgress) {
      return PurchaseOutcome.failed;
    }

    _isPurchaseInProgress = true;
    _notifyListeners();

    try {
      final customerState = await _revenueCat.purchasePackage(package);
      _applyCustomerState(customerState);
      _lastError = null;
      return PurchaseOutcome.purchased;
    } on PlatformException catch (error, stackTrace) {
      final errorCode = PurchasesErrorHelper.getErrorCode(error);
      if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        debugPrint(
          'Google Play reports ITEM_ALREADY_OWNED; refreshing purchases.',
        );
        return _recoverAlreadyOwnedPurchase();
      }
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        _lastError = null;
        return PurchaseOutcome.cancelled;
      }
      if (errorCode == PurchasesErrorCode.paymentPendingError) {
        _lastError = null;
        return PurchaseOutcome.pending;
      }
      if (errorCode == PurchasesErrorCode.receiptAlreadyInUseError ||
          errorCode == PurchasesErrorCode.receiptInUseByOtherSubscriberError) {
        _lastError = 'RevenueCat receipt belongs to another app account.';
        debugPrint('$_lastError\n$stackTrace');
        return PurchaseOutcome.ownedByAnotherAppAccount;
      }
      if (errorCode == PurchasesErrorCode.networkError ||
          errorCode == PurchasesErrorCode.offlineConnectionError ||
          errorCode == PurchasesErrorCode.storeProblemError) {
        _lastError = 'RevenueCat store connection error: $error';
        debugPrint('$_lastError\n$stackTrace');
        return PurchaseOutcome.storeUnavailable;
      }

      _lastError = 'RevenueCat purchase error: $error';
      debugPrint('$_lastError\n$stackTrace');
      return PurchaseOutcome.failed;
    } catch (error, stackTrace) {
      _lastError = 'RevenueCat purchase error: $error';
      debugPrint('$_lastError\n$stackTrace');
      return PurchaseOutcome.failed;
    } finally {
      _isPurchaseInProgress = false;
      _notifyListeners();
    }
  }

  Future<PurchaseOutcome> _recoverAlreadyOwnedPurchase() async {
    try {
      // restorePurchases is the RevenueCat-recommended response to
      // ITEM_ALREADY_OWNED. If a refund/re-purchase happened recently, force a
      // second uncached Play/RevenueCat sync before deciding that access is
      // still inactive.
      var customerState = await _revenueCat.restorePurchases();
      if (!customerState.isPremium) {
        customerState = await _revenueCat.resyncPurchases();
      }

      _applyCustomerState(customerState);
      _lastError = null;
      return customerState.isPremium
          ? PurchaseOutcome.restored
          : PurchaseOutcome.alreadyOwnedButInactive;
    } catch (error, stackTrace) {
      if (error is PlatformException) {
        final errorCode = PurchasesErrorHelper.getErrorCode(error);
        if (errorCode == PurchasesErrorCode.receiptAlreadyInUseError ||
            errorCode ==
                PurchasesErrorCode.receiptInUseByOtherSubscriberError) {
          _lastError = 'RevenueCat receipt belongs to another app account.';
          debugPrint('$_lastError\n$stackTrace');
          return PurchaseOutcome.ownedByAnotherAppAccount;
        }
      }

      _lastError = 'RevenueCat already-owned recovery error: $error';
      debugPrint('$_lastError\n$stackTrace');
      return PurchaseOutcome.alreadyOwnedButInactive;
    }
  }

  Future<bool> restorePurchases() async {
    await _initialization;
    if (!_isConfigured || _isDisposed || _isPurchaseInProgress) return false;

    _isPurchaseInProgress = true;
    _notifyListeners();

    try {
      return await _restorePurchasesInternal();
    } finally {
      _isPurchaseInProgress = false;
      _notifyListeners();
    }
  }

  Future<bool> _restorePurchasesInternal() async {
    try {
      final customerState = await _revenueCat.restorePurchases();
      _applyCustomerState(customerState);
      _lastError = null;
      return customerState.isPremium;
    } catch (error, stackTrace) {
      _lastError = 'RevenueCat restore error: $error';
      debugPrint('$_lastError\n$stackTrace');
      return false;
    }
  }

  void _notifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(_authSubscription.cancel());
    if (_isConfigured) {
      _revenueCat.removeCustomerStateListener(_handleCustomerStateUpdate);
    }
    super.dispose();
  }
}
