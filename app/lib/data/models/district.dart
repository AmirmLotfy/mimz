import 'dart:math';

/// District model — represents a user's owned territory
class District {
  final String id;
  final String name;
  final int sectors;
  final String area;
  final List<Structure> structures;
  final Resources resources;
  final int prestigeLevel;
  final int newSectors; // Tracks how many sectors were added in the last update for targeted animation

  const District({
    required this.id,
    required this.name,
    this.sectors = 1,
    this.area = '1.0 sq km',
    this.structures = const [],
    this.resources = const Resources(),
    this.prestigeLevel = 1,
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
    final base = 1.0;
    final structureBonus = structures.length * 0.8;
    return base + structureBonus;
  }

  /// Total prestige from structures
  int get totalPrestige {
    int base = prestigeLevel;
    for (final s in structures) {
      base += s.tier == 'master' ? 3 : s.tier == 'rare' ? 2 : 1;
    }
    return base;
  }

  /// Generate hex cell positions for map rendering based on sector count.
  /// Returns list of (col, row) offsets in a hex spiral pattern.
  List<HexCell> get hexCells {
    final cells = <HexCell>[];
    if (sectors <= 0) return cells;

    // Center cell
    cells.add(const HexCell(0, 0, true));
    if (sectors <= 1) return cells;

    // Spiral outward - each ring adds 6 * ring cells
    int placed = 1;
    int ring = 1;
    // Hex directions for pointy-top hexagons
    final dirs = [
      [1, 0], [1, -1], [0, -1],
      [-1, 0], [-1, 1], [0, 1],
    ];

    while (placed < sectors) {
      int q = 0, r = -ring;
      for (int d = 0; d < 6 && placed < sectors; d++) {
        for (int s = 0; s < ring && placed < sectors; s++) {
          cells.add(HexCell(q, r, false));
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
        newSectors: 0, // Reset when coming from fresh JSON over network
      );

  District copyWith({
    String? name,
    int? sectors,
    String? area,
    List<Structure>? structures,
    Resources? resources,
    int? prestigeLevel,
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
        newSectors: newSectors ?? this.newSectors,
      );

  static District get demo => District(
        id: 'district_001',
        name: 'Verdant Reach',
        sectors: 7,
        area: '7.7 sq km',
        structures: [
          const Structure(id: 's1', name: 'Solarium Wing', tier: 'master'),
          const Structure(id: 's2', name: 'Cedar Pavilion', tier: 'master'),
          const Structure(id: 's3', name: 'Stone Arch', tier: 'rare'),
        ],
        resources: const Resources(stone: 1250, glass: 480, wood: 920),
        prestigeLevel: 4,
        newSectors: 0,
      );
}

/// Single hex cell position using axial coordinates
class HexCell {
  final int q;
  final int r;
  final bool isCenter;
  const HexCell(this.q, this.r, this.isCenter);
}

class Structure {
  final String id;
  final String name;
  final String tier;

  const Structure({required this.id, required this.name, required this.tier});

  factory Structure.fromJson(Map<String, dynamic> json) => Structure(
        id: json['id'] as String,
        name: json['name'] as String,
        tier: json['tier'] as String,
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

  Map<String, dynamic> toJson() => {'stone': stone, 'glass': glass, 'wood': wood};
}
