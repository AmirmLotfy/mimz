import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../core/providers.dart';
import '../../../data/models/user.dart';
import '../../../services/auth_service.dart';
import '../../../services/push_notification_service.dart';
import '../../world/providers/game_state_provider.dart';

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

  Future<void> syncFromBackend(bool onboarded) async {
    await _storage.write(key: _kOnboardingKey, value: onboarded ? 'true' : 'false');
    if (mounted) state = AsyncValue.data(onboarded);
  }

  /// Reset — called on sign out to remove the flag.
  Future<void> resetOnboarding() async {
    await _storage.delete(key: _kOnboardingKey);
    if (mounted) state = const AsyncValue.data(false);
  }
}

// ─── Current User ─────────────────────────────────────────────────────────────

/// Current user profile (fetched from backend after auth)
final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, AsyncValue<MimzUser>>((ref) {
  return CurrentUserNotifier(ref);
});

class BootstrapFailure {
  final String message;
  final int? statusCode;
  final String? traceId;
  final bool retryable;

  const BootstrapFailure({
    required this.message,
    this.statusCode,
    this.traceId,
    this.retryable = false,
  });

  @override
  String toString() =>
      'BootstrapFailure($statusCode, retryable=$retryable, traceId=$traceId): $message';
}

String bootstrapFailureMessage(Object? err) {
  if (err is BootstrapFailure) return err.message;
  if (err is DioException) {
    final code = err.response?.statusCode;
    if (code == 401) return 'Sign-in expired. Please sign in again.';
    if (code == 403)
      return 'Backend access is restricted. Please contact support/admin.';
    if (code == 400) return 'Could not load your profile. Please retry.';
    if (code != null && code >= 500)
      return 'Server issue while loading your profile. Please retry shortly.';
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError) {
      return 'Could not reach the server. Check your connection and retry.';
    }
  }
  return 'Could not load your profile. Please retry.';
}

bool hasCoreUserProfile(MimzUser user) {
  return (user.preferredName?.trim().isNotEmpty ?? false) &&
      (user.ageBand?.trim().isNotEmpty ?? false) &&
      (user.studyWorkStatus?.trim().isNotEmpty ?? false);
}

String nextRouteForUser(MimzUser user) {
  if (user.onboardingCompleted) return '/world';

  switch (user.onboardingStage) {
    case 'interests':
      return '/onboarding/interests';
    case 'preferences':
      return '/onboarding/preferences';
    case 'summary':
      return '/onboarding/summary';
    case 'permissions_location':
      return '/permissions/location';
    case 'permissions_microphone':
      return '/permissions/microphone';
    case 'profile':
      if (!hasCoreUserProfile(user)) return '/onboarding/profile-setup';
      if (user.interests.isEmpty) return '/onboarding/interests';
      return '/onboarding/preferences';
    case 'permissions':
      return '/permissions/location';
    case 'emblem':
      return '/district/emblem';
    case 'district_name':
      return '/district/name';
    case 'district_reveal':
      return '/district/reveal';
    case 'completed':
      return '/world';
    default:
      return '/onboarding/profile-setup';
  }
}

class CurrentUserNotifier extends StateNotifier<AsyncValue<MimzUser>> {
  final Ref _ref;
  Future<void>? _fetchInFlight;

  CurrentUserNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    final authService = _ref.read(authServiceProvider);
    if (authService.currentStatus == AuthStatus.authenticated) {
      await fetchUser();
    } else if (authService.currentStatus == AuthStatus.unauthenticated) {
      // Not authenticated — no user to show
      state = const AsyncValue.error('Not authenticated', StackTrace.empty);
    } else {
      // Wait for Firebase/auth bootstrap to resolve instead of flashing an
      // unauthenticated error during startup.
      state = const AsyncValue.loading();
    }

    // Listen for future auth state changes to keep user in sync
    _ref.listen<AsyncValue<AuthStatus>>(authStatusProvider, (previous, next) {
      final status = next.valueOrNull;
      if (status == AuthStatus.authenticated) {
        fetchUser();
      } else if (status == AuthStatus.unauthenticated) {
        PushNotificationService.instance
            .unregister(_ref.read(apiClientProvider));
        GameStateCacheStore.instance.clear();
        _ref.invalidate(gameStateProvider);
        state = const AsyncValue.error('Not authenticated', StackTrace.empty);
      }
    });
  }

  Future<void> fetchUser() async {
    if (_fetchInFlight != null) {
      return _fetchInFlight!;
    }
    final future = _fetchUserInternal();
    _fetchInFlight = future;
    try {
      await future;
    } finally {
      _fetchInFlight = null;
    }
  }

  Future<void> _fetchUserInternal() async {
    final previousUser = state.valueOrNull;
    if (previousUser == null) {
      state = const AsyncValue.loading();
    }
    final auth = _ref.read(authServiceProvider);
    await auth.getIdToken();

    DioException? lastDio;
    Object? lastErr;
    StackTrace? lastSt;
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        final apiClient = _ref.read(apiClientProvider);
        final snapshot = await _ref.read(gameStateProvider.notifier).load(
              force: true,
              bootstrapIfMissing: true,
            );
        final user = snapshot?.user;
        if (user == null) {
          throw StateError('Game state did not include a user profile.');
        }
        state = AsyncValue.data(user);
        await _ref
            .read(isOnboardedProvider.notifier)
            .syncFromBackend(user.onboardingCompleted);
        PushNotificationService.instance.initialize(apiClient);
        return;
      } on DioException catch (e, st) {
        lastDio = e;
        lastErr = e;
        lastSt = st;
        final code = e.response?.statusCode ?? 0;
        final transient = code >= 500 ||
            e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout ||
            e.type == DioExceptionType.connectionError;
        if (attempt < 2 && transient) {
          await Future.delayed(const Duration(milliseconds: 600));
          continue;
        }
        break;
      } catch (e, st) {
        lastErr = e;
        lastSt = st;
        break;
      }
    }

    final traceId = lastDio?.response?.headers.value('x-correlation-id');
    final statusCode = lastDio?.response?.statusCode;
    final mapped = BootstrapFailure(
      message: bootstrapFailureMessage(lastErr),
      statusCode: statusCode,
      traceId: traceId,
      retryable: statusCode == null || statusCode >= 500 || statusCode == 429,
    );

    debugPrint('[Mimz] bootstrap failed: $mapped');
    if (lastSt != null) debugPrint('[Mimz] $lastSt');

    // Keep prior user data for transient failures, avoid poisoning an already-loaded session.
    if (previousUser != null && mapped.retryable) {
      state = AsyncValue.data(previousUser);
      return;
    }

    state = AsyncValue.error(mapped, lastSt ?? StackTrace.empty);
  }

  void updateUser(MimzUser user) {
    state = AsyncValue.data(user);
  }
}
