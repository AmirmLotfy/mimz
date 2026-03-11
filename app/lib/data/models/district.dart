/// District model — represents a user's owned territory
class District {
  final String id;
  final String name;
  final int sectors;
  final String area;
  final List<Structure> structures;
  final Resources resources;

  const District({
    required this.id,
    required this.name,
    this.sectors = 1,
    this.area = '1.0 sq km',
    this.structures = const [],
    this.resources = const Resources(),
  });

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
      );

  static District get demo => District(
        id: 'district_001',
        name: 'Verdant Reach',
        sectors: 3,
        area: '4.2 sq km',
        structures: [
          const Structure(id: 's1', name: 'Solarium Wing', tier: 'master'),
          const Structure(id: 's2', name: 'Cedar Pavilion', tier: 'master'),
          const Structure(id: 's3', name: 'Stone Arch', tier: 'rare'),
        ],
        resources: const Resources(stone: 1250, glass: 480, wood: 920),
      );
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

  factory Resources.fromJson(Map<String, dynamic> json) => Resources(
        stone: json['stone'] as int? ?? 0,
        glass: json['glass'] as int? ?? 0,
        wood: json['wood'] as int? ?? 0,
      );
}
