import * as db from '../lib/db.js';
import * as game from './gameService.js';
import type {
  ConflictState,
  District,
  DistrictHealthSummary,
  GameState,
  HeroBanner,
  LeaderboardEntry,
  LeaderboardScope,
  LeaderboardSummary,
  MimzEvent,
  MissionSummary,
  RankState,
  RecommendedAction,
  SquadSummary,
  StructureProgress,
  User,
} from '../models/types.js';
import { STRUCTURE_CATALOG } from '../models/types.js';

function startOfWeekScope(now = new Date()): string {
  const startOfYear = new Date(now.getFullYear(), 0, 1);
  const weekNum = Math.ceil(((now.getTime() - startOfYear.getTime()) / 86400000 + startOfYear.getDay() + 1) / 7);
  return `weekly_${now.getFullYear()}_${weekNum}`;
}

function withRanks(scope: LeaderboardScope, entries: any[]): LeaderboardEntry[] {
  return entries.map((entry, index) => ({
    ...entry,
    rank: typeof entry.rank === 'number' ? entry.rank : index + 1,
    scope,
  }));
}

const RANK_TIERS: Array<{
  minXp: number;
  rank: number;
  title: string;
  prestigeTier: RankState['prestigeTier'];
}> = [
  { minXp: 0, rank: 1, title: 'Explorer', prestigeTier: 'bronze' },
  { minXp: 1000, rank: 2, title: 'Pathfinder', prestigeTier: 'bronze' },
  { minXp: 3000, rank: 3, title: 'Strategist', prestigeTier: 'silver' },
  { minXp: 8000, rank: 4, title: 'Cartographer', prestigeTier: 'silver' },
  { minXp: 15000, rank: 5, title: 'Architect', prestigeTier: 'gold' },
  { minXp: 30000, rank: 6, title: 'Warden', prestigeTier: 'platinum' },
  { minXp: 50000, rank: 7, title: 'Sovereign', prestigeTier: 'diamond' },
];

function buildRankState(user: User): RankState {
  const current = [...RANK_TIERS].reverse().find((tier) => user.xp >= tier.minXp) ?? RANK_TIERS[0];
  const next = RANK_TIERS.find((tier) => tier.minXp > user.xp);
  return {
    rank: current.rank,
    rankTitle: current.title,
    prestigeTier: current.prestigeTier,
    nextRankXp: next ? Math.max(0, next.minXp - user.xp) : 0,
  };
}

function isoDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}

function addDays(date: Date, days: number): Date {
  const next = new Date(date);
  next.setUTCDate(next.getUTCDate() + days);
  return next;
}

function buildStreakHistory(user: User): Array<{ date: string; active: boolean }> {
  const today = new Date();
  const activityHistory = Array.isArray((user as any).activityHistory)
    ? new Set<string>(((user as any).activityHistory as string[]).slice(-21))
    : new Set<string>();

  if (activityHistory.size === 0 && user.lastActivityDate && user.dailyStreak > 0) {
    const last = new Date(`${user.lastActivityDate}T00:00:00.000Z`);
    for (let i = user.dailyStreak - 1; i >= 0; i--) {
      activityHistory.add(isoDate(addDays(last, -i)));
    }
  }

  return Array.from({ length: 14 }, (_, index) => {
    const date = isoDate(addDays(today, index - 13));
    return {
      date,
      active: activityHistory.has(date),
    };
  });
}

function buildStreakRiskState(user: User): 'secured' | 'at_risk' | 'cold' {
  const today = isoDate(new Date());
  if (user.lastActivityDate === today) return 'secured';
  if (user.dailyStreak > 0) return 'at_risk';
  return 'cold';
}

function buildDistrictHealthSummary(district: District): DistrictHealthSummary {
  const frontier = district.cells.filter((cell) => cell.layer === 'frontier');
  const vulnerableCells = frontier.filter((cell) => cell.stability < 40).length;
  const reclaimableCells = frontier.filter((cell) => cell.stability <= 0).length;
  const nextExpansionIn = Math.max(0, district.influenceThreshold - district.influence);

  if (reclaimableCells > 0) {
    return {
      state: 'reclaimable',
      headline: 'Your frontier is ready to reclaim',
      summary: `${reclaimableCells} cells are cooling out. One short session can stabilize them.`,
      vulnerableCells,
      reclaimableCells,
      nextExpansionIn,
    };
  }
  if (district.decayState === 'vulnerable' || vulnerableCells > 0) {
    return {
      state: 'vulnerable',
      headline: 'Your frontier needs attention',
      summary: `${vulnerableCells} frontier cells are vulnerable. Keep momentum to hold the edge.`,
      vulnerableCells,
      reclaimableCells,
      nextExpansionIn,
    };
  }
  if (district.decayState === 'cooling') {
    return {
      state: 'cooling',
      headline: 'Your district is cooling',
      summary: 'A quick round today will keep your district warm and growing.',
      vulnerableCells,
      reclaimableCells,
      nextExpansionIn,
    };
  }
  return {
    state: 'stable',
    headline: 'Your district is stable',
    summary: nextExpansionIn > 0
      ? `${nextExpansionIn} more influence until your next expansion.`
      : 'You are ready to expand on your next strong result.',
    vulnerableCells,
    reclaimableCells,
    nextExpansionIn,
  };
}

