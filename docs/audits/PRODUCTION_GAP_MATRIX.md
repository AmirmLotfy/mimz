# Mimz Production Gap Matrix

| ID | Area | Severity | Current | Target | Fix Status |
|---|---|---:|---|---|---|
| PR-001 | Backend auth strictness | Critical | Non-prod auth bypass possible | Strict token validation unless explicit dev bypass flag | Fixed |
| PR-002 | Bootstrap/routing races | High | first-route gate race possible | deterministic auth/bootstrap/onboarding gating | Partially fixed |
| PR-003 | Pending link credential leakage | High | stale provider link state across sign-out | clear pending link credentials on sign-out | Fixed |
| PR-004 | Live tool session ownership | Critical | sessionId validity checked without ownership | enforce `session.userId == request.userId` | Fixed |
| PR-005 | Live reward idempotency gaps | High | combo/materials/vision could double-grant | idempotency on all grant-affecting tools | Fixed |
| PR-006 | Session log abuse surface | Medium | unvalidated `events` payload | schema + max events validation | Fixed |
| PR-007 | District payload contract mismatch | Critical | client parsed wrong shape | parse nested `district` object | Fixed |
| PR-008 | District indefinite loading behavior | High | previously could spin indefinitely | explicit loading/error/empty/retry states | Fixed |
| PR-009 | Reward claim false-success path | High | failed claim could still proceed | block navigation on claim failure + retry | Fixed |
| PR-010 | Squad create/join dead UI | Critical | snackbar-only (no API calls) | real API integration + error handling | Fixed |
| PR-011 | Squad/event count inflation | High | duplicate joins increment counts repeatedly | transactional idempotent joins | Fixed |
| PR-012 | Settings load crash risk | High | null bool state after load failure | safe defaults + no null dereference | Fixed |
| PR-013 | Profile photo consistency | Medium | optimistic local drift on failed PATCH | backend-first update sequencing | Fixed |
| PR-014 | Static demo providers | High | events/rewards/squad providers use static data | API-backed providers and robust async states | Open |
| PR-015 | Live session persistence | High | in-memory session map reset on restart | shared persistent session store / resilient refresh path | Open |
| PR-016 | Release signing fallback | High | debug signing fallback still allowed | fail release build when release keystore absent | Open |
| PR-017 | Observability depth | Medium | basic logs only | stronger crash/support instrumentation | Open |
| PR-018 | Cost/rate safeguards | Medium | baseline limits only | per-user/IP/session abuse controls | Open |

## Priority Queue

1. PR-014, PR-015, PR-016 (must close before broad release)
2. PR-017, PR-018 (close before scale-up)
