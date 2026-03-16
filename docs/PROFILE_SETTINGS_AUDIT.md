# Profile & Settings Audit

## Scope
- `ProfileScreen`, `ProfileEditScreen`, `SettingsScreen`, `SecurityScreen`
- Profile/provider/service wiring, account/settings actions, state persistence, and UX states

## Current State (as implemented)

### Profile
- Avatar change/remove exists in `ProfileScreen` and writes profile metadata to `/profile`.
- Profile screen uses provider-backed user data, but includes hardcoded subtitle values in several menu tiles (reward count, squad count, rank).
- Upload/remove failure UX is snackbar-only; no in-place retry affordance.

### Profile Edit
- Save flow is real and persists through `PATCH /profile`.
- Field set includes display name, preferred name, major/profession, district name, interests, difficulty, and voice.
- Difficulty values are inconsistent with app/backend (`casual/dynamic/hardcore` vs `easy/dynamic/hard`).

### Settings
- Notifications/haptic/sound/location toggles persist via `SettingsService` (`FlutterSecureStorage`).
- Security route exists and includes provider display + reset password.
- Dead/fake items still exist:
  - Email tile action is no-op.
  - My Interests route points to onboarding route that is blocked for onboarded users by router redirect.
- Difficulty/squad writes use optimistic update but silently swallow patch failures.

### Security
- Biometrics state checks and enable/disable flow exist.
- "Open Settings" action for unenrolled biometrics is placeholder behavior.
- File currently imports haptics from the wrong path.

## Confirmed Gaps
1. Compile safety: wrong imports and method references in profile/settings area.
2. Dead account actions (Email) and blocked interests flow.
3. Inconsistent preference enum values.
4. Missing explicit error/recovery UX for some settings writes.
5. Safe area/padding treatment is inconsistent across settings-related screens.

## Acceptance Criteria for Hardening
- No dead settings/profile action remains visible.
- Every visible action either performs a real flow or is intentionally removed.
- Profile edit and settings updates display success/error states and do not silently fail.
- Difficulty/squad values are consistent app-wide and backend-compatible.
- Security screen opens actual app settings where required.
- All profile/settings screens are safe-area correct and bottom-nav safe.
