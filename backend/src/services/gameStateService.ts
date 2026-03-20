import * as db from '../lib/db.js';
import * as game from './gameService.js';
import type {
  ConflictState,
  District,
  GameState,
  LeaderboardEntry,
  LeaderboardScope,
  LeaderboardSummary,
  MimzEvent,
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

  return {
    user,
    district,
    currentMission: await buildMission(userId, user, district, squadId),
    activeEvent,
    eventZones: events.map((event) => game.buildEventZone(event, district)),
    squadSummary,
    streakState: {
      liveStreak: user.streak,
      dailyStreak: user.dailyStreak,
      bestStreak: user.bestStreak,
      lastActivityDate: user.lastActivityDate,
    },
    structureEffects,
    structureProgress: buildStructureProgress(user, district),
    notifications: notifications.slice(0, 10) as any,
    leaderboardSnippets,
    activeConflicts: conflicts.map((conflict) => toConflictState(conflict, district.name)),
  };
}
