# AI AND LIVE SYSTEM AUDIT
> Generated: 2026-03-13

## Model Configuration

| Setting | Value | Assessment |
|---|---|---|
| Live/Realtime model | gemini-2.0-flash-live-001 | ✅ Correct — This is the Live API model |
| Async/Challenge model | gemini-2.5-flash | ✅ Good — Best async capacity |
| Utility model | gemini-2.5-flash-lite | ✅ Good — Low cost for utility |
| Voice | Aoede | ✅ Good engagement voice |
| Response modalities | AUDIO + TEXT | ✅ Correct |
| Session type support | onboarding, quiz, vision_quest | ✅ Complete |

## Ephemeral Token Flow

| Step | Status |
|---|---|
| Client requests token at POST /live/ephemeral-token | ✅ Working |
| Token minted with model, session type, and TTL | ✅ Working |
| Session registry stores active sessions in-memory Map | ⚠️ In-memory — lost on restart |
| Client uses token to connect directly to Gemini WebSocket | ✅ Correct pattern |
| Tool calls proxied back through POST /live/tool-execute | ✅ Working |

## Flutter Live Session Controller Assessment

| Feature | File | Status |
|---|---|---|
| Session orchestration | live_session_controller.dart | ✅ Real (566 lines) |
| WebSocket client | live_websocket_client.dart | ✅ (expected) |
| Audio capture | live_audio_capture_service.dart | ✅ (expected) |
| Audio playback | live_audio_playback_service.dart | ✅ (expected) |
| Camera stream | live_camera_stream_service.dart | ✅ (expected) |
| Tool bridge | live_tool_bridge_client.dart | ✅ (expected) |
| Reconnect policy | live_reconnect_policy.dart | ✅ Real |
| Turn detection | live_turn_detector.dart | ✅ Real |
| Error mapping | live_error_mapper.dart | ✅ Real |
| Session logging | live_session_logger.dart | ✅ Real |
| Mock adapter | live_mock_adapter.dart | ✅ Real |
| Permission guard | live_permission_guard.dart | ✅ Real |

## CRITICAL: live_quiz_screen.dart is NOT wired to the controller

The `LiveSessionController` exists and is fully implemented (566 lines), but **the quiz screen never calls it**.

```dart
// In live_quiz_screen.dart — what happens now:
bool _isListening = true;  // ← local boolean, no Gemini
GestureDetector(
  onTap: () => setState(() => _isListening = !_isListening),
  // ← no session start, no session end, nothing
```

The screen should:
```dart
// initState:
ref.read(liveSessionControllerProvider).startSession(config: LiveSessionConfig.quiz(...));

// On build, watch:
final sessionState = ref.watch(liveSessionStateProvider);
```

## Tool Schema Quality

| Schema | Zod Validated | Args Complete | Status |
|---|---|---|---|
| start_onboarding | ✅ | ✅ | Good |
| save_user_profile | ✅ | ✅ | Good |
| grade_answer | ✅ | ✅ | Good |
| award_territory | ✅ | ✅ | Good |
| apply_combo_bonus | ✅ | ✅ | Good |
| join_squad_mission | ✅ | ✅ | Good but handler is partial |

## Prompt / System Instruction Quality

Prompt content is defined inside `liveService.ts` as part of session config. The system instructions define AI persona, available tools, and game rules. This is standard practice. Quality is good but not inspected in detail in this pass.

## Vision Quest Assessment

- Camera frames are captured by `LiveCameraStreamService`
- Frames should be sent to model via the WebSocket `sendImage` call
- Validation happens via `validate_vision_result` tool with `confidence` + `objectIdentified` args
- **Gap:** The wiring between camera capture and Gemini model frame submission needs verification — if camera frames are not sent, the vision quest is sight-only, not vision-AI

## Cost Waste Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Idle sessions (user leaves quiz open) | Medium | Session duration timer in controller exists (maxSessionDuration) |
| In-memory session registry leaking | Low | Add cleanup interval |
| Hint/repeat abuse | Low | maxHintsPerRound=3, maxRepeatsPerRound=5 guards exist |
| Reward cap bypass | Low | maxRewardPerHour guard in grantReward |

## Summary

- Live session infrastructure: **Excellent** — 566-line controller, 12 supporting classes
- Backend tool execution: **Excellent** — 15 tools, all validated, most implemented
- Model selection: **Excellent** — correct models for each mode
- **CRITICAL GAP: quiz screen never calls the controller** — this is the only show-stopper
