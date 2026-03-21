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

export const LeaderboardScopeSchema = z.enum([
  'global',
  'weekly',
  'region',
  'topic',
  'squad',
  'event',
]);
export type LeaderboardScope = z.infer<typeof LeaderboardScopeSchema>;

export const RegionAnchorSchema = z.object({
  regionId: z.string().default('global_central'),
  label: z.string().default('Global District Grid'),
  privacy: z.enum(['coarse']).default('coarse'),
});
export type RegionAnchor = z.infer<typeof RegionAnchorSchema>;

export const TopicAffinitySchema = z.object({
  topic: z.string(),
  answered: z.number().int().min(0).default(0),
  correct: z.number().int().min(0).default(0),
  streak: z.number().int().min(0).default(0),
  masteryScore: z.number().min(0).default(0),
  winRate: z.number().min(0).max(1).default(0),
  lastPlayedAt: TimestampSchema.optional(),
});
export type TopicAffinity = z.infer<typeof TopicAffinitySchema>;

// ─── User ────────────────────────────────────────────────

export const UserSchema = z.object({
  id: z.string(),
  displayName: z.string().min(1).max(30).default('Explorer'),
  displayNameLower: z.string().optional(),
  handle: z.string().min(1).max(30).default('@explorer'),
  email: z.string().email().optional(),
  xp: z.number().int().min(0).default(0),
  influence: z.number().int().min(0).default(0),
  streak: z.number().int().min(0).default(0),
  bestStreak: z.number().int().min(0).default(0),
  dailyStreak: z.number().int().min(0).default(0),
  lastActivityDate: z.string().optional(), // ISO date YYYY-MM-DD
  activityHistory: z.array(z.string()).default([]),
  sectors: z.number().int().min(0).default(1),
  districtId: z.string().optional(),
  districtName: z.string().default('My District'),
  
  // Account/Profile Media
  profileImageUrl: z.string().nullable().optional(),
  storagePath: z.string().nullable().optional(),
  emblemId: z.string().nullable().optional(),

  // Personalization
  preferredName: z.string().nullable().optional(),
  ageBand: z.string().optional(),
  studyWorkStatus: z.string().optional(),
  majorOrProfession: z.string().nullable().optional(),
  interests: z.array(z.string()).default([]),
  
  // Preferences
  difficultyPreference: z.enum(['easy', 'dynamic', 'hard']).default('dynamic'),
  squadPreference: z.enum(['solo', 'social']).default('social'),
  voicePreference: z.string().nullable().optional(),

  topicStats: z.record(TopicAffinitySchema).default({}),

  visibility: VisibilitySchema.default('coarse'),
  onboardingStage: z.enum([
    'profile',
    'interests',
    'preferences',
    'summary',
    'permissions',
    'permissions_location',
    'permissions_microphone',
    'emblem',
    'district_name',
    'district_reveal',
    'completed',
  ]).default('profile'),
  onboardingCompleted: z.boolean().default(false),
  meetMimzIntroSeen: z.boolean().default(false),
  createdAt: TimestampSchema,
  updatedAt: TimestampSchema.optional(),
});
export type User = z.infer<typeof UserSchema>;

export const UserProfileSchema = UserSchema.pick({
  displayName: true,
  preferredName: true,
  handle: true,
  profileImageUrl: true,
  studyWorkStatus: true,
  majorOrProfession: true,
  interests: true,
  visibility: true,
  districtName: true,
  difficultyPreference: true,
  squadPreference: true,
  voicePreference: true,
  onboardingStage: true,
  onboardingCompleted: true,
  meetMimzIntroSeen: true,
}).partial();
export type UserProfile = z.infer<typeof UserProfileSchema>;

export const ProfilePatchSchema = UserProfileSchema.extend({
  profileImageUrl: z.string().url().nullable().optional(),
  storagePath: z.string().nullable().optional(),
  preferredName: z.string().nullable().optional(),
  majorOrProfession: z.string().nullable().optional(),
  voicePreference: z.string().nullable().optional(),
});
export type ProfilePatch = z.infer<typeof ProfilePatchSchema>;

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

