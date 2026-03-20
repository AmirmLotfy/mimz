# AUTH AND IDENTITY AUDIT
> Generated: 2026-03-13

## Auth Methods Supported

| Method | Frontend | Backend | Status |
|---|---|---|---|
| Email/Password sign-up | ✅ AuthScreen | ✅ Firebase Auth | Working |
| Email/Password sign-in | ✅ AuthScreen | ✅ Firebase Auth | Working |
| Google Sign-In | ✅ AuthScreen | ✅ Firebase Auth | Working |
| Password reset | ❌ Missing | N/A | Not implemented |
| Email link sign-in | ❌ Missing | N/A | Not needed |
| Apple Sign-In | ❌ Missing | N/A | Not needed for hackathon |

## Bootstrap Flow

| Step | Status | Notes |
|---|---|---|
| Firebase Auth returns userId | ✅ | Standard Firebase |
| App calls POST /auth/bootstrap | ✅ | Triggered after sign-in |
| bootstrapUser creates user record | ✅ Race-safe | Catch/retry on Firestore conflict |
| bootstrapUser creates district record | ✅ Race-safe | District with default values |
| Idempotent: existing user returned as-is | ✅ | Fast path with early return |
| Duplicate district prevention | ✅ | Checks for existing district |

## Auth Guard Assessment

| Check | Status |
|---|---|
| Auth state persisted across app restart | ✅ Firebase handles |
| Auth state exposed via authProvider | ✅ Riverpod provider |
| Unauthenticated access to protected routes | ❌ No redirect guard in router |
| Token refresh | ✅ Firebase SDK handles |
| Sign-out behavior | ❓ Settings stub — sign out not implemented |

## Identity Risk Assessment

| Scenario | Risk | Current Handling |
|---|---|---|
| User signs in with Google | Low | Standard Firebase Google OAuth |
| Same Gmail used for email/password after Google | Medium | Firebase shows error — not handled gracefully |
| Provider linking | Not implemented | Minor risk |
| Duplicate bootstrap calls (race) | Low | Race-safe catch/retry in place |
| Duplicate district creation | Low | Race-safe in bootstrapUser |
| userId from JWT invalid | Low | auth middleware validates |
| User deleted from Auth but exists in Firestore | Low | getUser returns old record |

## Error Handling Assessment

| Error | Handled? | UX Response |
|---|---|---|
| Invalid email | ❓ | Firebase throws, may not display |
| Wrong password | ❓ | Firebase throws, may not display |
| Network failure during sign-in | ❓ | May silently hang |
| Google sign-in cancelled | ❓ | May leave loading state |
| Bootstrap API failure | ❓ | May leave app in limbo |

## Summary

- Auth infrastructure: **Solid** — Firebase Auth + backend bootstrap
- Bootstrap idempotency: **Solid** — race-safe implementation
- Auth guard in router: **MISSING** — should be P0 fix
- Sign out: **MISSING** — settings is a stub
- Error states: **Missing** — auth screen needs error display
- Identity scenarios: **Mostly safe** — Firebase handles provider conflicts at auth level
