import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      state = AsyncValue.data(MimzUser.demo);
    }
  }

  Future<void> fetchUser() async {
    state = const AsyncValue.loading();
    try {
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.bootstrap();
      final user = MimzUser.fromJson(response['user'] as Map<String, dynamic>);
      state = AsyncValue.data(user);
    } catch (e, st) {
      // Fallback to demo user
      state = AsyncValue.data(MimzUser.demo);
    }
  }

  void updateUser(MimzUser user) {
    state = AsyncValue.data(user);
  }
}
