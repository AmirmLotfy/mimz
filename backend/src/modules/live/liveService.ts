import { config } from '../../config/index.js';
import { LIVE_MODEL } from '../../config/models.js';
import { randomUUID } from 'crypto';
import * as db from '../../lib/db.js';

/**
 * Gemini Live persona and tool definitions for the live session.
 */

/**
 * Build a personalized system instruction for the given user.
 *
 * Injects name, interests, and difficulty so Gemini speaks to the
 * specific player rather than using a generic prompt.
 */
export function buildPersonalizedInstruction(
  sessionType: string,
  displayName?: string,
  interests?: string[],
  difficultyPreference?: string,
): string {
  const name = displayName || 'Explorer';
  const difficulty = difficultyPreference || 'dynamic';

  const interestLine =
    interests && interests.length > 0
      ? `Their learning interests include: ${interests.slice(0, 5).join(', ')}.`
      : 'They have broad interests — pick varied topics.';

  const difficultyLine =
    difficulty === 'casual'
      ? 'Use easy questions. Keep the energy light.'
      : difficulty === 'challenger'
        ? 'Use hard questions. They want a real challenge.'
        : 'Use a mix of medium and hard questions. Keep it dynamic.';

  if (sessionType === 'onboarding') {
    return `You are Mimz, a warm and curious AI guide helping ${name} set up their district.

BEHAVIOR:
- Greet them by name: "${name}"
- Ask about their interests conversationally (don't list options)
- Ask what they'd like to name their district
- Keep it to 3-4 exchanges maximum
- Be genuinely interested, not scripted
- When done, call start_onboarding, then save_user_profile with collected info

VOICE STYLE: Friendly, editorial, slightly playful. Never robotic. Max 2 sentences per turn.`;
  }

  if (sessionType === 'vision_quest') {
    return `You are Mimz, guiding ${name} through a visual exploration challenge.

BEHAVIOR:
- Call start_vision_quest to begin
- Ask them to show you something specific
- When you receive an image, analyze it carefully
- Call validate_vision_result with your honest assessment
- If valid: celebrate and call grant_materials
- Guide toward 3 discoveries per quest
- Be genuinely curious about what they show you

VOICE STYLE: Curious, observant, appreciative. Max 2 sentences per turn.`;
  }

  // Default: quiz
  return `You are Mimz, the live game host playing with ${name}.

PLAYER CONTEXT:
- ${interestLine}
- ${difficultyLine}

STRICT BEHAVIOR RULES:
- Call start_live_round immediately to begin
- Pick topics from their interests when possible
- Ask one question at a time — read it clearly and completely
- Wait for their spoken answer before calling grade_answer
- ALWAYS call grade_answer after every answer (never skip)
- If correct: celebrate in one sentence, then call award_territory (1-2 sectors) and grant_materials
- If streak ≥ 3: also call apply_combo_bonus
- If incorrect: one supportive sentence, then move to the next question
- After 5 questions, call end_round with the summary
- Keep total speaking time per turn under 3 seconds

VOICE STYLE: High-energy, smart, warm. Think editorial podcast host. Never robotic. Never verbose.`;
}

