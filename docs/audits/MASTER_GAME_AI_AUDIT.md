# MASTER GAME + AI AUDIT — Mimz
> Last updated: 2026-03-15

## Executive Summary

Mimz is a **live voice-and-vision mobile game** built on Gemini Live, Flutter, Fastify + Firestore. After a full-stack audit, the core architecture is production-credible and demo-ready with targeted fixes.

**The pipeline is real:** real microphone capture (record pkg), real PCM playback (just_audio), real WebSocket connection to Gemini Live, real backend tool execution (15 handlers), real Firestore state. No core system is fake.

**The gaps are targeted:** system prompt is generic (not personalized), tool calls lack idempotency guards, vision quest and squad mission persistence is shallow.

---

## Architecture Map

```
[Flutter App]
  ├── LiveSessionController (orchestrator, 568 lines)
  │     ├── LiveWebSocketClient (dart:io WS, inactivity timeout)
  │     ├── LiveAudioCaptureService (record pkg, 16kHz PCM)
  │     ├── LiveAudioPlaybackService (just_audio, WAV header)
  │     ├── LiveCameraStreamService (camera pkg)
  │     ├── LiveTokenClient → GET /live/ephemeral-token
  │     └── LiveToolBridgeClient → POST /live/tool-execute
  │
  ├── LiveQuizScreen → liveSessionStateProvider (real state)
  ├── WorldHomeScreen → districtProvider (Firestore sync)
  └── RoundResultScreen → quizStateProvider

[Backend — Fastify + Firestore]
  ├── POST /live/ephemeral-token → mintEphemeralToken
  ├── POST /live/tool-execute → executeTool (15 handlers)
  ├── GET /district → getDistrict
  ├── GET /questions → question bank
  └── POST /questions/validate → validationService
```

---

## Audit Areas

### A. Gameplay Systems

| System | Status | Notes |
|--------|--------|-------|
| Auth + bootstrap | ✅ Real | bootstrapUser, race-safe |
| Onboarding flow | ✅ Real | 3 screens, profile patch |
| Live quiz round | ✅ Real | grade_answer, award_territory |
| District growth | ✅ Real | expandTerritory, Firestore |
| Structure unlock | ✅ Real | full cost check + resource deduction |
| Vision quest | ⚠️ Partial | camera + frame send OK; persistence shallow |
| Squad missions | ⚠️ Partial | contribute_squad_progress works; join shallow |
| Events | ⚠️ Partial | routes exist; event creation limited |
| Leaderboard | ✅ Real | upsertLeaderboardEntry on every end_round |

### B. AI Features

| Feature | Model | Status |
|---------|-------|--------|
| Live quiz voice | LIVE_REALTIME | ✅ Real (WebSocket + audio) |
| Live onboarding | LIVE_REALTIME | ✅ Real |
| Vision quest | LIVE_REALTIME | ✅ Real (image frames) |
| Personalized system prompt | LIVE_REALTIME | ⚠️ Generic — not user-aware |
| Answer grading (server) | ASYNC_CHALLENGE | ✅ Real (validationService) |
| Question generation | ASYNC_CHALLENGE | ✅ Real (questionService) |
| Hints | LIVE_REALTIME | ✅ Real (requestHint via text) |

### C. Backend Coverage

| Route | Status |
|-------|--------|
| POST /auth/bootstrap | ✅ |
| PATCH /profile | ✅ |
| GET /district | ✅ |
| POST /live/ephemeral-token | ✅ |
| POST /live/tool-execute | ✅ (15 tools) |
| GET /questions | ✅ |
| POST /questions/validate | ✅ |
| GET /leaderboard | ✅ |
| POST /squads | ✅ |
| GET /events | ✅ |

### D. Live Voice + Hearing

| Aspect | Status |
|--------|--------|
| Mic permission | ✅ LivePermissionGuard |
| PCM capture stream | ✅ record pkg, 16kHz mono |
| WebSocket audio send | ✅ base64 encoded |
| Model audio receive | ✅ inlineData decoded |
| WAV playback | ✅ just_audio + header |
| Barge-in | ✅ stopImmediately + resume capture |
| Inactivity timeout | ✅ configurable per session |
| Reconnect | ✅ exponential backoff |

### E. Game State Authority

| Action | Authority |
|--------|-----------|
| XP grant | ✅ Backend (grade_answer handler) |
| Territory | ✅ Backend (award_territory, bounded) |
| Streak | ✅ Backend (grade_answer) |
| Structure unlock | ✅ Backend (with cost check) |
| Squad progress | ⚠️ Backend write exists; UI may not refresh |
| Leaderboard | ✅ Backend upsert on end_round |

---

## Critical Fixes Required

1. **System prompt personalization** — inject user name + interests + difficulty
2. **Tool idempotency** for grade_answer and award_territory
3. **Vision quest Firestore persistence**
4. **Squad mission participation Firestore write**
5. **Mock adapter production guard**

---

## Overall Assessment

**Demo readiness: 8/10.** With the 5 targeted fixes, Mimz is genuinely ready to demo as a hackathon entry. The live voice pipeline, tool execution, game logic, and backend state are all real and connected. The gaps are experience quality improvements, not core architecture rework.
