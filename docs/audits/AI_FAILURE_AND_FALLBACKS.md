# AI Failure and Fallbacks

## Error Codes

| Code | Trigger | User Message | Recovery |
|------|---------|-------------|----------|
| `permissionDenied` | Mic/camera permission refused | "Mimz needs access to your microphone..." | Open Settings |
| `tokenFetchFailed` | Backend unreachable or 4xx | "Couldn't connect to Mimz servers..." | Retry |
| `tokenExpired` | Token TTL exceeded | "Your session expired. Starting fresh..." | Refresh Token |
| `wsConnectFailed` | WebSocket timeout (10s) | "Connection failed. Retrying..." | Retry |
| `wsUnexpectedClose` | Abnormal WebSocket close | "Connection dropped. Reconnecting..." | Reconnect |
| `wsMalformedMessage` | Unparseable server message | "Received unexpected response..." | Retry (non-blocking) |
| `audioCaptureFailed` | Mic hardware error | "Couldn't access the microphone..." | Retry |
| `audioPlaybackFailed` | Speaker error | "Audio playback issue..." | Reconnect |
| `cameraInitFailed` | Camera hardware error | "Camera isn't available..." | Retry |
| `toolExecutionFailed` | Backend tool error | "Something went wrong in the game..." | Retry |
| `backendTimeout` | Tool execution >10s | "Server took too long..." | Retry |
| `sessionExpired` | Session timed out | "Session timed out. Let's start a new round!" | New session |
| `rateLimited` | Backend 429 | "Too many requests..." | Retry (with backoff) |
| `modelUnavailable` | Model 503 / not found | "AI model temporarily unavailable..." | Retry with fallback |
| `unknown` | Catch-all | "Something unexpected happened..." | Retry |

## Recovery Strategies

| Strategy | Behavior |
|----------|----------|
| `retry` | User-initiated retry; shows retry button |
| `refreshToken` | Invalidates cached token → auto-retry |
| `reconnect` | Full teardown → reconnect with backoff |
| `openSettings` | Prompts user to open system settings |
| `fatal` | End session; show error banner |

## Error Severity Display

| Severity | UI Treatment |
|----------|-------------|
| `transient` | Auto-dismissing toast, session continues |
| `banner` | Visible banner but session continues |
| `blocking` | Blocks interaction until resolved |

## Reconnect Flow
```
Error detected → check recovery strategy
  → reconnect/refreshToken → check canRetry (max 3)
    → yes → wait (backoff + jitter) → teardown → restart session
    → no → emit fatal error → end session
  → retry → show toast, user can retry
  → openSettings → show settings prompt
  → fatal → end session immediately
```

## Fallback Model Strategy
- Primary model from `MODEL_REGISTRY` via env config
- Each role has a `fallback` model ID (e.g., `gemini-2.0-flash` as fallback for `gemini-2.5-flash-native-audio-preview-...`)
- `getModelWithFallback(role)` returns both for application-level retry logic

## Demo-Safe Behavior
- All errors map to friendly user messages — no raw error strings shown
- Tool execution failures send error response back to Gemini so it can adapt
- Session duration capped to prevent runaway costs during demo
- Debounced commands prevent accidental spam during nervous demo moments