function buildRecommendedActions(
  user: User,
  district: District,
  structureProgress: StructureProgress,
  activeEvent: MimzEvent | null,
  squadId: string | null,
): {
  primary: RecommendedAction;
  secondary?: RecommendedAction;
  banner: HeroBanner;
} {
  const health = buildDistrictHealthSummary(district);
  const streakRisk = buildStreakRiskState(user);
  const eventAction: RecommendedAction = {
    type: 'event',
    title: activeEvent ? `Join ${activeEvent.title}` : 'Event challenge unavailable',
    subtitle: activeEvent
      ? 'Live zone rewards are boosted right now.'
      : 'No active event right now.',
    reasonWhyNow: activeEvent
      ? 'The live event is boosting rewards and leaderboard movement right now.'
      : 'This will return when a live event rotates in.',
    rewardPreview: activeEvent
      ? `Boosted event rewards in about 4 minutes.`
      : 'No live event rewards at the moment.',
    impactLabel: activeEvent
      ? 'Event zone influence'
      : 'World event',
    ctaLabel: 'Join Event',
    route: '/events',
    estimatedMinutes: 4,
    badge: 'LIVE',
  };
  const sprintAction: RecommendedAction = {
    type: 'sprint',
    title: 'Secure your daily streak',
    subtitle: 'Three quick questions to lock in today.',
    reasonWhyNow: 'You can protect your rhythm fast without committing to a full round.',
    rewardPreview: 'Streak secured, daily bonus, and a small district push.',
    impactLabel: 'Daily rhythm',
    ctaLabel: 'Start Sprint',
    route: '/play/sprint',
    estimatedMinutes: 2,
    badge: 'DAILY',
  };
  const quizAction: RecommendedAction = {
    type: 'quiz',
    title: 'Play a live district round',
    subtitle: 'Five strong questions to grow your frontier.',
    reasonWhyNow: 'This is the main progression loop for territory, materials, and structures.',
    rewardPreview: 'Frontier growth, materials, and squad/event contribution.',
    impactLabel: 'Frontier growth',
    ctaLabel: 'Play Live Quiz',
    route: '/play/quiz',
    estimatedMinutes: 4,
    badge: 'LIVE',
  };
  const reclaimAction: RecommendedAction = {
    type: 'reclaim',
    title: 'Reclaim your frontier',
    subtitle: health.summary,
    reasonWhyNow: 'Your newest cells are weakening and are easiest to stabilize right now.',
    rewardPreview: `${health.reclaimableCells} reclaimable cells and rhythm recovery.`,
    impactLabel: 'District recovery',
    ctaLabel: 'Reclaim Frontier',
    route: '/world',
    estimatedMinutes: 2,
    badge: 'SAVE',
  };
  const buildAction: RecommendedAction = {
    type: 'build',
    title: `Build ${structureProgress.nextStructureName ?? 'your next structure'}`,
    subtitle: 'Your district is ready for its next permanent upgrade.',
    reasonWhyNow: 'You have enough progress banked to convert play into a permanent district bonus.',
    rewardPreview: `${structureProgress.nextStructureName ?? 'Next structure'} unlocks a lasting gameplay effect.`,
    impactLabel: 'Permanent upgrade',
    ctaLabel: 'Open Build',
    route: '/district/detail',
    estimatedMinutes: 1,
    badge: 'BUILD',
  };
  const squadAction: RecommendedAction = {
    type: 'squad',
    title: squadId == null ? 'Join a squad' : 'Push your squad mission',
    subtitle: squadId == null
      ? 'Shared missions make every round matter more.'
      : 'Your next round contributes directly to squad progress.',
    reasonWhyNow: squadId == null
      ? 'Joining a squad turns your sessions into shared progression and bonus momentum.'
      : 'Your squad is active enough for your next session to matter immediately.',
    rewardPreview: squadId == null
      ? 'Unlock shared missions and social momentum.'
      : 'Bonus squad contribution from your next result.',
    impactLabel: 'Squad momentum',
    ctaLabel: squadId == null ? 'Find Squad' : 'Open Squad',
    route: '/squad',
    estimatedMinutes: 2,
    badge: 'TEAM',
  };
  const visionAction: RecommendedAction = {
    type: 'vision',
    title: 'Run a vision quest',
    subtitle: 'A fast camera challenge can unlock structure progress.',
    reasonWhyNow: 'Vision quests are your shortest premium session and can open structure lanes quickly.',
    rewardPreview: 'Fast materials, structure blueprint progress, and event tie-ins.',
    impactLabel: 'Blueprint progress',
    ctaLabel: 'Start Vision Quest',
    route: '/play/vision',
    estimatedMinutes: 2,
    badge: 'CAM',
  };

  if (health.state === 'reclaimable' || health.state === 'vulnerable') {
    return {
      primary: reclaimAction,
      secondary: streakRisk === 'at_risk' ? sprintAction : quizAction,
      banner: {
        eyebrow: 'Frontier Alert',
        title: health.headline,
        body: health.summary,
        accent: 'persimmon',
        route: '/district/detail',
      },
    };
  }

  if (activeEvent) {
    return {
      primary: eventAction,
      secondary: streakRisk === 'at_risk' ? sprintAction : quizAction,
      banner: {
        eyebrow: 'Live Event',
        title: `${activeEvent.title} is live`,
        body: 'Your district can earn boosted rewards in the active event zone.',
        accent: 'gold',
        route: '/events',
      },
    };
  }

  if (structureProgress.readyToBuild) {
    return {
      primary: buildAction,
      secondary: quizAction,
      banner: {
        eyebrow: 'District Upgrade',
        title: `${structureProgress.nextStructureName ?? 'A new structure'} is ready`,
        body: 'Convert your recent progress into a permanent district bonus.',
        accent: 'moss',
        route: '/district/detail',
      },
    };
  }

  if (streakRisk === 'at_risk') {
    return {
      primary: sprintAction,
      secondary: squadId == null ? squadAction : visionAction,
      banner: {
        eyebrow: 'Keep Momentum',
        title: 'Your streak is at risk today',
        body: 'A quick sprint now protects your rhythm and keeps your district warm.',
        accent: 'mist',
        route: '/play/sprint',
      },
    };
  }

  return {
    primary: quizAction,
    secondary: squadId == null ? squadAction : visionAction,
    banner: {
      eyebrow: 'Today',
      title: 'One strong round grows your district',
      body: 'Play now to push your frontier, earn materials, and build toward your next unlock.',
      accent: 'moss',
      route: '/play/quiz',
    },
  };
}

