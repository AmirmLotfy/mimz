import { randomUUID } from 'crypto';
import * as db from '../lib/db.js';
import type { User, District, Resources, TopicAffinity, MimzEvent } from '../models/types.js';
import { STRUCTURE_CATALOG, type StructureCatalogEntry, ACHIEVEMENT_CATALOG } from '../models/types.js';
import { config } from '../config/index.js';

// ═══════════════════════════════════════════════════════
// AUTH SERVICE
// ═══════════════════════════════════════════════════════

export async function bootstrapUser(userId: string, email?: string): Promise<User> {
  // Check if user already exists (fast path)
  const existing = await db.getUser(userId);
  if (existing) return existing;

  // Race protection: If two concurrent bootstrap calls arrive for the same
  // user, the second create will fail. We catch that and return the existing user.
  const now = new Date().toISOString();
  const newUser: User = {
    id: userId,
    displayName: 'Explorer',
    displayNameLower: 'explorer',
    handle: `@mimz_${userId.substring(0, 6)}`,
    email: email,
    xp: 0,
    influence: 0,
    streak: 0,
    bestStreak: 0,
    dailyStreak: 0,
    activityHistory: [],
    sectors: 1,
    districtName: 'My District',
    interests: [],
    difficultyPreference: 'dynamic',
    squadPreference: 'social',
    topicStats: {},
    visibility: 'coarse',
    onboardingStage: 'profile',
    onboardingCompleted: false,
    meetMimzIntroSeen: false,
    createdAt: now,
  } as User;

  try {
    await db.createUser(newUser);
  } catch (err: any) {
    // If user was created between our check and create, return it
    const raceUser = await db.getUser(userId);
    if (raceUser) return raceUser;
    throw err; // Re-throw if it's a genuinely unexpected error
  }

  // Create starter district
  const district: District = {
    id: `district_${userId}`,
    ownerId: userId,
    name: 'My District',
    sectors: 1,
    influence: 0,
    influenceThreshold: 500,
    area: '1.0 sq km',
    cells: buildTerritoryCells(1),
    structures: [],
    regionAnchor: {
      regionId: 'global_central',
      label: 'Global District Grid',
      privacy: 'coarse',
    },
    topicAffinities: [],
    decayState: 'stable',
    resources: { stone: 50, glass: 20, wood: 40 },
    visibility: 'coarse',
    prestigeLevel: 1,
    createdAt: now,
  };

  try {
    await db.createDistrict(district);
    await db.updateUser(userId, { districtId: district.id });
  } catch (err: any) {
    // District may already exist from a race — attempt to read it
    const existingDistrict = await db.getDistrict(userId);
    if (existingDistrict) {
      return { ...newUser, districtId: existingDistrict.id };
    }
    throw err;
  }

  return { ...newUser, districtId: district.id };
}

export async function getUser(userId: string): Promise<User | null> {
  return db.getUser(userId);
}

export async function updateProfile(
  userId: string,
  updates: Partial<User> & {
    profileImageUrl?: string | null;
    storagePath?: string | null;
    preferredName?: string | null;
    majorOrProfession?: string | null;
    voicePreference?: string | null;
    emblemId?: string | null;
  },
): Promise<User | null> {
  const incomingDifficulty = updates.difficultyPreference as string | undefined;
  const normalizedDifficulty =
    incomingDifficulty === 'medium'
      ? 'dynamic'
      : incomingDifficulty === 'casual'
        ? 'easy'
        : incomingDifficulty === 'challenger'
          ? 'hard'
        : incomingDifficulty;

  // Whitelist allowed fields
  const safe: Partial<User> = {};
  if (updates.displayName !== undefined) {
    safe.displayName = updates.displayName;
    (safe as any).displayNameLower = updates.displayName.toLowerCase();
  }
  if (updates.handle !== undefined) safe.handle = updates.handle;

  if (updates.preferredName !== undefined) safe.preferredName = updates.preferredName;
  if (updates.ageBand !== undefined) safe.ageBand = updates.ageBand;
  if (updates.studyWorkStatus !== undefined) safe.studyWorkStatus = updates.studyWorkStatus;
  if (updates.majorOrProfession !== undefined) safe.majorOrProfession = updates.majorOrProfession;
  if (updates.interests !== undefined) safe.interests = updates.interests;

  if (normalizedDifficulty !== undefined) {
    safe.difficultyPreference = normalizedDifficulty as User['difficultyPreference'];
  }
  if (updates.squadPreference !== undefined) safe.squadPreference = updates.squadPreference;
  if (updates.voicePreference !== undefined) safe.voicePreference = updates.voicePreference;
  if (updates.onboardingStage !== undefined) safe.onboardingStage = updates.onboardingStage;
  if (updates.onboardingCompleted !== undefined) {
    safe.onboardingCompleted = updates.onboardingCompleted;
    if (updates.onboardingCompleted) {
      safe.onboardingStage = 'completed';
    }
  }
  if (updates.meetMimzIntroSeen !== undefined) safe.meetMimzIntroSeen = updates.meetMimzIntroSeen;

  if (updates.emblemId !== undefined) safe.emblemId = updates.emblemId;

  if (updates.profileImageUrl !== undefined) safe.profileImageUrl = updates.profileImageUrl;
  if (updates.storagePath !== undefined) safe.storagePath = updates.storagePath;

  if (updates.visibility !== undefined) safe.visibility = updates.visibility;
  if (updates.districtName !== undefined) {
    safe.districtName = updates.districtName;
    // Also update the district name
    const district = await db.getDistrictByOwner(userId);
    if (district) await db.updateDistrict(district.id, { name: updates.districtName });
  }

  await db.updateUser(userId, safe);
  return db.getUser(userId);
}

