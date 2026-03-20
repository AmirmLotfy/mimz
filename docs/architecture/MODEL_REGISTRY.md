# Model Registry

## Canonical Roles

Mimz uses role-based model routing. Product flows must reference roles, not hardcoded model strings.

- `LIVE_REALTIME_MODEL`: realtime voice-and-vision sessions.
- `ASYNC_REASONING_MODEL`: async reasoning/generation tasks.
- `LOW_COST_UTILITY_MODEL`: low-cost transforms and lightweight classification.
- `OPTIONAL_IMAGE_MODEL`: optional image-generation tasks.

## Source Of Truth

- Backend registry: `backend/src/config/models.ts`
- Environment inputs:
  - `GEMINI_LIVE_MODEL`
  - `GEMINI_MODEL`
  - `GEMINI_UTILITY_MODEL`
  - `GEMINI_IMAGE_MODEL`

## Rules

- No feature module may hardcode model IDs.
- Model ids are validated at backend startup.
- Live session token responses should carry the resolved model id for clients.

## Defaults

- Live: `gemini-2.5-flash-native-audio-preview-12-2025`
- Async reasoning: `gemini-2.5-flash`
- Utility: `gemini-2.5-flash-lite`
- Optional image: `gemini-2.5-flash-image-preview`