async function buildMission(userId: string, user: User, district: District, squadId: string | null): Promise<string> {
  const sectors = district?.sectors ?? user.sectors ?? 0;
  const structures = district?.structures ?? [];
  const dailyStreak = (user as any).dailyStreak ?? 0;

  if (sectors < 3) {
    return 'Win your first quiz round';
  }
  if (sectors < 10 && structures.length === 0) {
    return 'Unlock your first structure via Vision Quest';
  }
  if (dailyStreak === 0) {
    return 'Start a daily streak — play today!';
  }
  if (!squadId) {
    return 'Join or create a squad';
  }
  return `Expand to ${sectors + 5} sectors`;
}

function buildMissionSummary(
  user: User,
  district: District,
  squadId: string | null,
  structureProgress: StructureProgress,
  activeEvent: MimzEvent | null,
  health: DistrictHealthSummary,
): MissionSummary {
  const sectors = district.sectors ?? user.sectors ?? 0;
  const hasStructures = district.structures.length > 0;
  const dailyStreak = user.dailyStreak ?? 0;

  if (health.state === 'reclaimable' || health.state === 'vulnerable') {
    return {
      title: 'Stabilize your frontier',
      summary: health.summary,
      rewardPreview: `${health.reclaimableCells} reclaimable cells and district recovery.`,
      route: '/world',
      estimatedMinutes: 2,
      priority: 'now',
    };
  }

  if (activeEvent != null) {
    return {
      title: `Play the ${activeEvent.title} event`,
      summary: 'A live event is active and can move your district faster than a normal session.',
      rewardPreview: 'Boosted event rewards and leaderboard progress.',
      route: '/events',
      estimatedMinutes: 4,
      priority: 'now',
    };
  }

  if (sectors < 3) {
    return {
      title: 'Win your first live round',
      summary: 'Your district needs one clean result to start feeling alive on the map.',
      rewardPreview: 'First frontier growth and materials.',
      route: '/play/quiz',
      estimatedMinutes: 4,
      priority: 'now',
    };
  }

  if (!hasStructures) {
    return {
      title: 'Unlock your first structure',
      summary: 'A vision quest is the fastest way to turn progress into district identity.',
      rewardPreview: 'Blueprint progress and your first permanent bonus.',
      route: '/play/vision',
      estimatedMinutes: 2,
      priority: 'soon',
    };
  }

  if (structureProgress.readyToBuild) {
    return {
      title: `Build ${structureProgress.nextStructureName ?? 'your next structure'}`,
      summary: 'You have enough progress banked for a permanent district upgrade.',
      rewardPreview: `${structureProgress.nextStructureName ?? 'Next structure'} is ready to activate.`,
      route: '/district/detail',
      estimatedMinutes: 1,
      priority: 'now',
    };
  }

  if (dailyStreak == 0) {
    return {
      title: 'Start your daily rhythm',
      summary: 'A quick sprint today starts your retention loop without a heavy session.',
      rewardPreview: 'Daily streak protection and bonus influence.',
      route: '/play/sprint',
      estimatedMinutes: 2,
      priority: 'soon',
    };
  }

  if (!squadId) {
    return {
      title: 'Join a squad',
      summary: 'Squads turn every good round into shared progress and extra momentum.',
      rewardPreview: 'Shared missions and bonus social progression.',
      route: '/squad',
      estimatedMinutes: 2,
      priority: 'later',
    };
  }

  return {
    title: `Expand to ${sectors + 5} sectors`,
    summary: 'Your district is stable enough to push for the next meaningful expansion.',
    rewardPreview: 'Frontier growth, materials, and structure progress.',
    route: '/play/quiz',
    estimatedMinutes: 4,
    priority: 'soon',
  };
}

