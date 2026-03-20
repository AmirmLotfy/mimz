# AI Live Production Spec

## Objective

Deliver reliable real-time voice/vision sessions with controlled cost and deterministic backend-authoritative outcomes.

## Session Lifecycle

1. Preconditions: authenticated + bootstrapped + required permissions
2. Request ephemeral/live token from backend
3. Connect websocket and complete handshake
4. Stream audio/camera data
5. Execute tools through backend only
6. Persist outcomes and update UI
7. Graceful teardown/recovery on failure

## Production Requirements

- Session ownership validation on all tool calls
- Idempotency across all reward-affecting tools
- Clear reconnect and fatal failure paths
- No silent reward success on backend failures
- Barge-in and playback/mic transitions remain deterministic

## Model Roles

- `LIVE_REALTIME_MODEL`: realtime live sessions
- `ASYNC_REASONING_MODEL`: async challenge/reasoning tasks
- `LOW_COST_UTILITY_MODEL`: lightweight transforms/classifications
- `OPTIONAL_IMAGE_MODEL`: optional image-related generation tasks

## Cost Controls

- cap tool retries and duplicate grants via idempotency
- bounded session log payload sizes
- enforce concise spoken responses (short turns)
- maximum session duration and inactivity timeout

## Remaining Gaps

- Session registry persistence across backend restart
- Additional adaptive fallback strategy when live primary model unavailable