// ═══════════════════════════════════════════════════════
// DISTRICT SERVICE
// ═══════════════════════════════════════════════════════

export async function getDistrict(userId: string): Promise<District | null> {
  return db.getDistrictByOwner(userId);
}

export async function expandTerritory(userId: string, sectors: number): Promise<{ success: boolean; sectors: number; area: string }> {
  // Validate bounds
  if (sectors > config.maxSectorsPerRound) {
    throw new Error(`Cannot add more than ${config.maxSectorsPerRound} sectors per round`);
  }

  const district = await db.getDistrictByOwner(userId);
  if (!district) throw new Error('No district found');

  const newTotal = district.sectors + sectors;
  const newArea = `${(newTotal * 1.1).toFixed(1)} sq km`;

  await db.expandTerritory(district.id, sectors);
  await db.incrementUserSectors(userId, sectors);
  await db.updateDailyStreak(userId);

  return { success: true, sectors: newTotal, area: newArea };
}

export async function unlockStructure(userId: string, structureId: string): Promise<{ success: boolean; structure: any }> {
  const catalog = STRUCTURE_CATALOG.find(s => s.id === structureId);
  if (!catalog) throw new Error(`Unknown structure: ${structureId}`);

  const user = await db.getUser(userId);
  const district = await db.getDistrictByOwner(userId);
  if (!user || !district) throw new Error('User or district not found');

  // Check requirements
  if (user.sectors < catalog.requirements.minSectors) {
    throw new Error(`Need ${catalog.requirements.minSectors} sectors (have ${user.sectors})`);
  }
  if (user.xp < catalog.requirements.minXp) {
    throw new Error(`Need ${catalog.requirements.minXp} XP (have ${user.xp})`);
  }

  // Check if already unlocked
  if (district.structures.some(s => s.id === structureId)) {
    throw new Error(`Structure ${structureId} already unlocked`);
  }

  // Check resources
  if (!canAfford(district.resources, catalog.cost)) {
    throw new Error('Insufficient resources');
  }

  // Deduct resources
  await db.addResources(district.id, {
    stone: -catalog.cost.stone,
    glass: -catalog.cost.glass,
    wood: -catalog.cost.wood,
  });

  // Add structure
  await db.addStructureToDistrict(district.id, {
    id: catalog.id,
    name: catalog.name,
    tier: catalog.tier,
    description: catalog.description,
    prestigeValue: catalog.prestigeValue,
  });

  return {
    success: true,
    structure: { ...catalog, unlockedAt: new Date().toISOString() },
  };
}

export function canAfford(resources: Resources, cost: Resources): boolean {
  return resources.stone >= cost.stone &&
         resources.glass >= cost.glass &&
         resources.wood >= cost.wood;
}

// ═══════════════════════════════════════════════════════
// INFLUENCE ECONOMY
// ═══════════════════════════════════════════════════════