function hasCoreProfile(user: User): boolean {
  return Boolean(
    user.preferredName?.trim().length &&
    user.ageBand?.trim().length &&
    user.studyWorkStatus?.trim().length,
  );
}

function nextRecommendedRoute(user: User): string {
  if (user.onboardingCompleted) return '/world';

  switch (user.onboardingStage) {
    case 'interests':
      return '/onboarding/interests';
    case 'preferences':
      return '/onboarding/preferences';
    case 'summary':
      return '/onboarding/summary';
    case 'permissions_location':
      return '/permissions/location';
    case 'permissions_microphone':
      return '/permissions/microphone';
    case 'profile':
      if (!hasCoreProfile(user)) return '/onboarding/profile-setup';
      if (user.interests.length === 0) return '/onboarding/interests';
      return '/onboarding/preferences';
    case 'permissions':
      return '/permissions/location';
    case 'emblem':
      return '/district/emblem';
    case 'district_name':
      return '/district/name';
    case 'district_reveal':
      return '/district/reveal';
    case 'completed':
      return '/world';
    default:
      return '/onboarding/profile-setup';
  }
}

function buildStructureProgress(user: User, district: District): StructureProgress {
  const unlockedCount = district.structures.length;
  const next = STRUCTURE_CATALOG.find((entry) => !district.structures.some((s) => s.id === entry.id));
  if (!next) {
    return {
      unlockedCount,
      totalAvailable: STRUCTURE_CATALOG.length,
      readyToBuild: false,
    };
  }

  const readyToBuild =
    user.sectors >= next.requirements.minSectors &&
    user.xp >= next.requirements.minXp &&
    game.canAfford(district.resources, next.cost);

  return {
    nextStructureId: next.id,
    nextStructureName: next.name,
    unlockedCount,
    totalAvailable: STRUCTURE_CATALOG.length,
    readyToBuild,
  };
}

async function buildSquadSummary(squadId: string | null): Promise<SquadSummary | undefined> {
  if (!squadId) return undefined;
  const [squad, members, missions] = await Promise.all([
    db.getSquad(squadId),
    db.getSquadMembers(squadId),
    db.getSquadMissions(squadId),
  ]);
  if (!squad) return undefined;
  return {
    squad,
    members: members as any,
    missions: missions as any,
  };
}