export const DistrictCellSchema = z.object({
  id: z.string(),
  q: z.number().int(),
  r: z.number().int(),
  layer: z.enum(['core', 'inner', 'frontier']).default('frontier'),
  stability: z.number().min(0).max(100).default(50),
  contested: z.boolean().default(false),
  protectedUntil: TimestampSchema.optional(),
  addedAt: TimestampSchema.optional(),
});
export type DistrictCell = z.infer<typeof DistrictCellSchema>;

export const DistrictSchema = z.object({
  id: z.string(),
  ownerId: z.string(),
  name: z.string().min(1).max(50),
  sectors: z.number().int().min(0).default(1),
  influence: z.number().int().min(0).default(0),
  influenceThreshold: z.number().int().min(1).default(500),
  area: z.string().default('1.0 sq km'),
  cells: z.array(DistrictCellSchema).default([]),
  anchorCell: z.string().optional(),
  regionAnchor: RegionAnchorSchema.default({
    regionId: 'global_central',
    label: 'Global District Grid',
    privacy: 'coarse',
  }),
  topicAffinities: z.array(TopicAffinitySchema).default([]),
  decayState: z.enum(['stable', 'cooling', 'vulnerable', 'reclaimable']).default('stable'),
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
  type: z.enum(['xp', 'territory', 'materials', 'structure', 'combo', 'influence']),
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
  mode: z.enum(['quiz', 'sprint', 'event']).default('quiz'),
  topic: z.string().default('General'),
  difficulty: z.enum(['easy', 'dynamic', 'hard']).default('dynamic'),
  eventId: z.string().optional(),
  questionIds: z.array(z.string()).default([]),
  questionCount: z.number().int().min(1).default(5),
  currentQuestionIndex: z.number().int().min(0).default(0),
  hintCount: z.number().int().min(0).default(0),
  repeatCount: z.number().int().min(0).default(0),
  questionsAsked: z.number().int().default(0),
  correctAnswers: z.number().int().default(0),
  totalScore: z.number().int().default(0),
  maxStreak: z.number().int().default(0),
  roundComplete: z.boolean().default(false),
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
  targetPrompt: z.string().optional(),
  targetKeywords: z.array(z.string()).default([]),
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
  regionId: z.string().optional(),
  topic: z.string().optional(),
  scope: LeaderboardScopeSchema.optional(),
});
export type LeaderboardEntry = z.infer<typeof LeaderboardEntrySchema>;

export const LeaderboardSummarySchema = z.object({
  scope: LeaderboardScopeSchema,
  title: z.string(),
  entries: z.array(LeaderboardEntrySchema).default([]),
});
export type LeaderboardSummary = z.infer<typeof LeaderboardSummarySchema>;

// ─── Achievements / Badges ───────────────────────────────

export const AchievementSchema = z.object({
  id: z.string(),
  name: z.string(),
  description: z.string(),
  icon: z.string().default('star'),
  category: z.enum(['streak', 'rounds', 'xp', 'territory', 'social', 'event', 'vision', 'special']),
  rarity: z.enum(['common', 'rare', 'legendary']).default('common'),
  requirement: z.number().int().min(1),
  field: z.string(),
});
export type Achievement = z.infer<typeof AchievementSchema>;

export const UserBadgeSchema = z.object({
  achievementId: z.string(),
  unlockedAt: TimestampSchema,
});
export type UserBadge = z.infer<typeof UserBadgeSchema>;

