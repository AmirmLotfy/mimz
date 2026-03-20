# Mimz Production Readiness Audit

Last updated: 2026-03-18

## Executive Summary

Mimz has moved from demo-grade to a stronger production baseline, but is **not fully ship-ready yet**.  
Critical blockers were found in auth strictness, live session security, backend mutation idempotency, and user-facing dead-end flows.

Current assessment:
- **Release build viability:** Medium
- **Auth/account correctness:** Medium
- **AI/live reliability:** Medium
- **Gameplay persistence integrity:** Medium
- **Profile/settings completeness:** Medium
- **Operational readiness:** Medium-low

## Area-by-Area Findings

### 1) Android Release Build
- Status: **Partially ready**
- Good:
  - Release minify/shrink enabled
  - Firebase config present for `com.mimz.mimz_mobile`
- Risks:
  - Release signing can still fall back to debug keystore if `key.properties` missing
  - Manifest includes `ACCESS_BACKGROUND_LOCATION` without clear production necessity path
  - Default backend URL drift risk in app config

### 2) Startup / Bootstrap / Routing
- Status: **Improved, still needs final polish**
- Fixed in this wave:
  - Splash now forces bootstrap resolution before protected routing
  - Router onboarding load treated as unknown instead of false
  - Router provider container is wired synchronously
- Remaining:
  - Add explicit bootstrap-ready route guard (in addition to splash gate) for deep-link safety

### 3) Auth / Account Flows
- Status: **Improved**
- Fixed in this wave:
  - `signOut()` clears pending provider-link credentials and storage keys
  - Removed synthetic local user fallback on bootstrap 403
  - Backend auth bypass now gated by `ALLOW_DEV_AUTH_BYPASS` (default false), blocked in production
- Remaining:
  - provider-linking UX should surface specific error when silent link attempts fail

### 4) Profile / Settings / Account
- Status: **Improved**
- Fixed:
  - Settings null-crash on failed preference load (safe defaults now set)
  - Profile photo update ordering improved to avoid optimistic backend drift
- Remaining:
  - profile stats still include hardcoded placeholder values in parts of UI

### 5) AI / Live
- Status: **Improved**
- Fixed:
  - session ownership validated for tool-execute path
  - removed non-prod session validity bypass
  - added idempotency for `apply_combo_bonus`, `grant_materials`, `validate_vision_result`
  - validated and bounded `/live/session-log` payload
- Remaining:
  - in-memory live session store is restart-sensitive
  - no persisted distributed session state

### 6) Gameplay / District / Progression
- Status: **Improved**
- Fixed:
  - district payload parsing corrected (`response['district']`)
  - district 404 self-heals by replaying bootstrap once
  - reward flow is backend-authoritative (no silent local success on failure)
- Remaining:
  - rewards/events/squad data still partially demo/static in providers

### 7) Squads / Events / Leaderboards
- Status: **Partially ready**
- Fixed:
  - squad create/join buttons now call real API instead of snackbars only
  - duplicate join count inflation fixed in db join logic (event/squad)
  - mission contribution now returns 404 when mission missing
- Remaining:
  - app squad/events providers still include static fallback/demo datasets

### 8) Security / Abuse / Data Safety
- Status: **Improved**
- Fixed:
  - auth bypass production hard-fail
  - live session ownership enforcement
  - duplicate reward grant safeguards expanded
- Remaining:
  - further abuse controls needed for high-scale rollout (IP/device heuristics, stricter quotas)

### 9) Firebase / Cloud / Deployment
- Status: **Partially ready**
- Good:
  - Cloud Run env reflects production project
  - backend reachable and health endpoints operational
- Risks:
  - service URL drift between scripts/docs/app defaults can regress deploys
  - runbook needs strict post-deploy verification checklist

### 10) Observability / Support
- Status: **Partial**
- Good:
  - backend structured request logging in place
- Missing/weak:
  - stronger crash/support integration and standardized incident workflow

## Ship Decision (Current)

- **Go/No-Go:** **No-Go** for broad public release until remaining high-priority items in `PRODUCTION_GAP_MATRIX` are addressed.
- **Canary readiness:** viable after completing listed critical/high blockers and rerunning release smoke matrix.
