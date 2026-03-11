/// Squad model
class Squad {
  final String id;
  final String name;
  final List<SquadMember> members;
  final List<SquadMission> missions;
  final DateTime createdAt;

  const Squad({
    required this.id,
    required this.name,
    this.members = const [],
    this.missions = const [],
    required this.createdAt,
  });

  factory Squad.fromJson(Map<String, dynamic> json) => Squad(
        id: json['id'] as String? ?? json['squadId'] as String,
        name: json['name'] as String,
        members: (json['members'] as List?)
                ?.map((m) => SquadMember.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        missions: (json['missions'] as List?)
                ?.map((m) => SquadMission.fromJson(m as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      );
}

class SquadMember {
  final String name;
  final String xp;
  final int rank;

  const SquadMember({required this.name, required this.xp, required this.rank});

  factory SquadMember.fromJson(Map<String, dynamic> json) => SquadMember(
        name: json['name'] as String,
        xp: json['xp'] as String? ?? '0 XP',
        rank: json['rank'] as int? ?? 0,
      );
}

class SquadMission {
  final String title;
  final double progress;
  final int members;
  final String deadline;

  const SquadMission({
    required this.title,
    this.progress = 0,
    this.members = 0,
    this.deadline = '',
  });

  factory SquadMission.fromJson(Map<String, dynamic> json) => SquadMission(
        title: json['title'] as String,
        progress: (json['progress'] as num?)?.toDouble() ?? 0,
        members: json['members'] as int? ?? 0,
        deadline: json['deadline'] as String? ?? '',
      );
}