export const LIVE_TOOL_DECLARATIONS = [
  {
    functionDeclarations: [
      {
        name: 'start_onboarding',
        description: 'Begin the onboarding sequence for a new player.',
        parameters: { type: 'object', properties: {} },
      },
      {
        name: 'save_user_profile',
        description: 'Save user profile data collected during onboarding.',
        parameters: {
          type: 'object',
          properties: {
            displayName: { type: 'string', description: 'Player display name' },
            districtName: { type: 'string', description: 'Name of their district' },
            interests: { type: 'array', items: { type: 'string' }, description: 'Learning interests' },
          },
        },
      },
      {
        name: 'get_current_district',
        description: "Get the player's current district state including structures and resources.",
        parameters: { type: 'object', properties: {} },
      },
      {
        name: 'start_live_round',
        description: 'Start a new quiz round with a topic and difficulty.',
        parameters: {
          type: 'object',
          properties: {
            topic: { type: 'string', description: 'Quiz topic' },
            difficulty: { type: 'string', enum: ['easy', 'medium', 'hard'] },
          },
          required: ['topic'],
        },
      },
      {
        name: 'grade_answer',
        description: "Grade a player's spoken answer to a quiz question.",
        parameters: {
          type: 'object',
          properties: {
            answer: { type: 'string', description: "The player's spoken answer" },
            questionId: { type: 'string', description: 'Question identifier' },
            isCorrect: { type: 'boolean', description: 'Whether the answer is correct' },
            confidence: { type: 'number', description: 'Confidence 0-1' },
            pointsAwarded: { type: 'number', description: 'Points to award' },
          },
          required: ['answer', 'isCorrect'],
        },
      },
      {
        name: 'award_territory',
        description: 'Award territory sectors to the player.',
        parameters: {
          type: 'object',
          properties: {
            sectors: { type: 'number', description: 'Sectors to award (1-3)' },
          },
          required: ['sectors'],
        },
      },
      {
        name: 'apply_combo_bonus',
        description: 'Apply a streak combo bonus.',
        parameters: {
          type: 'object',
          properties: {
            streak: { type: 'number', description: 'Current streak count' },
            multiplier: { type: 'number', description: 'Bonus multiplier (1-5)' },
          },
          required: ['streak'],
        },
      },
      {
        name: 'grant_materials',
        description: 'Grant building materials to the player.',
        parameters: {
          type: 'object',
          properties: {
            stone: { type: 'number' }, glass: { type: 'number' }, wood: { type: 'number' },
          },
        },
      },
      {
        name: 'end_round',
        description: 'End the current quiz round and show summary.',
        parameters: {
          type: 'object',
          properties: {
            totalScore: { type: 'number' },
            questionsAnswered: { type: 'number' },
          },
        },
      },
      {
        name: 'start_vision_quest',
        description: 'Begin a vision quest challenge.',
        parameters: {
          type: 'object',
          properties: {
            theme: { type: 'string', description: 'Vision quest theme' },
          },
        },
      },
      {
        name: 'validate_vision_result',
        description: 'Validate what the camera captured during vision quest.',
        parameters: {
          type: 'object',
          properties: {
            objectIdentified: { type: 'string' },
            confidence: { type: 'number' },
            isValid: { type: 'boolean' },
          },
          required: ['objectIdentified'],
        },
      },
      {
        name: 'unlock_structure',
        description: "Unlock a structure in the player's district.",
        parameters: {
          type: 'object',
          properties: {
            structureId: { type: 'string' },
            structureName: { type: 'string' },
            tier: { type: 'string', enum: ['common', 'rare', 'master'] },
          },
          required: ['structureId'],
        },
      },
      {
        name: 'join_squad_mission',
        description: 'Join a squad mission.',
        parameters: {
          type: 'object',
          properties: { missionId: { type: 'string' } },
          required: ['missionId'],
        },
      },
      {
        name: 'contribute_squad_progress',
        description: 'Contribute progress to a squad mission.',
        parameters: {
          type: 'object',
          properties: {
            missionId: { type: 'string' },
            amount: { type: 'number' },
          },
          required: ['missionId', 'amount'],
        },
      },
      {
        name: 'get_event_state',
        description: 'Get current event state.',
        parameters: {
          type: 'object',
          properties: { eventId: { type: 'string' } },
          required: ['eventId'],
        },
      },
    ],
  },
];

// ─── Session Tracking ──────────────────────────────────

interface LiveSession {
  sessionId: string;
  userId: string;
  sessionType: string;
  model: string;
  createdAt: string;
  expiresAt: string;
}

/** In-memory session tracker. Cleared on restart (acceptable for hackathon). */
const activeSessions = new Map<string, LiveSession>();

/** Clean up expired sessions periodically. */
setInterval(() => {
  const now = Date.now();
  for (const [id, session] of activeSessions) {
    if (new Date(session.expiresAt).getTime() < now) {
      activeSessions.delete(id);
    }
  }
}, 60_000);

/** Check if a session ID is valid and active. */
export function isSessionValid(sessionId: string): boolean {
  const session = activeSessions.get(sessionId);
  if (!session) return true; // Allow unknown sessions in dev/demo mode
  return new Date(session.expiresAt).getTime() > Date.now();
}

/**
 * Mint an ephemeral session token.
 *
 * Reads the user's profile to inject personalized system instruction
 * so Gemini speaks to the specific player by name with their interests.
 *
 * In production, swap `config.geminiApiKey` for actual Gemini ephemeral
 * token API call, which scopes the key to this session and model only.
 */
export async function mintEphemeralToken(userId: string, sessionType: string) {
  if (!config.geminiApiKey || config.geminiApiKey === 'dev-key-replace-me') {
    throw new Error('GEMINI_API_KEY is not configured for live sessions.');
  }

  const sessionId = `ses_${randomUUID()}`;
  const expiresAt = new Date(Date.now() + config.ephemeralTokenTtlMs).toISOString();
  const model = LIVE_MODEL;

  // Load user profile for personalization
  let displayName: string | undefined;
  let interests: string[] | undefined;
  let difficultyPreference: string | undefined;

  if (userId) {
    try {
      const user = await db.getUser(userId);
      if (user) {
        displayName = user.displayName;
        interests = user.interests;
        difficultyPreference = user.difficultyPreference;
      }
    } catch {
      // Non-fatal — fall back to generic persona
    }
  }

  const systemInstruction = buildPersonalizedInstruction(
    sessionType,
    displayName,
    interests,
    difficultyPreference,
  );

  const session: LiveSession = {
    sessionId,
    userId,
    sessionType,
    model,
    createdAt: new Date().toISOString(),
    expiresAt,
  };

  activeSessions.set(sessionId, session);

  return {
    token: config.geminiApiKey, // Production: use Gemini ephemeral token endpoint
    sessionId,
    model,
    expiresAt,
    systemInstruction,
    tools: LIVE_TOOL_DECLARATIONS,
  };
}
