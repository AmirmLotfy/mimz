# Release Readiness Audit - Mimz

**Date:** 2026-03-16  
**Status:** PARTIALLY READY - BUILD PASS, RUNTIME CERTIFICATION BLOCKED

## Baseline Findings

| Category | Risk | Current Finding |
| :--- | :--- | :--- |
| Android release config | High | Signing secrets are hardcoded in `app/android/app/build.gradle.kts`; release keystore assumptions are not safely externalized. |
| Firebase/Google auth | High | Release SHA verification is incomplete without production keystore confirmation; auth bootstrap failure UX can still route forward on profile fetch failure. |
| Backend/env safety | High | Backend config still allows dev-style fallback for `GEMINI_API_KEY`; live token flow returns raw API key as session token. |
| Release scripts | Medium | Script path assumptions and smoke-test log handling have edge cases; preflight checks are not consistently enforced before build. |
| Docs accuracy | Medium | Several release docs still claim full readiness and include stale signing/region assumptions. |

## Hardening Scope (Active)
1. Android release config hardening (signing, manifest placeholders, shrinker safety).
2. Firebase/Google release auth resilience and clear user-facing failure behavior.
3. Backend/env/live release-safe behavior (fail-fast + token safety).
4. Release build + device install + runtime smoke verification.
5. Script and deployment-note hardening for reproducibility.

## Hardening Outcomes
- Release signing secrets externalized from source and build fallback behavior made explicit.
- Manifest maps key moved to placeholder/property injection.
- Release auth bootstrap now checks profile load before navigation.
- Backend now fails fast on missing Gemini API key in production config/deploy paths.
- Release scripts hardened for path safety and stronger diagnostics.
- Release APK successfully built at `app/build/app/outputs/flutter-apk/app-release.apk`.

## Remaining Blockers
1. No connected Android device during this run for runtime smoke certification.
2. Firebase Console SHA registration still needs explicit verification for production Google sign-in confidence.
3. Maps API key must be provided via release property/env for guaranteed map runtime.
4. Live token architecture is functionally working but still not true scoped ephemeral token security.

## Acceptance Checklist
- [x] `flutter build apk --release` succeeds with non-hardcoded signing inputs.
- [ ] Release APK installs and launches on physical Android device.
- [ ] Critical flows pass smoke test (auth, onboarding, map, live, settings, sign-out).
- [x] No debug-only dependencies required for runtime success.
- [x] Firebase/Google release requirements are documented with exact remaining blockers.
- [x] Backend env defaults are production-safe and fail fast when critical secrets are missing.
- [x] Release scripts run from any working directory and provide actionable diagnostics.