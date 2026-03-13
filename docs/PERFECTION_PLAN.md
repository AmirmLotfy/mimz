# MIMZ PERFECTION PLAN
> Generated: 2026-03-13 | Prioritized action plan based on MASTER_AUDIT + GAP_MATRIX

---

## TIER 1 — CRITICAL BLOCKERS (Fix immediately)

### 1.1 Wire Live Quiz Screen to LiveSessionController
**Priority: P0 — Demo breaks without this**
- **Gap:** GAP-01
- **Why it matters:** The Gemini Live session never starts from the quiz screen — the heart of the app is dead.
- **Impacted files:** `live_quiz_screen.dart`, `live_providers.dart`
- **Expected impact:** App actually starts a Gemini voice session, AI speaks to user, microphone works
- **Implementation:**
  - In `_LiveQuizScreenState.initState()`, call `ref.read(liveSessionControllerProvider).startSession(config: LiveSessionConfig.quiz(...))`
  - React to `liveSessionStateProvider` instead of `quizStateProvider` for waveform, score, transcript
  - Close button should call `endSession()`

### 1.2 Verify & Fix Live Onboarding Screen Connection
**Priority: P0 — Demo starts here**
- **Gap:** GAP-02
- **Impacted files:** `live_onboarding_screen.dart`
- **Expected impact:** AI greets user by voice on first launch
- **Implementation:** Confirm `liveSessionControllerProvider` is used; if not, wire it identically to quiz

### 1.3 Fix Round Result → District Growth Loop
**Priority: P0 — The core game loop must be visible**
- **Gap:** GAP-06
- **Impacted files:** `round_result_screen.dart`, `world_provider.dart`
- **Expected impact:** After a round, the map grows when user returns to world tab
- **Implementation:** After round ends, set `districtGrowthEventProvider` with new sector count; ensure `districtProvider` is refreshed

### 1.4 Wire Onboarding Name/Emblem to Backend
**Priority: P0**
- **Gap:** GAP-07  
- **Impacted files:** `district_naming_screen.dart`, `emblem_selection_screen.dart`
- **Expected impact:** District shows user's chosen name, not "My District" default
- **Implementation:** On confirm, call `ApiClient.patch('/profile', { districtName: ..., emblemId: ... })`

### 1.5 Add Router Auth Guard
**Priority: P0**
- **Gap:** GAP-04
- **Impacted files:** `router.dart`, `auth_provider.dart`
- **Expected impact:** Unauthenticated access redirected to /splash or /welcome
- **Implementation:** Add `redirect` to GoRouter that checks `authStateProvider`

---

## TIER 2 — HACKATHON DEMO BLOCKERS

### 2.1 Seed Demo Data in Firestore
**Priority: P1 — Empty states kill the demo**
- **Gap:** GAP-09, GAP-10, GAP-20
- **Impacted area:** Firestore — events collection, squads collection
- **Expected impact:** Events tab shows live events; Squad tab shows real squads
- **Implementation:** Run seed script to create 3 events and 1 public squad

### 2.2 Create District Detail Screen
**Priority: P1 — Judges need to see the district system**
- **Gap:** GAP-05
- **Impacted files:** New `district_detail_screen.dart`; `router.dart`
- **Expected impact:** Tapping on map or district name shows structures, resources, prestige
- **Implementation:** Create screen with cards for structures, resources bar, and prestige level

### 2.3 Fix Empty States on All Tabs
**Priority: P1**
- **Gap:** GAP-15
- **Impacted files:** `squad_hub_screen.dart`, `events_screen.dart`, `reward_vault_screen.dart`
- **Expected impact:** Graceful "nothing here yet" states with CTAs instead of blank screens

### 2.4 Implement Basic Settings (Sign Out + Name Change)
**Priority: P1 — Users need to be able to sign out**
- **Gap:** GAP-11
- **Impacted files:** `settings_screen.dart`
- **Expected impact:** Judges can reset and restart the demo by signing out

### 2.5 Clean Up Dead UI (Toolbar Icons, Layers Button)
**Priority: P1 — Dead buttons look bad during demo**
- **Gap:** GAP-13, GAP-14
- **Implementation:** Remove 5 unused toolbar icons from quiz screen, remove or hide Layers button

---

## TIER 3 — UX/POLISH UPGRADES

### 3.1 Loading States / Skeletons
- All async screens need a shimmer or spinner
- Priority screens: world_home, events, squads

### 3.2 Auth Error Display
- Show FirebaseAuthException messages in auth_screen
- "Wrong password", "User not found", "Network error"

### 3.3 Profile Screen Enhancement
- Show real XP, streak, sector count from backend
- Show district thumbnail

### 3.4 Round Result → Reward animation
- Confetti or particle effect when XP is awarded
- Map zoom-out animation after returning to world

### 3.5 Vision Quest Success Screen Polish
- Show actual identified object label from Gemini
- Animated "verified" stamp with glow

---

## TIER 4 — ARCHITECTURE HARDENING

### 4.1 Squad Mission Persistence Fix
- Fix `contribute_squad_progress` to actually update squad mission Firestore records
- Currently just grants XP directly to user

### 4.2 In-Memory Session Registry TTL
- Add cleanup interval to session Map in `liveService.ts`
- Prevents memory leak on long-running Cloud Run instances

### 4.3 Type-safe backend DTOs
- Several route handlers use `as any` — add Zod validation to all body params

### 4.4 Leaderboard Data Pipeline Verification
- Trace `end_round` → `upsertLeaderboardEntry` → Flutter `leaderboardProvider` → screen
- Ensure full pipeline works end-to-end

---

## TIER 5 — PERFORMANCE / COST

### 5.1 World Grid Painter Optimization
- Clip to visible viewport before drawing 4000×4000 grid
- Currently RepaintBoundary-cached but initial paint still draws 50×50 = 2500 lines

### 5.2 Firestore Read Caching
- District and user data fetched on every provider watch — add 30s cache TTL

### 5.3 Gemini Session Idle Timeout
- Sessions with no activity for 3 min should auto-terminate
- Prevents cost waste from idle open WebSocket connections

---

## TIER 6 — NICE-TO-HAVE (Post-Hackathon)

- Push notifications via FCM
- District export / share feature
- Squad leaderboard
- Vision quest history gallery
- Map zoom levels with different district views
- Sound design (SFX triggers on reward grant)
- Haptics tuning for all interactions

---

## Implementation Order (Immediate)

1. ✅ Fix auth router guard → GAP-04
2. ✅ Wire live_quiz_screen → GAP-01  
3. ✅ Verify live_onboarding_screen → GAP-02
4. ✅ Fix round_result → growth loop → GAP-06
5. ✅ Wire onboarding name save → GAP-07
6. ✅ Seed demo events + squad → GAP-09, GAP-10
7. ✅ Create district detail screen → GAP-05
8. ✅ Fix empty states → GAP-15
9. ✅ Implement sign out in settings → GAP-11
10. ✅ Remove dead toolbar icons → GAP-13
