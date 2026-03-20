# AI Live Backend Interaction Spec

Last updated: 2026-03-18

## App Voice And Persona

- Tone: warm, sharp, concise, slightly competitive, game-master-like.
- Response length: one sentence by default.
- Never monologue, never block pace.
- Speak outcomes and next action clearly.

## Canonical Voice Moments

- Welcome: short identity + momentum line.
- Onboarding transitions: explain value in one sentence.
- First district reveal: celebratory and concrete.
- Round start: challenge prompt + timer cue.
- Hint: minimal clue, no answer leakage.
- Correct/incorrect reactions: energetic but brief.
- Streak/bonus callouts: explicit multiplier impact.
- Structure unlock: progression significance.
- Session end: summary + best next action.

## Live Hearing And Reaction Contract

- Listening states:
  - `armed` (awaiting speech)
  - `capturing`
  - `processing`
  - `playing_response`
  - `tool_wait`
- Must support barge-in/interruption while AI is speaking.
- Session teardown always releases microphone/audio resources.
- Reconnect policy:
  - bounded attempts with jitter
  - explicit exit path to world

## Interaction Architecture

### Components

- Flutter:
  - audio capture/playback
  - websocket/session client
  - UX state machine and route control
- Backend:
  - ephemeral token issuance
  - tool execution authorization
  - reward/progression mutation
  - audit logging and correlation ids
- Firebase:
  - auth identity and token verification
- Gemini Live:
  - realtime voice/vision interaction

## Sequences

### Auth Bootstrap Sequence

1. Firebase sign-in success.
2. Client obtains valid ID token.
3. `POST /auth/bootstrap`.
4. Backend returns user + district.
5. Client enters world/onboarding gate.

### Live Session Sequence

1. Client requests ephemeral token.
2. Backend returns model + websocket URL + backend session id + correlation id.
3. Client stores backend session id before websocket handshake.
4. Client opens live websocket session.
5. User speech and vision data streamed.
6. Model emits responses and tool intents.
7. Backend tool bridge executes authoritative actions.
8. Client receives reward update payload and refreshes district.

### Regional Reliability Rule

- Vertex live transport region is configured separately from Cloud Run region (`GEMINI_LIVE_VERTEX_LOCATION`, default `us-central1`).
- Cloud Run deployment region must never implicitly override live websocket region.
- Region/model mismatch is treated as a fatal connect error (not infinite reconnect).

### Previous sequence (kept for compatibility)

1. Client requests ephemeral token.
2. Client opens live websocket session.
3. User speech and vision data streamed.
4. Model emits responses and tool intents.
5. Backend tool bridge executes authoritative actions.
6. Client receives reward update payload and refreshes district.

### Tool Execution Sequence

1. AI intent requests tool call.
2. Client forwards signed session tool call to backend.
3. Backend validates session/user and executes domain action.
4. Backend persists state and emits result payload.
5. Client updates UI with confirmed result.

## Model Routing Strategy (Canonical)

- `LIVE_REALTIME_MODEL`: realtime voice+vision rounds.
- `ASYNC_REASONING_MODEL`: question crafting, nuanced explanations.
- `LOW_COST_UTILITY_MODEL`: classification, transforms, lightweight text ops.
- `OPTIONAL_IMAGE_MODEL`: optional asset generation paths.

### Rules

- Model ids must be sourced from a single registry/config layer.
- No hardcoded model names inside feature logic.
- Startup validation must fail fast on missing required model config.

## Failure Contracts

- Live connect failure -> recovery screen with retry and exit.
- Tool execution failure -> no fake reward; show retry.
- Auth/token failure -> sign-out recovery path.
- Backend unavailable -> degrade to non-live accessible routes.

## Live Round Quality Checklist

Use this checklist for persona and tool behaviour; optional to log tool-call coverage for monitoring.

- **No monologue:** Keep model turns short (one sentence by default; max ~3 seconds speaking per turn).
- **Always grade after answer:** Every user answer must be followed by a `grade_answer` tool call; never skip.
- **Celebrate and reward on correct:** On correct answer: one celebratory sentence, then `award_territory` (1–2 sectors) and `grant_materials`.
- **Supportive on incorrect:** On incorrect answer: one supportive sentence, then move to next question; no harsh punishment.
- **Streak/combo:** When streak ≥ 3, also call `apply_combo_bonus`.
- **End round:** After 5 questions, call `end_round` with summary.

Optional monitoring: log tool-call coverage (e.g. that `grade_answer` was called for every question in a round) to detect model drift.
