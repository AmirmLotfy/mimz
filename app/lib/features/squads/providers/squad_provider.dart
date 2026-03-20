import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../data/models/squad.dart';
import '../../world/providers/game_state_provider.dart';

final squadProvider = FutureProvider<Squad?>((ref) async {
  final canonicalSquad = ref.read(canonicalSquadProvider);
  if (canonicalSquad != null) return canonicalSquad;

  try {
    final apiClient = ref.read(apiClientProvider);
    final data = await apiClient.getMySquad();
    if (data == null) return null;
    final squadData = data['squad'] as Map<String, dynamic>?;
    if (squadData == null) return null;
    return Squad.fromJson(squadData);
  } catch (e) {
    return null;
  }
});

/// Squad missions derived from the loaded squad.
final squadMissionsProvider = Provider<List<SquadMission>>((ref) {
  final canonical = ref.watch(canonicalSquadMissionsProvider);
  if (canonical.isNotEmpty) return canonical;
  final squadAsync = ref.watch(squadProvider);
  return squadAsync.valueOrNull?.missions ?? const [];
});

/// Squad members derived from the loaded squad.
final squadMembersProvider = Provider<List<SquadMember>>((ref) {
  final canonical = ref.watch(canonicalSquadMembersProvider);
  if (canonical.isNotEmpty) return canonical;
  final squadAsync = ref.watch(squadProvider);
  return squadAsync.valueOrNull?.members ?? const [];
});