export const ACHIEVEMENT_CATALOG: Achievement[] = [
  { id: 'first_round', name: 'First Steps', description: 'Complete your first round', icon: 'play_circle', category: 'rounds', rarity: 'common', requirement: 1, field: 'roundsCompleted' },
  { id: 'streak_3', name: 'Hat Trick', description: 'Get a 3-question streak', icon: 'local_fire_department', category: 'streak', rarity: 'common', requirement: 3, field: 'bestStreak' },
  { id: 'streak_10', name: 'On Fire', description: 'Get a 10-question streak', icon: 'whatshot', category: 'streak', rarity: 'rare', requirement: 10, field: 'bestStreak' },
  { id: 'streak_25', name: 'Unstoppable', description: 'Get a 25-question streak', icon: 'bolt', category: 'streak', rarity: 'legendary', requirement: 25, field: 'bestStreak' },
  { id: 'xp_1000', name: 'Rising Star', description: 'Earn 1,000 XP', icon: 'star', category: 'xp', rarity: 'common', requirement: 1000, field: 'xp' },
  { id: 'xp_10000', name: 'Knowledge Seeker', description: 'Earn 10,000 XP', icon: 'school', category: 'xp', rarity: 'rare', requirement: 10000, field: 'xp' },
  { id: 'xp_50000', name: 'Grand Scholar', description: 'Earn 50,000 XP', icon: 'emoji_events', category: 'xp', rarity: 'legendary', requirement: 50000, field: 'xp' },
  { id: 'territory_5', name: 'Settler', description: 'Expand to 5 sectors', icon: 'map', category: 'territory', rarity: 'common', requirement: 5, field: 'sectors' },
  { id: 'territory_20', name: 'Expansionist', description: 'Expand to 20 sectors', icon: 'public', category: 'territory', rarity: 'rare', requirement: 20, field: 'sectors' },
  { id: 'territory_50', name: 'Empire Builder', description: 'Expand to 50 sectors', icon: 'castle', category: 'territory', rarity: 'legendary', requirement: 50, field: 'sectors' },
  { id: 'daily_7', name: 'Weekly Warrior', description: 'Play 7 days in a row', icon: 'calendar_month', category: 'streak', rarity: 'rare', requirement: 7, field: 'dailyStreak' },
  { id: 'daily_30', name: 'Monthly Master', description: 'Play 30 days in a row', icon: 'military_tech', category: 'streak', rarity: 'legendary', requirement: 30, field: 'dailyStreak' },
  { id: 'vision_1', name: 'First Discovery', description: 'Complete a vision quest', icon: 'visibility', category: 'vision', rarity: 'common', requirement: 1, field: 'visionQuestsCompleted' },
  { id: 'squad_join', name: 'Team Player', description: 'Join a squad', icon: 'groups', category: 'social', rarity: 'common', requirement: 1, field: 'squadJoined' },
  { id: 'event_win', name: 'Event Champion', description: 'Win an event challenge', icon: 'trophy', category: 'event', rarity: 'legendary', requirement: 1, field: 'eventsWon' },
];

// ─── Territory Conflict ──────────────────────────────────

export const TerritoryConflictSchema = z.object({
  id: z.string(),
  type: z.enum(['event_zone', 'rivalry', 'inactivity_takeover']),
  status: z.enum(['active', 'resolved', 'expired']).default('active'),
  attackerId: z.string().optional(),
  defenderId: z.string(),
  eventId: z.string().optional(),
  cellsAtStake: z.number().int().min(0).default(0),
  cellsWon: z.number().int().min(0).default(0),
  startedAt: TimestampSchema,
  resolvedAt: TimestampSchema.optional(),
});
export type TerritoryConflict = z.infer<typeof TerritoryConflictSchema>;

export const ConflictStateSchema = TerritoryConflictSchema.extend({
  headline: z.string().optional(),
  summary: z.string().optional(),
  districtName: z.string().optional(),
});
export type ConflictState = z.infer<typeof ConflictStateSchema>;

export const StructureEffectSchema = z.object({
  xpMultiplier: z.number().default(1),
  materialMultiplier: z.number().default(1),
  influenceMultiplier: z.number().default(1),
  decayReduction: z.number().default(0),
  streakProtection: z.number().int().default(0),
  squadMultiplier: z.number().default(1),
});
export type StructureEffect = z.infer<typeof StructureEffectSchema>;

export const EventZoneSchema = z.object({
  id: z.string(),
  eventId: z.string(),
  title: z.string(),
  status: z.enum(['live', 'upcoming', 'completed']).default('upcoming'),
  regionId: z.string().default('global_central'),
  regionLabel: z.string().default('Global District Grid'),
  districtEffect: z.string().default('Boost district influence in this zone.'),
  rewardMultiplier: z.number().default(1),
});
export type EventZone = z.infer<typeof EventZoneSchema>;

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
  sessionType: z.enum(['onboarding', 'quiz', 'sprint', 'vision_quest', 'event']).default('quiz'),
  eventId: z.string().optional(),
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
  executionTimeMs: z.number().int().optional(),
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

