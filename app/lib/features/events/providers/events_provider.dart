import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/event.dart';

/// Events list — tries API, falls back to demo data
final eventsProvider = Provider<List<MimzEvent>>((ref) {
  // TODO: Wire to API when backend events list endpoint returns List
  // For now, show demo data matching the game world
  return const [
    MimzEvent(
      id: 'e1',
      title: 'Neon Harvest',
      status: EventStatus.live,
      participants: 1247,
      description: 'Collect light fragments across your district before the timer runs out.',
    ),
    MimzEvent(
      id: 'e2',
      title: 'Heritage Walk',
      status: EventStatus.upcoming,
      participants: 342,
      description: 'A guided vision quest through historical landmarks in your area.',
    ),
    MimzEvent(
      id: 'e3',
      title: 'District Wars',
      status: EventStatus.upcoming,
      participants: 4500,
      description: 'Compete against other districts in a multi-round live quiz tournament.',
    ),
  ];
});

/// Active live event — derived from events list
final activeEventProvider = Provider<MimzEvent?>((ref) {
  final events = ref.watch(eventsProvider);
  try {
    return events.firstWhere((e) => e.status == EventStatus.live);
  } catch (_) {
    return null;
  }
});
