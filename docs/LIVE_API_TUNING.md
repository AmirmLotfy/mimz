# Live API Tuning

Configuration and optimization parameters for Gemini Live sessions.

## Session Lifecycle

```
Permission Check → Token Fetch → WebSocket Connect → Setup Message → Audio Capture → Session Active → Teardown
```

### Timeouts & Caps
| Parameter | Value | Source |
|-----------|-------|--------|
| Token TTL | 5 minutes | `config.ephemeralTokenTtlMs` |
| Token cache min-remaining | 1 minute | `LiveTokenClient.fetchToken()` |
| WebSocket connect timeout | 10 seconds | `LiveWebSocketClient.connect()` |
| Tool execution send timeout | 5 seconds | `LiveToolBridgeClient` |
| Tool execution receive timeout | 10 seconds | `LiveToolBridgeClient` |
| Inactivity warning | 2-5 min per mode | `LiveSessionConfig.inactivityTimeout` |
| Max session duration | 5-10 min per mode | `LiveSessionConfig.maxSessionDuration` |
| Reconnect max attempts | 3 | `LiveReconnectPolicy.maxAttempts` |
| Reconnect initial delay | 1 second | With exponential backoff + ±25% jitter |
| Reconnect max delay | 30 seconds | `LiveReconnectPolicy.maxDelay` |
| Camera frame interval | ≥2 seconds | `LiveCameraStreamService.frameInterval` |
| Max frames per session | 20-30 | `LiveSessionConfig.maxFramesPerSession` |

### Per-Mode Configuration
| Parameter | Onboarding | Quiz | Vision Quest |
|-----------|-----------|------|-------------|
| Inactivity timeout | 5 min | 2 min | 3 min |
| Max session duration | 5 min | 10 min | 5 min |
| Camera enabled | No | No | Yes |
| Max frames/session | N/A | N/A | 20 |
| Max hints | 3 | 3 | 3 |
| Max repeats | 5 | 5 | 5 |

## Audio Pipeline
- Capture: PCM 16kHz mono → base64-encoded chunks → WebSocket
- Playback: Gemini returns PCM 24kHz → `AudioPlaybackService` queue → speaker
- Barge-in: `interruptWithUserSpeech()` stops playback immediately + resumes mic

## Reconnect Strategy
1. First failure: retry after ~1s (+ jitter)
2. Second failure: retry after ~2s + refresh token
3. Third failure: retry after ~4s + refresh token
4. After 3 failures: emit `LiveConnectionPhase.failed` with fatal error

## Token Management
- Backend mints tokens at `/live/ephemeral-token`
- Client caches token until expired or invalidated
- Token refresh triggered automatically on reconnect attempt ≥1
- In-memory session tracking on backend with 60s cleanup interval
