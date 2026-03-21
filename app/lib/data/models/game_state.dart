import 'district.dart';
import 'event.dart';
import 'squad.dart';
import 'user.dart';

class GameStateSnapshot {
  final MimzUser user;
  final District district;
  final bool onboardingCompleted;
  final String nextRecommendedRoute;
  final bool showMeetMimzPrompt;
  final String currentMission;
  final MissionSummaryModel? missionSummary;
  final MimzEvent? activeEvent;
  final List<EventZoneModel> eventZones;
  final SquadSummaryModel? squadSummary;
  final RankStateModel rankState;
  final StreakStateModel streakState;
  final DistrictHealthSummaryModel districtHealthSummary;
  final HeroBannerModel worldHeroBanner;
  final RecommendedActionModel recommendedPrimaryAction;
  final RecommendedActionModel? recommendedSecondaryAction;
  final StructureEffectsModel structureEffects;
  final StructureProgressModel structureProgress;
  final List<NotificationModel> notifications;
  final List<LeaderboardSummaryModel> leaderboardSnippets;
  final List<ConflictStateModel> activeConflicts;

  const GameStateSnapshot({
    required this.user,
    required this.district,
    this.onboardingCompleted = false,
    this.nextRecommendedRoute = '/world',
    this.showMeetMimzPrompt = false,
    required this.currentMission,
    this.missionSummary,
    this.activeEvent,
    this.eventZones = const [],
    this.squadSummary,
    required this.rankState,
    required this.streakState,
    required this.districtHealthSummary,
    required this.worldHeroBanner,
    required this.recommendedPrimaryAction,
    this.recommendedSecondaryAction,
    required this.structureEffects,
    required this.structureProgress,
    this.notifications = const [],
    this.leaderboardSnippets = const [],
    this.activeConflicts = const [],
  });