// ─── Feedback ─────────────────────────────────────────────

export const FeedbackCategorySchema = z.enum(['general', 'bug', 'ux', 'feature']);
export type FeedbackCategory = z.infer<typeof FeedbackCategorySchema>;

export const FeedbackSubmissionSchema = z.object({
  category: FeedbackCategorySchema.default('general'),
  message: z.string().trim().min(10).max(1200),
});
export type FeedbackSubmission = z.infer<typeof FeedbackSubmissionSchema>;

export const ClientTelemetryEventSchema = z.object({
  sessionId: z.string().min(1),
  event: z.string().trim().min(1).max(80),
  occurredAt: TimestampSchema,
  route: z.string().optional(),
  correlationId: z.string().optional(),
  metadata: z.record(z.unknown()).default({}),
});
export type ClientTelemetryEvent = z.infer<typeof ClientTelemetryEventSchema>;

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

// ─── Question System ──────────────────────────────────────

export const QuestionDifficultySchema = z.enum(['easy', 'medium', 'hard']);
export type QuestionDifficulty = z.infer<typeof QuestionDifficultySchema>;

export const QuestionTypeSchema = z.enum([
  'multiple_choice',
  'short_answer',
  'fill_blank',
  'true_false',
  'numeric',
]);
export type QuestionType = z.infer<typeof QuestionTypeSchema>;

export const AnswerSchemaSchema = z.object({
  // For exact / alias matching
  exact: z.string().optional(),
  aliases: z.array(z.string()).default([]),

  // For multiple choice
  choices: z.array(z.object({
    id: z.string(),
    text: z.string(),
    isCorrect: z.boolean(),
  })).default([]),

  // For numeric answers
  numericAnswer: z.number().optional(),
  numericTolerance: z.number().default(0),

  // For semantic (AI-graded)
  semanticKeywords: z.array(z.string()).default([]),
  semanticThreshold: z.number().min(0).max(1).default(0.8),
});
export type AnswerSchema = z.infer<typeof AnswerSchemaSchema>;

export const QuestionSchema = z.object({
  id: z.string(),
  topic: z.string(),
  subtopic: z.string().optional(),
  tags: z.array(z.string()).default([]),
  difficulty: QuestionDifficultySchema,
  type: QuestionTypeSchema,

  // Human-readable question text
  text: z.string(),

  // Spoken delivery phrasing (TTS-optimized, no markdown)
  spokenPhrase: z.string(),

  // Answer grading data (kept server-side, never sent to client)
  answerSchema: AnswerSchemaSchema,

  // Metadata
  source: z.enum(['deterministic', 'ai_generated']).default('ai_generated'),
  language: z.string().default('en').optional(),
  interests: z.array(z.string()).default([]),
  createdAt: TimestampSchema.optional(),
});
export type Question = z.infer<typeof QuestionSchema>;

// Client-safe question (strips answer schema)
export const ClientQuestionSchema = QuestionSchema.omit({ answerSchema: true }).extend({
  // For multiple choice, include the shuffled options (without isCorrect flag)
  choices: z.array(z.object({ id: z.string(), text: z.string() })).optional(),
});
export type ClientQuestion = z.infer<typeof ClientQuestionSchema>;

// ─── Answer Validation ────────────────────────────────────

export const AnswerValidationRequestSchema = z.object({
  sessionId: z.string(),
  questionId: z.string(),
  userAnswer: z.string().max(500),
  answeredInMs: z.number().int().min(0).optional(),
});
export type AnswerValidationRequest = z.infer<typeof AnswerValidationRequestSchema>;

export const AnswerValidationResultSchema = z.object({
  isCorrect: z.boolean(),
  confidenceScore: z.number().min(0).max(1),
  matchType: z.enum(['exact', 'alias', 'multiple_choice', 'numeric', 'semantic', 'none']),
  normalizedAnswer: z.string(),
  correctAnswer: z.string(),
  explanation: z.string().optional(),
  pointsAwarded: z.number().int().default(0),
  streakBonus: z.number().int().default(0),
  newStreak: z.number().int().default(0),
});
export type AnswerValidationResult = z.infer<typeof AnswerValidationResultSchema>;

