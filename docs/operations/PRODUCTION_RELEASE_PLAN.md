# Mimz Production Release Plan

## Release Goal

Ship a stable Android release connected to production backend/Firebase with deterministic auth, backend-authoritative progression, and resilient live sessions.

## Stage Plan

### Stage 1: Critical Blockers (Required)
- Enforce release signing with release keystore only.
- Remove remaining static demo data providers from live user paths.
- Add resilient live session handling for backend restarts (session refresh strategy).
- Re-run full release and smoke checks.

### Stage 2: High-Priority Hardening
- Strengthen observability and support diagnostics.
- Expand anti-abuse controls for live and reward mutation endpoints.
- Complete route-level bootstrap-readiness guard for deep links.

### Stage 3: Operational Readiness
- Freeze env/service URL source-of-truth.
- Finalize runbook and on-call response matrix.
- Publish canary rollout + rollback criteria.

## Release Confidence Criteria

Release can proceed when:
- all critical gaps in `PRODUCTION_GAP_MATRIX` are closed,
- release build and install pass,
- smoke tests pass on physical Android device,
- no auth/bootstrap/district hard blockers remain.

## Rollout Recommendation

- Canary rollout (5-10%) -> monitor 24h -> expand to 50% -> full.
- Rollback trigger: bootstrap failure spike, live session failure spike, or reward mutation errors.
