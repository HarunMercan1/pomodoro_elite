import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/supabase_constants.dart';
import '../services/guest_stats_migration_service.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({
    GuestStatsMigrationService? guestStatsMigrationService,
    SupabaseClient? supabaseClient,
    Future<void> Function()? onBeforeIdentityChange,
    Future<void> Function()? deleteRemoteAccount,
  })  : _supabase = supabaseClient ?? Supabase.instance.client,
        _guestStatsMigrationService =
            guestStatsMigrationService ?? GuestStatsMigrationService(),
        _onBeforeIdentityChange = onBeforeIdentityChange,
        _deleteRemoteAccount = deleteRemoteAccount {
    _initializeAuth();
  }

  final SupabaseClient _supabase;
  final GuestStatsMigrationService _guestStatsMigrationService;
  final Future<void> Function()? _onBeforeIdentityChange;
  final Future<void> Function()? _deleteRemoteAccount;
  User? _user;
  bool _isGuest = false;
  bool _isLoading = true;
  bool _googleInitialized = false;

  User? get user => _user;
  bool get isGuest => _isGuest;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null || _isGuest;
  String get displayName =>
      _user?.userMetadata?['full_name'] ?? _user?.email ?? 'Guest';
  String? get avatarUrl => _user?.userMetadata?['avatar_url'];

  Future<void> _initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _isGuest = prefs.getBool('isGuest') ?? false;

    _supabase.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _isGuest = false;
        prefs.setBool('isGuest', false);
      }
      _isLoading = false;
      notifyListeners();
    });

    // Check current session
    _user = _supabase.auth.currentUser;
    _isLoading = false;
    notifyListeners();
  }

  // 🔥 Google Sign-In SDK'yı başlat (lazy)
  Future<void> _ensureGoogleInitialized() async {
    if (!_googleInitialized) {
      await GoogleSignIn.instance.initialize(
        serverClientId: SupabaseConstants.googleWebClientId,
      );
      _googleInitialized = true;
    }
  }

  // 🔥 EMAIL/PASSWORD SIGN IN
  Future<void> signIn(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      await _onBeforeIdentityChange?.call();
    } catch (e) {
      rethrow;
    }
  }

  // 🔥 EMAIL/PASSWORD SIGN UP
  Future<void> signUp(String email, String password) async {
    try {
      final response =
          await _supabase.auth.signUp(email: email, password: password);
      if (response.session != null) {
        await _onBeforeIdentityChange?.call();
      }
    } catch (e) {
      rethrow;
    }
  }

  // 🔥 GOOGLE SIGN IN
  Future<void> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    if (_isGuest) {
      // Supabase oturumu açılmadan önce misafir verisinin değişmez bir
      // snapshot'ını al. Auth event'i geldiğinde StatsProvider bu kuyruğu
      // atomik biçimde yeni hesaba aktarır.
      await _guestStatsMigrationService.prepareGuestSnapshot();
    }

    try {
      await _performGoogleSignIn();
    } catch (e) {
      // Stale session durumunda: signOut yapıp tekrar dene
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('canceled') ||
          errorStr.contains('sign_in_failed')) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (_) {}

        // Tekrar dene
        await _performGoogleSignIn();
      } else {
        rethrow;
      }
    }
  }

  /// Google ile giriş akışını gerçekleştirir
  Future<void> _performGoogleSignIn() async {
    final googleUser = await GoogleSignIn.instance.authenticate();

    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('No ID Token found');
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
    await _onBeforeIdentityChange?.call();
  }

  // 🔥 SIGN OUT
  Future<void> signOut() async {
    await _onBeforeIdentityChange?.call();

    // Google Sign-In oturumunu da kapat
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {}

    await _supabase.auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', false);
    _isGuest = false;
    _user = null;
    notifyListeners();
  }

  // 🔥 DELETE ACCOUNT
  /// Kullanıcının Supabase hesabını ve buluttaki istatistiklerini kalıcı olarak
  /// siler, ardından uygulamayı temiz bir misafir moduna döndürür.
  ///
  /// Sunucu tarafı silme başarısız olursa hiçbir yerel durum değişmez ve hata
  /// yeniden fırlatılır. RevenueCat kimliği, auth oturumu kapandığında
  /// PurchaseProvider tarafından otomatik olarak logOut edilir; yerel istatistik
  /// önbelleği de StatsProvider'ın signedOut dinleyicisiyle temizlenir.
  Future<void> deleteAccount() async {
    // RPC, oturum açmamış çağrıları 42501 ile reddeder.
    final deleteRemoteAccount = _deleteRemoteAccount ??
        () => _supabase.rpc<void>('delete_my_account');
    await deleteRemoteAccount();

    // Hesap artık sunucuda yok; kalan adımlar yalnızca yerel temizliktir ve
    // hiçbiri kullanıcıyı silinmiş hesapta oturum açık halde bırakmamalı.
    try {
      await _onBeforeIdentityChange?.call();
    } catch (e) {
      debugPrint('Identity change cleanup failed after deletion: $e');
    }

    // Google hesabının uygulamaya verdiği erişimi de geri al.
    try {
      await _ensureGoogleInitialized();
      await GoogleSignIn.instance.disconnect();
    } catch (_) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }

    try {
      // Yerel oturum her durumda kaldırılır; silinmiş kullanıcı için sunucunun
      // döndürdüğü 403/404 yanıtları gotrue tarafından zaten yok sayılır.
      await _supabase.auth.signOut();
    } catch (e) {
      debugPrint('Supabase sign out after deletion failed: $e');
    }

    // Silinen hesaba ait bekleyen misafir aktarımları yeni bir hesaba
    // taşınmasın.
    try {
      await _guestStatsMigrationService.clearPendingBatches();
    } catch (e) {
      debugPrint('Clearing guest migration queue failed: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true);
    _isGuest = true;
    _user = null;
    notifyListeners();
  }

  // 🔥 GUEST MODE
  Future<void> continueAsGuest() async {
    await _onBeforeIdentityChange?.call();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true);
    _isGuest = true;
    notifyListeners();
  }
}
