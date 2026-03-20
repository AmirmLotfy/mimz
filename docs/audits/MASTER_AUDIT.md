# MIMZ MASTER AUDIT
> Generated: 2026-03-13 | Auditor: Principal AI Systems + Flutter Architect Review
> Status: **LAUNCH-BLOCKING GAPS FOUND**

---

## 1. PROJECT INVENTORY

### Flutter App — Features
| Feature | Screens | Status |
|---|---|---|
| auth | splash, welcome, auth | Functional but thin |
| onboarding | permission_overview, location_perm, mic_perm, camera_perm, live_onboarding, onboarding_summary, emblem_selection, district_naming | Mostly visual shells |
| world | world_home_screen, world_expanded_sheet, leaderboard_screen | **Real + high quality** |
| live | play_hub_screen, live_quiz_screen, round_result_screen, vision_quest_camera_screen, vision_quest_success_screen | **CRITICAL: UI not wired to LiveSessionController** |
| squads | squad_hub_screen | Thin/incomplete |
| events | events_screen | Thin/incomplete |
| profile | profile_screen | Basic |
| rewards | reward_vault_screen | Visual only |
| settings | settings_screen | Stub |
| district | No dedicated screen — embedded in world | District detail missing |

### Backend Routes
| Route | Endpoints | Status |
|---|---|---|
| /live | ephemeral-token, tool-execute, session-log, config | **Real and solid** |
| /auth | bootstrap | Basic |
| /district | GET, PATCH | Basic |
| /profile | GET, PATCH | Basic |
| /rewards | GET | Basic |
| /squads | Multiple | Incomplete — squad join/create missing persistence |
| /events | Multiple | Basic |
| /leaderboard | GET | Basic |
| /notifications | GET | Stub — returns empty array |

### Backend Services
| Service | Status |
|---|---|
| gameService.ts (285 lines) | **Real — bootstrapUser, grantReward, calculateScore, expandTerritory, unlockStructure** |
| executeLiveTool.ts (451 lines) | **Real — 15 tool handlers wired to gameService** |
| liveService.ts (8KB) | Ephemeral token minting + session registry |
| toolSchemas.ts | Zod validation schemas |

### Flutter Services
| Service | Status |
|---|---|
| LiveSessionController (566 lines) | **Real orchestrator — WS + audio + camera + reconnect** |
| live_session_manager.dart | @deprecated — superseded by controller |
| GeminiLiveClient | Should exist in services/ |
| AudioService | Should exist in services/ |
| ApiClient | Exists — wired to Cloud Run URL |

### Routes Declared in router.dart
24 routes total. All routes resolve to real screen files. No broken imports detected.

### Deployment & Config
| Item | Status |
|---|---|
| Cloud Run (mimz-backend) | **Deployed — revision 00007 live** |
| Firestore | Connected — /readyz returns 200 |
| GEMINI_API_KEY | Stored in Secret Manager — injected into Cloud Run |
| Firebase Auth | Configured via FlutterFire |
| .gcloudignore | Fixed — fast deploys now |
| deploy_backend.sh | Has GCP_PROJECT_ID — solid |

---

## 2. CRITICAL GAPS FOUND

### 🔴 CRITICAL-1: Live quiz screen NOT wired to LiveSessionController
`live_quiz_screen.dart` watches `quizStateProvider` but the mic button (`_isListening`) only toggles **local boolean state**. No `liveSessionControllerProvider` is ever read or called. The Gemini Live session is never started from the quiz screen. This is the #1 demo-breaking issue.

### 🔴 CRITICAL-2: Live onboarding screen — unknown connection to controller
`/onboarding/live` screen (`live_onboarding_screen.dart`) — unknown whether it properly starts a Gemini Live session. Must verify.

### 🔴 CRITICAL-3: Vision quest camera flow — no actual image analysis wired
`vision_quest_camera_screen.dart` captures video via camera but it is unclear whether the image frames are being sent to the Gemini model for real vision analysis, or whether validation happens locally.

