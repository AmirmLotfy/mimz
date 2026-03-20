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
  final String userId;

  const SquadMember({
    required this.name,
    required this.xp,
    required this.rank,
    this.userId = '',
  });

  factory SquadMember.fromJson(Map<String, dynamic> json) => SquadMember(
        userId: json['userId'] as String? ?? '',
        name: json['displayName'] as String? ?? json['name'] as String? ?? 'Member',
        xp: (json['xpContributed'] as num?)?.toInt().toString() != null
            ? '${json['xpContributed']} XP'
            : '0 XP',
        rank: json['rank'] as int? ?? 0,
      );
}

class SquadMission {
  final String id;
  final String title;
  final String description;
  final double progress;
  final int members;
  final String deadline;
  final int goalProgress;
  final int currentProgress;

  const SquadMission({
    this.id = '',
    required this.title,
    this.description = '',
    this.progress = 0,
    this.members = 0,
    this.deadline = '',
    this.goalProgress = 100,
    this.currentProgress = 0,
  });

  bool get isCompleted => currentProgress >= goalProgress && goalProgress > 0;

  factory SquadMission.fromJson(Map<String, dynamic> json) {
    final goal = (json['goalProgress'] as num?)?.toInt() ?? 100;
    final current = (json['currentProgress'] as num?)?.toInt() ?? 0;
    final progressRatio = goal > 0 ? (current / goal).clamp(0.0, 1.0) : 0.0;
    return SquadMission(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Mission',
      description: json['description'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? progressRatio,
      members: json['members'] as int? ?? 0,
      deadline: json['deadline'] as String? ?? '',
      goalProgress: goal,
      currentProgress: current,
    );
  }
}
