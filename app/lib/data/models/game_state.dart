import 'district.dart';
import 'event.dart';
import 'squad.dart';
import 'user.dart';

class GameStateSnapshot {
  final MimzUser user;
  final District district;
  final String currentMission;
  final MimzEvent? activeEvent;
  final List<EventZoneModel> eventZones;
  final SquadSummaryModel? squadSummary;
  final StreakStateModel streakState;
  final StructureEffectsModel structureEffects;
  final StructureProgressModel structureProgress;
  final List<NotificationModel> notifications;
  final List<LeaderboardSummaryModel> leaderboardSnippets;
  final List<ConflictStateModel> activeConflicts;

  const GameStateSnapshot({
    required this.user,
    required this.district,
    required this.currentMission,
    this.activeEvent,
    this.eventZones = const [],
    this.squadSummary,
    required this.streakState,
    required this.structureEffects,
    required this.structureProgress,
    this.notifications = const [],
    this.leaderboardSnippets = const [],
    this.activeConflicts = const [],
  });

  factory GameStateSnapshot.fromJson(Map<String, dynamic> json) {
    final activeEventJson = _asStringDynamicMap(json['activeEvent']);
    final squadSummaryJson = _asStringDynamicMap(json['squadSummary']);
    return GameStateSnapshot(
      user: MimzUser.fromJson(json['user'] as Map<String, dynamic>),
      district: District.fromJson(json['district'] as Map<String, dynamic>),
      currentMission: json['currentMission'] as String? ?? 'Build your district',
      activeEvent: activeEventJson != null
          ? MimzEvent.fromJson(activeEventJson)
          : null,
      eventZones: (json['eventZones'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(EventZoneModel.fromJson)
              .toList() ??
          const [],
      squadSummary: squadSummaryJson != null
          ? SquadSummaryModel.fromJson(squadSummaryJson)
          : null,
      streakState: StreakStateModel.fromJson(
        _asStringDynamicMap(json['streakState']) ?? const {},
      ),
      structureEffects: StructureEffectsModel.fromJson(
        _asStringDynamicMap(json['structureEffects']) ?? const {},
      ),
      structureProgress: StructureProgressModel.fromJson(
        _asStringDynamicMap(json['structureProgress']) ?? const {},
      ),
      notifications: (json['notifications'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(NotificationModel.fromJson)
              .toList() ??
          const [],
      leaderboardSnippets: (json['leaderboardSnippets'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(LeaderboardSummaryModel.fromJson)
              .toList() ??
          const [],
      activeConflicts: (json['activeConflicts'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ConflictStateModel.fromJson)
              .toList() ??
          const [],
    );
  }
}

Map<String, dynamic>? _asStringDynamicMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, dynamicValue) => MapEntry('$key', dynamicValue));
  }
  return null;
}

class EventZoneModel {
  final String id;
  final String eventId;
  final String title;
  final String status;
  final String regionId;
  final String regionLabel;
  final String districtEffect;
  final double rewardMultiplier;

  const EventZoneModel({
    required this.id,
    required this.eventId,
    required this.title,
    this.status = 'upcoming',
    this.regionId = 'global_central',
    this.regionLabel = 'Global District Grid',
    this.districtEffect = '',
    this.rewardMultiplier = 1,
  });

  factory EventZoneModel.fromJson(Map<String, dynamic> json) => EventZoneModel(
        id: json['id'] as String? ?? '',
        eventId: json['eventId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        status: json['status'] as String? ?? 'upcoming',
        regionId: json['regionId'] as String? ?? 'global_central',
        regionLabel: json['regionLabel'] as String? ?? 'Global District Grid',
        districtEffect: json['districtEffect'] as String? ?? '',
        rewardMultiplier: (json['rewardMultiplier'] as num?)?.toDouble() ?? 1,
      );
}

class StreakStateModel {
  final int liveStreak;
  final int dailyStreak;
  final int bestStreak;
  final String? lastActivityDate;

  const StreakStateModel({
    this.liveStreak = 0,
    this.dailyStreak = 0,
    this.bestStreak = 0,
    this.lastActivityDate,
  });

  factory StreakStateModel.fromJson(Map<String, dynamic> json) => StreakStateModel(
        liveStreak: (json['liveStreak'] as num?)?.toInt() ?? 0,
        dailyStreak: (json['dailyStreak'] as num?)?.toInt() ?? 0,
        bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
        lastActivityDate: json['lastActivityDate'] as String?,
      );
}

class StructureEffectsModel {
  final double xpMultiplier;
  final double materialMultiplier;
  final double influenceMultiplier;
  final double decayReduction;
  final int streakProtection;
  final double squadMultiplier;

  const StructureEffectsModel({
    this.xpMultiplier = 1,
    this.materialMultiplier = 1,
    this.influenceMultiplier = 1,
    this.decayReduction = 0,
    this.streakProtection = 0,
    this.squadMultiplier = 1,
  });

  factory StructureEffectsModel.fromJson(Map<String, dynamic> json) => StructureEffectsModel(
        xpMultiplier: (json['xpMultiplier'] as num?)?.toDouble() ?? 1,
        materialMultiplier: (json['materialMultiplier'] as num?)?.toDouble() ?? 1,
        influenceMultiplier: (json['influenceMultiplier'] as num?)?.toDouble() ?? 1,
        decayReduction: (json['decayReduction'] as num?)?.toDouble() ?? 0,
        streakProtection: (json['streakProtection'] as num?)?.toInt() ?? 0,
        squadMultiplier: (json['squadMultiplier'] as num?)?.toDouble() ?? 1,
      );
}

class StructureProgressModel {
  final String? nextStructureId;
  final String? nextStructureName;
  final int unlockedCount;
  final int totalAvailable;
  final bool readyToBuild;

  const StructureProgressModel({
    this.nextStructureId,
    this.nextStructureName,
    this.unlockedCount = 0,
    this.totalAvailable = 0,
    this.readyToBuild = false,
  });

  factory StructureProgressModel.fromJson(Map<String, dynamic> json) => StructureProgressModel(
        nextStructureId: json['nextStructureId'] as String?,
        nextStructureName: json['nextStructureName'] as String?,
        unlockedCount: (json['unlockedCount'] as num?)?.toInt() ?? 0,
        totalAvailable: (json['totalAvailable'] as num?)?.toInt() ?? 0,
        readyToBuild: json['readyToBuild'] as bool? ?? false,
      );
}

class NotificationModel {
  final String id;
  final String type;
  final String title;
  final String body;
  final bool read;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.read = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? 'system',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        read: json['read'] as bool? ?? false,
      );
}

class LeaderboardSummaryModel {
  final String scope;
  final String title;
  final List<Map<String, dynamic>> entries;

  const LeaderboardSummaryModel({
    required this.scope,
    required this.title,
    this.entries = const [],
  });

  factory LeaderboardSummaryModel.fromJson(Map<String, dynamic> json) => LeaderboardSummaryModel(
        scope: json['scope'] as String? ?? 'global',
        title: json['title'] as String? ?? '',
        entries: (json['entries'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .toList() ??
            const [],
      );
}

class ConflictStateModel {
  final String id;
  final String type;
  final String status;
  final int cellsAtStake;
  final String? headline;
  final String? summary;
  final String? districtName;

  const ConflictStateModel({
    required this.id,
    required this.type,
    required this.status,
    this.cellsAtStake = 0,
    this.headline,
    this.summary,
    this.districtName,
  });

  factory ConflictStateModel.fromJson(Map<String, dynamic> json) => ConflictStateModel(
        id: json['id'] as String? ?? '',
        type: json['type'] as String? ?? 'rivalry',
        status: json['status'] as String? ?? 'active',
        cellsAtStake: (json['cellsAtStake'] as num?)?.toInt() ?? 0,
        headline: json['headline'] as String?,
        summary: json['summary'] as String?,
        districtName: json['districtName'] as String?,
      );
}

class SquadSummaryModel {
  final Squad? squad;
  final List<SquadMember> members;
  final List<SquadMission> missions;

  const SquadSummaryModel({
    this.squad,
    this.members = const [],
    this.missions = const [],
  });

  factory SquadSummaryModel.fromJson(Map<String, dynamic> json) {
    final squadJson = json['squad'] as Map<String, dynamic>?;
    final members = (json['members'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(SquadMember.fromJson)
            .toList() ??
        const <SquadMember>[];
    final missions = (json['missions'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(SquadMission.fromJson)
            .toList() ??
        const <SquadMission>[];

    if (squadJson == null) {
      return SquadSummaryModel(members: members, missions: missions);
    }

    return SquadSummaryModel(
      squad: Squad.fromJson({
        ...squadJson,
        'members': members
            .map((member) => {
                  'userId': member.userId,
                  'displayName': member.name,
                  'rank': member.rank,
                  'xpContributed': int.tryParse(member.xp.split(' ').first) ?? 0,
                })
            .toList(),
        'missions': missions
            .map((mission) => {
                  'id': mission.id,
                  'title': mission.title,
                  'description': mission.description,
                  'goalProgress': mission.goalProgress,
                  'currentProgress': mission.currentProgress,
                  'deadline': mission.deadline,
                })
            .toList(),
      }),
      members: members,
      missions: missions,
    );
  }
}
