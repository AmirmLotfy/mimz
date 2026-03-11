/// Blueprint / reward model
class Blueprint {
  final String id;
  final String name;
  final BlueprintTier tier;
  final int materials;
  final DateTime? unlockedAt;

  const Blueprint({
    required this.id,
    required this.name,
    this.tier = BlueprintTier.common,
    this.materials = 0,
    this.unlockedAt,
  });

  factory Blueprint.fromJson(Map<String, dynamic> json) => Blueprint(
        id: json['id'] as String,
        name: json['name'] as String,
        tier: BlueprintTier.values.firstWhere(
          (t) => t.name == json['tier'],
          orElse: () => BlueprintTier.common,
        ),
        materials: json['materials'] as int? ?? 0,
        unlockedAt: json['unlockedAt'] != null
            ? DateTime.tryParse(json['unlockedAt'] as String)
            : null,
      );
}

enum BlueprintTier { common, rare, master }
