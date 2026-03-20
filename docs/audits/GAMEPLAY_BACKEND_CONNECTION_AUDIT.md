# GAMEPLAY BACKEND CONNECTION AUDIT — Mimz
> Last updated: 2026-03-15

## Backend Authority Matrix

| Gameplay Action | Backend Handler | Firestore Write | Idempotent |
|----------------|----------------|-----------------|------------|
| Auth bootstrap | bootstrapUser | users, districts | ✅ race-safe |
| Profile update | updateProfile | users | ✅ |
| Start round | start_live_round | rounds | ✅ by roundId |
| Grade answer | grade_answer | users.xp, users.streak, rounds | ❌ needs corr-id guard |
| Award territory | award_territory | districts.sectors, users.sectors | ❌ needs corr-id guard |
| Apply combo | apply_combo_bonus | users.xp, districts.resources | ❌ |
| Grant materials | grant_materials | districts.resources | ❌ |
| End round | end_round | rounds.status, leaderboard | ✅ by roundId |
| Unlock structure | unlock_structure | districts.structures, resources | ✅ (duplicate check) |
| Vision quest XP | validate_vision_result | users.xp | ❌ |
| Squad progress | contribute_squad_progress | squads.missions | ✅ |
| Squad join mission | join_squad_mission | Nothing (audit only) | ⚠️ shallow |

---

## Connection Integrity

### ✅ Connected Correctly
- Auth → Firestore user doc (users/{uid})
- District → Firestore district doc (districts/district_{uid})
- Rounds → Firestore rounds collection
- Leaderboard → upserted on every end_round

### ⚠️ Partially Connected
- Vision quest: XP granted but quest not persisted as a document
- Squad join: audit log written but no Firestore squad participation record
- Event contribution: no tool maps to event scoring in executeLiveTool

### ❌ Client-Only (Should Be Fixed)
- None. All significant state changes go through backend tools.

---

## Anti-Abuse Controls

| Control | Implementation |
|---------|---------------|
| Reward cap | maxRewardPerHour = 5000 XP/hour |
| Sector cap | maxSectorsPerRound = 3 |
| Streak cap | maxStreakBonus = 10 |
| Session validity | isSessionValid() before any tool execution |
| Rate limiting | fastify/rate-limit on all routes |
| Tool arg validation | Zod schema per tool in toolSchemas.ts |
| Audit trail | audit() called in every mutating tool |

---

## Recommendations

1. **Add correlationId idempotency** to grade_answer and award_territory — if same `correlationId` executes twice, return cached result from memory map (no re-write).
2. **Persist vision quest** to Firestore `visionQuests/{questId}` for history and stats.
3. **Persist squad mission join** — write `squadMissions/{missionId}/participants/{userId}` so contribute can reference it.
4. **Add `score_event_contribution` tool** to executeLiveTool for event scoring path.
