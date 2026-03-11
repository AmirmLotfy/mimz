import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// TODO: Uncomment when Firebase is configured
// import 'package:firebase_auth/firebase_auth.dart' as fb;
// import 'package:google_sign_in/google_sign_in.dart';

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
  // TODO: Uncomment when Firebase is configured
  // final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final _statusController = StreamController<AuthStatus>.broadcast();
  Stream<AuthStatus> get statusStream => _statusController.stream;

  AuthStatus _currentStatus = AuthStatus.unknown;
  AuthStatus get currentStatus => _currentStatus;

  String? _userId;
  String? get userId => _userId;

  String? _userEmail;
  String? get userEmail => _userEmail;

  /// Providers linked to current account
  List<String> _linkedProviders = [];
  List<String> get linkedProviders => _linkedProviders;

  AuthService() {
    _init();
  }

  void _init() {
    // TODO: Listen to Firebase Auth state changes when Firebase is configured
    // _auth.authStateChanges().listen((user) {
    //   if (user != null) {
    //     _userId = user.uid;
    //     _userEmail = user.email;
    //     _linkedProviders = user.providerData.map((p) => p.providerId).toList();
    //     _currentStatus = AuthStatus.authenticated;
    //     _cacheToken(user);
    //   } else {
    //     _userId = null;
    //     _userEmail = null;
    //     _linkedProviders = [];
    //     _currentStatus = AuthStatus.unauthenticated;
    //   }
    //   _statusController.add(_currentStatus);
    // });

    // Demo mode: auto-authenticate
    _userId = 'demo_user_001';
    _userEmail = 'demo@mimz.app';
    _linkedProviders = ['demo'];
    _currentStatus = AuthStatus.authenticated;
    _statusController.add(_currentStatus);
  }

  // ─── Google Sign In ──────────────────────────────────

  /// Sign in with Google. Handles:
  /// - Fresh Google sign-in → creates Firebase user
  /// - Returning Google sign-in → signs into existing account
  /// - Same email exists with email/password → links providers
  Future<AuthResult> signInWithGoogle() async {
    // TODO: Implement real Google Sign In
    // try {
    //   final googleUser = await _googleSignIn.signIn();
    //   if (googleUser == null) return AuthResult.fail(AuthErrorType.cancelled);
    //
    //   final googleAuth = await googleUser.authentication;
    //   final credential = fb.GoogleAuthProvider.credential(
    //     accessToken: googleAuth.accessToken,
    //     idToken: googleAuth.idToken,
    //   );
    //
    //   try {
    //     final userCredential = await _auth.signInWithCredential(credential);
    //     await _onAuthSuccess(userCredential.user!);
    //     return AuthResult.ok();
    //   } on fb.FirebaseAuthException catch (e) {
    //     if (e.code == 'account-exists-with-different-credential') {
    //       // Same email exists with email/password — attempt to link
    //       return await _handleProviderConflict(e.email!, credential);
    //     }
    //     return _mapFirebaseError(e);
    //   }
    // } catch (e) {
    //   return AuthResult.fail(AuthErrorType.unknown, e.toString());
    // }

    _userId = 'google_user_001';
    _userEmail = 'user@gmail.com';
    _linkedProviders = ['google.com'];
    _currentStatus = AuthStatus.authenticated;
    _statusController.add(_currentStatus);
    return AuthResult.ok();
  }

  // ─── Email/Password ──────────────────────────────────

  /// Create account with email/password
  Future<AuthResult> createAccountWithEmail(String email, String password) async {
    // TODO: Implement real email sign up
    // try {
    //   final userCredential = await _auth.createUserWithEmailAndPassword(
    //     email: email, password: password,
    //   );
    //   await userCredential.user!.sendEmailVerification();
    //   await _onAuthSuccess(userCredential.user!);
    //   return AuthResult.ok();
    // } on fb.FirebaseAuthException catch (e) {
    //   return _mapFirebaseError(e);
    // }

    _userId = 'email_user_001';
    _userEmail = email;
    _linkedProviders = ['password'];
    _currentStatus = AuthStatus.authenticated;
    _statusController.add(_currentStatus);
    return AuthResult.ok();
  }

  /// Sign in with email/password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    // TODO: Implement real email sign in
    // try {
    //   final userCredential = await _auth.signInWithEmailAndPassword(
    //     email: email, password: password,
    //   );
    //   await _onAuthSuccess(userCredential.user!);
    //   return AuthResult.ok();
    // } on fb.FirebaseAuthException catch (e) {
    //   return _mapFirebaseError(e);
    // }

    _userId = 'email_user_001';
    _userEmail = email;
    _linkedProviders = ['password'];
    _currentStatus = AuthStatus.authenticated;
    _statusController.add(_currentStatus);
    return AuthResult.ok();
  }

  /// Send password reset email
  Future<AuthResult> sendPasswordReset(String email) async {
    // TODO: Implement real password reset
    // try {
    //   await _auth.sendPasswordResetEmail(email: email);
    //   return AuthResult.ok();
    // } on fb.FirebaseAuthException catch (e) {
    //   return _mapFirebaseError(e);
    // }
    return AuthResult.ok();
  }

  // ─── Apple Sign In ───────────────────────────────────

  /// Sign in with Apple
  Future<AuthResult> signInWithApple() async {
    // TODO: Implement Apple Sign In
    // try {
    //   final appleProvider = fb.AppleAuthProvider();
    //   final userCredential = await _auth.signInWithProvider(appleProvider);
    //   await _onAuthSuccess(userCredential.user!);
    //   return AuthResult.ok();
    // } on fb.FirebaseAuthException catch (e) {
    //   return _mapFirebaseError(e);
    // }

    _userId = 'apple_user_001';
    _userEmail = 'apple@privaterelay.appleid.com';
    _linkedProviders = ['apple.com'];
    _currentStatus = AuthStatus.authenticated;
    _statusController.add(_currentStatus);
    return AuthResult.ok();
  }

  // ─── Provider Linking ────────────────────────────────

  /// Link an additional auth provider to the current account.
  /// e.g. link Google to an existing email/password account.
  // Future<AuthResult> linkProvider(fb.AuthCredential credential) async {
  //   try {
  //     final user = _auth.currentUser;
  //     if (user == null) return AuthResult.fail(AuthErrorType.unknown, 'Not signed in');
  //     await user.linkWithCredential(credential);
  //     _linkedProviders = user.providerData.map((p) => p.providerId).toList();
  //     return AuthResult.ok();
  //   } on fb.FirebaseAuthException catch (e) {
  //     if (e.code == 'provider-already-linked') {
  //       return AuthResult.fail(AuthErrorType.credentialAlreadyInUse, 'Provider already linked');
  //     }
  //     if (e.code == 'credential-already-in-use') {
  //       return AuthResult.fail(AuthErrorType.credentialAlreadyInUse, 'Credential used by another account');
  //     }
  //     return _mapFirebaseError(e);
  //   }
  // }

  // ─── Provider Conflict Resolution ─────────────────────

  /// Handle same-email different-provider scenario.
  /// When a user tries Google sign-in but has an email/password account:
  /// 1. Sign in with email/password first
  /// 2. Link the Google credential
  // Future<AuthResult> _handleProviderConflict(
  //   String email,
  //   fb.AuthCredential pendingCredential,
  // ) async {
  //   // Check what providers exist for this email
  //   final methods = await _auth.fetchSignInMethodsForEmail(email);
  //   if (methods.contains('password')) {
  //     // User needs to sign in with password first, then link
  //     // Store pending credential for post-link
  //     await _storage.write(key: 'pending_credential', value: 'google');
  //     return AuthResult.fail(
  //       AuthErrorType.accountExistsWithDifferentCredential,
  //       'Please sign in with your password to link Google.',
  //     );
  //   }
  //   return AuthResult.fail(AuthErrorType.unknown, 'Unresolvable provider conflict');
  // }

  // ─── Session Management ──────────────────────────────

  /// Sign out and clear cached tokens
  Future<void> signOut() async {
    // TODO: await _auth.signOut();
    // TODO: await _googleSignIn.signOut();
    await _storage.delete(key: 'firebase_id_token');
    _userId = null;
    _userEmail = null;
    _linkedProviders = [];
    _currentStatus = AuthStatus.unauthenticated;
    _statusController.add(_currentStatus);
  }

  /// Get current ID token for API calls. Caches for efficiency.
  Future<String?> getIdToken() async {
    // TODO: Implement real token retrieval with caching
    // final user = _auth.currentUser;
    // if (user == null) return null;
    //
    // // Check cached token
    // final cached = await _storage.read(key: 'firebase_id_token');
    // final expiry = await _storage.read(key: 'firebase_id_token_expiry');
    // if (cached != null && expiry != null) {
    //   final expiryTime = int.tryParse(expiry) ?? 0;
    //   if (DateTime.now().millisecondsSinceEpoch < expiryTime - 60000) {
    //     return cached; // Return cached if not expired (1 min margin)
    //   }
    // }
    //
    // // Fetch fresh token and cache it
    // final token = await user.getIdToken();
    // if (token != null) {
    //   await _storage.write(key: 'firebase_id_token', value: token);
    //   // Firebase tokens expire in 1 hour
    //   final newExpiry = DateTime.now().millisecondsSinceEpoch + 3600000;
    //   await _storage.write(key: 'firebase_id_token_expiry', value: newExpiry.toString());
    // }
    // return token;

    return 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
  }

  // ─── Helpers ─────────────────────────────────────────

  // Future<void> _onAuthSuccess(fb.User user) async {
  //   _userId = user.uid;
  //   _userEmail = user.email;
  //   _linkedProviders = user.providerData.map((p) => p.providerId).toList();
  //   _currentStatus = AuthStatus.authenticated;
  //   _statusController.add(_currentStatus);
  //   await _cacheToken(user);
  // }

  // Future<void> _cacheToken(fb.User user) async {
  //   final token = await user.getIdToken();
  //   if (token != null) {
  //     await _storage.write(key: 'firebase_id_token', value: token);
  //     final expiry = DateTime.now().millisecondsSinceEpoch + 3600000;
  //     await _storage.write(key: 'firebase_id_token_expiry', value: expiry.toString());
  //   }
  // }

  // AuthResult _mapFirebaseError(fb.FirebaseAuthException e) {
  //   switch (e.code) {
  //     case 'invalid-email':
  //       return AuthResult.fail(AuthErrorType.invalidEmail, 'Invalid email address');
  //     case 'weak-password':
  //       return AuthResult.fail(AuthErrorType.weakPassword, 'Password is too weak');
  //     case 'wrong-password':
  //       return AuthResult.fail(AuthErrorType.wrongPassword, 'Incorrect password');
  //     case 'user-not-found':
  //       return AuthResult.fail(AuthErrorType.userNotFound, 'No account found');
  //     case 'email-already-in-use':
  //       return AuthResult.fail(AuthErrorType.emailAlreadyInUse, 'Email already in use');
  //     case 'network-request-failed':
  //       return AuthResult.fail(AuthErrorType.networkError, 'Network error');
  //     default:
  //       return AuthResult.fail(AuthErrorType.unknown, e.message);
  //   }
  // }

  void dispose() {
    _statusController.close();
  }
}
