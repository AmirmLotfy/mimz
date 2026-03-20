import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../data/models/game_state.dart';
import '../../../data/models/squad.dart';
import '../../../data/models/event.dart';

final gameStateProvider = FutureProvider<GameStateSnapshot?>((ref) async {
  final apiClient = ref.read(apiClientProvider);
  final response = await apiClient.getGameState();
  return GameStateSnapshot.fromJson(response);
});

final canonicalDistrictProvider = Provider((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.district;
});

final canonicalMissionProvider = Provider<String?>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.currentMission;
});

final canonicalActiveEventProvider = Provider<MimzEvent?>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.activeEvent;
});

final eventZonesProvider = Provider<List<EventZoneModel>>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.eventZones ?? const [];
});

final activeConflictsProvider = Provider<List<ConflictStateModel>>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.activeConflicts ?? const [];
});

final structureProgressProvider = Provider<StructureProgressModel?>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.structureProgress;
});

final structureEffectsProvider = Provider<StructureEffectsModel?>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.structureEffects;
});

final gameStateNotificationsProvider = Provider<List<NotificationModel>>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.notifications ?? const [];
});

final leaderboardSnippetsProvider = Provider<List<LeaderboardSummaryModel>>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.leaderboardSnippets ?? const [];
});

final canonicalSquadSummaryProvider = Provider<SquadSummaryModel?>((ref) {
  return ref.watch(gameStateProvider).valueOrNull?.squadSummary;
});

final canonicalSquadProvider = Provider<Squad?>((ref) {
  return ref.watch(canonicalSquadSummaryProvider)?.squad;
});

final canonicalSquadMembersProvider = Provider<List<SquadMember>>((ref) {
  return ref.watch(canonicalSquadSummaryProvider)?.members ?? const [];
});

final canonicalSquadMissionsProvider = Provider<List<SquadMission>>((ref) {
  return ref.watch(canonicalSquadSummaryProvider)?.missions ?? const [];
});
