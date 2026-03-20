/// District model — represents a user's owned territory
class District {
  final String id;
  final String name;
  final int sectors;
  final String area;
  final List<Structure> structures;
  final Resources resources;
  final int prestigeLevel;
  final int influence;
  final int influenceThreshold;
  final List<Map<String, dynamic>> rawCells;
  final String decayState;
  final String regionId;
  final String regionLabel;
  final List<DistrictTopicAffinity> topicAffinities;
  final int newSectors;

  const District({
    required this.id,
    required this.name,
    this.sectors = 1,
    this.area = '1.0 sq km',
    this.structures = const [],
    this.resources = const Resources(),
    this.prestigeLevel = 1,
    this.influence = 0,
    this.influenceThreshold = 500,
    this.rawCells = const [],
    this.decayState = 'stable',
    this.regionId = 'global_central',
    this.regionLabel = 'Global District Grid',
    this.topicAffinities = const [],
    this.newSectors = 0,
  });

  /// Derived population based on sectors and structures
  int get population => sectors * 850 + structures.length * 1200;

  /// Formatted population string
  String get populationFormatted {
    if (population >= 1000) {
      return '${(population / 1000).toStringAsFixed(1)}k';
    }
    return population.toString();
  }

  /// Growth rate based on structures
  double get growthRate {
    const base = 1.0;
    final structureBonus = structures.length * 0.8;
    return base + structureBonus;
  }

  /// Total prestige from structures
  int get totalPrestige {
    int base = prestigeLevel;
    for (final s in structures) {
      base += s.tier == 'master'
          ? 3
          : s.tier == 'rare'
              ? 2
              : 1;
    }
    return base;
  }

  /// Generate hex cell positions with layer metadata.
  /// Uses server-provided cells when available, otherwise falls back to spiral.
  List<HexCell> get hexCells {
    if (rawCells.isNotEmpty) {
      return rawCells.map((c) {
        final q = (c['q'] as num?)?.toInt() ?? 0;
        final r = (c['r'] as num?)?.toInt() ?? 0;
        final layerStr = c['layer'] as String? ?? 'frontier';
        final stability = (c['stability'] as num?)?.toDouble() ?? 50;
        final contested = c['contested'] as bool? ?? false;
        final layer = layerStr == 'core'
            ? CellLayer.core
            : layerStr == 'inner'
                ? CellLayer.inner
                : CellLayer.frontier;
        return HexCell(
          q,
          r,
          q == 0 && r == 0,
          layer: layer,
          stability: stability,
          contested: contested,
        );
      }).toList();
    }

    // Fallback: spiral with auto-assigned layers
    final cells = <HexCell>[];
    if (sectors <= 0) return cells;

    final total = sectors;
    final coreCount = (total * 0.2).floor().clamp(1, total);
    final innerCount = (total * 0.4).floor();

    cells.add(const HexCell(0, 0, true, layer: CellLayer.core, stability: 100));
    if (sectors <= 1) return cells;

    int placed = 1;
    int ring = 1;
    final dirs = [
      [1, 0],
      [1, -1],
      [0, -1],
      [-1, 0],
      [-1, 1],
      [0, 1],
    ];

    while (placed < sectors) {
      int q = 0, r = -ring;
      for (int d = 0; d < 6 && placed < sectors; d++) {
        for (int s = 0; s < ring && placed < sectors; s++) {
          CellLayer layer;
          double stability;
          if (placed < coreCount) {
            layer = CellLayer.core;
            stability = 100;
          } else if (placed < coreCount + innerCount) {
            layer = CellLayer.inner;
            stability = 75;
          } else {
            layer = CellLayer.frontier;
            stability = 50;
          }
          cells.add(HexCell(q, r, false, layer: layer, stability: stability));
          placed++;
          q += dirs[d][0];
          r += dirs[d][1];
        }
      }
      ring++;
    }
    return cells;
  }

