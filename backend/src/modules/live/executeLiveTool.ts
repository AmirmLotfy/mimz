import { randomUUID } from 'crypto';
import { TOOL_SCHEMAS, KNOWN_TOOLS } from './toolSchemas.js';
import * as game from '../../services/gameService.js';
import * as db from '../../lib/db.js';
import type { LiveToolExecutionResponse } from '../../models/types.js';

// ═══════════════════════════════════════════════════════
// IDEMPOTENCY GUARD
// Prevents double-grant if the model retries a tool call.
// Key: `${correlationId}:${toolName}` → cached result
// Cleared automatically after 10 min.
// ═══════════════════════════════════════════════════════

const _idempotencyCache = new Map<string, ToolResult>();
const _idempotencyExpiry = new Map<string, number>();
const IDEMPOTENCY_TTL_MS = 10 * 60 * 1000;

setInterval(() => {
  const now = Date.now();
  for (const [key, expiry] of _idempotencyExpiry) {
    if (expiry < now) {
      _idempotencyCache.delete(key);
      _idempotencyExpiry.delete(key);
    }
  }
}, 60_000);

function idempotencyKey(correlationId: string, toolName: string): string {
  return `${correlationId}:${toolName}`;
}

function getCachedResult(correlationId: string, toolName: string): ToolResult | undefined {
  return _idempotencyCache.get(idempotencyKey(correlationId, toolName));
}

function setCachedResult(correlationId: string, toolName: string, result: ToolResult): void {
  const key = idempotencyKey(correlationId, toolName);
  _idempotencyCache.set(key, result);
  _idempotencyExpiry.set(key, Date.now() + IDEMPOTENCY_TTL_MS);
}

// ═══════════════════════════════════════════════════════
// TOOL EXECUTION CONTEXT
// ═══════════════════════════════════════════════════════

export interface ToolContext {
  userId: string;
  sessionId: string;
  correlationId: string;
}

export interface ToolResult {
  success: boolean;
  data: Record<string, unknown>;
  error?: string;
}

type ToolHandler = (args: Record<string, unknown>, ctx: ToolContext) => Promise<ToolResult>;

// ═══════════════════════════════════════════════════════
// HANDLER IMPLEMENTATIONS
// ═══════════════════════════════════════════════════════

