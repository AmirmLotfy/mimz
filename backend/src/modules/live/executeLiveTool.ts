import { randomUUID } from 'crypto';
import { TOOL_SCHEMAS, KNOWN_TOOLS } from './toolSchemas.js';
import * as game from '../../services/gameService.js';
import * as rounds from '../../services/roundService.js';
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
  eventId?: string;
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
        influence: (district as any).influence ?? 0,
        influenceThreshold: (district as any).influenceThreshold ?? 500,
        area: district.area,
        structureCount: district.structures.length,
        resources: district.resources,
        prestigeLevel: district.prestigeLevel,
      } : { message: 'No district yet. Start playing to build one!' },
    };
  },

  // ─── Quiz Round ──────────────────────────────────
  async start_live_round(args, ctx) {
    const round = await rounds.startRound(ctx.userId, {
      mode: (args.mode as 'quiz' | 'sprint' | 'event' | undefined) ?? 'quiz',
      topic: (args.topic as string | undefined) ?? undefined,
      difficulty: (args.difficulty as 'easy' | 'medium' | 'hard' | undefined) ?? undefined,
      eventId: (args.eventId as string | undefined) ?? ctx.eventId,
    });

    await game.audit(ctx.userId, 'start_live_round', { roundId: round.roundId, topic: round.topic, mode: round.mode }, {
      toolName: 'start_live_round', sessionId: ctx.sessionId,
    });

    return {
      success: true,
      data: {
        roundId: round.roundId,
        mode: round.mode,
        topic: round.topic,
        difficulty: round.difficulty,
        questionCount: round.questionCount,
        currentQuestionIndex: round.currentQuestionIndex,
        currentQuestion: round.currentQuestion,
        questions: round.questions,
        message: `Round started. Ask this exact question next: ${round.currentQuestion?.spokenPhrase ?? round.currentQuestion?.text ?? 'Begin the round.'}`,
      },
    };
  },

  async grade_answer(args, ctx) {
    const cached = getCachedResult(ctx.correlationId, 'grade_answer');
    if (cached) return cached;

    const activeRound = await db.getActiveRound(ctx.userId);
    if (!activeRound) throw new Error('No active round found');

    const resultData = await rounds.answerRound(
      ctx.userId,
      activeRound.id,
      args.answer as string,
      args.questionId as string | undefined,
    );

    await game.audit(ctx.userId, 'grade_answer', {
      questionId: resultData.questionId,
      topic: resultData.topic,
      isCorrect: resultData.isCorrect,
      xpAwarded: resultData.xpAwarded,
      influenceGranted: resultData.influenceGranted,
      currentQuestionIndex: resultData.currentQuestionIndex,
      roundComplete: resultData.roundComplete,
    }, {
      toolName: 'grade_answer', sessionId: ctx.sessionId,
    });

    const result: ToolResult = {
      success: true,
      data: {
        ...resultData,
        currentStreak: resultData.newStreak,
        message: resultData.isCorrect
          ? `Correct. +${resultData.xpAwarded} XP and +${resultData.influenceGranted} influence.${resultData.territoryExpanded ? ` Territory expanded by ${resultData.sectorsGained}.` : ''}${resultData.roundComplete ? ' The round is complete.' : ''}`
          : `Not quite. The correct answer was ${resultData.correctAnswer}.${resultData.roundComplete ? ' The round is complete.' : ' Move to the next question.'}`,
      },
    };
    setCachedResult(ctx.correlationId, 'grade_answer', result);
    return result;
  },

  async request_round_hint(args, ctx) {
    const cached = getCachedResult(ctx.correlationId, 'request_round_hint');
    if (cached) return cached;

    const activeRound = (args.roundId as string | undefined)
      ? await db.getRound(args.roundId as string)
      : await db.getActiveRound(ctx.userId);
    if (!activeRound) throw new Error('No active round found');

    const hintResult = await rounds.requestRoundHint(ctx.userId, activeRound.id);

    await game.audit(ctx.userId, 'request_round_hint', {
      roundId: hintResult.roundId,
      questionId: hintResult.questionId,
      hintCount: hintResult.hintCount,
    }, {
      toolName: 'request_round_hint', sessionId: ctx.sessionId,
    });

    const result: ToolResult = {
      success: true,
      data: {
        ...hintResult,
        prompt: hintResult.currentQuestion.spokenPhrase ?? hintResult.currentQuestion.text,
        message: `Hint ${hintResult.hintCount}: ${hintResult.hint}`,
      },
    };
    setCachedResult(ctx.correlationId, 'request_round_hint', result);
    return result;
  },

  async request_round_repeat(args, ctx) {
    const cached = getCachedResult(ctx.correlationId, 'request_round_repeat');
    if (cached) return cached;

    const activeRound = (args.roundId as string | undefined)
      ? await db.getRound(args.roundId as string)
      : await db.getActiveRound(ctx.userId);
    if (!activeRound) throw new Error('No active round found');

    const repeatResult = await rounds.requestRoundRepeat(ctx.userId, activeRound.id);

    await game.audit(ctx.userId, 'request_round_repeat', {
      roundId: repeatResult.roundId,
      questionId: repeatResult.questionId,
      repeatCount: repeatResult.repeatCount,
    }, {
      toolName: 'request_round_repeat', sessionId: ctx.sessionId,
    });

    const result: ToolResult = {
      success: true,
      data: {
        ...repeatResult,
        prompt: repeatResult.currentQuestion.spokenPhrase ?? repeatResult.currentQuestion.text,
        message: 'Repeat the current question exactly as returned.',
      },
    };
    setCachedResult(ctx.correlationId, 'request_round_repeat', result);
    return result;
  },

  async award_territory(args, ctx) {
    const cached = getCachedResult(ctx.correlationId, 'award_territory');
    if (cached) return cached;

    // Influence-driven: grant bonus influence and check if threshold triggers expansion
    const bonusInfluence = ((args.sectors as number) || 1) * 250;
    await db.incrementUserInfluence(ctx.userId, bonusInfluence);
    const district = await game.getDistrict(ctx.userId);
    if (district) {
      await db.incrementDistrictInfluence(district.id, bonusInfluence);
    }
    await game.grantReward(ctx.userId, 'influence', bonusInfluence, 'award_territory', ctx.sessionId);

    const growthResult = await game.checkGrowthThreshold(ctx.userId);

    await game.audit(ctx.userId, 'award_territory', {
      bonusInfluence,
      expanded: growthResult.expanded,
      sectorsGained: growthResult.sectorsGained,
    }, {
      toolName: 'award_territory', sessionId: ctx.sessionId,
    });

    if (growthResult.expanded) {
      db.createNotification({
        id: `notif_${randomUUID()}`,
        userId: ctx.userId,
        title: 'Territory expanded!',
        body: `Your district grew by ${growthResult.sectorsGained} sector${growthResult.sectorsGained > 1 ? 's' : ''}. New area: ${growthResult.area}`,
        type: 'territory_expanded',
        createdAt: new Date().toISOString(),
        read: false,
        data: { sectors: growthResult.sectorsGained, totalSectors: growthResult.newTotal },
      }).catch(() => {});
    }

    const result: ToolResult = {
      success: true,
      data: {
        influenceGranted: bonusInfluence,
        territoryExpanded: growthResult.expanded,
        sectorsGained: growthResult.sectorsGained,
        totalSectors: growthResult.newTotal,
        area: growthResult.area,
        influenceRemaining: growthResult.influenceRemaining,
        message: growthResult.expanded
          ? `+${bonusInfluence} influence — Territory expanded by ${growthResult.sectorsGained}!`
          : `+${bonusInfluence} influence — ${growthResult.influenceRemaining} more to next expansion`,
      },
    };
    setCachedResult(ctx.correlationId, 'award_territory', result);
    return result;
  },

  async apply_combo_bonus(args, ctx) {
    const cached = getCachedResult(ctx.correlationId, 'apply_combo_bonus');
    if (cached) return cached;

    const streak = args.streak as number;
    const multiplier = args.multiplier as number;
    const { bonusXp, bonusMaterials } = game.calculateComboBonus(streak, multiplier);

    await db.incrementUserXp(ctx.userId, bonusXp);
    const district = await game.getDistrict(ctx.userId);
    if (district) await db.addResources(district.id, bonusMaterials);

    const influenceGranted = game.calculateInfluenceGrant('combo', 'medium', streak);
    await db.incrementUserInfluence(ctx.userId, influenceGranted);
    if (district) await db.incrementDistrictInfluence(district.id, influenceGranted);

    await game.grantReward(ctx.userId, 'combo', bonusXp, 'apply_combo_bonus', ctx.sessionId);
    await game.grantReward(ctx.userId, 'influence', influenceGranted, 'apply_combo_bonus', ctx.sessionId);

    await game.updatePrestigeIfNeeded(ctx.userId);

    const result: ToolResult = {
      success: true,
      data: {
        bonusXp,
        bonusMaterials,
        influenceGranted,
        message: `🔥 ${streak}x combo! +${bonusXp} XP, +${influenceGranted} influence, and bonus materials!`,
      },
    };
    setCachedResult(ctx.correlationId, 'apply_combo_bonus', result);
    return result;
  },

  async grant_materials(args, ctx) {
    const cached = getCachedResult(ctx.correlationId, 'grant_materials');
    if (cached) return cached;

    const stone = args.stone as number;
    const glass = args.glass as number;
    const wood = args.wood as number;

    const district = await game.getDistrict(ctx.userId);
    if (!district) throw new Error('No district found');

    const effects = await game.getStructureEffects(ctx.userId);
    const boostedStone = Math.floor(stone * effects.materialMultiplier);
    const boostedGlass = Math.floor(glass * effects.materialMultiplier);
    const boostedWood = Math.floor(wood * effects.materialMultiplier);

    await db.addResources(district.id, { stone: boostedStone, glass: boostedGlass, wood: boostedWood });
    await game.grantReward(ctx.userId, 'materials', boostedStone + boostedGlass + boostedWood, 'grant_materials', ctx.sessionId);

    const result: ToolResult = {
      success: true,
      data: {
        stone: boostedStone, glass: boostedGlass, wood: boostedWood,
        message: `📦 Materials granted: ${boostedStone} stone, ${boostedGlass} glass, ${boostedWood} wood`,
      },
    };
    setCachedResult(ctx.correlationId, 'grant_materials', result);
    return result;
  },

  async end_round(args, ctx) {
    const activeRound = (args.roundId as string | undefined)
      ? await db.getRound(args.roundId as string)
      : await db.getActiveRound(ctx.userId);
    if (!activeRound) {
      throw new Error('No round available to finish');
    }

    const summary = await rounds.finishRound(ctx.userId, activeRound.id);

    await game.audit(ctx.userId, 'end_round', {
      roundId: summary.roundId,
      eventId: ctx.eventId,
      totalScore: summary.totalScore,
      questionsAnswered: summary.questionsAnswered,
      correctAnswers: summary.correctAnswers,
      newBadges: summary.newBadges,
    }, {
      toolName: 'end_round', sessionId: ctx.sessionId,
    });

    // Fire notification (non-blocking)
    db.createNotification({
      id: `notif_${randomUUID()}`,
      userId: ctx.userId,
      title: 'Round complete!',
      body: `Great job! You scored ${summary.totalScore} XP this round. Keep it up!`,
      type: 'round_complete',
      createdAt: new Date().toISOString(),
      read: false,
      data: { roundId: summary.roundId, totalScore: summary.totalScore },
    }).catch(() => {});

    return {
      success: true,
      data: {
        ...summary,
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

    const targetPrompt = (args.targetPrompt as string) || 'Show me something interesting around you.';

    return {
      success: true,
      data: {
        questId: quest.id,
        theme: quest.theme,
        targetPrompt,
        message: 'Vision quest started! Show me something interesting.',
      },
    };
  },

  async validate_vision_result(args, ctx) {
    const cached = getCachedResult(ctx.correlationId, 'validate_vision_result');
    if (cached) return cached;

    const confidence = typeof args.confidence === 'number' ? args.confidence : 0;
    const rawValid = typeof args.isValid === 'boolean' ? args.isValid : false;
    const isValid = rawValid && confidence >= 0.5;

    const result = {
      objectIdentified: args.objectIdentified as string,
      confidence,
      isValid,
    };

    let influenceGranted = 0;
    if (result.isValid) {
      await db.incrementUserXp(ctx.userId, 200);
      await game.grantReward(ctx.userId, 'xp', 200, 'validate_vision_result', ctx.sessionId);

      influenceGranted = game.calculateInfluenceGrant('vision_quest', 'medium', 0);
      await db.incrementUserInfluence(ctx.userId, influenceGranted);
      const district = await game.getDistrict(ctx.userId);
      if (district) await db.incrementDistrictInfluence(district.id, influenceGranted);
      await game.grantReward(ctx.userId, 'influence', influenceGranted, 'validate_vision_result', ctx.sessionId);
    }

    await game.updatePrestigeIfNeeded(ctx.userId);

    const toolResult: ToolResult = {
      success: true,
      data: {
        ...result,
        xpAwarded: result.isValid ? 200 : 0,
        influenceGranted,
        message: result.isValid
          ? `Verified: "${result.objectIdentified}"! +200 XP, +${influenceGranted} influence`
          : `Hmm, not quite. Try again!`,
      },
    };
    setCachedResult(ctx.correlationId, 'validate_vision_result', toolResult);
    return toolResult;
  },

  // ─── Structures ──────────────────────────────────
  async unlock_structure(args, ctx) {
    const structureId = args.structureId as string;
    const result = await game.unlockStructure(ctx.userId, structureId);

    await game.grantReward(ctx.userId, 'structure', result.structure.prestigeValue || 1, 'unlock_structure', ctx.sessionId);
    await game.audit(ctx.userId, 'unlock_structure', { structureId }, {
      toolName: 'unlock_structure', sessionId: ctx.sessionId,
    });

    // Fire notification (non-blocking)
    db.createNotification({
      id: `notif_${randomUUID()}`,
      userId: ctx.userId,
      title: 'New structure unlocked!',
      body: `${result.structure.name} has been built in your district.`,
      type: 'structure_unlocked',
      createdAt: new Date().toISOString(),
      read: false,
      data: { structureId, structureName: result.structure.name },
    }).catch(() => {});

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
