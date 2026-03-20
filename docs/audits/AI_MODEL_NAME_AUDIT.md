# AI Model Name Audit Record

| File Path | Current Model Found | Action Needed | New Target Action |
| --- | --- | --- | --- |
| `cloudbuild.yaml` | `gemini-2.0-flash-live-001` / `gemini-2.5-flash` | Update live string | Change live model to `gemini-2.5-flash-native-audio-preview-12-2025` |
| `backend/test/modelConfig.test.ts` | `gemini-2.0-flash-live-001` | Update expectation | Change to `gemini-2.5-flash-native-audio-preview-12-2025` |
| `backend/.env.example` | `gemini-2.0-flash-live-001` | Update env definition | Change to `gemini-2.5-flash-native-audio-preview-12-2025` |
| `backend/src/config/index.ts` | `gemini-2.0-flash-live-001` | Update Zod default schemas | Update live to `gemini-2.5-flash-native-audio...` |
| `backend/src/config/models.ts` | Multiple fallbacks (`gemini-2.0-flash-live-001`, `gemini-2.0-flash`, etc) | Rewrite registry | Update fallbacks and active default IDs |
| `docs/architecture/MODEL_ROUTING_STRATEGY.md` | `gemini-2.0-flash-live-001`, `gemini-2.0-flash` fallbacks | Rewrite docs | Standardize around the new mandated models |
| `docs/operations/ENVIRONMENT.md` | `gemini-2.0-flash-exp` (deprecated) | Delete old exp ref | Update references |
| `docs/audits/AI_AND_LIVE_SYSTEM_AUDIT.md`| `gemini-2.0-flash-live-001` | Rewrite docs | Standardize around the new mandated models |
| `docs/operations/CLOUD_RUN_DEPLOY.md` | `gemini-2.0-flash-live-001` | Update CLI flags | Standardize around the new mandated models |
| `docs/audits/AI_FAILURE_AND_FALLBACKS.md`| `gemini-2.0-flash` fallback | Update fallback docs | Standardize around the new mandated models |
| `docs/architecture/LIVE_MESSAGE_FLOW.md` | `gemini-2.0-flash-live-001` | Update WS init string | Standardize around the new mandated models |
| `README.md` | `gemini-2.0-flash-live-001` | Update snippet | Standardize around the new mandated models |
| `scripts/deploy.sh` | `gemini-2.0-flash-live-001` | Update bash variable | Standardize around the new mandated models |

## SDK Findings

- **Backend**: Uses Node `fetch` (`google-auth-library` to generate the JWTs). No `@google/generative-ai` or `@google/genai` npm modules found.
- **Frontend**: Uses raw Dart WebSockets (`web_socket_channel`) connecting directly to the `/ws/google.ai.generativelanguage.v1alpha.GenerativeService.BidiGenerateContent` endpoint using the Cloud Run backend's minted ephemeral tokens. No legacy or preview Flutter packages or HTTP bindings were found.

*Status: Zero SDK migrations are required! We strictly just need to update the model string constants and documentation.*
