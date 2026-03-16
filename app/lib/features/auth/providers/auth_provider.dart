import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/providers.dart';
import '../../../data/models/user.dart';
import '../../../services/auth_service.dart';

/// Stream of auth status changes
final authStatusProvider = StreamProvider<AuthStatus>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.statusStream;
});

/// Whether the user is currently authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  final status = ref.watch(authStatusProvider);
  return status.valueOrNull == AuthStatus.authenticated;
});

// ─── Onboarding Gate ──────────────────────────────────────────────────────────

const _kOnboardingKey = 'mimz_onboarding_complete';

/// Persistent onboarding-complete flag backed by flutter_secure_storage.
/// Set to true after the user names their district for the first time.
final isOnboardedProvider =
    StateNotifierProvider<OnboardingNotifier, AsyncValue<bool>>((ref) {
  return OnboardingNotifier();
});

class OnboardingNotifier extends StateNotifier<AsyncValue<bool>> {
  OnboardingNotifier() : super(const AsyncValue.loading()) {
    _load();
  }

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  Future<void> _load() async {
    try {
      final val = await _storage.read(key: _kOnboardingKey);
      if (mounted) state = AsyncValue.data(val == 'true');
    } catch (e, st) {
      if (mounted) state = AsyncValue.error(e, st);
    }
  }

  /// Call this when the user successfully completes district naming.
  Future<void> markOnboarded() async {
    await _storage.write(key: _kOnboardingKey, value: 'true');
    if (mounted) state = const AsyncValue.data(true);
  }

  /// Reset — called on sign out to remove the flag.
  Future<void> resetOnboarding() async {
    await _storage.delete(key: _kOnboardingKey);
    if (mounted) state = const AsyncValue.data(false);
  }
}

// ─── Current User ─────────────────────────────────────────────────────────────

/// Current user profile (fetched from backend after auth)
final currentUserProvider = StateNotifierProvider<CurrentUserNotifier, AsyncValue<MimzUser>>((ref) {
  return CurrentUserNotifier(ref);
});

class CurrentUserNotifier extends StateNotifier<AsyncValue<MimzUser>> {
  final Ref _ref;

  CurrentUserNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final authService = _ref.read(authServiceProvider);
    if (authService.currentStatus == AuthStatus.authenticated) {
      await fetchUser();
    } else {
      // Not authenticated — no user to show
      state = const AsyncValue.error('Not authenticated', StackTrace.empty);
    }

    // Listen for future auth state changes to keep user in sync
    _ref.listen<AsyncValue<AuthStatus>>(authStatusProvider, (previous, next) {
      final status = next.valueOrNull;
      if (status == AuthStatus.authenticated) {
        fetchUser();
      } else if (status == AuthStatus.unauthenticated) {
        state = const AsyncValue.error('Not authenticated', StackTrace.empty);
      }
    });
  }

  Future<void> fetchUser() async {
    state = const AsyncValue.loading();
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.bootstrap();
      final user = MimzUser.fromJson(response['user'] as Map<String, dynamic>);
      state = AsyncValue.data(user);
    } catch (e, st) {
      debugPrint('[Mimz] bootstrap failed: $e');
      if (st != null) debugPrint('[Mimz] $st');
      state = AsyncValue.error(e, st);
    }
  }

  void updateUser(MimzUser user) {
    state = AsyncValue.data(user);
  }
}
