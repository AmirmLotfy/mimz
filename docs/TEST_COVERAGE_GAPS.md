# Mimz Test Coverage Gaps

## 🔴 Flutter Critical Gaps
1. **Auth & Bootstrap:** No tests for routing logic (signed in vs signed out vs onboarded).
2. **Onboarding:** No tests verifying onboarding state gets saved properly.
3. **World Map:** No tests for `world_provider` or district growth state.
4. **Live Quiz State:** No tests for connection phases, tool execution parsing, or token failures.
5. **Vision Quest:** No tests for successful detection logic and state transitions.
6. **Navigation:** Escaping modals, deep linking edges, shell route states are untested.

## 🔴 Backend Critical Gaps
1. **Live API (`/live/config`, `/live/token`):** Untested.
2. **Auth Middleware (`server.authenticate`):** Untested. No tests for token rejection.
3. **Profile Updates:** `/profile` PATCH endpoint untested.
4. **Tool Registry Side Effects:** The logic is unit tested, but the DB updates happening after a tool runs (like adding a squad mission or giving sectors) lack integration coverage.
5. **Health Checks:** `/readyz` is untested.