  factory GameStateSnapshot.fromJson(Map<String, dynamic> json) {
    final activeEventJson = _asStringDynamicMap(json['activeEvent']);
    final squadSummaryJson = _asStringDynamicMap(json['squadSummary']);
    final missionSummaryJson = _asStringDynamicMap(json['missionSummary']);
    return GameStateSnapshot(
      user: MimzUser.fromJson(json['user'] as Map<String, dynamic>),
      district: District.fromJson(json['district'] as Map<String, dynamic>),
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      nextRecommendedRoute:
          json['nextRecommendedRoute'] as String? ?? '/world',
      showMeetMimzPrompt: json['showMeetMimzPrompt'] as bool? ?? false,
      currentMission: json['currentMission'] as String? ?? 'Build your district',
      missionSummary: missionSummaryJson != null
          ? MissionSummaryModel.fromJson(missionSummaryJson)
          : null,
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
      rankState: RankStateModel.fromJson(
        _asStringDynamicMap(json['rankState']) ?? const {},
      ),
      streakState: StreakStateModel.fromJson(
        _asStringDynamicMap(json['streakState']) ?? const {},
      ),
      districtHealthSummary: DistrictHealthSummaryModel.fromJson(
        _asStringDynamicMap(json['districtHealthSummary']) ?? const {},
      ),
      worldHeroBanner: HeroBannerModel.fromJson(
        _asStringDynamicMap(json['worldHeroBanner']) ?? const {},
      ),
      recommendedPrimaryAction: RecommendedActionModel.fromJson(
        _asStringDynamicMap(json['recommendedPrimaryAction']) ?? const {},
      ),
      recommendedSecondaryAction:
          _asStringDynamicMap(json['recommendedSecondaryAction']) != null
              ? RecommendedActionModel.fromJson(
                  _asStringDynamicMap(json['recommendedSecondaryAction'])!,
                )
              : null,
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
  final String streakRiskState;
  final List<StreakHistoryEntryModel> streakHistory;

  const StreakStateModel({
    this.liveStreak = 0,
    this.dailyStreak = 0,
    this.bestStreak = 0,
    this.lastActivityDate,
    this.streakRiskState = 'cold',
    this.streakHistory = const [],
  });

  factory StreakStateModel.fromJson(Map<String, dynamic> json) => StreakStateModel(
        liveStreak: (json['liveStreak'] as num?)?.toInt() ?? 0,
        dailyStreak: (json['dailyStreak'] as num?)?.toInt() ?? 0,
        bestStreak: (json['bestStreak'] as num?)?.toInt() ?? 0,
        lastActivityDate: json['lastActivityDate'] as String?,
        streakRiskState: json['streakRiskState'] as String? ?? 'cold',
        streakHistory: (json['streakHistory'] as List?)
                ?.whereType<Map<String, dynamic>>()
                .map(StreakHistoryEntryModel.fromJson)
                .toList() ??
            const [],
      );
}

class StreakHistoryEntryModel {
  final String date;
  final bool active;

  const StreakHistoryEntryModel({
    required this.date,
    this.active = false,
  });

  factory StreakHistoryEntryModel.fromJson(Map<String, dynamic> json) =>
      StreakHistoryEntryModel(
        date: json['date'] as String? ?? '',
        active: json['active'] as bool? ?? false,
      );
}

class RankStateModel {
  final int rank;
  final String rankTitle;
  final int nextRankXp;
  final String prestigeTier;

  const RankStateModel({
    this.rank = 1,
    this.rankTitle = 'Explorer',
    this.nextRankXp = 0,
    this.prestigeTier = 'bronze',
  });

  factory RankStateModel.fromJson(Map<String, dynamic> json) => RankStateModel(
        rank: (json['rank'] as num?)?.toInt() ?? 1,
        rankTitle: json['rankTitle'] as String? ?? 'Explorer',
        nextRankXp: (json['nextRankXp'] as num?)?.toInt() ?? 0,
        prestigeTier: json['prestigeTier'] as String? ?? 'bronze',
      );
}

class DistrictHealthSummaryModel {
  final String state;
  final String headline;
  final String summary;
  final int vulnerableCells;
  final int reclaimableCells;
  final int nextExpansionIn;

  const DistrictHealthSummaryModel({
    this.state = 'stable',
    this.headline = 'District stable',
    this.summary = '',
    this.vulnerableCells = 0,
    this.reclaimableCells = 0,
    this.nextExpansionIn = 0,
  });

  factory DistrictHealthSummaryModel.fromJson(Map<String, dynamic> json) =>
      DistrictHealthSummaryModel(
        state: json['state'] as String? ?? 'stable',
        headline: json['headline'] as String? ?? 'District stable',
        summary: json['summary'] as String? ?? '',
        vulnerableCells: (json['vulnerableCells'] as num?)?.toInt() ?? 0,
        reclaimableCells: (json['reclaimableCells'] as num?)?.toInt() ?? 0,
        nextExpansionIn: (json['nextExpansionIn'] as num?)?.toInt() ?? 0,
      );
}

class HeroBannerModel {
  final String eyebrow;
  final String title;
  final String body;
  final String accent;
  final String route;

  const HeroBannerModel({
    this.eyebrow = 'Today',
    this.title = 'Grow your district',
    this.body = '',
    this.accent = 'moss',
    this.route = '/play',
  });

  factory HeroBannerModel.fromJson(Map<String, dynamic> json) =>
      HeroBannerModel(
        eyebrow: json['eyebrow'] as String? ?? 'Today',
        title: json['title'] as String? ?? 'Grow your district',
        body: json['body'] as String? ?? '',
        accent: json['accent'] as String? ?? 'moss',
        route: json['route'] as String? ?? '/play',
      );
}

class MissionSummaryModel {
  final String title;
  final String summary;
  final String rewardPreview;
  final String route;
  final int estimatedMinutes;
  final String priority;

  const MissionSummaryModel({
    this.title = 'Build your district',
    this.summary = '',
    this.rewardPreview = '',
    this.route = '/play',
    this.estimatedMinutes = 3,
    this.priority = 'now',
  });

  factory MissionSummaryModel.fromJson(Map<String, dynamic> json) =>
      MissionSummaryModel(
        title: json['title'] as String? ?? 'Build your district',
        summary: json['summary'] as String? ?? '',
        rewardPreview: json['rewardPreview'] as String? ?? '',
        route: json['route'] as String? ?? '/play',
        estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 3,
        priority: json['priority'] as String? ?? 'now',
      );
}

class RecommendedActionModel {
  final String type;
  final String title;
  final String subtitle;
  final String reasonWhyNow;
  final String rewardPreview;
  final String impactLabel;
  final String ctaLabel;
  final String route;
  final int estimatedMinutes;
  final String badge;

  const RecommendedActionModel({
    this.type = 'quiz',
    this.title = '',
    this.subtitle = '',
    this.reasonWhyNow = '',
    this.rewardPreview = '',
    this.impactLabel = 'District impact',
    this.ctaLabel = 'Play',
    this.route = '/play',
    this.estimatedMinutes = 2,
    this.badge = 'NOW',
  });

  factory RecommendedActionModel.fromJson(Map<String, dynamic> json) =>
      RecommendedActionModel(
        type: json['type'] as String? ?? 'quiz',
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String? ?? '',
        reasonWhyNow: json['reasonWhyNow'] as String? ?? '',
        rewardPreview: json['rewardPreview'] as String? ?? '',
        impactLabel: json['impactLabel'] as String? ?? 'District impact',
        ctaLabel: json['ctaLabel'] as String? ?? 'Play',
        route: json['route'] as String? ?? '/play',
        estimatedMinutes: (json['estimatedMinutes'] as num?)?.toInt() ?? 2,
        badge: json['badge'] as String? ?? 'NOW',
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
