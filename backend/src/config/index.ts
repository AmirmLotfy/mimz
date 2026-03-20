import { z } from 'zod';

// ─── Config schema with runtime validation ──────────────

const ConfigSchema = z.object({
  port: z.coerce.number().int().min(1).max(65535).default(8080),
  nodeEnv: z.enum(['development', 'production', 'test']).default('development'),
  logLevel: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace']).default('info'),

  // Rate limiting
  rateLimitMax: z.coerce.number().int().min(1).default(100),
  rateLimitWindow: z.string().default('1 minute'),
  allowDevAuthBypass: z.coerce.boolean().default(false),

  // Firebase / GCP
  gcpProjectId: z.string().min(1),
  firebaseProjectId: z.string().min(1).optional(),
  firestoreDatabase: z.string().default('(default)'),
  storageBucket: z.string().optional(),

  // Gemini
  geminiAuthMode: z.enum(['vertex', 'api_key']).default('vertex'),
  geminiApiKey: z.string().optional(),
  geminiVertexLocation: z.string().default('europe-west1'),
  geminiLiveVertexLocation: z.string().default('us-central1'),
  geminiModel: z.string().default('gemini-2.5-flash'),
  geminiLiveModel: z.string().default('gemini-live-2.5-flash-native-audio'),
  geminiUtilityModel: z.string().default('gemini-2.5-flash-lite'),
  geminiImageModel: z.string().default('gemini-2.5-flash-image-preview'),

  // Token
  ephemeralTokenTtlMs: z.coerce.number().int().default(5 * 60 * 1000), // 5 minutes

  // Abuse protection
  maxRewardPerHour: z.coerce.number().int().default(5000),
  maxSectorsPerRound: z.coerce.number().int().default(3),
  maxStreakBonus: z.coerce.number().int().default(10),
});

function loadConfig() {
  const nodeEnv = process.env.NODE_ENV ?? 'development';
  const isProd = nodeEnv === 'production';

  const raw = {
    port: process.env.PORT,
    nodeEnv,
    logLevel: process.env.LOG_LEVEL,
    rateLimitMax: process.env.RATE_LIMIT_MAX,
    rateLimitWindow: process.env.RATE_LIMIT_WINDOW,
    allowDevAuthBypass: process.env.ALLOW_DEV_AUTH_BYPASS,
    gcpProjectId: process.env.GCP_PROJECT_ID ?? process.env.GOOGLE_CLOUD_PROJECT ?? (isProd ? '' : 'mimz-dev'),
    firebaseProjectId: process.env.FIREBASE_PROJECT_ID,
    firestoreDatabase: process.env.FIRESTORE_DATABASE,
    storageBucket: process.env.STORAGE_BUCKET,
    geminiAuthMode: process.env.GEMINI_AUTH_MODE,
    geminiApiKey: process.env.GEMINI_API_KEY,
    geminiVertexLocation: process.env.GEMINI_VERTEX_LOCATION,
    geminiLiveVertexLocation:
      process.env.GEMINI_LIVE_VERTEX_LOCATION ?? process.env.GEMINI_VERTEX_LOCATION,
    geminiModel: process.env.GEMINI_MODEL,
    geminiLiveModel: process.env.GEMINI_LIVE_MODEL,
    geminiUtilityModel: process.env.GEMINI_UTILITY_MODEL,
    geminiImageModel: process.env.GEMINI_IMAGE_MODEL,
    ephemeralTokenTtlMs: process.env.EPHEMERAL_TOKEN_TTL_MS,
    maxRewardPerHour: process.env.MAX_REWARD_PER_HOUR,
    maxSectorsPerRound: process.env.MAX_SECTORS_PER_ROUND,
    maxStreakBonus: process.env.MAX_STREAK_BONUS,
  };

  const result = ConfigSchema.safeParse(raw);
  if (!result.success) {
    console.error('❌ Invalid configuration:', result.error.format());
    // Don't crash in dev — just warn
    if (process.env.NODE_ENV === 'production') {
      process.exit(1);
    }
  }

  return result.success ? result.data : ConfigSchema.parse({
    ...raw,
    gcpProjectId: raw.gcpProjectId || (isProd ? '' : 'mimz-dev'),
    geminiApiKey: raw.geminiApiKey || (isProd ? undefined : 'dev-key-replace-me'),
  });
}

export const config = loadConfig();

if (config.nodeEnv === 'production') {
  if (!config.gcpProjectId?.trim()) {
    console.error('❌ Production requires GCP_PROJECT_ID');
    process.exit(1);
  }
  if (config.geminiAuthMode !== 'vertex') {
    console.error('❌ Production requires GEMINI_AUTH_MODE=vertex to avoid exposing API keys to clients');
    process.exit(1);
  }
  if (config.allowDevAuthBypass) {
    console.error('❌ Production must not enable ALLOW_DEV_AUTH_BYPASS');
    process.exit(1);
  }
}

export type Config = z.infer<typeof ConfigSchema>;