async function buildLeaderboardSnippets(district: District, topTopic?: string, activeEvent?: MimzEvent | null): Promise<LeaderboardSummary[]> {
  const scopes: Array<{ scope: LeaderboardScope; title: string; key: string }> = [
    { scope: 'global', title: 'Global Prestige', key: 'global' },
    { scope: 'weekly', title: 'Weekly Growth', key: startOfWeekScope() },
    { scope: 'region', title: `${(district as any).regionAnchor?.label ?? 'Regional'} Districts`, key: `region_${(district as any).regionAnchor?.regionId ?? 'global_central'}` },
  ];

  if (topTopic) {
    scopes.push({ scope: 'topic', title: `${topTopic} Masters`, key: `topic_${game.slugifyTopic(topTopic)}` });
  }
  if (activeEvent) {
    scopes.push({ scope: 'event', title: `${activeEvent.title} Leaders`, key: `event_${activeEvent.id}` });
  }

  const results = await Promise.all(scopes.map(async ({ scope, title, key }) => {
    try {
      const entries = await db.getLeaderboard(key, 3);
      return {
        scope,
        title,
        entries: withRanks(scope, entries),
      } satisfies LeaderboardSummary;
    } catch {
      return {
        scope,
        title,
        entries: [],
      } satisfies LeaderboardSummary;
    }
  }));

  return results;
}

function toConflictState(conflict: any, districtName: string): ConflictState {
  const type = conflict.type === 'inactivity_takeover'
    ? 'Your frontier is vulnerable to reclaim.'
    : conflict.type === 'event_zone'
      ? 'An event zone is under contest.'
      : 'A rival district is pressuring your frontier.';
  return {
    ...conflict,
    districtName,
    headline: 'Frontier Conflict',
    summary: type,
  };
}

export async function getCanonicalGameState(userId: string): Promise<GameState | null> {
  const [user, rawDistrict] = await Promise.all([
    db.getUser(userId),
    game.syncDistrictDerivedState(userId),
  ]);
  if (!user || !rawDistrict) return null;

  let district = rawDistrict;
  if (!Array.isArray((district as any).cells) || (district as any).cells.length === 0) {
    await game.syncTerritoryCells(userId);
    district = (await game.syncDistrictDerivedState(userId)) ?? rawDistrict;
  }

  const [events, notifications, squadId, conflicts, structureEffects] = await Promise.all([
    db.listEvents().catch(() => [] as MimzEvent[]),
    db.getUserNotifications(userId).catch(() => [] as any[]),
    db.getSquadIdForUser(userId).catch(() => null),
    db.getActiveConflicts(userId).catch(() => [] as any[]),
    game.getStructureEffects(userId),
  ]);

  const activeEvent = events.find((event) => event.status === 'live') ?? null;
  const topTopic = Object.values(((user as any).topicStats ?? {}) as Record<string, any>)
    .sort((a, b) => (b.masteryScore ?? 0) - (a.masteryScore ?? 0))[0]?.topic as string | undefined;
  const [leaderboardSnippets, squadSummary] = await Promise.all([
    buildLeaderboardSnippets(district, topTopic, activeEvent),
    buildSquadSummary(squadId),
  ]);
  const structureProgress = buildStructureProgress(user, district);
  const districtHealth = buildDistrictHealthSummary(district);
  const recommended = buildRecommendedActions(
    user,
    district,
    structureProgress,
    activeEvent,
    squadId,
  );

  return {
    user,
    district,
    onboardingCompleted: user.onboardingCompleted,
    nextRecommendedRoute: nextRecommendedRoute(user),
    showMeetMimzPrompt: user.onboardingCompleted && !user.meetMimzIntroSeen,
    currentMission: await buildMission(userId, user, district, squadId),
    missionSummary: buildMissionSummary(
      user,
      district,
      squadId,
      structureProgress,
      activeEvent,
      districtHealth,
    ),
    activeEvent,
    eventZones: events.map((event) => game.buildEventZone(event, district)),
    squadSummary,
    rankState: buildRankState(user),
    streakState: {
      liveStreak: user.streak,
      dailyStreak: user.dailyStreak,
      bestStreak: user.bestStreak,
      lastActivityDate: user.lastActivityDate,
      streakRiskState: buildStreakRiskState(user),
      streakHistory: buildStreakHistory(user),
    },
    districtHealthSummary: districtHealth,
    worldHeroBanner: recommended.banner,
    recommendedPrimaryAction: recommended.primary,
    recommendedSecondaryAction: recommended.secondary,
    structureEffects,
    structureProgress,
    notifications: notifications.slice(0, 10) as any,
    leaderboardSnippets,
    activeConflicts: conflicts.map((conflict) => toConflictState(conflict, district.name)),
  };
}