export function calculateInfluenceGrant(
  source: 'grade_answer' | 'vision_quest' | 'combo' | 'event' | 'squad',
  difficulty: string,
  streak: number,
): number {
  const baseMap: Record<string, Record<string, number>> = {
    grade_answer: { easy: 50, medium: 75, hard: 120 },
    vision_quest: { easy: 120, medium: 150, hard: 180 },
    combo: { easy: 30, medium: 40, hard: 60 },
    event: { easy: 60, medium: 80, hard: 100 },
    squad: { easy: 40, medium: 50, hard: 70 },
  };
  const base = baseMap[source]?.[difficulty] ?? 75;
  const streakMultiplier = 1 + Math.min(streak, config.maxStreakBonus) * 0.05;
  return Math.floor(base * streakMultiplier);
}

export async function checkGrowthThreshold(userId: string): Promise<{
  expanded: boolean;
  sectorsGained: number;
  newTotal: number;
  area: string;
  influenceRemaining: number;
}> {
  const district = await db.getDistrictByOwner(userId);
  if (!district) return { expanded: false, sectorsGained: 0, newTotal: 0, area: '0', influenceRemaining: 0 };

  const currentInfluence = (district as any).influence ?? 0;
  const threshold = (district as any).influenceThreshold ?? 500;

  if (currentInfluence < threshold) {
    return {
      expanded: false,
      sectorsGained: 0,
      newTotal: district.sectors,
      area: district.area,
      influenceRemaining: threshold - currentInfluence,
    };
  }

  const sectorsToGain = Math.min(Math.floor(currentInfluence / threshold), config.maxSectorsPerRound);
  const influenceSpent = sectorsToGain * threshold;
  const remainingInfluence = currentInfluence - influenceSpent;

  await db.expandTerritory(district.id, sectorsToGain);
  await db.incrementUserSectors(userId, sectorsToGain);

  const newThreshold = Math.floor(threshold * 1.08);
  const newTotal = district.sectors + sectorsToGain;
  const newArea = `${(newTotal * 1.1).toFixed(1)} sq km`;

  // Rebuild cell model with new sectors
  const newCells = buildTerritoryCells(newTotal);
  await db.updateDistrict(district.id, {
    influence: remainingInfluence,
    influenceThreshold: newThreshold,
    area: newArea,
    cells: newCells,
  } as any);

  return {
    expanded: true,
    sectorsGained: sectorsToGain,
    newTotal,
    area: newArea,
    influenceRemaining: remainingInfluence,
  };
}

// ═══════════════════════════════════════════════════════
// TERRITORY LAYERS + DECAY
// ═══════════════════════════════════════════════════════

export type CellLayer = 'core' | 'inner' | 'frontier';

export interface TerritoryCell {
  id: string;
  q: number;
  r: number;
  layer: CellLayer;
  stability: number;
  contested: boolean;
  protectedUntil?: string;
  addedAt?: string;
}

const HEX_DIRS = [
  [1, 0], [1, -1], [0, -1],
  [-1, 0], [-1, 1], [0, 1],
];

function generateSpiralCells(count: number): Array<{ q: number; r: number }> {
  const cells: Array<{ q: number; r: number }> = [];
  if (count <= 0) return cells;
  cells.push({ q: 0, r: 0 });
  let placed = 1;
  let ring = 1;
  while (placed < count) {
    let q = 0, r = -ring;
    for (let d = 0; d < 6 && placed < count; d++) {
      for (let s = 0; s < ring && placed < count; s++) {
        cells.push({ q, r });
        placed++;
        q += HEX_DIRS[d][0];
        r += HEX_DIRS[d][1];
      }
    }
    ring++;
  }
  return cells;
}

function assignLayers(cells: Array<{ q: number; r: number }>): TerritoryCell[] {
  const total = cells.length;
  const coreCount = Math.max(1, Math.floor(total * 0.2));
  const innerCount = Math.floor(total * 0.4);

  return cells.map((c, i) => {
    let layer: CellLayer;
    let stability: number;
    if (i < coreCount) {
      layer = 'core';
      stability = 100;
    } else if (i < coreCount + innerCount) {
      layer = 'inner';
      stability = 75;
    } else {
      layer = 'frontier';
      stability = 50;
    }
    return {
      id: `cell_${c.q}_${c.r}`,
      q: c.q,
      r: c.r,
      layer,
      stability,
      contested: false,
      addedAt: new Date().toISOString(),
    };
  });
}

export function buildTerritoryCells(sectors: number): TerritoryCell[] {
  const positions = generateSpiralCells(sectors);
  return assignLayers(positions);
}

