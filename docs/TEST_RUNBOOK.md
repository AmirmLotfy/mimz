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

## Writing Tests

*   **Flutter:** Place tests in `app/test/`. Use `test/test_helpers/test_app_wrapper.dart` to mount widgets with localization and providers.
*   **Backend:** Place tests in `backend/test/`. We use Vitest. Run `npm run test:watch` for TDD.
