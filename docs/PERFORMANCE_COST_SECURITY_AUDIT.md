# PERFORMANCE, COST, AND SECURITY AUDIT
> Generated: 2026-03-13

## Performance

| Issue | Severity | Area | Notes |
|---|---|---|---|
| WorldGridPainter draws 4000×4000 grid | Low | world_home_screen.dart | RepaintBoundary protects repaints — initial paint is expensive |
| 4000×4000 canvas allocation | Medium | world_home_screen.dart | SizedBox(width: 4000, height: 4000) — try to reduce if on weak devices |
| AnimationController created inline in _centerMap | Medium | world_home_screen.dart | Creates a new controller every time — leads to leak unless disposed |
| No stream debounce on audio capture | Low | live_audio_capture_service.dart | Every mic frame sent — may flood WebSocket |

## Cost

| Issue | Severity | Notes |
|---|---|---|
| Sessions left open | Medium | User leaves quiz → session stays open in Cloud Run registry |
| Session registry Map with no TTL | Low | Small memory leak on long-running instances |
| Idle hint/repeat calls | Low | Guards exist (max 3 hints, 5 repeats) |
| No token budget per session | Medium | System instruction + tool schemas can be 2-3K tokens per session |
| Combo bonus can double-count | Low | apply_combo_bonus adds materials to district AND grants reward — needs audit |

## Security

| Issue | Severity | Notes |
|---|---|---|
| /live/config endpoint has no auth | Medium | Returns model config without auth — not critical but should require auth |
| Reward anti-abuse cap enforced | ✅ Good | maxRewardPerHour in grantReward |
| Audit logging on all tool calls | ✅ Good | Every tool execution logged to Firestore |
| Rate limiting on all endpoints | ✅ Good | `@fastify/rate-limit` applied globally (100/min) |
| GEMINI_API_KEY in Secret Manager | ✅ Good | Never in code or env files |
| Firestore rules deployed | ✅ Good | secure baseline rules in place |
| Auth middleware validates userId | ✅ Good | JWT verification in middleware |
| Tool name validation | ✅ Good | Unknown tools rejected with 400 |

## Summary

- Security: **Strong fundamentals** — rate limiting, audit logs, secret manager, auth middleware
- Performance: Risk in animation controller leak inside `_centerMap`
- Cost: Primary risk is idle open sessions — mitigation already exists in controller (sessionDurationTimer)  
- No critical security holes found