// ─── Question Generation Request ─────────────────────────

export const QuestionGenerationRequestSchema = z.object({
  userId: z.string(),
  sessionId: z.string(),
  interests: z.array(z.string()).default([]),
  difficulty: QuestionDifficultySchema.default('medium'),
  count: z.number().int().min(1).max(20).default(5),
  excludeIds: z.array(z.string()).default([]),
  topic: z.string().optional(),
});
export type QuestionGenerationRequest = z.infer<typeof QuestionGenerationRequestSchema>;

export const RoundStartRequestSchema = z.object({
  mode: z.enum(['quiz', 'sprint', 'event']).default('quiz'),
  topic: z.string().optional(),
  difficulty: z.enum(['easy', 'dynamic', 'hard']).optional(),
  eventId: z.string().optional(),
});
export type RoundStartRequest = z.infer<typeof RoundStartRequestSchema>;

export const RoundQuestionSchema = ClientQuestionSchema;
export type RoundQuestion = z.infer<typeof RoundQuestionSchema>;

export const RoundDefinitionSchema = z.object({
  roundId: z.string(),
  mode: z.enum(['quiz', 'sprint', 'event']).default('quiz'),
  topic: z.string(),
  difficulty: z.enum(['easy', 'dynamic', 'hard']),
  eventId: z.string().optional(),
  questionCount: z.number().int().min(1),
  currentQuestionIndex: z.number().int().min(0).default(0),
  currentQuestion: RoundQuestionSchema.optional(),
  questions: z.array(RoundQuestionSchema).default([]),
  hintCount: z.number().int().min(0).default(0),
  repeatCount: z.number().int().min(0).default(0),
  isComplete: z.boolean().default(false),
});
export type RoundDefinition = z.infer<typeof RoundDefinitionSchema>;

export const AnswerResultSchema = AnswerValidationResultSchema.extend({
  roundId: z.string(),
  questionId: z.string(),
  topic: z.string(),
  xpAwarded: z.number().int().default(0),
  influenceGranted: z.number().int().default(0),
  sectorsGained: z.number().int().default(0),
  materialsEarned: ResourcesSchema.default({ stone: 0, glass: 0, wood: 0 }),
  comboXp: z.number().int().default(0),
  territoryExpanded: z.boolean().default(false),
  nextQuestion: RoundQuestionSchema.optional(),
  questionCount: z.number().int().min(1).default(5),
  currentQuestionIndex: z.number().int().min(0).default(0),
  roundComplete: z.boolean().default(false),
});
export type AnswerResult = z.infer<typeof AnswerResultSchema>;

export const VisionQuestResultSchema = z.object({
  questId: z.string(),
  targetPrompt: z.string().optional(),
  objectIdentified: z.string(),
  confidence: z.number().min(0).max(1).default(0),
  isValid: z.boolean().default(false),
  xpAwarded: z.number().int().default(0),
  influenceGranted: z.number().int().default(0),
  structureUnlocked: z.string().optional(),
  message: z.string().optional(),
});
export type VisionQuestResult = z.infer<typeof VisionQuestResultSchema>;

export const StreakStateSchema = z.object({
  liveStreak: z.number().int().min(0).default(0),
  dailyStreak: z.number().int().min(0).default(0),
  bestStreak: z.number().int().min(0).default(0),
  lastActivityDate: z.string().optional(),
  streakRiskState: z.enum(['secured', 'at_risk', 'cold']).default('cold'),
  streakHistory: z.array(z.object({
    date: z.string(),
    active: z.boolean().default(false),
  })).default([]),
});
export type StreakState = z.infer<typeof StreakStateSchema>;

export const StructureProgressSchema = z.object({
  nextStructureId: z.string().optional(),
  nextStructureName: z.string().optional(),
  unlockedCount: z.number().int().min(0).default(0),
  totalAvailable: z.number().int().min(0).default(0),
  readyToBuild: z.boolean().default(false),
});
export type StructureProgress = z.infer<typeof StructureProgressSchema>;

