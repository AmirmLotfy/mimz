# BACKEND COMPLETENESS AUDIT
> Generated: 2026-03-13

## Routes Assessment

| Route | Endpoints | Auth | Validation | Game Logic | Status |
|---|---|---|---|---|---|
| /live/ephemeral-token | POST | ✅ userId req | ✅ Zod | ✅ audit log | **SOLID** |
| /live/tool-execute | POST | ✅ userId req | ✅ Zod + session | ✅ 15 handlers | **SOLID** |
| /live/session-log | POST | ✅ userId req | Loose | ✅ audit log | Good |
| /live/config | GET | ❌ No auth | None | N/A | **Missing auth** |
| /auth/bootstrap | POST | ✅ userId req | None | ✅ race-safe | **SOLID** |
| /district | GET/PATCH | ✅ userId req | Partial | ✅ calls gameService | Good |
| /profile | GET/PATCH | ✅ userId req | Partial | ✅ whitelisted | Good |
| /rewards | GET | ✅ userId req | None | ✅ calls db | Good |
| /squads | Multiple | ✅ userId req | Partial | ⚠️ Incomplete | **PARTIAL** |
| /events | Multiple | ✅ userId req | Partial | ⚠️ No seed data | **PARTIAL** |
| /leaderboard | GET | ✅ userId req | None | ✅ calls db | Good |
| /notifications | GET | ✅ userId req | None | ❌ Returns [] | **STUB** |

## gameService.ts Assessment

| Function | Status | Notes |
|---|---|---|
| bootstrapUser | ✅ Complete | Race-safe with catch/retry |
| getUser | ✅ Complete | Direct DB call |
| updateProfile | ✅ Complete | Whitelisted fields |
| getDistrict | ✅ Complete | Direct DB call |
| expandTerritory | ✅ Complete | Validates sector cap |
| unlockStructure | ✅ Complete | Full requirements check |
| canAfford | ✅ Complete | Resource check |
| getPrestigeLevel | ✅ Complete | XP tiers |
| calculateResourceRate | ✅ Complete | Tier-based multiplier |
| grantReward | ✅ Complete | Anti-abuse cap enforced |
| calculateScore | ✅ Complete | Difficulty + streak bonus |
| calculateComboBonus | ✅ Complete | Capped streak |
| audit | ✅ Complete | Persists to Firestore |

## executeLiveTool.ts — Tool Handler Assessment

| Tool | Status | Notes |
|---|---|---|
| start_onboarding | ✅ Real | bootstraps user |
| save_user_profile | ✅ Real | persists profile updates |
| get_current_district | ✅ Real | returns district data |
| start_live_round | ✅ Real | creates round in Firestore |
| grade_answer | ✅ Real | updates XP + streak |
| award_territory | ✅ Real | expands territory |
| apply_combo_bonus | ✅ Real | bonus XP + materials |
| grant_materials | ✅ Real | updates resources |
| end_round | ✅ Real | closes round + updates leaderboard |
| start_vision_quest | ✅ Real | creates quest record |
| validate_vision_result | ✅ Real | grants XP if confidence > 0.6 |
| unlock_structure | ✅ Real | full requirements + resource check |
| join_squad_mission | ⚠️ Stub | Only audit log — no squad record updated |
| contribute_squad_progress | ⚠️ Partial | Grants user XP but doesn't update squad |
| get_event_state | ✅ Real | fetches event from Firestore |

## Critical Missing Backend Pieces

1. **Squad progression** — `contribute_squad_progress` does not update `squads/{id}/missions/{id}.currentProgress`
2. **Notifications** — `/notifications` returns `[]` always — no delivery system
3. **Ephemeral token config** — `/live/config` accessible without auth
4. **Events seeding** — No events in Firestore — all event routes work but return empty
5. **Squads seeding** — No squads in Firestore — all squad routes work but return empty
6. **Session cleanup** — In-memory sessionMap never cleaned up if Cloud Run stays alive

## Summary

- **gameService.ts**: 13/13 functions ✅ fully implemented
- **executeLiveTool.ts**: 13/15 tools ✅, 2/15 partial ⚠️
- **Backend routes**: 8/12 solid, 2/12 partial, 1/12 stub, 1/12 missing auth
- **Overall backend**: Remarkably solid for a hackathon project — main issues are data seeding and squad persistence
