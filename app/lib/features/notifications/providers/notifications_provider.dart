import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/notification_item.dart';
import '../../../core/providers.dart';
import '../../world/providers/game_state_provider.dart';

final notificationsProvider = StateNotifierProvider<NotificationsNotifier,
    AsyncValue<List<NotificationItem>>>((ref) {
  return NotificationsNotifier(ref);
});

class NotificationsNotifier
    extends StateNotifier<AsyncValue<List<NotificationItem>>> {
  final Ref _ref;

  NotificationsNotifier(this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final snapshot =
          await _ref.read(gameStateProvider.future).catchError((_) => null);
      if (snapshot != null) {
        state = AsyncValue.data(
          snapshot.notifications
              .map(
                (item) => NotificationItem.fromJson({
                  'id': item.id,
                  'title': item.title,
                  'body': item.body,
                  'type': item.type,
                  'read': item.read,
                  'createdAt': DateTime.now().toIso8601String(),
                }),
              )
              .toList(),
        );
        return;
      }

      final response = await _ref.read(apiClientProvider).get('/notifications');
      final list = (response['notifications'] as List<dynamic>? ?? [])
          .map(
              (item) => NotificationItem.fromJson(item as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    final current = state.valueOrNull;
    if (current == null) return;
    state = AsyncValue.data(
      current.map((n) => n.id == id ? n.copyWith(isRead: true) : n).toList(),
    );
    try {
      await _ref
          .read(apiClientProvider)
          .patch('/notifications/$id/read', const {});
      _ref.invalidate(gameStateProvider);
    } catch (_) {
      await load();
    }
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull;
    if (current == null) return;
    state =
        AsyncValue.data(current.map((n) => n.copyWith(isRead: true)).toList());
    try {
      await _ref
          .read(apiClientProvider)
          .patch('/notifications/read-all', const {});
      _ref.invalidate(gameStateProvider);
    } catch (_) {
      await load();
    }
  }

  void clearAll() {
    state = const AsyncValue.data([]);
  }
}

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final canonical = ref.watch(gameStateNotificationsProvider);
  if (canonical.isNotEmpty) {
    return canonical.where((n) => !n.read).length;
  }
  final items = ref.watch(notificationsProvider).valueOrNull ??
      const <NotificationItem>[];
  return items.where((n) => !n.isRead).length;
});
