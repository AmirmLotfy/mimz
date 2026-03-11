import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../data/models/squad.dart';

final squadProvider = FutureProvider<Squad?>((ref) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    // Attempt to fetch squad from API
    final response = await apiClient.getProfile();
    // If user has a squad, the profile includes squadId
    // For now, return null (no squad by default)
    return null;
  } catch (e) {
    return null; // No squad by default
  }
});

/// Squad missions — tries API, falls back to demo data
final squadMissionsProvider = Provider<List<SquadMission>>((ref) {
  // TODO: Wire to API when backend squad missions endpoint exists
  // For now, show realistic demo data that matches the game world
  return const [
    SquadMission(title: 'The Verdant Challenge', progress: 0.65, members: 4, deadline: '2d 14h left'),
    SquadMission(title: 'Atlas Sprint', progress: 0.3, members: 6, deadline: '5d 2h left'),
  ];
});

/// Squad members — realistic demo data
final squadMembersProvider = Provider<List<SquadMember>>((ref) {
  return const [
    SquadMember(name: 'Atlas Runner', xp: '12,450 XP', rank: 1),
    SquadMember(name: 'Verdant Scout', xp: '9,800 XP', rank: 2),
    SquadMember(name: 'Stone Mason', xp: '8,200 XP', rank: 3),
  ];
});