export async function syncTerritoryCells(userId: string): Promise<TerritoryCell[]> {
  const district = await db.getDistrictByOwner(userId);
  if (!district) return [];

  const existingCells = (district as any).cells || [];
  if (Array.isArray(existingCells) && existingCells.length > 0 && typeof existingCells[0] === 'object') {
    if (existingCells.length === district.sectors) return existingCells;
  }

  const cells = buildTerritoryCells(district.sectors);
  await db.updateDistrict(district.id, { cells } as any);
  return cells;
}

export function slugifyTopic(topic: string): string {
  return topic
    .toLowerCase()
    .replace(/&/g, 'and')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 48) || 'general';
}

export function buildVisionQuestBlueprint(theme: string): {
  targetPrompt: string;
  targetKeywords: string[];
  rewardStructureId?: string;
} {
  const normalized = theme.trim().toLowerCase();
  switch (normalized) {
    case 'science':
      return {
        targetPrompt: 'Show me something related to science: a notebook, diagram, lab item, or science book.',
        targetKeywords: ['science', 'notebook', 'diagram', 'book', 'lab', 'experiment'],
        rewardStructureId: 'observatory',
      };
    case 'engineering':
      return {
        targetPrompt: 'Show me something engineered: a tool, circuit, device, sketch, or technical note.',
        targetKeywords: ['tool', 'device', 'circuit', 'engineer', 'sketch', 'technical'],
        rewardStructureId: 'maker_hub',
      };
    case 'nature':
      return {
        targetPrompt: 'Show me something from nature: a plant, leaf, flower, or natural texture.',
        targetKeywords: ['plant', 'leaf', 'flower', 'nature', 'tree', 'grass'],
        rewardStructureId: 'park_pavilion',
      };
    case 'design':
      return {
        targetPrompt: 'Show me something designed: a poster, book cover, object, or visual composition.',
        targetKeywords: ['design', 'poster', 'cover', 'object', 'layout', 'visual'],
        rewardStructureId: 'library',
      };
    default:
      return {
        targetPrompt: 'Show me something that matches the theme around you.',
        targetKeywords: ['object', 'item', 'thing', normalized],
      };
  }
}

export function validateVisionQuestObservation(
  targetKeywords: string[],
  objectIdentified: string,
  confidence: number,
): boolean {
  if (!objectIdentified.trim()) return false;
  if (confidence < 0.5) return false;

  const normalizedObject = objectIdentified.trim().toLowerCase();
  return targetKeywords.some((keyword) => {
    const normalizedKeyword = keyword.trim().toLowerCase();
    return normalizedKeyword.length > 0 &&
        (normalizedObject.includes(normalizedKeyword) ||
            normalizedKeyword.includes(normalizedObject));
  });
}

export function deriveDecayState(district: District | null): 'stable' | 'cooling' | 'vulnerable' | 'reclaimable' {
  if (!district) return 'stable';
  const cells = ((district as any).cells as TerritoryCell[] | undefined) ?? [];
  const frontier = cells.filter(c => c.layer === 'frontier');
  if (frontier.length === 0) return 'stable';

  const reclaimable = frontier.filter(c => c.stability <= 0).length;
  if (reclaimable > 0) return 'reclaimable';

  const vulnerable = frontier.filter(c => c.stability < 40).length;
  if (vulnerable >= Math.ceil(frontier.length / 3)) return 'vulnerable';

  const cooling = frontier.filter(c => c.stability < 75).length;
  if (cooling > 0) return 'cooling';

  return 'stable';
}

function toTopicAffinity(topic: string, answered: number, correct: number, streak: number, lastPlayedAt?: string): TopicAffinity {
  const winRate = answered > 0 ? correct / answered : 0;
  return {
    topic,
    answered,
    correct,
    streak,
    masteryScore: Math.round((correct * 8) + (answered * 2) + (streak * 5)),
    winRate,
    ...(lastPlayedAt ? { lastPlayedAt } : {}),
  };
}

export async function recordTopicOutcome(userId: string, topic: string, isCorrect: boolean): Promise<TopicAffinity | null> {
  const user = await db.getUser(userId);
  if (!user) return null;

  const key = slugifyTopic(topic);
  const current = ((user as any).topicStats?.[key] as TopicAffinity | undefined);
  const answered = (current?.answered ?? 0) + 1;
  const correct = (current?.correct ?? 0) + (isCorrect ? 1 : 0);
  const streak = isCorrect ? (current?.streak ?? 0) + 1 : 0;
  const updated = toTopicAffinity(topic, answered, correct, streak, new Date().toISOString());

  await db.updateUser(userId, {
    topicStats: {
      ...((user as any).topicStats ?? {}),
      [key]: updated,
    } as any,
  } as any);

  await syncDistrictDerivedState(userId);
  return updated;
}

