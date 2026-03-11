import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// TODO: Uncomment when Firebase is configured
// import 'package:firebase_auth/firebase_auth.dart' as fb;

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Wraps Firebase Authentication with a clean interface
class AuthService {
  // TODO: Uncomment when Firebase is configured
  // final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  final _statusController = StreamController<AuthStatus>.broadcast();
  Stream<AuthStatus> get statusStream => _statusController.stream;

  AuthStatus _currentStatus = AuthStatus.unknown;
  AuthStatus get currentStatus => _currentStatus;

  String? _userId;
  String? get userId => _userId;

  AuthService() {
    _init();
  }

  void _init() {
    // TODO: Listen to Firebase Auth state changes
    // _auth.authStateChanges().listen((user) {
    //   if (user != null) {
    //     _userId = user.uid;
    //     _currentStatus = AuthStatus.authenticated;
    //     _cacheToken(user);
    //   } else {
    //     _userId = null;
    //     _currentStatus = AuthStatus.unauthenticated;
    //   }
    //   _statusController.add(_currentStatus);
    // });

    // Demo mode: auto-authenticate
    _userId = 'demo_user_001';
    _currentStatus = AuthStatus.authenticated;
    _statusController.add(_currentStatus);
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    // TODO: Implement Apple Sign In
    // final appleProvider = fb.AppleAuthProvider();
    // await _auth.signInWithProvider(appleProvider);
    _userId = 'apple_user_001';
    _currentStatus = AuthStatus.authenticated;
    _statusController.add(_currentStatus);
    return true;
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    // TODO: Implement Google Sign In
    _userId = 'google_user_001';
    _currentStatus = AuthStatus.authenticated;
    _statusController.add(_currentStatus);
    return true;
  }

  /// Sign in with Email/Password
  Future<bool> signInWithEmail(String email, String password) async {
    // TODO: Implement email sign in
    // await _auth.signInWithEmailAndPassword(email: email, password: password);
    _userId = 'email_user_001';
    _currentStatus = AuthStatus.authenticated;
    _statusController.add(_currentStatus);
    return true;
  }

  /// Create account with Email/Password
  Future<bool> createAccountWithEmail(String email, String password) async {
    // TODO: Implement email sign up
    // await _auth.createUserWithEmailAndPassword(email: email, password: password);
    _userId = 'email_user_001';
    _currentStatus = AuthStatus.authenticated;
    _statusController.add(_currentStatus);
    return true;
  }

  /// Sign out
  Future<void> signOut() async {
    // TODO: await _auth.signOut();
    await _storage.delete(key: 'firebase_id_token');
    _userId = null;
    _currentStatus = AuthStatus.unauthenticated;
    _statusController.add(_currentStatus);
  }

  /// Get current ID token for API calls
  Future<String?> getIdToken() async {
    // TODO: return await _auth.currentUser?.getIdToken();
    return 'demo_token_${DateTime.now().millisecondsSinceEpoch}';
  }

  void dispose() {
    _statusController.close();
  }
}
