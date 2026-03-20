# Implementation Gap Analysis

Last updated: 2026-03-18

## Method

Ideal behavior from source-of-truth docs was compared against current Flutter + backend implementation.

## Gap Matrix

| Issue ID | Area | Severity | Current Behavior | Ideal Behavior | Recommended Fix | Effort | Demo Impact | Retention Impact | Status |
|---|---|---|---|---|---|---|---|---|---|
| MIMZ-001 | District payload contract | Critical | Client parsed `/district` wrapper as direct district object | Client parses canonical `district` object and handles schema mismatch safely | Parse `response['district']` with explicit validation | S | High | High | Fixed |
| MIMZ-002 | District loading UX | Critical | District error path previously collapsed into infinite loading | Loading, error, and empty are distinct with actions | Separate state checks and show retryable error UI | S | High | High | Fixed |
| MIMZ-003 | Auth recovery from profile failure | High | User could get stuck on profile error with no logout path | Error states expose sign-out and retry | Add sign-out action to profile error/loading states | S | High | High | Fixed |
| MIMZ-004 | Cloud Run edge auth policy | Critical | Requests blocked by invoker auth before backend middleware | Service reachable, app auth enforced by backend middleware | Use `--no-invoker-iam-check`, align deploy scripts/docs | S | High | High | Fixed |
| MIMZ-005 | Reward authority | Critical | Client could progress locally even when backend mutation failed | Reward progression confirmed by backend only | Remove silent local grant; fail with retry UX | M | High | High | Fixed |
| MIMZ-006 | Result flow error handling | High | Reward claim failure could still continue flow as success | Stay on result and retry on failure | Show actionable error and keep claim CTA | S | High | Medium | Fixed |
| MIMZ-007 | Routing gate completeness | High | Route guard mainly used auth+onboarding flags; bootstrap resolution was implicit | Explicit bootstrap gate before protected shell | Route authenticated unresolved bootstrap states to splash | M | High | High | Fixed |
| MIMZ-008 | Permission state reflection | Medium | Permission status not consistently centralized in settings | Unified permission status + recovery controls | Add permission status provider + settings actions | M | Medium | Medium | Open |
| MIMZ-009 | Live session reconnection and reset semantics | High | Retry could reuse stale transport/listeners and ambiguous recovery actions | Clean reconnect lifecycle with deterministic retry/reset/exit | Add pre-start teardown, hard reset action, explicit world exit | M | High | High | Fixed |
| MIMZ-010 | Model routing centralization | Medium | Some model names/config may still be scattered | Single role-based model registry | Enforce role keys and startup validation | M | Medium | Medium | In Progress |
| MIMZ-011 | Live region coupling risk | Critical | Live websocket region could inherit Cloud Run region and fail by model availability | Dedicated live region config independent of backend deploy region | Add `GEMINI_LIVE_VERTEX_LOCATION` config + deploy wiring | S | High | High | Fixed |
| MIMZ-012 | Live tool session authorization mismatch | High | Tool calls could use websocket session id instead of backend-minted session id | Backend-issued session id used for all tool-execute calls | Parse/store `sessionId` from token response and preserve through session | S | High | High | Fixed |
| MIMZ-013 | Onboarding persistence depth | Medium | Completion gate exists; personalization persistence depth uneven | Save-as-you-go and resumable onboarding draft | Add onboarding draft endpoint/state reconciliation | M | Medium | Medium | Open |
| MIMZ-014 | Squad/event contribution visibility | Medium | Contribution effects not always obvious post-round | Result screens show contribution deltas | Add squad/event delta badges in round result | M | Medium | Medium | Open |
| MIMZ-015 | Offline/degraded mode UX | Medium | Partial handling via errors/retries, no unified degraded banner strategy | Unified global degraded state messaging | Add connectivity/backend status banner service | M | Medium | Medium | Open |
| MIMZ-016 | Test coverage for critical path | High | Some tests exist, but reliability path coverage incomplete | Deterministic tests for auth/bootstrap/live/rewards/district | Add targeted unit/widget tests and smoke checklist | M | High | High | In Progress |

## Highest Priority Remaining

1. `MIMZ-007` bootstrap-aware route gating.
2. `MIMZ-013` onboarding draft persistence depth.
3. `MIMZ-016` critical-path test expansion.
4. `MIMZ-010` full model role enforcement.

## Fixed In This Wave

- `MIMZ-001`, `MIMZ-002`, `MIMZ-003`, `MIMZ-004`, `MIMZ-005`, `MIMZ-006`, `MIMZ-007`, `MIMZ-009`, `MIMZ-011`, `MIMZ-012`.
