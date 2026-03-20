# GAMEPLAY AND MAP AUDIT
> Generated: 2026-03-13

## District System Assessment

| Aspect | Status | Notes |
|---|---|---|
| District creation | ✅ Auto-created on bootstrap | Default: 1 sector, 50 stone, 20 glass, 40 wood |
| District persistence | ✅ Firestore | Via db.createDistrict |
| District growth via gameplay | ⚠️ Backend solid, Flutter broken | award_territory tool works; UI doesn't trigger it |
| Resources management | ✅ Backend solid | addResources/addStructureToDistrict |
| Structure unlock | ✅ Backend solid | Full requirements + resource check |
| Prestige level | ✅ Backend solid | getPrestigeLevel XP tiers |
| District detail view | ❌ Missing screen | No way to see structures/resources in app |

## Game Loop Assessment

| Step | Status | Notes |
|---|---|---|
| User opens app | ✅ Sees map with district |
| User starts quiz | 🔴 Tap "quiz" → no Gemini session starts |
| AI asks questions | 🔴 Not wired |
| User answers by voice | 🔴 Not wired |
| grade_answer tool called | 🔴 Not wired |
| XP + streak awarded | 🔴 Depends on above |
| award_territory tool called | 🔴 Depends on above |
| Map grows | 🔴 No growth event triggered |
| User sees bigger district | 🔴 |

**CRITICAL: The entire gameplay loop is broken because live_quiz_screen doesn't wire to the controller.**

## Vision Quest Assessment

| Step | Status | Notes |
|---|---|---|
| User taps "Vision Quest" | ✅ Opens camera screen |
| Camera feed shown | ✅ Real camera |
| Frames sent to Gemini | ⚠️ Unclear if frames route to model |
| Gemini responds | ⚠️ Needs verification |
| validate_vision_result called | ⚠️ Unclear |
| XP awarded | ✅ If result is valid |
| Success screen shown | ✅ Screen exists |

## Map System Assessment

| Aspect | Status | Quality |
|---|---|---|
| Hex grid rendering | ✅ Real | High quality CustomPainter |
| Growth animation | ✅ Real | Shockwave + pop with timeline phases |
| InteractiveViewer | ✅ Real | Pinch to zoom, pan |
| Camera centering | ✅ Real | Animated to new growth center |
| World grid | ✅ Real | 4000×4000 grid with RepaintBoundary |
| Structure indicators | ✅ Partial | Dot markers only — no real icons |
| New hex animation | ✅ Real | Pop + elasticOut curve |
| Growth event triggering | ⚠️ Partial | Event state exists but not populated post-round |

## Reward System Assessment

| Component | Status | Notes |
|---|---|---|
| grantReward (backend) | ✅ Real | Rate-limited (maxRewardPerHour) |
| Reward log persisted | ✅ Real | Firestore rewards collection |
| Reward vault screen | ⚠️ Visual | Shows reward types, no real data loaded |
| Reward → district update | ⚠️ Partial | Materials granted but no resource display in UI |

## Squad System Assessment

| Feature | Status | Notes |
|---|---|---|
| Squad creation | ⚠️ Route exists | No UI flow to create squad |
| Squad joining | ⚠️ Route exists | No UI flow |
| Squad missions | ⚠️ Partial | Tool handler exists but no Firestore update |
| Squad display | ❌ No data | Always empty — no seed squads |

## Events System Assessment

| Feature | Status | Notes |
|---|---|---|
| Event listing | ⚠️ Route exists | Firestore has no events |
| Event joining | ⚠️ Route exists | Works but no events to join |
| Event leaderboard | ⚠️ Route exists | No data |

## Summary

- Map system: **Premium quality** — hex growth, animations, viewport, RepaintBoundary all implemented
- District backend: **Solid** — full CRUD, resources, structures, prestige
- Gameplay loop: **BROKEN at the UI layer** — quiz screen not wired
- Squads/Events: **Backend routes work, no seed data**
- District detail: **Missing screen entirely**
