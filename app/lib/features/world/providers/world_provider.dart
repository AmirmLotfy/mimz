import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../data/models/district.dart';
import '../../../services/sound_service.dart';
import 'game_state_provider.dart';
/// Current district data — fetched from API. No demo fallback; loading/error shown in UI.
final districtProvider = StateNotifierProvider<DistrictNotifier, AsyncValue<District>>((ref) {
  return DistrictNotifier(ref);
});

/// Parse backend /district payload, which wraps district data under `district`.
District parseDistrictResponse(Map<String, dynamic> response) {
  final districtJson = response['district'];
  if (districtJson is! Map<String, dynamic>) {
    throw const FormatException('District payload missing `district` object');
  }
  return District.fromJson(districtJson);
}

/// Minimal district used only for in-memory reward math when API state is not yet loaded.
District _placeholderDistrict() => const District(
  id: '',
  name: 'My District',
  sectors: 0,
  area: '0.0 sq km',
  structures: [],
  resources: Resources(),
  prestigeLevel: 1,
  influence: 0,
  influenceThreshold: 500,
  newSectors: 0,
);

class DistrictNotifier extends StateNotifier<AsyncValue<District>> {
  final Ref _ref;

  DistrictNotifier(this._ref) : super(const AsyncValue.loading()) {
    _fetchDistrict();
  }

  DateTime? _lastFetch;

  Future<void> _fetchDistrict() async {
    // PERF-02: Skip re-fetch if we fetched successfully in the last 30s
    if (_lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < const Duration(seconds: 30)) {
      return;
    }
    try {
      final gameState = await _ref.read(gameStateProvider.future);
      if (gameState != null) {
        state = AsyncValue.data(gameState.district);
      } else {
        final apiClient = _ref.read(apiClientProvider);
        final response = await apiClient.getDistrict();
        state = AsyncValue.data(parseDistrictResponse(response));
      }
      _lastFetch = DateTime.now();
    } on DioException catch (e, st) {
      final code = e.response?.statusCode;
      if (code == 401) {
        state = AsyncValue.error(
          StateError('Session expired. Please sign in again.'),
          st,
        );
        return;
      }
      if (code == 404) {
        // Self-heal once: replay bootstrap, then retry district fetch.
        try {
          final apiClient = _ref.read(apiClientProvider);
          await apiClient.bootstrap();
          _ref.invalidate(gameStateProvider);
          final gameState = await _ref.read(gameStateProvider.future);
          if (gameState != null) {
            state = AsyncValue.data(gameState.district);
          } else {
            final retry = await apiClient.getDistrict();
            state = AsyncValue.data(parseDistrictResponse(retry));
          }
          _lastFetch = DateTime.now();
          return;
        } catch (_) {}
        state = AsyncValue.error(
          StateError('District not found yet. Please retry.'),
          st,
        );
        return;
      }
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    _lastFetch = null; // Force refresh when explicitly requested
    _ref.invalidate(gameStateProvider);
    await _fetchDistrict();
  }

  void updateLocal(District newDistrict) {
    state = AsyncValue.data(newDistrict);
  }

  /// Sync state after a round. Backend already granted rewards during the
  /// live session via tool calls -- we just refresh to get confirmed state.
  Future<RewardClaim> claimRewards({
    required int score,
    required int streak,
    required int sectorsEarned,
    required Resources materialsEarned,
  }) async {
    final current = state.valueOrNull ?? _placeholderDistrict();
    final beforeSectors = current.sectors;

    try {
      await refresh();
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401) {
        throw StateError('Session expired. Please sign in again.');
      }
      throw StateError('Could not sync rewards. Please retry.');
    } catch (_) {
      throw StateError('Could not sync rewards. Please retry.');
    }

    final confirmed = state.valueOrNull ?? current;
    final gained = (confirmed.sectors - beforeSectors).clamp(0, 99999);
    final gainedSectors = gained > 0 ? gained : sectorsEarned;
    final districtHealth = _ref.read(districtHealthSummaryProvider);
    final structureProgress = _ref.read(structureProgressProvider);
    final primaryAction = _ref.read(recommendedPrimaryActionProvider);
    state = AsyncValue.data(confirmed.copyWith(newSectors: gainedSectors));

    _ref.read(districtGrowthEventProvider.notifier).state =
        DistrictGrowthEvent(
          newSectors: gainedSectors,
          materialsEarned: materialsEarned,
          scoreEarned: score,
          timestamp: DateTime.now(),
        );
    _ref.read(worldArrivalFeedbackProvider.notifier).state =
        WorldArrivalFeedback(
          districtName: confirmed.name,
          sectorsGained: gainedSectors,
          materials: materialsEarned,
          newTotalSectors: confirmed.sectors,
          score: score,
          decayState: confirmed.decayState,
          healthHeadline: districtHealth?.headline,
          healthSummary: districtHealth?.summary,
          nextActionTitle: primaryAction?.title,
          structureReadyName:
              structureProgress?.readyToBuild == true
                  ? structureProgress?.nextStructureName
                  : null,
          reclaimableCells: districtHealth?.reclaimableCells ?? 0,
          vulnerableCells: districtHealth?.vulnerableCells ?? 0,
          timestamp: DateTime.now(),
        );
    SoundService.instance.playDistrictGrowth();

    _ref.invalidate(gameStateProvider);

    return RewardClaim(
      sectorsGained: gainedSectors,
      materials: materialsEarned,
      newTotalSectors: confirmed.sectors,
      score: score,
    );
  }

