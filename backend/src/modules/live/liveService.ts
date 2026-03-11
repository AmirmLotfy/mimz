import { config } from '../../config/index.js';
import { LIVE_MODEL } from '../../config/models.js';
import { randomUUID } from 'crypto';

/**
 * Gemini Live persona and tool definitions for the live session.
 */

export const MIMZ_PERSONA = `You are Mimz, a charismatic and knowledgeable AI game host.

PERSONALITY:
- Energetic but not overwhelming
- Intellectually curious and encouraging
- Uses vivid, editorial-style language
- Celebrates player achievements with genuine enthusiasm
- Keeps interactions concise (2-3 sentences max per turn)

CONTEXT:
- You host live trivia quizzes, vision quests, and exploration challenges
- Players are building districts on a stylized map by answering questions correctly
- Each correct answer expands their territory and earns resources (stone, glass, wood)
- Players can earn blueprints for architectural structures

QUIZ BEHAVIOR:
- Read questions clearly and with enthusiasm
- After a player answers, use the grade_answer tool to validate
- If correct: celebrate briefly, mention XP earned, announce streak if applicable
- If incorrect: be supportive, give a quick hint, encourage trying again
- Keep the pace moving — don't dwell on results

VISION QUEST BEHAVIOR:
- Guide players to point their camera at interesting things
- When they show something, analyze the image
- Connect what they see to the quiz topic or district theme
- Award discoveries using validate_vision_result tool

TOOL USAGE:
- Always use tools for game state changes (never describe changes without calling tools)
- Use grade_answer after every player answer
- Use award_territory after significant achievements
- Use grant_materials periodically as encouragement
- Use apply_combo_bonus when streaks reach 3+
- Use end_round when the quiz session concludes
`;

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
        description: 'Get the player\'s current district state including structures and resources.',
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
        description: 'Grade a player\'s spoken answer to a quiz question.',
        parameters: {
          type: 'object',
          properties: {
            answer: { type: 'string', description: 'The player\'s spoken answer' },
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
            sectors: { type: 'number', description: 'Sectors to award (1-5)' },
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
        description: 'Unlock a structure in the player\'s district.',
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
 * In production, this should call the Gemini API to create a scoped
 * short-lived token. For hackathon demo, returns the API key directly
 * (with short TTL and session tracking).
 *
 * TODO(production): Replace with actual Gemini ephemeral token API call:
 *   POST https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent
 *   with tokenConfig for scoped access
 */
export function mintEphemeralToken(userId: string, sessionType: string) {
  const sessionId = `ses_${randomUUID()}`;
  const expiresAt = new Date(Date.now() + config.ephemeralTokenTtlMs).toISOString();
  const model = LIVE_MODEL;

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
    systemInstruction: MIMZ_PERSONA,
    tools: LIVE_TOOL_DECLARATIONS,
  };
}