export const SquadSummarySchema = z.object({
  squad: SquadSchema.nullable().optional(),
  members: z.array(SquadMemberSchema).default([]),
  missions: z.array(SquadMissionSchema).default([]),
});
export type SquadSummary = z.infer<typeof SquadSummarySchema>;

export const RankStateSchema = z.object({
  rank: z.number().int().min(1).default(1),
  rankTitle: z.string().default('Explorer'),
  nextRankXp: z.number().int().min(0).default(0),
  prestigeTier: z.enum(['bronze', 'silver', 'gold', 'platinum', 'diamond']).default('bronze'),
});
export type RankState = z.infer<typeof RankStateSchema>;

export const DistrictHealthSummarySchema = z.object({
  state: z.enum(['stable', 'cooling', 'vulnerable', 'reclaimable']).default('stable'),
  headline: z.string().default('District stable'),
  summary: z.string().default('Your frontier is holding steady.'),
  vulnerableCells: z.number().int().min(0).default(0),
  reclaimableCells: z.number().int().min(0).default(0),
  nextExpansionIn: z.number().int().min(0).default(0),
});
export type DistrictHealthSummary = z.infer<typeof DistrictHealthSummarySchema>;

export const HeroBannerSchema = z.object({
  eyebrow: z.string().default('Today'),
  title: z.string().default('Grow your district'),
  body: z.string().default('One strong session changes your world.'),
  accent: z.enum(['moss', 'mist', 'gold', 'persimmon']).default('moss'),
  route: z.string().default('/play'),
});
export type HeroBanner = z.infer<typeof HeroBannerSchema>;

export const RecommendedActionSchema = z.object({
  type: z.enum(['quiz', 'sprint', 'event', 'vision', 'reclaim', 'squad', 'build']).default('quiz'),
  title: z.string(),
  subtitle: z.string().default(''),
  reasonWhyNow: z.string().default('This is the strongest move for your district right now.'),
  rewardPreview: z.string().default('District growth and progression rewards.'),
  impactLabel: z.string().default('District impact'),
  ctaLabel: z.string().default('Play'),
  route: z.string().default('/play'),
  estimatedMinutes: z.number().int().min(1).default(2),
  badge: z.string().default('NOW'),
});
export type RecommendedAction = z.infer<typeof RecommendedActionSchema>;

export const MissionSummarySchema = z.object({
  title: z.string().default('Build your district'),
  summary: z.string().default('One strong session changes your district today.'),
  rewardPreview: z.string().default('District growth and progression rewards.'),
  route: z.string().default('/play'),
  estimatedMinutes: z.number().int().min(1).default(3),
  priority: z.enum(['now', 'soon', 'later']).default('now'),
});
export type MissionSummary = z.infer<typeof MissionSummarySchema>;

export const GameStateSchema = z.object({
  user: UserSchema,
  district: DistrictSchema,
  onboardingCompleted: z.boolean().default(false),
  nextRecommendedRoute: z.string().default('/world'),
  showMeetMimzPrompt: z.boolean().default(false),
  currentMission: z.string(),
  missionSummary: MissionSummarySchema.optional(),
  activeEvent: EventSchema.nullable().optional(),
  eventZones: z.array(EventZoneSchema).default([]),
  squadSummary: SquadSummarySchema.optional(),
  rankState: RankStateSchema,
  streakState: StreakStateSchema,
  districtHealthSummary: DistrictHealthSummarySchema,
  worldHeroBanner: HeroBannerSchema,
  recommendedPrimaryAction: RecommendedActionSchema,
  recommendedSecondaryAction: RecommendedActionSchema.optional(),
  structureEffects: StructureEffectSchema,
  structureProgress: StructureProgressSchema,
  notifications: z.array(NotificationSchema).default([]),
  leaderboardSnippets: z.array(LeaderboardSummarySchema).default([]),
  activeConflicts: z.array(ConflictStateSchema).default([]),
});
export type GameState = z.infer<typeof GameStateSchema>;
