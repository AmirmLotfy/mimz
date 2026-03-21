import { config } from '../../config/index.js';
import { LIVE_MODEL } from '../../config/models.js';
import { randomUUID } from 'crypto';
import * as db from '../../lib/db.js';
import { GoogleAuth } from 'google-auth-library';

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
  districtName?: string,
  eventContext?: { title: string; description: string },
): string {
  const name = displayName || 'Explorer';
  const difficulty = difficultyPreference || 'dynamic';

  const interestLine =
    interests && interests.length > 0
      ? `Their learning interests include: ${interests.slice(0, 5).join(', ')}.`
      : 'They have broad interests — pick varied topics.';

  const difficultyLine =
    difficulty === 'easy'
      ? 'Use easy questions. Keep the energy light.'
      : difficulty === 'hard'
        ? 'Use hard questions. They want a real challenge.'
        : 'Use a mix of medium and hard questions. Keep it dynamic.';

  const districtLine = name !== 'Explorer'
    ? `Their district is called "${districtName || 'unnamed'}". Reference it occasionally.`
    : '';

  if (sessionType === 'onboarding') {
    return `You are Mimz, a warm and curious AI guide welcoming ${name} into the world they just created.

BEHAVIOR:
- Greet them by name: "${name}"
- Give a short premium voice welcome to their district
- Reference their interests and district identity if available
- Do not ask onboarding questions
- Do not collect profile data or rename their district
- Deliver one concise welcome turn, then stop talking
- If the user speaks, answer briefly and guide them back to the world map

VOICE STYLE: Friendly, editorial, slightly playful. Never robotic. Max 2 sentences per turn.`;
  }

  if (sessionType === 'vision_quest') {
    return `You are Mimz, guiding ${name} through a visual exploration challenge.

BEHAVIOR:
- Call start_vision_quest to begin
- Ask them to show you something specific
- When you receive an image, analyze it carefully
- Call validate_vision_result with the questId, what you identified, and a confidence estimate
- The backend decides whether the observation counts and awards the rewards
- Guide toward 3 discoveries per quest
- Be genuinely curious about what they show you

VOICE STYLE: Curious, observant, appreciative. Max 2 sentences per turn.`;
  }

  if (sessionType === 'sprint') {
    return `You are Mimz, running a Daily Sprint for ${name}.

PLAYER CONTEXT:
- ${interestLine}
- ${difficultyLine}${districtLine ? `\n- ${districtLine}` : ''}

STRICT RULES — SPRINT MODE:
- Call start_live_round immediately with mode "sprint"
- Ask the exact currentQuestion returned by the tool
- Ask ONLY 3 questions total — fast, punchy, no filler
- After each answer: call grade_answer immediately with the backend questionId
- If the player asks for a hint, call request_round_hint and use the returned hint
- If the player asks you to repeat, call request_round_repeat and repeat the exact currentQuestion
- The backend decides correctness, rewards, territory, and combo state
- If grade_answer returns nextQuestion, ask that exact question next
- If grade_answer returns roundComplete=true, call end_round immediately
- Total session must be under 2 minutes. Speed is the game.

VOICE STYLE: Lightning-fast, punchy. Think quiz show buzzers.`;
  }

  if (sessionType === 'event' && eventContext) {
    return `You are Mimz, hosting a special event challenge: "${eventContext.title}".
${eventContext.description ? eventContext.description + '\n' : ''}
PLAYER CONTEXT:
- Player: ${name}
- ${interestLine}
- ${difficultyLine}${districtLine ? `\n- ${districtLine}` : ''}

STRICT BEHAVIOR RULES:
- Call start_live_round immediately with mode "event" and topic "${eventContext.title}"
- Ask the exact currentQuestion returned by the tool
- Ask 5 questions themed around this event
- Call grade_answer after every answer with the backend questionId
- If the player asks for a hint, call request_round_hint and use the returned hint
- If the player asks you to repeat, call request_round_repeat and repeat the exact currentQuestion
- The backend decides correctness, rewards, territory, and combo state
- If grade_answer returns nextQuestion, ask that exact question next
- If grade_answer returns roundComplete=true, call end_round immediately
- Keep total speaking time per turn under 3 seconds

VOICE STYLE: High-energy, competitive, event-specific. Make it feel like a special occasion.`;
  }

  // Default: quiz
  return `You are Mimz, the live game host playing with ${name}.

PLAYER CONTEXT:
- ${interestLine}
- ${difficultyLine}${districtLine ? `\n- ${districtLine}` : ''}

STRICT BEHAVIOR RULES:
- Call start_live_round immediately to begin
- Pick topics from their interests when possible
- Ask the exact currentQuestion returned by the tool
- Wait for their spoken answer before calling grade_answer
- ALWAYS call grade_answer after every answer with the backend questionId
- If the player explicitly asks for a hint, call request_round_hint and use the backend hint
- If the player asks you to repeat, call request_round_repeat and repeat the exact currentQuestion
- The backend decides correctness, rewards, territory, combo, and next question
- If grade_answer returns nextQuestion, ask that exact question next
- If grade_answer returns roundComplete=true, call end_round immediately
- Keep total speaking time per turn under 3 seconds

VOICE STYLE: High-energy, smart, warm. Think editorial podcast host. Never robotic. Never verbose.`;
}

