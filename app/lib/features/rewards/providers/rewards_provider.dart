import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../data/models/blueprint.dart';
import '../../world/providers/world_provider.dart';

/// Blueprints derived from unlocked district structures (real data).
final blueprintsProvider = Provider<List<Blueprint>>((ref) {
  final districtAsync = ref.watch(districtProvider);
  final district = districtAsync.valueOrNull;
  if (district == null || district.structures.isEmpty) return const [];

  return district.structures.map((s) {
    final tier = switch (s.tier) {
      'master' => BlueprintTier.master,
      'rare' => BlueprintTier.rare,
      _ => BlueprintTier.common,
    };
    final materials = switch (s.tier) {
      'master' => 250,
      'rare' => 120,
      _ => 50,
    };
    return Blueprint(
      id: s.id,
      name: s.name,
      tier: tier,
      materials: materials,
      unlockedAt: s.unlockedAt,
    );
  }).toList();
});

final vaultStatsProvider = Provider<Map<String, int>>((ref) {
  final blueprints = ref.watch(blueprintsProvider);
  return {
    'total': blueprints.length,
    'master': blueprints.where((b) => b.tier == BlueprintTier.master).length,
    'rare': blueprints.where((b) => b.tier == BlueprintTier.rare).length,
    'common': blueprints.where((b) => b.tier == BlueprintTier.common).length,
  };
});

/// Reward history from backend — paginated, most recent first.
final rewardHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final apiClient = ref.read(apiClientProvider);
    final res = await apiClient.getRewards();
    final rewards = res['rewards'];
    if (rewards is List) {
      return rewards.cast<Map<String, dynamic>>();
    }
    return const [];
  } catch (_) {
    return const [];
  }
});