export async function syncDistrictDerivedState(userId: string): Promise<District | null> {
  const [user, district] = await Promise.all([
    db.getUser(userId),
    db.getDistrictByOwner(userId),
  ]);
  if (!user || !district) return null;

  const topicAffinities = Object.values(((user as any).topicStats ?? {}) as Record<string, TopicAffinity>)
    .sort((a, b) => b.masteryScore - a.masteryScore)
    .slice(0, 6);
  const decayState = deriveDecayState(district);
  const regionAnchor = (district as any).regionAnchor ?? {
    regionId: 'global_central',
    label: 'Global District Grid',
    privacy: 'coarse',
  };

  await db.updateDistrict(district.id, {
    regionAnchor,
    topicAffinities,
    decayState,
  } as any);

  return {
    ...(district as any),
    regionAnchor,
    topicAffinities,
    decayState,
  } as District;
}

export async function reclaimFrontier(userId: string): Promise<{
  stabilizedCells: number;
  recoveredCells: number;
  decayState: 'stable' | 'cooling' | 'vulnerable' | 'reclaimable';
  district: District | null;
}> {
  const district = await db.getDistrictByOwner(userId);
  if (!district) {
    return { stabilizedCells: 0, recoveredCells: 0, decayState: 'stable', district: null };
  }

  const cells: TerritoryCell[] = (((district as any).cells ?? []) as TerritoryCell[]).map(cell => ({ ...cell }));
  let stabilizedCells = 0;
  let recoveredCells = 0;

  const frontierCells = cells
    .filter((c) => c.layer === 'frontier')
    .sort((a, b) => a.stability - b.stability);

  for (const cell of frontierCells) {
    if (stabilizedCells >= 3) break;
    if (cell.stability <= 0) {
      cell.stability = 35;
      recoveredCells++;
      stabilizedCells++;
      continue;
    }
    if (cell.stability < 90) {
      cell.stability = Math.min(100, Math.max(0, cell.stability + 20));
      stabilizedCells++;
    }
  }

  const nextDecayState = deriveDecayState({ ...(district as any), cells } as District);
  await db.updateDistrict(district.id, {
    cells,
    decayState: nextDecayState,
  } as any);

  return {
    stabilizedCells,
    recoveredCells,
    decayState: nextDecayState,
    district: {
      ...(district as any),
      cells,
      decayState: nextDecayState,
    } as District,
  };
}

export function buildEventZone(event: MimzEvent, district?: District | null): {
  id: string;
  eventId: string;
  title: string;
  status: 'live' | 'upcoming' | 'completed';
  regionId: string;
  regionLabel: string;
  districtEffect: string;
  rewardMultiplier: number;
} {
  const region = ((district as any)?.regionAnchor as { regionId?: string; label?: string } | undefined);
  const status = event.status === 'live' ? 'live' : event.status === 'completed' ? 'completed' : 'upcoming';
  return {
    id: `zone_${event.id}`,
    eventId: event.id,
    title: event.title,
    status,
    regionId: region?.regionId ?? 'global_central',
    regionLabel: region?.label ?? 'Global District Grid',
    districtEffect: status === 'live'
      ? 'Active event zone: correct answers yield bonus district influence.'
      : 'Event zone will light up when the event goes live.',
    rewardMultiplier: status === 'live' ? 1.2 : 1.0,
  };
}

export async function promoteStableFrontier(userId: string): Promise<void> {
  const district = await db.getDistrictByOwner(userId);
  if (!district) return;

  const cells: TerritoryCell[] = (district as any).cells || [];
  if (!Array.isArray(cells) || cells.length === 0) return;

  let changed = false;
  for (const cell of cells) {
    if (cell.layer === 'frontier' && cell.stability >= 90) {
      cell.layer = 'inner';
      changed = true;
    } else if (cell.layer === 'inner' && cell.stability >= 100) {
      const total = cells.length;
      const coreCount = cells.filter(c => c.layer === 'core').length;
      if (coreCount < Math.max(1, Math.floor(total * 0.25))) {
        cell.layer = 'core';
        changed = true;
      }
    }
    if (cell.layer === 'frontier' && cell.stability < 90) {
      cell.stability = Math.min(100, cell.stability + 2);
      changed = true;
    }
  }

  if (changed) {
    await db.updateDistrict(district.id, { cells } as any);
  }
}