const getCurrentDistrictTool = {
  name: 'get_current_district',
  description: "Get the player's current district state including structures and resources.",
  parameters: { type: 'object', properties: {} },
};

const startLiveRoundTool = {
  name: 'start_live_round',
  description: 'Start a new backend-authored round and receive the exact question to ask next.',
  parameters: {
    type: 'object',
    properties: {
      topic: { type: 'string', description: 'Quiz topic' },
      difficulty: { type: 'string', enum: ['easy', 'dynamic', 'hard'] },
      mode: { type: 'string', enum: ['quiz', 'sprint', 'event'] },
      eventId: { type: 'string', description: 'Optional event identifier for event mode' },
    },
  },
};

const gradeAnswerTool = {
  name: 'grade_answer',
  description: "Submit a player's spoken answer for backend-authoritative grading.",
  parameters: {
    type: 'object',
    properties: {
      answer: { type: 'string', description: "The player's spoken answer" },
      questionId: { type: 'string', description: 'Question identifier returned by start_live_round or a previous grade_answer result' },
    },
    required: ['answer'],
  },
};

const requestHintTool = {
  name: 'request_round_hint',
  description: 'Fetch a backend-authored hint for the current round question.',
  parameters: {
    type: 'object',
    properties: {
      roundId: { type: 'string', description: 'Optional current round identifier' },
    },
  },
};

const requestRepeatTool = {
  name: 'request_round_repeat',
  description: 'Fetch the exact current round question again so you can repeat it accurately.',
  parameters: {
    type: 'object',
    properties: {
      roundId: { type: 'string', description: 'Optional current round identifier' },
    },
  },
};

const endRoundTool = {
  name: 'end_round',
  description: 'End the current quiz round and show summary.',
  parameters: {
    type: 'object',
    properties: {
      totalScore: { type: 'number' },
      questionsAnswered: { type: 'number' },
    },
  },
};

const startVisionQuestTool = {
  name: 'start_vision_quest',
  description: 'Begin a vision quest challenge.',
  parameters: {
    type: 'object',
    properties: {
      theme: { type: 'string', description: 'Vision quest theme' },
    },
  },
};

const validateVisionResultTool = {
  name: 'validate_vision_result',
  description: 'Submit a vision quest observation for backend validation.',
  parameters: {
    type: 'object',
    properties: {
      questId: { type: 'string' },
      objectIdentified: { type: 'string' },
      confidence: { type: 'number' },
    },
    required: ['questId', 'objectIdentified'],
  },
};

function buildToolDeclarations(sessionType: string) {
  if (sessionType === 'onboarding') {
    return [];
  }

  if (sessionType === 'vision_quest') {
    return [
      {
        functionDeclarations: [
          getCurrentDistrictTool,
          startVisionQuestTool,
          validateVisionResultTool,
        ],
      },
    ];
  }

  return [
    {
      functionDeclarations: [
        getCurrentDistrictTool,
        startLiveRoundTool,
        gradeAnswerTool,
        requestHintTool,
        requestRepeatTool,
        endRoundTool,
      ],
    },
  ];
}

