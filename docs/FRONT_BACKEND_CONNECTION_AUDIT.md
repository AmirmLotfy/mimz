# Front/Backend Connection Audit

## Findings
1. **Base URLs**: The frontend `ApiClient` correctly uses `String.fromEnvironment('BACKEND_URL')` with a default Cloud Run URL.
2. **Health Check**: `ApiClient` has a `checkHealth()` method hitting `/healthz`, which is defined in the backend. However, it is not proactively used to guard app flows.
3. **AI/Live Endpoints**: `getEphemeralToken` and `executeToolCall` are wired up in `ApiClient`, but error states during these calls (e.g. if the Gemini API is down) might not be handled gracefully in `gemini_live_client.dart` or `live_providers.dart`.
4. **Auth Flow**: `bootstrap()` is called correctly, but token refresh failures or boot failures just silently leave the user without data or boot them to login abruptly.

## Action Plan
- Integrate `checkHealth()` from `ApiClient` into the new `ConnectivityService`.
- Audit provider handlers (like in `WorldProvider`, `SquadProvider`) to ensure they surface errors instead of swallowing them.
- Ensure the backend's `health.ts` properly exposes readiness (which it currently does via `/healthz` and `/readyz`).