export async function applyInactivityDecay(userId: string, daysSinceActivity: number): Promise<{
  cellsLost: number;
  frontierWeakened: number;
}> {
  const district = await db.getDistrictByOwner(userId);
  if (!district) return { cellsLost: 0, frontierWeakened: 0 };

  const cells: TerritoryCell[] = (district as any).cells || [];
  if (!Array.isArray(cells) || cells.length <= 1) return { cellsLost: 0, frontierWeakened: 0 };

  let frontierWeakened = 0;
  let cellsLost = 0;

  if (daysSinceActivity <= 3) {
    return { cellsLost: 0, frontierWeakened: 0 };
  }

  for (const cell of cells) {
    if (cell.layer === 'core') continue;

    if (daysSinceActivity >= 4 && daysSinceActivity <= 7) {
      if (cell.layer === 'frontier') {
        cell.stability = Math.max(0, cell.stability - 10);
        frontierWeakened++;
      }
    } else if (daysSinceActivity > 7) {
      if (cell.layer === 'frontier') {
        cell.stability = Math.max(0, cell.stability - 20);
        frontierWeakened++;
      } else if (cell.layer === 'inner') {
        cell.stability = Math.max(0, cell.stability - 5);
      }
    }
  }

  const remaining = cells.filter(c => c.stability > 0 || c.layer === 'core');
  cellsLost = cells.length - remaining.length;

  if (cellsLost > 0 || frontierWeakened > 0) {
    const newSectors = remaining.length;
    const newArea = `${(newSectors * 1.1).toFixed(1)} sq km`;
    await db.updateDistrict(district.id, {
      cells: remaining,
      sectors: newSectors,
      area: newArea,
    } as any);
    await db.updateUser(userId, { sectors: newSectors } as any);
  } else {
    await db.updateDistrict(district.id, { cells } as any);
  }

  return { cellsLost, frontierWeakened };
}

// ═══════════════════════════════════════════════════════
// STRUCTURE EFFECTS
// ═══════════════════════════════════════════════════════

export interface StructureEffects {
  xpMultiplier: number;
  materialMultiplier: number;
  influenceMultiplier: number;
  decayReduction: number;
  streakProtection: number;
  squadMultiplier: number;
}

export async function getStructureEffects(userId: string): Promise<StructureEffects> {
  const district = await db.getDistrictByOwner(userId);
  const effects: StructureEffects = {
    xpMultiplier: 1.0,
    materialMultiplier: 1.0,
    influenceMultiplier: 1.0,
    decayReduction: 0,
    streakProtection: 0,
    squadMultiplier: 1.0,
  };
  if (!district) return effects;

  for (const s of district.structures) {
    switch (s.id) {
      case 'library':
        effects.xpMultiplier += 0.1;
        break;
      case 'observatory':
        effects.influenceMultiplier += 0.15;
        break;
      case 'archive':
        effects.decayReduction += 0.3;
        break;
      case 'park_pavilion':
        effects.streakProtection += 1;
        break;
      case 'maker_hub':
        effects.materialMultiplier += 0.15;
        break;
    }
  }
  return effects;
}

export function getPrestigeLevel(xp: number): number {
  if (xp >= 50000) return 10;
  if (xp >= 30000) return 8;
  if (xp >= 15000) return 6;
  if (xp >= 8000) return 4;
  if (xp >= 3000) return 2;
  return 1;
}

export function calculateResourceRate(structures: Array<{ tier: string }>): Resources {
  const rates = { stone: 0, glass: 0, wood: 0 };
  for (const s of structures) {
    const m = s.tier === 'master' ? 3 : s.tier === 'rare' ? 2 : 1;
    rates.stone += 10 * m;
    rates.glass += 5 * m;
    rates.wood += 8 * m;
  }
  return rates;
}

export async function updatePrestigeIfNeeded(userId: string): Promise<number> {
  const user = await db.getUser(userId);
  if (!user) return 1;
  const newPrestige = getPrestigeLevel(user.xp);
  const district = await db.getDistrictByOwner(userId);
  if (district && district.prestigeLevel !== newPrestige) {
    await db.updateDistrict(district.id, { prestigeLevel: newPrestige } as any);
  }
  return newPrestige;
}

