import { z } from 'zod';

// ═══════════════════════════════════════════════════════
// CORE DOMAIN MODELS — Zod schemas for all backend types
// ═══════════════════════════════════════════════════════

// ─── Shared ──────────────────────────────────────────────

export const TimestampSchema = z.string().datetime().or(z.date().transform(d => d.toISOString()));

export const ResourcesSchema = z.object({
  stone: z.number().int().min(0).default(0),
  glass: z.number().int().min(0).default(0),
  wood: z.number().int().min(0).default(0),
});
export type Resources = z.infer<typeof ResourcesSchema>;

export const TierSchema = z.enum(['common', 'rare', 'master']);
export type Tier = z.infer<typeof TierSchema>;

export const VisibilitySchema = z.enum(['public', 'private', 'coarse']);
export type Visibility = z.infer<typeof VisibilitySchema>;

// ─── User ────────────────────────────────────────────────

export const UserSchema = z.object({
  id: z.string(),
  displayName: z.string().min(1).max(30).default('Explorer'),
  handle: z.string().min(1).max(30).default('@explorer'),
  email: z.string().email().optional(),
  xp: z.number().int().min(0).default(0),
  streak: z.number().int().min(0).default(0),
  bestStreak: z.number().int().min(0).default(0),
  sectors: z.number().int().min(0).default(1),
  districtId: z.string().optional(),
  districtName: z.string().default('My District'),
  interests: z.array(z.string()).default([]),
  visibility: VisibilitySchema.default('coarse'),
  createdAt: TimestampSchema,
  updatedAt: TimestampSchema.optional(),
});
export type User = z.infer<typeof UserSchema>;

export const UserProfileSchema = UserSchema.pick({
  displayName: true,
  handle: true,
  interests: true,
  visibility: true,
  districtName: true,
}).partial();
export type UserProfile = z.infer<typeof UserProfileSchema>;

// ─── District ────────────────────────────────────────────

export const StructureSchema = z.object({
  id: z.string(),
  name: z.string(),
  tier: TierSchema,
  description: z.string().default(''),
  prestigeValue: z.number().int().default(1),
  unlockedAt: TimestampSchema.optional(),
});
export type Structure = z.infer<typeof StructureSchema>;

export const DistrictSchema = z.object({
  id: z.string(),
  ownerId: z.string(),
  name: z.string().min(1).max(50),
  sectors: z.number().int().min(0).default(1),
  area: z.string().default('1.0 sq km'),
  cells: z.array(z.string()).default([]),  // H3 cell IDs
  anchorCell: z.string().optional(),       // coarse public anchor
  structures: z.array(StructureSchema).default([]),
  resources: ResourcesSchema.default({ stone: 0, glass: 0, wood: 0 }),
  visibility: VisibilitySchema.default('coarse'),
  prestigeLevel: z.number().int().min(1).default(1),
  createdAt: TimestampSchema,
  updatedAt: TimestampSchema.optional(),
});
export type District = z.infer<typeof DistrictSchema>;

// ─── Inventory / Rewards ─────────────────────────────────

export const RewardGrantSchema = z.object({
  id: z.string(),
  userId: z.string(),
  type: z.enum(['xp', 'territory', 'materials', 'structure', 'combo']),
  amount: z.number().int().min(0).default(0),
  detail: z.record(z.unknown()).default({}),
  source: z.string(),          // tool name or event
  sessionId: z.string().optional(),
  grantedAt: TimestampSchema,
});
export type RewardGrant = z.infer<typeof RewardGrantSchema>;

// ─── Round / Quiz ────────────────────────────────────────

export const RoundSessionSchema = z.object({
  id: z.string(),
  userId: z.string(),
  topic: z.string().default('General'),
  difficulty: z.enum(['easy', 'medium', 'hard']).default('medium'),
  questionsAsked: z.number().int().default(0),
  correctAnswers: z.number().int().default(0),
  totalScore: z.number().int().default(0),
  maxStreak: z.number().int().default(0),
  status: z.enum(['active', 'completed', 'abandoned']).default('active'),
  startedAt: TimestampSchema,
  endedAt: TimestampSchema.optional(),
});
export type RoundSession = z.infer<typeof RoundSessionSchema>;

// ─── Vision Quest ────────────────────────────────────────

export const VisionQuestSchema = z.object({
  id: z.string(),
  userId: z.string(),
  theme: z.string().default('discovery'),
  objectIdentified: z.string().optional(),
  confidence: z.number().min(0).max(1).default(0),
  isValid: z.boolean().default(false),
  structureUnlocked: z.string().optional(),
  status: z.enum(['active', 'completed', 'failed']).default('active'),
  startedAt: TimestampSchema,
  completedAt: TimestampSchema.optional(),
});
export type VisionQuest = z.infer<typeof VisionQuestSchema>;

// ─── Squad ───────────────────────────────────────────────

export const SquadMemberSchema = z.object({
  userId: z.string(),
  displayName: z.string(),
  rank: z.number().int().default(0),
  xpContributed: z.number().int().default(0),
  joinedAt: TimestampSchema,
});
export type SquadMember = z.infer<typeof SquadMemberSchema>;

export const SquadMissionSchema = z.object({
  id: z.string(),
  title: z.string(),
  description: z.string().default(''),
  targetProgress: z.number().int().default(100),
  currentProgress: z.number().int().default(0),
  reward: ResourcesSchema.default({ stone: 0, glass: 0, wood: 0 }),
  status: z.enum(['active', 'completed']).default('active'),
  expiresAt: TimestampSchema.optional(),
});
export type SquadMission = z.infer<typeof SquadMissionSchema>;

