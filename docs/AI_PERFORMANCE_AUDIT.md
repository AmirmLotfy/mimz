# AI Performance Audit

Full audit of the Mimz AI stack conducted 2026-03-12.

## Architecture Summary

| Layer | Tech | Files |
|-------|------|-------|
| Live voice/vision | Gemini 2.0 Flash Live WebSocket | `live_websocket_client.dart`, `live_message_codec.dart` |
| Session orchestration | `LiveSessionController` | `live_session_controller.dart` (540+ lines) |
| Token management | Backend-minted ephemeral tokens | `live_token_client.dart`, `liveService.ts` |
| Tool execution | 15 Zod-validated tools via backend HTTP | `executeLiveTool.ts`, `toolSchemas.ts` |
| Model registry | Centralized 3-role config | `backend/src/config/models.ts` |
| Error handling | 15 typed error codes + recovery strategies | `live_event.dart`, `live_error_mapper.dart` |
| Reconnect | Exponential backoff + jitter | `live_reconnect_policy.dart` |

## Issues Found & Fixed

### Critical
| Issue | File | Fix |
|-------|------|-----|
| Inactivity timer never re-arms (no-op `_resetInactivityTimer`) | `live_websocket_client.dart` | Fixed: properly re-arms on every send |
| No debounce on hint/repeat/difficulty commands | `live_session_controller.dart` | Added 2s cooldown + per-session caps |
| No tool execution timeout | `live_tool_bridge_client.dart` | Added 5s send / 10s receive timeout |
| No session duration cap | `live_session_config.dart` | Added `maxSessionDuration` (5-10 min per mode) |
| No camera frame cap | `live_camera_stream_service.dart` | Added `maxFramesPerSession` (20-30 per session) |

### Moderate
| Issue | File | Fix |
|-------|------|-----|
| Hardcoded model ID fallback on client | `live_backend_dtos.dart` | Changed to throw if backend doesn't provide model |
| MIMZ_PERSONA oversized (43 lines) | `liveService.ts` | Trimmed to 15 concise lines |
| No `executionTimeMs` on tool responses | `executeLiveTool.ts` | Added timing + `toModelPayload()` helper |
| No `modelUnavailable` error code | `live_event.dart` | Added error code + user message |
| No startup model config log | `models.ts` | Added `logActiveModels()` |

### Legacy Code
| Issue | File | Action |
|-------|------|--------|
| `GeminiLiveClient` duplicates new layered architecture | `gemini_live_client.dart` | Marked `@deprecated` |
| `LiveSessionManager` duplicates new controller | `live_session_manager.dart` | Marked `@deprecated` |

## Strengths Found (No Changes Needed)
- Clean sealed event hierarchy with exhaustive pattern matching
- Immutable state with `copyWith` pattern
- Tool name registry on both client and server with identical names
- Zod validation on all tool arguments with typed defaults
- Correlation IDs on every tool execution
- Rate limiting and abuse protection in backend config
- Permission guard before session startup
- Debug-only logger with bounded entry list
- Mock adapter for development without API key
