/**
 * Centralized AI Model Registry
 *
 * All model references go through this module.
 * No scattered hardcoded model names anywhere else.
 *
 * Roles:
 *   LIVE_REALTIME   — Gemini Live native-audio model for voice sessions
 *   ASYNC_CHALLENGE — Fast async model for challenge generation, grading support
 *   LOW_COST_UTILITY — Cheapest model for summaries, categorization, copy variants
 *
 * Migration notes:
 *   - gemini-2.0-flash-exp was a preview model, shut down in early 2025
 *   - gemini-2.0-flash-live-001 remains the stable Live API model
 *   - gemini-2.5-flash is the current recommended async model (GA)
 *   - gemini-2.5-flash-lite is available for low-cost tasks
 */

export interface ModelConfig {
  id: string;
  role: string;
  description: string;
  fallback?: string;
  costTier: 'low' | 'medium' | 'high';
}

// ─── Model Definitions ──────────────────────────────────

export const MODEL_REGISTRY: Record<string, ModelConfig> = {
  LIVE_REALTIME: {
    id: process.env.GEMINI_LIVE_MODEL || 'gemini-2.0-flash-live-001',
    role: 'Live voice+vision sessions',
    description: 'Native audio model for real-time voice interaction via Gemini Live API',
    fallback: 'gemini-2.0-flash-live-001',
    costTier: 'medium',
  },
  ASYNC_CHALLENGE: {
    id: process.env.GEMINI_MODEL || 'gemini-2.5-flash',
    role: 'Challenge generation and async grading',
    description: 'Fast async model for generating quiz questions, event copy, and grading support',
    fallback: 'gemini-2.0-flash',
    costTier: 'medium',
  },
  LOW_COST_UTILITY: {
    id: process.env.GEMINI_UTILITY_MODEL || 'gemini-2.5-flash-lite',
    role: 'Summaries, categorization, copy variants',
    description: 'Cheapest model for lightweight tasks that do not require deep reasoning',
    fallback: 'gemini-2.0-flash-lite',
    costTier: 'low',
  },
};

// ─── Accessors ──────────────────────────────────────────

/** Get model ID by role. Throws if role is unknown. */
export function getModelId(role: keyof typeof MODEL_REGISTRY): string {
  const entry = MODEL_REGISTRY[role];
  if (!entry) throw new Error(`Unknown model role: ${role}`);
  return entry.id;
}

/** Get the live realtime model ID. */
export const LIVE_MODEL = MODEL_REGISTRY.LIVE_REALTIME.id;

/** Get the async challenge model ID. */
export const ASYNC_MODEL = MODEL_REGISTRY.ASYNC_CHALLENGE.id;

/** Get the low-cost utility model ID. */
export const UTILITY_MODEL = MODEL_REGISTRY.LOW_COST_UTILITY.id;

/** Get model ID with its fallback for resilient selection. */
export function getModelWithFallback(role: keyof typeof MODEL_REGISTRY): { primary: string; fallback: string } {
  const entry = MODEL_REGISTRY[role];
  if (!entry) throw new Error(`Unknown model role: ${role}`);
  return { primary: entry.id, fallback: entry.fallback ?? entry.id };
}

/** Log active model configuration at startup. */
export function logActiveModels(): void {
  console.log('═══ Active AI Models ═══');
  for (const [role, cfg] of Object.entries(MODEL_REGISTRY)) {
    console.log(`  ${role}: ${cfg.id} (${cfg.costTier}) → fallback: ${cfg.fallback ?? 'none'}`);
  }
  console.log('════════════════════════');
}