// ═══════════════════════════════════════════════════════
// REWARD SERVICE
// ═══════════════════════════════════════════════════════

export async function grantReward(
  userId: string,
  type: 'xp' | 'territory' | 'materials' | 'structure' | 'combo' | 'influence',
  amount: number,
  source: string,
  sessionId?: string,
  detail?: Record<string, unknown>,
): Promise<void> {
  // Anti-abuse: check reward cap
  const oneHourAgo = new Date(Date.now() - 3600000);
  const recent = await db.getRewardsSince(userId, oneHourAgo);
  const totalRecent = recent.reduce((sum, r) => sum + r.amount, 0);

  if (totalRecent + amount > config.maxRewardPerHour) {
    throw new Error(`Reward cap exceeded (${totalRecent + amount} > ${config.maxRewardPerHour})`);
  }

  await db.logReward({
    id: `rw_${randomUUID()}`,
    userId,
    type,
    amount,
    detail: detail || {},
    source,
    sessionId,
    grantedAt: new Date().toISOString(),
  });
}

// ═══════════════════════════════════════════════════════
// SCORING SERVICE
// ═══════════════════════════════════════════════════════

export function calculateScore(isCorrect: boolean, streak: number, difficulty: string): {
  points: number;
  streakBonus: number;
  newStreak: number;
} {
  if (!isCorrect) return { points: 0, streakBonus: 0, newStreak: 0 };

  const base = difficulty === 'hard' ? 150 : difficulty === 'medium' ? 100 : 75;
  const cappedStreak = Math.min(streak, config.maxStreakBonus);
  const streakBonus = Math.floor(base * cappedStreak * 0.1);

  return {
    points: base + streakBonus,
    streakBonus,
    newStreak: streak + 1,
  };
}

export function calculateComboBonus(streak: number, multiplier: number): {
  bonusXp: number;
  bonusMaterials: Resources;
} {
  const capped = Math.min(streak, config.maxStreakBonus);
  const bonusXp = Math.floor(capped * multiplier * 50);
  return {
    bonusXp,
    bonusMaterials: {
      stone: Math.floor(capped * 5),
      glass: Math.floor(capped * 3),
      wood: Math.floor(capped * 4),
    },
  };
}

// ═══════════════════════════════════════════════════════
// ACHIEVEMENT / BADGE SERVICE
// ═══════════════════════════════════════════════════════

export async function checkAndGrantAchievements(userId: string): Promise<string[]> {
  const user = await db.getUser(userId);
  if (!user) return [];

  const existing = await db.getUserBadges(userId);
  const existingIds = new Set(existing.map(b => b.achievementId));
  const newBadges: string[] = [];

  const stats: Record<string, number> = {
    xp: user.xp,
    bestStreak: user.bestStreak,
    sectors: user.sectors,
    dailyStreak: (user as any).dailyStreak ?? 0,
    roundsCompleted: 0,
    visionQuestsCompleted: 0,
    squadJoined: 0,
    eventsWon: 0,
  };

  for (const achievement of ACHIEVEMENT_CATALOG) {
    if (existingIds.has(achievement.id)) continue;
    const val = stats[achievement.field] ?? 0;
    if (val >= achievement.requirement) {
      await db.grantBadge(userId, achievement.id);
      newBadges.push(achievement.id);

      db.createNotification({
        id: `notif_${randomUUID()}`,
        userId,
        title: `Achievement unlocked: ${achievement.name}`,
        body: achievement.description,
        type: 'achievement',
        createdAt: new Date().toISOString(),
        read: false,
        data: { achievementId: achievement.id, rarity: achievement.rarity },
      }).catch(() => {});
    }
  }

  return newBadges;
}

// ═══════════════════════════════════════════════════════
// TERRITORY CONFLICT
// ═══════════════════════════════════════════════════════

export async function createEventConflict(
  eventId: string,
  defenderId: string,
  cellsAtStake: number,
): Promise<string> {
  const id = `conflict_${randomUUID()}`;
  const conflict = {
    id,
    type: 'event_zone',
    status: 'active',
    defenderId,
    eventId,
    cellsAtStake,
    cellsWon: 0,
    startedAt: new Date().toISOString(),
  };
  await db.createConflict(conflict);
  return id;
}

