import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/blueprint.dart';

final blueprintsProvider = Provider<List<Blueprint>>((ref) {
  return const [
    Blueprint(id: 'bp1', name: 'Solarium Wing', tier: BlueprintTier.master, materials: 250),
    Blueprint(id: 'bp2', name: 'Cedar Pavilion', tier: BlueprintTier.master, materials: 200),
    Blueprint(id: 'bp3', name: 'Stone Arch', tier: BlueprintTier.rare, materials: 120),
    Blueprint(id: 'bp4', name: 'Moss Garden', tier: BlueprintTier.common, materials: 50),
    Blueprint(id: 'bp5', name: 'Glass Dome', tier: BlueprintTier.rare, materials: 150),
    Blueprint(id: 'bp6', name: 'Doric Column', tier: BlueprintTier.master, materials: 280),
  ];
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
