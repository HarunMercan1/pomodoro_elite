import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/supabase_constants.dart';

class AuthProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? _user;
  bool _isGuest = false;
  bool _isLoading = true;
  bool _googleInitialized = false;

  User? get user => _user;
  bool get isGuest => _isGuest;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null || _isGuest;
  String get displayName => _user?.userMetadata?['full_name'] ?? _user?.email ?? 'Guest';
  String? get avatarUrl => _user?.userMetadata?['avatar_url'];

  AuthProvider() {
    _initializeAuth();
  }

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
    } catch (e) {
      rethrow;
    }
  }

  // 🔥 EMAIL/PASSWORD SIGN UP
  Future<void> signUp(String email, String password) async {
    try {
      await _supabase.auth.signUp(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // 🔥 GOOGLE SIGN IN
  Future<void> signInWithGoogle() async {
    await _ensureGoogleInitialized();

    final googleUser = await GoogleSignIn.instance.authenticate();
    if (googleUser == null) {
      throw Exception('Google Sign-In cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('No ID Token found');
    }

    await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  // 🔥 SIGN OUT
  Future<void> signOut() async {
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

  // 🔥 GUEST MODE
  Future<void> continueAsGuest() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isGuest', true);
    _isGuest = true;
    notifyListeners();
  }
}
