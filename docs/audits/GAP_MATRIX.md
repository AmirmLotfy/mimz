# MIMZ GAP MATRIX
> Generated: 2026-03-13 | Full Project Gap Assessment

| ID | Category | Severity | Area | Description | User Impact | Demo Impact | Fix |
|---|---|---|---|---|---|---|---|
| GAP-01 | AI/Live Flaw | **CRITICAL** | live_quiz_screen.dart | Mic button toggles local bool — LiveSessionController never started from quiz screen | App does nothing when user speaks | Completely broken demo | Wire `liveSessionControllerProvider` to quiz screen lifecycle |
| GAP-02 | AI/Live Flaw | **CRITICAL** | live_onboarding_screen.dart | Unknown if Gemini session starts during onboarding — needs verification | First-run AI voice may be dead | Demo breaks at first interaction | Verify and wire if needed |
| GAP-03 | AI/Live Flaw | **CRITICAL** | vision_quest_camera_screen.dart | Camera frames captured but Gemini vision analysis wiring unclear | Vision quest may be fake | Demo fails on camera mode | Verify camera frames → Gemini model |
| GAP-04 | Broken Route | **HIGH** | router.dart | No auth redirect guard — unauthenticated users can navigate directly to /world | Security gap | N/A | Add GoRouter redirect using auth state |
| GAP-05 | Missing Screen | **HIGH** | district | No district detail screen — can't inspect structures, resources, prestige | Core game loop obscured | Can't show district progress | Create district_detail_screen.dart |
| GAP-06 | Gameplay Disconnect | **HIGH** | round_result_screen.dart | Round result may not trigger district growth event in world_home_screen | District doesn't grow after playing | Breaks core loop demo | Ensure growthEvent is emitted post-round |
| GAP-07 | Gameplay Disconnect | **HIGH** | onboarding | Emblem + district name selected during onboarding are visual-only — not persisted via API | Profile always shows default name | Demo shows wrong district name | Wire onboarding CTAs to backend |
| GAP-08 | Backend Incomplete | **HIGH** | squads | Squad mission contribution grants XP to user directly — no squad progress updated | Squad play feels disconnected | Squads demo is fake | Fix contribute_squad_progress to update squad records |
| GAP-09 | Missing Data | **HIGH** | events | No events seeded in Firestore — events screen always empty | Nothing to do in events tab | Events tab shows nothing | Seed 2–3 demo events |
| GAP-10 | Missing Data | **HIGH** | squads | No squads seeded in Firestore — squads screen always empty | Nothing to see in squad tab | Squad tab shows nothing | Seed a demo squad |
| GAP-11 | UI Inconsistency | **HIGH** | settings_screen.dart | Settings screen is a stub — no sign out, no name change, no privacy | Trapped in app — no sign out | Demo looks incomplete | Implement sign out + basic settings |
| GAP-12 | Auth Flaw | **MEDIUM** | all | No error state for failed auth (wrong password, network error) — auth_screen may silently fail | Users stuck | N/A | Add auth error display |
| GAP-13 | UI Inconsistency | **MEDIUM** | live_quiz_screen.dart | 5 toolbar icons (shape, map, trophy, settings, overflow) do nothing | Confusing dead UI | Very visible during demo | Remove or connect icons |
| GAP-14 | UI Inconsistency | **MEDIUM** | world_home_screen.dart | Layers map button does nothing | Minor | Minor | Connect or hide |
| GAP-15 | Missing State | **MEDIUM** | all screens | Many screens missing empty states (squad hub, events, rewards vault) | Blank screens feel broken | Visible during demo | Add proper empty states |
| GAP-16 | Missing State | **MEDIUM** | all screens | No loading states on async screens — data flickers from null to real | Poor UX | Noticeable | Add loading skeletons/spinners |
| GAP-17 | Performance | **MEDIUM** | world_home_screen.dart | `_WorldGridPainter` draws a 4000×4000 grid — RepaintBoundary protects it but initial paint is expensive | Slight lag on first render | N/A | Only draw visible region |
| GAP-18 | Security | **MEDIUM** | backend/routes | /live/config route requires no auth — anyone can probe the config | Minor security | N/A | Add auth check |
| GAP-19 | Backend Incomplete | **MEDIUM** | notifications.ts | Notifications route returns empty array — completely unimplemented | No notification system | N/A | Either implement or remove route |
| GAP-20 | Hackathon Demo | **MEDIUM** | all | No demo seed data — fresh install always sees empty state everywhere | Judges see nothing | Critical for demo | Seed demo user, district, events, squad |
| GAP-21 | Cost | **LOW** | liveService.ts | Session registry is in-memory Map — sessions lost on Cloud Run restart; no TTL cleanup | Potential memory leak | N/A | Add periodic cleanup |
| GAP-22 | UI Polish | **LOW** | live_quiz_screen.dart | Score and streak text use `MimzTypography.displayLarge` at 40px but stream from provider is static default "Listening..." | Stale initial text | Minor | Wire displayText to live transcript |
| GAP-23 | Deployment | **LOW** | /healthz | Cloud Run reserves /healthz — always returns Google 404 | None — use /readyz | N/A | Update docs to say use /readyz |
| GAP-24 | Docs | **LOW** | all | Existing audit docs (MAP_RENDERING_AUDIT, AI_PERFORMANCE_AUDIT, etc.) predate current code state | May mislead | N/A | Keep these but note they are superseded by MASTER_AUDIT |

---

## Blocking Hackathon Success

| Gap ID | Blocking? | Notes |
|---|---|---|
| GAP-01 | **YES** | Live quiz must actually work with Gemini |
| GAP-02 | **YES** | Onboarding voice intro must work |
| GAP-03 | **YES** | Vision quest must show real AI vision |
| GAP-04 | **NO** | Security nice-to-have |
| GAP-05 | **YES** | Judges need to see district detail |
| GAP-06 | **YES** | Core loop must be visible |
| GAP-07 | **YES** | District name must match what user says |
| GAP-08 | **NO** | Squads nice-to-have |
| GAP-09 | **YES** | Events tab can't be empty |
| GAP-10 | **YES** | Squad tab can't be empty |
| GAP-11 | **NO** | Settings nice-to-have |
| GAP-20 | **YES** | Demo needs pre-seeded data |