export async function createRivalryConflict(
  attackerId: string,
  defenderId: string,
  cellsAtStake: number,
): Promise<string> {
  const id = `conflict_${randomUUID()}`;
  const conflict = {
    id,
    type: 'rivalry',
    status: 'active',
    attackerId,
    defenderId,
    cellsAtStake,
    cellsWon: 0,
    startedAt: new Date().toISOString(),
  };
  await db.createConflict(conflict);
  return id;
}

export async function resolveConflict(
  conflictId: string,
  winnerId: string,
  cellsWon: number,
): Promise<void> {
  const conflict = await db.getConflict(conflictId);
  if (!conflict) {
    throw new Error('Conflict not found');
  }

  const attackerId = conflict.attackerId as string | undefined;
  const defenderId = conflict.defenderId as string | undefined;
  const loserId = winnerId == attackerId ? defenderId : attackerId ?? defenderId;
  const transferCount = Math.max(0, cellsWon);

  await db.updateConflict(conflictId, {
    status: 'resolved',
    cellsWon: transferCount,
    resolvedAt: new Date().toISOString(),
  });

  if (transferCount <= 0) {
    return;
  }

  if (loserId && loserId != winnerId) {
    const loserDistrict = await db.getDistrictByOwner(loserId);
    if (loserDistrict) {
      const loserCells: TerritoryCell[] =
          (((loserDistrict as any).cells as TerritoryCell[] | undefined) ?? []);
      const removableFrontier = loserCells
        .filter((cell) => cell.layer === 'frontier')
        .sort((a, b) => a.stability - b.stability);

      if (removableFrontier.length > 0) {
        const removableIds = new Set(
          removableFrontier
            .slice(0, transferCount)
            .map((cell) => cell.id),
        );
        const remainingCells =
          loserCells.filter((cell) => !removableIds.has(cell.id));
        await db.updateDistrict(loserDistrict.id, {
          cells: remainingCells,
          sectors: remainingCells.length,
          area: `${(remainingCells.length * 1.1).toFixed(1)} sq km`,
        } as any);
        await db.updateUser(loserId, { sectors: remainingCells.length } as any);
      }
    }
  }

  const winnerDistrict = await db.getDistrictByOwner(winnerId);
  if (winnerDistrict) {
    await db.expandTerritory(winnerDistrict.id, transferCount);
    await db.incrementUserSectors(winnerId, transferCount);
    await syncTerritoryCells(winnerId);
  }

  if (loserId && loserId != winnerId) {
    await syncTerritoryCells(loserId).catch(() => {});
  }
}

export async function processInactivityTakeover(
  inactiveUserId: string,
  claimantUserId: string,
): Promise<{ cellsClaimed: number }> {
  const inactiveDistrict = await db.getDistrictByOwner(inactiveUserId);
  if (!inactiveDistrict) return { cellsClaimed: 0 };

  const cells: TerritoryCell[] = (inactiveDistrict as any).cells || [];
  const neutralized = cells.filter(c => c.layer === 'frontier' && c.stability <= 0);

  if (neutralized.length === 0) return { cellsClaimed: 0 };

  const cellsToClaim = Math.min(neutralized.length, 3);
  const neutralizedIds = new Set(neutralized.slice(0, cellsToClaim).map((cell) => cell.id));
  const remaining = cells.filter(c => !neutralizedIds.has(c.id));
  await db.updateDistrict(inactiveDistrict.id, {
    cells: remaining,
    sectors: remaining.length,
    area: `${(remaining.length * 1.1).toFixed(1)} sq km`,
  } as any);
  await db.updateUser(inactiveUserId, { sectors: remaining.length } as any);

  const claimantDistrict = await db.getDistrictByOwner(claimantUserId);
  if (claimantDistrict) {
    await db.expandTerritory(claimantDistrict.id, cellsToClaim);
    await db.incrementUserSectors(claimantUserId, cellsToClaim);
  }

  await createRivalryConflict(claimantUserId, inactiveUserId, cellsToClaim);

  return { cellsClaimed: cellsToClaim };
}

// ═══════════════════════════════════════════════════════
// AUDIT SERVICE
// ═══════════════════════════════════════════════════════

export async function audit(
  userId: string,
  action: string,
  detail: Record<string, unknown> = {},
  extra: { toolName?: string; sessionId?: string; correlationId?: string; ip?: string } = {},
): Promise<void> {
  await db.logAudit({
    id: `audit_${randomUUID()}`,
    userId,
    action,
    detail,
    timestamp: new Date().toISOString(),
    ...extra,
  });
}