  /// Syncs UI state based on rewards executed entirely on the backend
  /// (e.g. by a Gemini Live tool execution).
  void syncBackendReward(Map<String, dynamic> payload) {
    final current = state.valueOrNull ?? _placeholderDistrict();

    final sectorsAdded = (payload['sectorsAdded'] as num?)?.toInt() ??
        (payload['sectorsGained'] as num?)?.toInt() ??
        0;
    
    // We update local state to reflect the new sectors without making another API call.
    if (sectorsAdded > 0) {
      final updated = current.copyWith(
        sectors: current.sectors + sectorsAdded,
        area: '${((current.sectors + sectorsAdded) * 1.1).toStringAsFixed(1)} sq km',
        newSectors: sectorsAdded,
      );
      state = AsyncValue.data(updated);

      // Fire growth event so the map UI plays the shockwave animations
      _ref.read(districtGrowthEventProvider.notifier).state =
          DistrictGrowthEvent(
            newSectors: sectorsAdded,
            materialsEarned: const Resources(stone: 0, glass: 0, wood: 0),
            scoreEarned: 0,
            timestamp: DateTime.now(),
          );
    }

    _ref.invalidate(gameStateProvider);
  }
}

String _fallbackMission(District? district) {
  if (district == null) return 'Build your district';
  if (district.sectors < 5) return 'Expand to 5 sectors';
  if (district.structures.isEmpty) return 'Unlock your first structure';
  return '${district.name} — ${district.sectors} sectors';
}

final currentMissionProvider = FutureProvider<String>((ref) async {
  final cachedMission = ref.watch(canonicalMissionProvider);
  if (cachedMission != null && cachedMission.isNotEmpty) {
    return cachedMission;
  }
  final district = ref.watch(districtProvider).valueOrNull;
  try {
    final gameState = await ref.read(gameStateProvider.future);
    final mission = gameState?.currentMission;
    if (mission != null && mission.isNotEmpty) return mission;
  } catch (_) {}
  return _fallbackMission(district);
});

/// Growth event — triggers map animation when district grows
final districtGrowthEventProvider = StateProvider<DistrictGrowthEvent?>((ref) => null);

final worldArrivalFeedbackProvider =
    StateProvider<WorldArrivalFeedback?>((ref) => null);

class DistrictGrowthEvent {
  final int newSectors;
  final Resources materialsEarned;
  final int scoreEarned;
  final DateTime timestamp;

  DistrictGrowthEvent({
    required this.newSectors,
    required this.materialsEarned,
    required this.scoreEarned,
    required this.timestamp,
  });
}

class WorldArrivalFeedback {
  final String districtName;
  final int sectorsGained;
  final Resources materials;
  final int newTotalSectors;
  final int score;
  final String decayState;
  final String? healthHeadline;
  final String? healthSummary;
  final String? nextActionTitle;
  final String? structureReadyName;
  final int reclaimableCells;
  final int vulnerableCells;
  final DateTime timestamp;

  WorldArrivalFeedback({
    required this.districtName,
    required this.sectorsGained,
    required this.materials,
    required this.newTotalSectors,
    required this.score,
    required this.decayState,
    this.healthHeadline,
    this.healthSummary,
    this.nextActionTitle,
    this.structureReadyName,
    this.reclaimableCells = 0,
    this.vulnerableCells = 0,
    required this.timestamp,
  });
}

/// Result of claiming rewards
class RewardClaim {
  final int sectorsGained;
  final Resources materials;
  final int newTotalSectors;
  final int score;

  RewardClaim({
    required this.sectorsGained,
    required this.materials,
    required this.newTotalSectors,
    required this.score,
  });
}
