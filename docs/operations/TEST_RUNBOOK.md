# Mimz Test Runbook

This document describes how to run tests across the Mimz project.

## Running Flutter Tests

To run all Flutter tests:
```bash
./run_flutter_tests.sh
# or manually:
cd app && flutter test
```

## Running Backend Tests

To run all backend tests:
```bash
./run_backend_tests.sh
# or manually:
cd backend && npm test
```

## Running Everything

To run the entire test suite (Flutter + Backend):
```bash
./run_all_tests.sh
```

## Production Reliability Gates (Release)

Run these before shipping a release APK:

1. **App tests (auth + live regressions)**
```bash
cd app
flutter test test/features/auth/ test/features/live/
```

2. **Backend typecheck**
```bash
cd backend
npm run build
```

3. **Backend health**
```bash
cd ..
./scripts/validate_deployment.sh
```

4. **Cloud Run auth/live error sweep**
```bash
gcloud logging read 'resource.type="cloud_run_revision" AND resource.labels.service_name="mimz-backend" AND (jsonPayload.url="/auth/bootstrap" OR jsonPayload.url="/live/ephemeral-token")' \
  --project=mimzapp --limit=50
```

Pass criteria:
- No repeated 401/400 storm for `/auth/bootstrap` during smoke.
- Live token endpoint returns 200 for authenticated sessions.
- Device smoke does not get stuck in infinite retry loops.

## Writing Tests

*   **Flutter:** Place tests in `app/test/`. Use `test/test_helpers/test_app_wrapper.dart` to mount widgets with localization and providers.
*   **Backend:** Place tests in `backend/test/`. We use Vitest. Run `npm run test:watch` for TDD.
