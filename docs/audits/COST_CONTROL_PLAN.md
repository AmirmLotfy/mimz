# Cost Control Plan

## Live Session Budget Rules

| Rule | Implementation |
|------|---------------|
| No always-on sessions | Sessions require explicit `startOnboardingSession()` / `startQuizSession()` / `startVisionQuestSession()` |
| Max session duration | 5 min (onboarding/vision), 10 min (quiz) — auto-closed by timer |
| Inactivity timeout | 2-5 min per mode — warns then closes |
| Session teardown on exit | `endSession()` cancels all subscriptions + closes WebSocket |
| Debounced commands | 2-second cooldown on hint/repeat/difficulty requests |
| Hint cap | Max 3 hints per round (silently capped, logged) |
| Repeat cap | Max 5 repeats per round |

## Image/Frame Usage Rules

| Rule | Value |
|------|-------|
| Camera only in vision quest mode | `enableCamera: true` only on `visionQuest` config |
| Minimum frame interval | 2 seconds (enforced floor) |
| Max frames per session | 20 (vision quest), 30 (default) |
| Frame quality | JPEG 70%, max 640px dimension |
| Frame cap enforcement | `LiveCameraStreamService` auto-stops periodic capture at cap |

## Async Generation Rules

| Rule | Implementation |
|------|---------------|
| Use cheapest model for utility tasks | `LOW_COST_UTILITY` role → `gemini-2.5-flash-lite` |
| Reserve reasoning model for generation | `ASYNC_CHALLENGE` role → `gemini-2.5-flash` |
| Prompt deduplication | Backend provides base persona, app adds mode-specific behavior |
| Tool response trimming | `toModelPayload()` strips human-readable `message` from model context |

## Backend/Network Rules

| Rule | Implementation |
|------|---------------|
| Rate limiting | `@fastify/rate-limit` at 100 req/min (configurable) |
| Request body limit | 1MB max |
| Request timeout | 30s server-side |
| Abuse protection | `maxRewardPerHour: 5000`, `maxSectorsPerRound: 3`, `maxStreakBonus: 10` |
| Audit logging | All tool executions logged with correlation IDs |
| No giant payload logs | Logger avoids raw audio/image dumps |

## Cost Estimates (Hackathon Demo)

| Component | Estimated Cost |
|-----------|---------------|
| Gemini Live sessions (10 demos × 5 min) | ~$2-5 |
| Backend (Cloud Run) | ~$1-3 |
| Firestore reads/writes | ~$0.50 |
| **Total demo budget** | **~$5-10** |

## Future Scale Notes
- Implement per-user session rate limiting (e.g., 10 sessions/hour)
- Cache generated challenge sets for reuse
- Template static reward/event copy instead of generating
- Batch offline tasks (badge text, event copy) using `LOW_COST_UTILITY` model
