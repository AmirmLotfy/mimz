import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// TODO: Uncommented as Firebase is now configured
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }


/// Auth error types for clean error handling
enum AuthErrorType {
  none,
  invalidEmail,
  weakPassword,
  wrongPassword,
  userNotFound,
  emailAlreadyInUse,
  accountExistsWithDifferentCredential,
  credentialAlreadyInUse,
  networkError,
  cancelled,
  unknown,
}

class AuthResult {
  final bool success;
  final AuthErrorType error;
  final String? message;

  AuthResult({required this.success, this.error = AuthErrorType.none, this.message});

  factory AuthResult.ok() => AuthResult(success: true);
  factory AuthResult.fail(AuthErrorType error, [String? message]) =>
      AuthResult(success: false, error: error, message: message);
}

/// Wraps Firebase Authentication with a clean interface.
///
/// Handles:
/// - Email/password sign-up and sign-in
/// - Google sign-in
/// - Apple sign-in
/// - Provider linking (same email, different providers)
/// - Token caching for API calls
/// - Auth state management
class AuthService {
  // Enabled real Firebase Auth
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  late final GoogleSignIn _googleSignIn;
  static const String _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '392547013333-51rid4rl2li0v5qf0kv6hhclb4umvgch.apps.googleusercontent.com',
  );

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: _androidOptions,
  );


  final _statusController = StreamController<AuthStatus>.broadcast();
  Stream<AuthStatus> get statusStream => _statusController.stream;

  AuthStatus _currentStatus = AuthStatus.unknown;
  AuthStatus get currentStatus => _currentStatus;

  String? _userId;
  String? get userId => _userId;

  String? _userEmail;
  String? get userEmail => _userEmail;

  fb.AuthCredential? _pendingLinkCredential;

  /// Providers linked to current account
  List<String> _linkedProviders = [];
  List<String> get linkedProviders => _linkedProviders;

  AuthService() {
    _googleSignIn = GoogleSignIn(
      // Explicitly pin the web OAuth client used to mint idToken/accessToken.
      serverClientId: _googleServerClientId,
    );
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _userId = user.uid;
        _userEmail = user.email;
        _linkedProviders = user.providerData.map((p) => p.providerId).toList();
        _currentStatus = AuthStatus.authenticated;
        _cacheToken(user);
      } else {
        _userId = null;
        _userEmail = null;
        _linkedProviders = [];
        _currentStatus = AuthStatus.unauthenticated;
      }
      _statusController.add(_currentStatus);
    });
  }

  // ─── Google Sign In ──────────────────────────────────

  /// Sign in with Google. Handles:
  /// - Fresh Google sign-in → creates Firebase user
  /// - Returning Google sign-in → signs into existing account
  /// - Same email exists with email/password → links providers
  Future<AuthResult> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn.signIn();
      } on PlatformException catch (e) {
        // Recover from stale Google Play Services state on some devices.
        if (e.code == 'sign_in_failed') {
          try {
            await _googleSignIn.disconnect();
          } catch (_) {}
          googleUser = await _googleSignIn.signIn();
        } else {
          rethrow;
        }
      }
      if (googleUser == null) return AuthResult.fail(AuthErrorType.cancelled);

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      try {
        final userCredential = await _auth.signInWithCredential(credential);
        await _onAuthSuccess(userCredential.user!);
        return AuthResult.ok();
      } on fb.FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          // Same email exists with email/password — attempt to link
          return await _handleProviderConflict(e.email!, credential);
        }
        return _mapFirebaseError(e);
      }
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') {
        return AuthResult.fail(AuthErrorType.cancelled);
      }
      if (e.code == 'network_error' || e.code == 'network-request-failed') {
        return AuthResult.fail(AuthErrorType.networkError, 'Network error');
      }
      if (e.code == 'sign_in_failed') {
        return AuthResult.fail(
          AuthErrorType.unknown,
          'Google sign-in failed (${e.code}). ${e.message ?? 'Please retry.'}',
        );
      }
      return AuthResult.fail(
        AuthErrorType.unknown,
        'Google sign-in failed (${e.code}). ${e.message ?? 'Please try again.'}',
      );
    } catch (_) {
      return AuthResult.fail(
        AuthErrorType.unknown,
        'Authentication failed. Please try again.',
      );
    }
  }

  // ─── Email/Password ──────────────────────────────────

  /// Create account with email/password
  Future<AuthResult> createAccountWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password,
      );
      await userCredential.user!.sendEmailVerification();
      await _onAuthSuccess(userCredential.user!);
      return AuthResult.ok();
    } on fb.FirebaseAuthException catch (e) {
      return _mapFirebaseError(e);
    }
  }

  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email, password: password,
      );

      // Auto-link pending Google credential if present in memory
      String? linkWarning;
      if (_pendingLinkCredential != null) {
        try {
          await userCredential.user!.linkWithCredential(_pendingLinkCredential!);
          _pendingLinkCredential = null;
          await _storage.delete(key: 'pending_link_email');
          await _storage.delete(key: 'pending_link_provider');
        } on fb.FirebaseAuthException catch (e) {
          linkWarning = 'Signed in, but account linking could not be completed (${e.code}).';
        }
      }

      await _onAuthSuccess(userCredential.user!);
      return linkWarning == null
          ? AuthResult.ok()
          : AuthResult(success: true, message: linkWarning);
    } on fb.FirebaseAuthException catch (e) {
      return _mapFirebaseError(e);
    }
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.ok();
    } on fb.FirebaseAuthException catch (e) {
      return _mapFirebaseError(e);
    }
  }



  // ─── Provider Linking ────────────────────────────────

  /// Link an additional auth provider to the current account.
  /// e.g. link Google to an existing email/password account.
  Future<AuthResult> linkProvider(fb.AuthCredential credential) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return AuthResult.fail(AuthErrorType.unknown, 'Not signed in');
      await user.linkWithCredential(credential);
      _linkedProviders = user.providerData.map((p) => p.providerId).toList();
      return AuthResult.ok();
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        return AuthResult.fail(AuthErrorType.credentialAlreadyInUse, 'Provider already linked');
      }
      if (e.code == 'credential-already-in-use') {
        return AuthResult.fail(AuthErrorType.credentialAlreadyInUse, 'Credential used by another account');
      }
      return _mapFirebaseError(e);
    }
  }

  // ─── Provider Conflict Resolution ─────────────────────

  /// Handle same-email different-provider scenario.
  /// When a user tries Google sign-in but has an email/password account:
  /// 1. Store the pending Google credential key so UI can resume link after password sign-in
  /// 2. Return an error asking user to sign in with password first
  Future<AuthResult> _handleProviderConflict(
    String email,
    fb.AuthCredential pendingCredential,
  ) async {
    _pendingLinkCredential = pendingCredential;
    // Store the email so the EmailAuthScreen can surface it
    await _storage.write(key: 'pending_link_email', value: email);
    await _storage.write(key: 'pending_link_provider', value: 'google');
    return AuthResult.fail(
      AuthErrorType.accountExistsWithDifferentCredential,
      'This email is already registered. Sign in with your password to link Google.',
    );
  }

  // ─── Session Management ──────────────────────────────

  /// Sign out and clear cached tokens
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    await _storage.delete(key: 'firebase_id_token');
    await _storage.delete(key: 'firebase_id_token_expiry');
    await _storage.delete(key: 'pending_link_email');
    await _storage.delete(key: 'pending_link_provider');
    _pendingLinkCredential = null;
    _userId = null;
    _userEmail = null;
    _linkedProviders = [];
    _currentStatus = AuthStatus.unauthenticated;
    _statusController.add(_currentStatus);
  }

  /// Get current ID token for API calls. Caches for efficiency.
  /// Retries on network failure so transient blips don't leave requests without a token.
  Future<String?> getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    // Check cached token first
    final cached = await _storage.read(key: 'firebase_id_token');
    final expiry = await _storage.read(key: 'firebase_id_token_expiry');
    if (cached != null && expiry != null) {
      final expiryTime = int.tryParse(expiry) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch < expiryTime - 60000) {
        return cached; // Return cached if not expired (1 min margin)
      }
    }

    // Fetch fresh token with retry on network error
    for (var attempt = 0; attempt < _tokenRetryAttempts; attempt++) {
      try {
        final token = await user.getIdToken(attempt > 0);
        if (token != null) {
          await _storage.write(key: 'firebase_id_token', value: token);
          final newExpiry = DateTime.now().millisecondsSinceEpoch + 3600000;
          await _storage.write(key: 'firebase_id_token_expiry', value: newExpiry.toString());
          return token;
        }
        break;
      } on fb.FirebaseAuthException catch (e) {
        if (e.code != 'network-request-failed') rethrow;
        if (attempt == _tokenRetryAttempts - 1) return cached; // Fall back to stale if still valid for a bit
        await Future<void>.delayed(_tokenRetryDelay);
      }
    }
    return cached;
  }

  // ─── Helpers ─────────────────────────────────────────

  Future<void> _onAuthSuccess(fb.User user) async {
    _userId = user.uid;
    _userEmail = user.email;
    _linkedProviders = user.providerData.map((p) => p.providerId).toList();
    _currentStatus = AuthStatus.authenticated;
    _statusController.add(_currentStatus);
    await _cacheToken(user);
  }

  static const _tokenRetryAttempts = 3;
  static const _tokenRetryDelay = Duration(seconds: 1);

  Future<void> _cacheToken(fb.User user) async {
    for (var attempt = 0; attempt < _tokenRetryAttempts; attempt++) {
      try {
        final token = await user.getIdToken(attempt > 0);
        if (token != null) {
          await _storage.write(key: 'firebase_id_token', value: token);
          final expiry = DateTime.now().millisecondsSinceEpoch + 3600000;
          await _storage.write(key: 'firebase_id_token_expiry', value: expiry.toString());
        }
        return;
      } on fb.FirebaseAuthException catch (e) {
        if (e.code != 'network-request-failed') rethrow;
        if (attempt == _tokenRetryAttempts - 1) return; // Don't crash; use stale token if any
        await Future<void>.delayed(_tokenRetryDelay);
      }
    }
  }

  AuthResult _mapFirebaseError(fb.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return AuthResult.fail(AuthErrorType.invalidEmail, 'Invalid email address');
      case 'weak-password':
        return AuthResult.fail(AuthErrorType.weakPassword, 'Password is too weak');
      case 'wrong-password':
        return AuthResult.fail(AuthErrorType.wrongPassword, 'Incorrect password');
      case 'user-not-found':
        return AuthResult.fail(AuthErrorType.userNotFound, 'No account found');
      case 'email-already-in-use':
        return AuthResult.fail(AuthErrorType.emailAlreadyInUse, 'Email already in use');
      case 'network-request-failed':
        return AuthResult.fail(AuthErrorType.networkError, 'Network error');
      case 'too-many-requests':
        return AuthResult.fail(AuthErrorType.unknown, 'Too many attempts. Try again later.');
      case 'user-disabled':
        return AuthResult.fail(AuthErrorType.unknown, 'This account has been disabled.');
      default:
        return AuthResult.fail(AuthErrorType.unknown, 'Authentication failed. Please try again.');
    }
  }

  void dispose() {
    _statusController.close();
  }
}
