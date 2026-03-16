# AI FEATURES + MODELS AUDIT — Mimz
> Last updated: 2026-03-15

## Model Registry

Centralized in `backend/src/config/models.ts`.

| Role | Env Var | Default | Cost |
|------|---------|---------|------|
| `LIVE_REALTIME` | `GEMINI_LIVE_MODEL` | `gemini-2.5-flash-native-audio-preview-12-2025` | medium |
| `ASYNC_CHALLENGE` | `GEMINI_MODEL` | `gemini-2.5-flash` | medium |
| `LOW_COST_UTILITY` | `GEMINI_UTILITY_MODEL` | `gemini-2.5-flash-lite` | low |

Startup validation via `logActiveModels()` — logs all 3 roles at boot.

---

## Feature → Model Mapping

| Feature | Role | Where Used |
|---------|------|-----------|
| Live quiz voice interaction | LIVE_REALTIME | `mintEphemeralToken` → `session.model` |
| Live onboarding voice | LIVE_REALTIME | Same |
| Live vision quest | LIVE_REALTIME | Same (image frames via WebSocket) |
| Server-side answer grading | ASYNC_CHALLENGE | `validationService.ts` |
| Question generation | ASYNC_CHALLENGE | `questionService.ts` |
| Interest taxonomy | Not AI — static catalog | `questionService.ts` |
| Hint responses | LIVE_REALTIME | `requestHint()` → text message in session |
| Reward copy | LIVE_REALTIME | Model-generated in session |
| Challenge generation | ASYNC_CHALLENGE | Deterministic bank (no API call) |
| Summaries/utility | LOW_COST_UTILITY | Available but not yet wired |

---

## AI Feature Status

### Live Quiz Session ✅ Real
- WebSocket to Gemini Live API
- System instruction with Mimz persona
- Audio I/O + tool calls
- grade_answer → backend authoritative

### Live Onboarding ✅ Real
- Same Live pipeline
- `startOnboardingSession()` → `LiveSessionConfig.onboarding`
- `save_user_profile` tool persists name/interests to Firestore

### Vision Quest ✅ Real (Audio + Camera)
- `LiveCameraStreamService` captures frames
- `LiveSessionController.attachCameraFrame()` → `ws.sendImage()`
- Gemini evaluates via multimodal input
- `validate_vision_result` tool authorizes reward

### Hint Generation ✅ Real
- `requestHint()` sends "Can I get a hint?" as text in live session
- Gemini responds in voice — no separate API call needed
- Rate-limited to 3 hints per round (`maxHintsPerRound = 3`)

### Server-side Answer Grading ✅ Real
- `validationService.ts` — 6 match modes
- Used by `/questions/validate` REST endpoint
- Also verifiable via backend tool `grade_answer`

### Question Generation ✅ Real
- 10-question deterministic bank in `questionService.ts`
- Interest scoring + difficulty filtering
- No per-request API call (cost-free)

---

## System Prompt Quality

### Current State
- Generic Mimz persona ("friendly and energetic AI game host")
- No user name injection
- No interest injection
- No difficulty adaptation

### Target State
- "You are Mimz, the live game host. You're playing with [name]. Their interests include [interests]. Use [difficulty] level questions."
- Keep responses under 2 sentences unless reading a question
- Always ask the next question after grading
- Never break character

---

## Model Config Issues (None Critical)

- `gemini-2.5-flash-native-audio-preview-12-2025` — preview model, may be updated. Config env var overrides.
- `gemini-2.5-flash-lite` — wired but not yet used by any live feature. Available for cheap tasks.
- No hardcoded model strings outside `models.ts` (confirmed).

---

## Cost Exposure

- Live sessions: 1 session ≈ $0.02–0.10 depending on duration/audio
- Server-side grading: zero AI cost (deterministic validation)
- Question bank: zero AI cost (static)
- All replay-vulnerable tools are backend-authoritative + rate-limited

**Estimated demo cost:** < $1 total for 10+ demo runs.