const handlers: Record<string, ToolHandler> = {
  // ─── Onboarding ──────────────────────────────────
  async start_onboarding(_args, ctx) {
    const user = await game.bootstrapUser(ctx.userId);
    return {
      success: true,
      data: {
        message: 'Welcome to Mimz! Let\'s set up your district.',
        userId: user.id,
        displayName: user.displayName,
      },
    };
  },

  async save_user_profile(args, ctx) {
    const updates: Record<string, unknown> = {};
    if (args.displayName) updates.displayName = args.displayName;
    if (args.districtName) updates.districtName = args.districtName;
    if (args.interests) updates.interests = args.interests;

    await game.updateProfile(ctx.userId, updates as any);
    await game.audit(ctx.userId, 'save_user_profile', updates, { toolName: 'save_user_profile', sessionId: ctx.sessionId });

    return {
      success: true,
      data: { message: 'Profile saved!', ...updates },
    };
  },

  // ─── District ────────────────────────────────────
  async get_current_district(_args, ctx) {
    const district = await game.getDistrict(ctx.userId);
    return {
      success: true,
      data: district ? {
        name: district.name,
        sectors: district.sectors,
        area: district.area,
        structureCount: district.structures.length,
        resources: district.resources,
        prestigeLevel: district.prestigeLevel,
      } : { message: 'No district yet. Start playing to build one!' },
    };
  },

  // ─── Quiz Round ──────────────────────────────────
  async start_live_round(args, ctx) {
    const round = await db.createRound({
      id: `round_${randomUUID()}`,
      userId: ctx.userId,
      topic: (args.topic as string) || 'General',
      difficulty: (args.difficulty as any) || 'medium',
      questionsAsked: 0,
      correctAnswers: 0,
      totalScore: 0,
      maxStreak: 0,
      status: 'active',
      startedAt: new Date().toISOString(),
    });

    await game.audit(ctx.userId, 'start_live_round', { roundId: round.id, topic: round.topic }, {
      toolName: 'start_live_round', sessionId: ctx.sessionId,
    });

    return {
      success: true,
      data: {
        roundId: round.id,
        topic: round.topic,
        difficulty: round.difficulty,
        message: `Round started! Topic: ${round.topic}`,
      },
    };
  },

  async grade_answer(args, ctx) {
    // Idempotency: if same correlationId already processed, return cached result
    const cached = getCachedResult(ctx.correlationId, 'grade_answer');
    if (cached) return cached;

    const isCorrect = args.isCorrect as boolean ?? true;
    const user = await db.getUser(ctx.userId);
    if (!user) throw new Error('User not found');

    const { points, streakBonus, newStreak } = game.calculateScore(
      isCorrect, user.streak, 'medium',
    );

    // Update user state
    if (isCorrect) {
      await db.incrementUserXp(ctx.userId, points);
      await db.updateUserStreak(ctx.userId, newStreak, user.bestStreak);
      await game.grantReward(ctx.userId, 'xp', points, 'grade_answer', ctx.sessionId);
    } else {
      await db.updateUserStreak(ctx.userId, 0, user.bestStreak);
    }

    // Update active round
    const round = await db.getActiveRound(ctx.userId);
    if (round) {
      await db.updateRound(round.id, {
        questionsAsked: round.questionsAsked + 1,
        correctAnswers: round.correctAnswers + (isCorrect ? 1 : 0),
        totalScore: round.totalScore + points,
        maxStreak: Math.max(round.maxStreak, newStreak),
      });
    }

    await game.audit(ctx.userId, 'grade_answer', { isCorrect, points, streak: newStreak }, {
      toolName: 'grade_answer', sessionId: ctx.sessionId,
    });

    const result: ToolResult = {
      success: true,
      data: {
        isCorrect,
        pointsAwarded: points,
        streakBonus,
        currentStreak: newStreak,
        message: isCorrect
          ? `Correct! +${points} XP${streakBonus > 0 ? ` (+${streakBonus} streak bonus!)` : ''}`
          : 'Incorrect. Streak reset. Keep going!',
      },
    };
    setCachedResult(ctx.correlationId, 'grade_answer', result);
    return result;
  },

  async award_territory(args, ctx) {
    // Idempotency: if same correlationId already processed, return cached result
    const cached = getCachedResult(ctx.correlationId, 'award_territory');
    if (cached) return cached;

    const sectors = args.sectors as number;
    const expansion = await game.expandTerritory(ctx.userId, sectors);

    await game.grantReward(ctx.userId, 'territory', sectors, 'award_territory', ctx.sessionId);
    await game.audit(ctx.userId, 'award_territory', { sectors }, {
      toolName: 'award_territory', sessionId: ctx.sessionId,
    });

    const result: ToolResult = {
      success: true,
      data: {
        sectorsAdded: sectors,
        totalSectors: expansion.sectors,
        area: expansion.area,
        message: `🗺 Territory expanded by ${sectors} sector${sectors > 1 ? 's' : ''}!`,
      },
    };
    setCachedResult(ctx.correlationId, 'award_territory', result);
    return result;
  },

  async apply_combo_bonus(args, ctx) {
    const streak = args.streak as number;
    const multiplier = args.multiplier as number;
    const { bonusXp, bonusMaterials } = game.calculateComboBonus(streak, multiplier);

    await db.incrementUserXp(ctx.userId, bonusXp);
    const district = await game.getDistrict(ctx.userId);
    if (district) await db.addResources(district.id, bonusMaterials);

    await game.grantReward(ctx.userId, 'combo', bonusXp, 'apply_combo_bonus', ctx.sessionId);

    return {
      success: true,
      data: {
        bonusXp,
        bonusMaterials,
        message: `🔥 ${streak}x combo! +${bonusXp} XP and bonus materials!`,
      },
    };
  },

  async grant_materials(args, ctx) {
    const stone = args.stone as number;
    const glass = args.glass as number;
    const wood = args.wood as number;

    const district = await game.getDistrict(ctx.userId);
    if (!district) throw new Error('No district found');

    await db.addResources(district.id, { stone, glass, wood });
    await game.grantReward(ctx.userId, 'materials', stone + glass + wood, 'grant_materials', ctx.sessionId);

    return {
      success: true,
      data: {
        stone, glass, wood,
        message: `📦 Materials granted: ${stone} stone, ${glass} glass, ${wood} wood`,
      },
    };
  },

  async end_round(args, ctx) {
    const round = await db.getActiveRound(ctx.userId);
    if (round) {
      await db.updateRound(round.id, {
        status: 'completed',
        totalScore: (args.totalScore as number) ?? round.totalScore,
        endedAt: new Date().toISOString(),
      });

      // Update leaderboard
      const user = await db.getUser(ctx.userId);
      if (user) {
        await db.upsertLeaderboardEntry('global', ctx.userId, {
          userId: ctx.userId,
          displayName: user.displayName,
          score: user.xp,
          districtName: user.districtName,
        });
      }
    }

    await game.audit(ctx.userId, 'end_round', { roundId: round?.id }, {
      toolName: 'end_round', sessionId: ctx.sessionId,
    });

    return {
      success: true,
      data: {
        roundId: round?.id,
        totalScore: round?.totalScore ?? 0,
        questionsAnswered: round?.questionsAsked ?? 0,
        correctAnswers: round?.correctAnswers ?? 0,
        message: 'Round complete! Great playing!',
      },
    };
  },

  // ─── Vision Quest ────────────────────────────────
  async start_vision_quest(args, ctx) {
    const questId = `vq_${randomUUID()}`;
    const quest = {
      id: questId,
      userId: ctx.userId,
      theme: (args.theme as string) || 'discovery',
      status: 'active' as const,
      confidence: 0,
      isValid: false,
      sessionId: ctx.sessionId,
      startedAt: new Date().toISOString(),
    };

    // Persist to Firestore so vision quest history is real
    try {
      await db.createVisionQuest(quest);
    } catch {
      // Non-fatal — audit trail still created below
    }

    await game.audit(ctx.userId, 'start_vision_quest', { questId: quest.id, theme: quest.theme }, {
      toolName: 'start_vision_quest', sessionId: ctx.sessionId,
    });

    return {
      success: true,
      data: {
        questId: quest.id,
        theme: quest.theme,
        message: 'Vision quest started! Show me something interesting.',
      },
    };
  },

  async validate_vision_result(args, ctx) {
    const result = {
      objectIdentified: args.objectIdentified as string,
      confidence: args.confidence as number,
      isValid: args.isValid as boolean ?? (args.confidence as number) > 0.6,
    };

    if (result.isValid) {
      await db.incrementUserXp(ctx.userId, 200);
      await game.grantReward(ctx.userId, 'xp', 200, 'validate_vision_result', ctx.sessionId);
    }

    return {
      success: true,
      data: {
        ...result,
        xpAwarded: result.isValid ? 200 : 0,
        message: result.isValid
          ? `Verified: "${result.objectIdentified}"! +200 XP`
          : `Hmm, not quite. Try again!`,
      },
    };
  },

  // ─── Structures ──────────────────────────────────
  async unlock_structure(args, ctx) {
    const structureId = args.structureId as string;
    const result = await game.unlockStructure(ctx.userId, structureId);

    await game.grantReward(ctx.userId, 'structure', result.structure.prestigeValue || 1, 'unlock_structure', ctx.sessionId);
    await game.audit(ctx.userId, 'unlock_structure', { structureId }, {
      toolName: 'unlock_structure', sessionId: ctx.sessionId,
    });

    return {
      success: true,
      data: {
        structure: result.structure,
        message: `🏛 ${result.structure.name} unlocked!`,
      },
    };
  },

  // ─── Squads ──────────────────────────────────────
  async join_squad_mission(args, ctx) {
    const missionId = args.missionId as string;

    // Persist participation record to Firestore
    const squadId = await db.getSquadIdForUser(ctx.userId);
    if (squadId) {
      try {
        await db.addSquadMissionParticipant(squadId, missionId, ctx.userId);
      } catch {
        // Non-fatal — user may already be a participant
      }
    }

    await game.audit(ctx.userId, 'join_squad_mission', { missionId, squadId: squadId || 'none' }, {
      toolName: 'join_squad_mission', sessionId: ctx.sessionId,
    });

    return {
      success: true,
      data: {
        missionId,
        squadId: squadId || null,
        message: 'Joined squad mission!',
      },
    };
  },

  async contribute_squad_progress(args, ctx) {
    const missionId = args.missionId as string;
    const amount = args.amount as number;

    const squadId = await db.getSquadIdForUser(ctx.userId);
    if (!squadId) {
      throw new Error('User is not in a squad');
    }

    // Find user's squad and update mission progress
    await db.updateSquadMissionProgress(squadId, missionId, amount);

    // Also award XP equivalent as direct reward
    await db.incrementUserXp(ctx.userId, Math.floor(amount * 10));
    await game.grantReward(ctx.userId, 'xp', Math.floor(amount * 10), 'contribute_squad_progress', ctx.sessionId);
    await game.audit(ctx.userId, 'contribute_squad_progress', { missionId, amount, squadId }, {
      toolName: 'contribute_squad_progress', sessionId: ctx.sessionId,
    });

    return {
      success: true,
      data: {
        missionId,
        contributed: amount,
        squadId,
        xpEarned: Math.floor(amount * 10),
        message: `Contributed ${amount} progress to squad mission! +${Math.floor(amount * 10)} XP`,
      },
    };
  },

  // ─── Events ──────────────────────────────────────
  async get_event_state(args, ctx) {
    const eventId = args.eventId as string;
    const event = await db.getEvent(eventId);

    return {
      success: true,
      data: event
        ? { id: event.id, title: event.title, status: event.status, participants: event.participantCount }
        : { message: 'Event not found' },
    };
  },
};