export const SquadSchema = z.object({
  id: z.string(),
  name: z.string().min(1).max(30),
  joinCode: z.string().min(4).max(8),
  leaderId: z.string(),
  memberCount: z.number().int().default(1),
  totalXp: z.number().int().default(0),
  createdAt: TimestampSchema,
});
export type Squad = z.infer<typeof SquadSchema>;

// ─── Event ───────────────────────────────────────────────

export const EventSchema = z.object({
  id: z.string(),
  title: z.string(),
  description: z.string().default(''),
  status: z.enum(['live', 'upcoming', 'completed']),
  participantCount: z.number().int().default(0),
  maxParticipants: z.number().int().optional(),
  startsAt: TimestampSchema,
  endsAt: TimestampSchema.optional(),
  reward: ResourcesSchema.default({ stone: 0, glass: 0, wood: 0 }),
});
export type MimzEvent = z.infer<typeof EventSchema>;

export const EventParticipationSchema = z.object({
  userId: z.string(),
  eventId: z.string(),
  score: z.number().int().default(0),
  joinedAt: TimestampSchema,
});
export type EventParticipation = z.infer<typeof EventParticipationSchema>;

// ─── Leaderboard ─────────────────────────────────────────

export const LeaderboardEntrySchema = z.object({
  userId: z.string(),
  displayName: z.string(),
  score: z.number().int().default(0),
  rank: z.number().int().default(0),
  districtName: z.string().optional(),
});
export type LeaderboardEntry = z.infer<typeof LeaderboardEntrySchema>;

// ─── Audit Log ───────────────────────────────────────────

export const AuditLogSchema = z.object({
  id: z.string(),
  userId: z.string(),
  action: z.string(),
  toolName: z.string().optional(),
  sessionId: z.string().optional(),
  correlationId: z.string().optional(),
  detail: z.record(z.unknown()).default({}),
  ip: z.string().optional(),
  timestamp: TimestampSchema,
});
export type AuditLog = z.infer<typeof AuditLogSchema>;

// ─── Live Session ────────────────────────────────────────

export const LiveSessionTokenRequestSchema = z.object({
  sessionType: z.enum(['onboarding', 'quiz', 'vision_quest']).default('quiz'),
});
export type LiveSessionTokenRequest = z.infer<typeof LiveSessionTokenRequestSchema>;

export const LiveToolExecutionRequestSchema = z.object({
  toolName: z.string().min(1),
  args: z.record(z.unknown()).default({}),
  sessionId: z.string().min(1),
  correlationId: z.string().optional(),
});
export type LiveToolExecutionRequest = z.infer<typeof LiveToolExecutionRequestSchema>;

export const LiveToolExecutionResponseSchema = z.object({
  success: z.boolean(),
  data: z.record(z.unknown()).default({}),
  error: z.string().optional(),
  correlationId: z.string().optional(),
  executedAt: TimestampSchema,
});
export type LiveToolExecutionResponse = z.infer<typeof LiveToolExecutionResponseSchema>;

// ─── Notification ────────────────────────────────────────

export const NotificationSchema = z.object({
  id: z.string(),
  userId: z.string(),
  type: z.enum(['reward', 'squad', 'event', 'system']),
  title: z.string(),
  body: z.string(),
  read: z.boolean().default(false),
  createdAt: TimestampSchema,
});
export type Notification = z.infer<typeof NotificationSchema>;

// ─── Structure Catalog ───────────────────────────────────

export interface StructureCatalogEntry {
  id: string;
  name: string;
  description: string;
  tier: Tier;
  cost: Resources;
  prestigeValue: number;
  requirements: { minSectors: number; minXp: number };
}

export const STRUCTURE_CATALOG: StructureCatalogEntry[] = [
  {
    id: 'library',
    name: 'Library',
    description: 'A quiet hall of knowledge that boosts XP gains.',
    tier: 'common',
    cost: { stone: 100, glass: 50, wood: 80 },
    prestigeValue: 2,
    requirements: { minSectors: 2, minXp: 500 },
  },
  {
    id: 'observatory',
    name: 'Observatory',
    description: 'A stargazing tower that reveals hidden quiz topics.',
    tier: 'rare',
    cost: { stone: 200, glass: 150, wood: 100 },
    prestigeValue: 5,
    requirements: { minSectors: 4, minXp: 3000 },
  },
  {
    id: 'archive',
    name: 'Archive',
    description: 'Deep vaults storing accumulated knowledge. Increases streak persistence.',
    tier: 'rare',
    cost: { stone: 180, glass: 120, wood: 60 },
    prestigeValue: 4,
    requirements: { minSectors: 3, minXp: 2000 },
  },
  {
    id: 'park_pavilion',
    name: 'Park Pavilion',
    description: 'A green space that attracts visitors and boosts social progression.',
    tier: 'common',
    cost: { stone: 60, glass: 30, wood: 120 },
    prestigeValue: 2,
    requirements: { minSectors: 1, minXp: 200 },
  },
  {
    id: 'maker_hub',
    name: 'Maker Hub',
    description: 'A workshop that converts raw materials into rare components.',
    tier: 'master',
    cost: { stone: 300, glass: 250, wood: 200 },
    prestigeValue: 8,
    requirements: { minSectors: 6, minXp: 8000 },
  },
];
