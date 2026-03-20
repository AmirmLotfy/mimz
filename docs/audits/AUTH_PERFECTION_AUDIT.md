# Auth Perfection Audit — Mimz App

## Summary of Critical Issues Found

### 🔴 CRITICAL
| Issue | Location | Impact |
|---|---|---|
| Same-email provider link doesn't complete automatically | `auth_service.dart:206` | Google users with existing email accounts get stuck, must re-tap Google after sign in. |
| Potential Guest Mode remnants | `router.dart` (need to verify) | App might allow unauthenticated access to protected routes if guards are weak. |
| Missing biometric implementation | `settings_screen.dart`, `biometric_service.dart` | UI toggle exists for biometrics, but it doesn't actually gate the app resume or login. Failed open. |

### 🟡 INCOMPLETE
| Issue | Location | Impact |
|---|---|---|
| User State not reset on sign-out | `auth_provider.dart:62` | `currentUserProvider` might hold stale user data if not properly invalidated on sign-out. |
| Settings Toggles read-only | `settings_screen.dart:49` | Toggles connect to `SettingsService`, but need to ensure `SettingsService` actually persists and applies them (e.g. notifications). |
| Missing Email Verification Gate | `auth_service.dart:130` | Sends verification email but UI doesn't force user to verify before proceeding. |
| Help/FAQ/About are placeholders | `settings_screen.dart` | Links open URLs but no deep in-app support or real legal docs yet. |
| No Email Verification UI | anywhere | Sent in auth_service but no screen to enter code/verify link. |

### 🟢 WORKING CORRECTLY
- Google Sign-In service layer (correct, handles cancellation, fetches tokens).
- Email/Password form validation and error handling is wired in `EmailAuthScreen`.
- Firebase auth state listener (`_init()` in `AuthService`) accurately updates status stream.
- Token caching and refresh logic in `AuthService` is sound.
- Password reset logic is wired to Firebase and works via BottomSheet in `EmailAuthScreen`.

## Phase-by-Phase Analysis

### Phase 1: Email Auth
- Email/password form exists.
- Needs verification enforcement.

### Phase 2: Google Auth  
- Service layer is implemented.
- Need to ensure idempotency on user creation in backend.

### Phase 3: Same-email / Multi-provider
- `_handleProviderConflict` stores pending link info, but user must manually re-trigger. Need to streamline the linking UX.

### Phase 4: Sign Out
- Firebase + Google sign-out works.
- `currentUserProvider` cache needs explicit invalidation.

### Phase 5: Biometrics
- Service exists, but not wired into an App lifecycle observer to gate resume.

---
*Generated: 2026-03-14 — Full hardening pass initiated*