  factory District.fromJson(Map<String, dynamic> json) => District(
        id: json['id'] as String,
        name: json['name'] as String,
        sectors: json['sectors'] as int? ?? 1,
        area: json['area'] as String? ?? '1.0 sq km',
        structures: (json['structures'] as List?)
                ?.map((s) => Structure.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        resources: json['resources'] != null
            ? Resources.fromJson(json['resources'] as Map<String, dynamic>)
            : const Resources(),
        prestigeLevel: json['prestigeLevel'] as int? ?? 1,
        influence: json['influence'] as int? ?? 0,
        influenceThreshold: json['influenceThreshold'] as int? ?? 500,
        rawCells: (json['cells'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .toList() ??
            const [],
        decayState: json['decayState'] as String? ?? 'stable',
        regionId:
            _mapFromDynamic(json['regionAnchor'])?['regionId'] as String? ??
                'global_central',
        regionLabel:
            _mapFromDynamic(json['regionAnchor'])?['label'] as String? ??
                'Global District Grid',
        topicAffinities: (json['topicAffinities'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(DistrictTopicAffinity.fromJson)
                .toList() ??
            const [],
        newSectors: 0,
      );

  double get influenceProgress => influenceThreshold > 0
      ? (influence / influenceThreshold).clamp(0.0, 1.0)
      : 0.0;

  District copyWith({
    String? name,
    int? sectors,
    String? area,
    List<Structure>? structures,
    Resources? resources,
    int? prestigeLevel,
    int? influence,
    int? influenceThreshold,
    List<Map<String, dynamic>>? rawCells,
    String? decayState,
    String? regionId,
    String? regionLabel,
    List<DistrictTopicAffinity>? topicAffinities,
    int? newSectors,
  }) =>
      District(
        id: id,
        name: name ?? this.name,
        sectors: sectors ?? this.sectors,
        area: area ?? this.area,
        structures: structures ?? this.structures,
        resources: resources ?? this.resources,
        prestigeLevel: prestigeLevel ?? this.prestigeLevel,
        influence: influence ?? this.influence,
        influenceThreshold: influenceThreshold ?? this.influenceThreshold,
        rawCells: rawCells ?? this.rawCells,
        decayState: decayState ?? this.decayState,
        regionId: regionId ?? this.regionId,
        regionLabel: regionLabel ?? this.regionLabel,
        topicAffinities: topicAffinities ?? this.topicAffinities,
        newSectors: newSectors ?? this.newSectors,
      );

  static District get demo => const District(
        id: 'district_001',
        name: 'Verdant Reach',
        sectors: 7,
        area: '7.7 sq km',
        structures: [
          Structure(id: 's1', name: 'Solarium Wing', tier: 'master'),
          Structure(id: 's2', name: 'Cedar Pavilion', tier: 'master'),
          Structure(id: 's3', name: 'Stone Arch', tier: 'rare'),
        ],
        resources: Resources(stone: 1250, glass: 480, wood: 920),
        prestigeLevel: 4,
        influence: 340,
        influenceThreshold: 500,
        decayState: 'stable',
        newSectors: 0,
      );

  int get coreCount =>
      hexCells.where((cell) => cell.layer == CellLayer.core).length;
  int get innerCount =>
      hexCells.where((cell) => cell.layer == CellLayer.inner).length;
  int get frontierCount =>
      hexCells.where((cell) => cell.layer == CellLayer.frontier).length;
  int get contestedCount => hexCells.where((cell) => cell.contested).length;
  int get vulnerableFrontierCount => hexCells
      .where((cell) => cell.layer == CellLayer.frontier && cell.stability < 40)
      .length;
  int get reclaimableFrontierCount => hexCells
      .where((cell) => cell.layer == CellLayer.frontier && cell.stability <= 0)
      .length;
}

class DistrictTopicAffinity {
  final String topic;
  final int answered;
  final int correct;
  final int streak;
  final double masteryScore;
  final double winRate;

  const DistrictTopicAffinity({
    required this.topic,
    this.answered = 0,
    this.correct = 0,
    this.streak = 0,
    this.masteryScore = 0,
    this.winRate = 0,
  });

  factory DistrictTopicAffinity.fromJson(Map<String, dynamic> json) =>
      DistrictTopicAffinity(
        topic: json['topic'] as String? ?? 'General',
        answered: (json['answered'] as num?)?.toInt() ?? 0,
        correct: (json['correct'] as num?)?.toInt() ?? 0,
        streak: (json['streak'] as num?)?.toInt() ?? 0,
        masteryScore: (json['masteryScore'] as num?)?.toDouble() ?? 0,
        winRate: (json['winRate'] as num?)?.toDouble() ?? 0,
      );
}

/// Territory cell layer
enum CellLayer { core, inner, frontier }

/// Single hex cell position using axial coordinates
class HexCell {
  final int q;
  final int r;
  final bool isCenter;
  final CellLayer layer;
  final double stability;
  final bool contested;
  const HexCell(
    this.q,
    this.r,
    this.isCenter, {
    this.layer = CellLayer.frontier,
    this.stability = 50,
    this.contested = false,
  });
}

class Structure {
  final String id;
  final String name;
  final String tier;
  final DateTime? unlockedAt;

  const Structure({
    required this.id,
    required this.name,
    required this.tier,
    this.unlockedAt,
  });

  factory Structure.fromJson(Map<String, dynamic> json) => Structure(
        id: json['id'] as String,
        name: json['name'] as String,
        tier: json['tier'] as String,
        unlockedAt: json['unlockedAt'] != null
            ? DateTime.tryParse(json['unlockedAt'] as String)
            : null,
      );
}

class Resources {
  final int stone;
  final int glass;
  final int wood;

  const Resources({this.stone = 0, this.glass = 0, this.wood = 0});

  int get total => stone + glass + wood;

  Resources operator +(Resources other) => Resources(
        stone: stone + other.stone,
        glass: glass + other.glass,
        wood: wood + other.wood,
      );

  factory Resources.fromJson(Map<String, dynamic> json) => Resources(
        stone: json['stone'] as int? ?? 0,
        glass: json['glass'] as int? ?? 0,
        wood: json['wood'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() =>
      {'stone': stone, 'glass': glass, 'wood': wood};
}

Map<String, dynamic>? _mapFromDynamic(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, dynamicValue) => MapEntry('$key', dynamicValue));
  }
  return null;
}
