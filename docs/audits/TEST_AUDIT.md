# Mimz Test Audit

## Current State of Flutter Tests (`app/test`)
- **Structure:** Only contains a default `widget_test.dart` which is likely failing or irrelevant to the actual app.
- **Dependencies:** Missing dedicated mocking libraries (like `mocktail` or `mockito`). Missing test helper infrastructure.
- **Coverage:** Effectively 0% for actual product code.
- **Command:** `flutter test` might run but tests nothing valuable.

## Current State of Backend Tests (`backend/test`)
- **Structure:** Contains unit tests for `domainModels`, `gameLogic`, `modelConfig`, `structureCatalog`, and `toolRegistry`.
- **Dependencies:** Uses `vitest` which is good.
- **Coverage:** Covers pure logic functions, but likely missing integration/API route tests (auth middleware, live websocket logic, ephemeral token service).
- **Command:** `npm test` runs `vitest run`.

## Gaps Identified
- **Flutter:** Needs a massive overhaul. `test_helpers` directory with `test_app_wrapper` and `provider_overrides` must be created. Real widget and unit tests needed for `auth`, `onboarding`, `live_quiz`, `vision_quest`, and map logic.
- **Backend:** Lacks endpoint testing and middleware testing. No factories or fixtures for requests/responses.
- **Scripts:** No unified test scripts at the repository root.

## Action Plan
1. Add `mocktail` to Flutter and setup test helpers.
2. Fix any failing baseline tests.
3. Write critical path Flutter tests.
4. Enhance backend tests with API route validations.
5. Create single commands at the root `scripts/` dir.
