import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../data/models/event.dart';
import '../../world/providers/game_state_provider.dart';

/// Events list from backend.
final eventsProvider = FutureProvider<List<MimzEvent>>((ref) async {
  final gameState = await ref.read(gameStateProvider.future).catchError((_) => null);
  if (gameState != null) {
    final events = <MimzEvent>[];
    if (gameState.activeEvent != null) {
      events.add(gameState.activeEvent!);
    }
    for (final zone in gameState.eventZones) {
      final exists = events.any((event) => event.id == zone.eventId);
      if (!exists) {
        events.add(MimzEvent(
          id: zone.eventId,
          title: zone.title,
          status: EventStatus.values.firstWhere(
            (status) => status.name == zone.status,
            orElse: () => EventStatus.upcoming,
          ),
          description: zone.districtEffect,
        ));
      }
    }
    if (events.isNotEmpty) return events;
  }

  final apiClient = ref.read(apiClientProvider);
  final res = await apiClient.getEvents();
  final raw = res['events'];
  if (raw is! List) return const [];
  return raw.whereType<Map<String, dynamic>>().map(MimzEvent.fromJson).toList();
});

/// Active live event — derived from events list
final activeEventProvider = Provider<MimzEvent?>((ref) {
  final canonical = ref.watch(canonicalActiveEventProvider);
  if (canonical != null) return canonical;
  final events = ref.watch(eventsProvider).valueOrNull ?? const <MimzEvent>[];
  try {
    return events.firstWhere((e) => e.status == EventStatus.live);
  } catch (_) {
    return null;
  }
});