// ═══════════════════════════════════════════════════════
// TOOL REGISTRY + EXECUTOR
// ═══════════════════════════════════════════════════════

/**
 * Execute a validated tool call.
 *
 * 1. Validates tool name is known
 * 2. Validates args against Zod schema
 * 3. Dispatches to handler
 * 4. Returns typed response
 */
export async function executeTool(
  toolName: string,
  rawArgs: Record<string, unknown>,
  ctx: ToolContext,
): Promise<LiveToolExecutionResponse> {
  const cid = ctx.correlationId || `corr_${randomUUID().substring(0, 8)}`;

  // 1. Validate tool name
  if (!KNOWN_TOOLS.includes(toolName)) {
    return {
      success: false,
      data: {},
      error: `Unknown tool: ${toolName}`,
      correlationId: cid,
      executedAt: new Date().toISOString(),
    };
  }

  // 2. Validate args
  const schema = TOOL_SCHEMAS[toolName];
  const parsed = schema.safeParse(rawArgs);
  if (!parsed.success) {
    return {
      success: false,
      data: {},
      error: `Invalid args for ${toolName}: ${parsed.error.message}`,
      correlationId: cid,
      executedAt: new Date().toISOString(),
    };
  }

  // 3. Execute
  try {
    const start = Date.now();
    const handler = handlers[toolName];
    const result = await handler(parsed.data as Record<string, unknown>, { ...ctx, correlationId: cid });
    const executionTimeMs = Date.now() - start;

    return {
      success: result.success,
      data: result.data,
      error: result.error,
      correlationId: cid,
      executedAt: new Date().toISOString(),
      executionTimeMs,
    };
  } catch (err: any) {
    return {
      success: false,
      data: {},
      error: err.message || 'Tool execution failed',
      correlationId: cid,
      executedAt: new Date().toISOString(),
      executionTimeMs: 0,
    };
  }
}

/**
 * Strip human-readable `message` field from tool result for model consumption.
 * Saves tokens in the context window — messages are only for client-side display.
 */
export function toModelPayload(result: LiveToolExecutionResponse): Record<string, unknown> {
  const { data, ...rest } = result;
  const trimmed = { ...data };
  delete trimmed['message'];
  return { ...rest, data: trimmed };
}