### 🔴 CRITICAL-4: Squads — no real persistence
`contribute_squad_progress` tool handler in `executeLiveTool.ts` grants XP directly to user instead of updating squad mission records. Squad join/create flows are not persisted correctly.

### 🔴 CRITICAL-5: Notifications route returns empty
`/notifications` route returns an empty array — no notification system implemented.

### 🟡 HIGH-1: District screen missing
There is no dedicated district detail screen. Users can see the map but cannot inspect/manage their district (structures, resources, prestige) via a dedicated screen.

### 🟡 HIGH-2: Auth gating not enforced in router
The router does not have a redirect guard. If a user navigates to `/world` without being authenticated, there is no redirect to `/splash` or `/welcome`.

### 🟡 HIGH-3: Settings screen is a stub
No actual settings (notification prefs, sign out, account deletion, privacy mode, display name change) are implemented.

### 🟡 HIGH-4: Round result screen — no district growth trigger
The round result screen (`round_result_screen.dart`) shows results but may not trigger a district growth event in the world map, breaking the "play → grow your district" loop visibility.

### 🟡 HIGH-5: Emblem and district naming not persisted to backend
The onboarding screens for emblem selection and district naming are visual-only — the selected values may not be sent back to `save_user_profile` via the live session or API.

### 🟠 MEDIUM-1: Leaderboard is static/demo data
The leaderboard screen loads data but the data pipeline from `end_round` → `upsertLeaderboardEntry` → Flutter leaderboard provider may not be wired.

### 🟠 MEDIUM-2: Events screen shows no real events
No seed events are in Firestore, making events screen always empty.

### 🟠 MEDIUM-3: Squad hub shows no squads
No squads exist in Firestore from an empty-state perspective.

### 🟠 MEDIUM-4: /healthz is intercepted by Cloud Run platform
Not a product issue, but the healthz route returns Google 404 by Cloud Run platform convention. Use /readyz only.

### 🔵 LOW-1: Dead toolbar icons in live_quiz_screen
The bottom toolbar has 6 icons — only the mic toggle works. Shield, map, trophy, settings, and overflow do nothing.

### 🔵 LOW-2: Map layers button does nothing
`_MapControlButton` for "layers" calls an empty tap handler.

---

## 3. WHAT IS REAL AND WORKING

✅ World home screen with hex-based district rendering (547 lines)
✅ GrowthAnimationPainter with shockwave + pop animations
✅ LiveSessionController (566 lines) with WS, audio, camera, reconnect, turn detection
✅ Backend gameService.ts with 7 game functions
✅ executeLiveTool.ts with 15 tool handlers all properly connected to game logic
✅ Cloud Run deployment — live at `https://mimz-backend-1012962167727.us-central1.run.app`
✅ Firestore connected (/readyz returns 200)
✅ Gemini API key in Secret Manager
✅ Firebase Auth wired with FlutterFire
✅ 36 documentation files covering architecture, AI tuning, security, etc.
✅ Design system tokens (colors, typography, spacing) consistent across screens

---

## 4. OVERALL RISK ASSESSMENT

| Category | Status | Risk Level |
|---|---|---|
| AI/Live Session | BROKEN CONNECTION in quiz screen | 🔴 Critical |
| Backend Logic | Solid but squad/events incomplete | 🟡 High |
| Auth Flow | No routing guard | 🟡 High |
| World/Map | Strong | ✅ Good |
| District System | Missing detail screen | 🟡 High |
| Gameplay Loop | Partially disconnected at POST-round | 🟡 High |
| UI/UX Quality | Mostly premium, some stubs | 🟠 Medium |
| Deployment | Live and working | ✅ Good |
| Security | Basic — rate limiting + audit logs | 🟠 Medium |
| Hackathon Readiness | NOT ready without CRITICAL fixes | 🔴 Critical |
