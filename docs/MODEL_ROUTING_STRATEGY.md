# Model Routing Strategy

Centralized model registry in `backend/src/config/models.ts`. All model IDs are env-configurable.

## Active Model Roles

| Role | Default Model | Env Override | Cost Tier | Fallback |
|------|--------------|-------------|-----------|----------|
| `LIVE_REALTIME` | `gemini-2.5-flash-native-audio-preview-12-2025` | `GEMINI_LIVE_MODEL` | medium | `gemini-2.0-flash-live-001` |
| `ASYNC_CHALLENGE` | `gemini-2.5-flash` | `GEMINI_MODEL` | medium | `gemini-2.0-flash` |
| `LOW_COST_UTILITY` | `gemini-2.5-flash-lite` | `GEMINI_UTILITY_MODEL` | low | `gemini-2.5-flash-lite` |

## Task-to-Model Mapping

| Task | Model Role | Why | Cost Note |
|------|-----------|-----|-----------|
| Live onboarding voice | LIVE_REALTIME | Native audio streaming required | ~$0.002/turn |
| Live quiz voice | LIVE_REALTIME | Real-time voice + tool calling | ~$0.002/turn |
| Live vision quest | LIVE_REALTIME | Real-time voice + image input | ~$0.003/turn (image tokens) |
| Challenge generation (future) | ASYNC_CHALLENGE | Needs reasoning for quality questions | Batch-friendly |
| Hint generation | LIVE_REALTIME (inline) | Part of live conversation flow | Included in session |
| Event copy (future) | LOW_COST_UTILITY | Simple text transforms | Very cheap |
| Badge/reward text (future) | LOW_COST_UTILITY | Template-like generation | Very cheap |
| Profile summaries (future) | LOW_COST_UTILITY | Short, formulaic text | Very cheap |
| Moderation (future) | LOW_COST_UTILITY | Classification task | Very cheap |

## Rules
1. Every model name comes from `MODEL_REGISTRY` or env override — never hardcoded
2. `getModelId(role)` is the only accessor for model IDs in backend code
3. `getModelWithFallback(role)` returns both primary and fallback for resilient use
4. `logActiveModels()` prints config at startup for deployment verification
5. Client receives model ID from backend token response — no client-side model strings
