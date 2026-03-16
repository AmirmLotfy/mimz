import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../data/models/district.dart';
/// Current district data — fetched from API with demo fallback
final districtProvider = StateNotifierProvider<DistrictNotifier, AsyncValue<District>>((ref) {
  return DistrictNotifier(ref);
});

class DistrictNotifier extends StateNotifier<AsyncValue<District>> {
  final Ref _ref;

  DistrictNotifier(this._ref) : super(AsyncValue.data(District.demo)) {
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
      final apiClient = _ref.read(apiClientProvider);
      final response = await apiClient.getDistrict();
      state = AsyncValue.data(District.fromJson(response));
      _lastFetch = DateTime.now();
    } catch (e) {
      // Keep demo data on failure — ensures demo never breaks
    }
  }

  Future<void> refresh() async {
    _lastFetch = null; // Force refresh when explicitly requested
    await _fetchDistrict();
  }

  void updateLocal(District newDistrict) {
    state = AsyncValue.data(newDistrict);
  }

  /// Claim rewards after a quiz/vision round.
  /// Calls backend to expand territory and grant resources, then refreshes state.
  Future<RewardClaim> claimRewards({
    required int score,
    required int streak,
    required int sectorsEarned,
    required Resources materialsEarned,
  }) async {
    final current = state.valueOrNull ?? District.demo;

    try {
      final apiClient = _ref.read(apiClientProvider);

      // Call backend to expand territory
      if (sectorsEarned > 0) {
        await apiClient.expandTerritory(sectorsEarned);
      }

      // Call backend to add resources
      if (materialsEarned.total > 0) {
        await apiClient.addResources(materialsEarned.toJson());
      }
    } catch (e) {
      // If backend is unavailable, apply locally for demo
    }

    // Update local state immediately for snappy UI
    final updated = current.copyWith(
      sectors: current.sectors + sectorsEarned,
      area: '${((current.sectors + sectorsEarned) * 1.1).toStringAsFixed(1)} sq km',
      resources: current.resources + materialsEarned,
      newSectors: sectorsEarned,
    );
    state = AsyncValue.data(updated);

    // Trigger growth animation
    _ref.read(districtGrowthEventProvider.notifier).state =
        DistrictGrowthEvent(
          newSectors: sectorsEarned,
          materialsEarned: materialsEarned,
          scoreEarned: score,
          timestamp: DateTime.now(),
        );

    return RewardClaim(
      sectorsGained: sectorsEarned,
      materials: materialsEarned,
      newTotalSectors: updated.sectors,
      score: score,
    );
  }

  /// Syncs UI state based on rewards executed entirely on the backend
  /// (e.g. by a Gemini Live tool execution).
  void syncBackendReward(Map<String, dynamic> payload) {
    final current = state.valueOrNull ?? District.demo;

    final sectorsAdded = (payload['sectorsAdded'] as num?)?.toInt() ?? 0;
    
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
  }
}

/// Current mission text — updated by game events
final currentMissionProvider = StateProvider<String>((ref) => 'The Verdant Sproutlings');

/// Growth event — triggers map animation when district grows
final districtGrowthEventProvider = StateProvider<DistrictGrowthEvent?>((ref) => null);

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
