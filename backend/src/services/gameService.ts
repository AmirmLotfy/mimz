import { randomUUID } from 'crypto';
import * as db from '../lib/db.js';
import type { User, District, Resources } from '../models/types.js';
import { STRUCTURE_CATALOG, type StructureCatalogEntry } from '../models/types.js';
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
    handle: `@mimz_${userId.substring(0, 6)}`,
    email: email,
    xp: 0,
    streak: 0,
    bestStreak: 0,
    sectors: 1,
    districtName: 'My District',
    interests: [],
    difficultyPreference: 'dynamic',
    squadPreference: 'social',
    visibility: 'coarse',
    createdAt: now,
  };

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
    area: '1.0 sq km',
    cells: [],
    structures: [],
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
  },
): Promise<User | null> {
  // Whitelist allowed fields
  const safe: Partial<User> = {};
  if (updates.displayName !== undefined) safe.displayName = updates.displayName;
  if (updates.handle !== undefined) safe.handle = updates.handle;

  if (updates.preferredName !== undefined) safe.preferredName = updates.preferredName;
  if (updates.ageBand !== undefined) safe.ageBand = updates.ageBand;
  if (updates.studyWorkStatus !== undefined) safe.studyWorkStatus = updates.studyWorkStatus;
  if (updates.majorOrProfession !== undefined) safe.majorOrProfession = updates.majorOrProfession;
  if (updates.interests !== undefined) safe.interests = updates.interests;

  if (updates.difficultyPreference !== undefined) safe.difficultyPreference = updates.difficultyPreference;
  if (updates.squadPreference !== undefined) safe.squadPreference = updates.squadPreference;
  if (updates.voicePreference !== undefined) safe.voicePreference = updates.voicePreference;

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

// ═══════════════════════════════════════════════════════
// REWARD SERVICE
// ═══════════════════════════════════════════════════════

export async function grantReward(
  userId: string,
  type: 'xp' | 'territory' | 'materials' | 'structure' | 'combo',
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