// ─── Session Tracking ──────────────────────────────────

interface LiveSession {
  sessionId: string;
  userId: string;
  sessionType: string;
  model: string;
  createdAt: string;
  expiresAt: string;
  eventId?: string;
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
export function isSessionValid(sessionId: string, userId?: string): boolean {
  const session = activeSessions.get(sessionId);
  if (!session) return false;
  if (userId && session.userId !== userId) return false;
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
export function getSessionEventId(sessionId: string): string | undefined {
  return activeSessions.get(sessionId)?.eventId;
}

export async function mintEphemeralToken(userId: string, sessionType: string, eventId?: string) {
  let token: string;
  let authType: 'api_key' | 'bearer';
  let websocketUrl: string;
  let model = LIVE_MODEL;

  if (config.geminiAuthMode === 'vertex') {
    // Use Cloud Run service account / ADC to mint an OAuth token for Vertex AI Live.
    const auth = new GoogleAuth({
      scopes: ['https://www.googleapis.com/auth/cloud-platform'],
    });
    const accessToken = await auth.getAccessToken();
    if (!accessToken) {
      throw new Error('Vertex auth failed: could not mint access token.');
    }
    token = accessToken;
    authType = 'bearer';
    const liveLocation = config.geminiLiveVertexLocation || config.geminiVertexLocation;
    websocketUrl =
      `wss://${liveLocation}-aiplatform.googleapis.com/ws/` +
      'google.cloud.aiplatform.v1.LlmBidiService/BidiGenerateContent';

    // Vertex AI expects full model resource path.
    if (!model.startsWith('projects/')) {
      model =
        `projects/${config.gcpProjectId}/locations/${liveLocation}/` +
        `publishers/google/models/${model}`;
    }
  } else {
    if (!config.geminiApiKey || config.geminiApiKey === 'dev-key-replace-me') {
      throw new Error('GEMINI_API_KEY is not configured for live sessions.');
    }
    token = config.geminiApiKey;
    authType = 'api_key';
    websocketUrl =
      'wss://generativelanguage.googleapis.com/ws/' +
      'google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent';
  }

  const sessionId = `ses_${randomUUID()}`;
  const expiresAt = new Date(Date.now() + config.ephemeralTokenTtlMs).toISOString();

  // Load user profile for personalization
  let displayName: string | undefined;
  let interests: string[] | undefined;
  let difficultyPreference: string | undefined;
  let districtName: string | undefined;

  if (userId) {
    try {
      const user = await db.getUser(userId);
      if (user) {
        displayName = user.displayName;
        interests = user.interests;
        difficultyPreference = user.difficultyPreference;
        districtName = user.districtName;
      }
    } catch {
      // Non-fatal — fall back to generic persona
    }
  }

  let eventContext: { title: string; description: string } | undefined;
  if (sessionType === 'event' && eventId) {
    try {
      const event = await db.getEvent(eventId);
      if (event) {
        eventContext = { title: event.title, description: event.description ?? '' };
      }
    } catch {
      // Non-fatal — use generic event instruction
    }
  }

  const systemInstruction = buildPersonalizedInstruction(
    sessionType,
    displayName,
    interests,
    difficultyPreference,
    districtName,
    eventContext,
  );

  const session: LiveSession = {
    sessionId,
    userId,
    sessionType,
    model,
    createdAt: new Date().toISOString(),
    expiresAt,
    eventId,
  };

  activeSessions.set(sessionId, session);

  return {
    token,
    authType,
    websocketUrl,
    sessionId,
    model,
    expiresAt,
    systemInstruction,
    tools: buildToolDeclarations(sessionType),
  };
}

/**
 * Validate that Vertex Live API credentials are available at startup.
 * Call this when geminiAuthMode === 'vertex' to fail fast with a clear log.
 */
export async function validateVertexLiveConfig(): Promise<void> {
  if (config.geminiAuthMode !== 'vertex') return;
  const auth = new GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  });
  try {
    const token = await auth.getAccessToken();
    if (!token) throw new Error('No token returned');
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    throw new Error(
      `Vertex Live API config invalid: ${msg}. ` +
        'Ensure GCP_PROJECT_ID and service account (ADC) have Vertex AI access.',
    );
  }
}
