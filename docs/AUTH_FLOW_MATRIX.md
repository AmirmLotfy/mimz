# Auth Flow Matrix — Mimz App

This matrix outlines the expected behavior for all edge cases during authentication, onboarding, and provider linking.

## 1. Fresh Sign Up

| Scenario | Pathway | Expected State | UI Response |
|----------|---------|----------------|-------------|
| New Email | `AuthService.createAccountWithEmail` | FireAuth account created | Nav to `/permissions` -> `/district/name` |
| New Google | `AuthService.signInWithGoogle` | FireAuth account created | Nav to `/permissions` -> `/district/name` |

## 2. Returning Sign In

| Scenario | Pathway | Expected State | UI Response |
|----------|---------|----------------|-------------|
| Known Email | `AuthService.signInWithEmail` | Valid session established | Nav to `/world` (if onboarded) or `/permissions` (if not) |
| Known Google | `AuthService.signInWithGoogle` | Valid session established | Nav to `/world` (if onboarded) or `/permissions` (if not) |

## 3. Account Link / Conflict resolution

| Scenario | Pathway | Expected State | UI Response |
|----------|---------|----------------|-------------|
| User has Email, Tries Google (same email) | Google SignIn -> catch `account-exists-with-different-credential` | Pending google credential saved | Error banner in UI: "already registered. Sign in with password to link" |
| User completes Email auth after pending Google link | Email SignIn succeeds -> `AuthService.completePendingProviderLink` | FireAuth User linked to Google credential! | Link completes silently, user proceeds to `/world`. |

## 4. Reset & Verification
- **Forgot Password**: Bottom sheet triggers reset link safely. 
- **Email Verification**: (Needs Implementation) Must block user from entering app until they verify.

## 5. Session Resume
- On app launch, `SplashRoute` awaits Firebase `authStateChanges`. 
- If user exists, token refreshed, allowed into shell. If biometrics enabled, present `local_auth` prompt.
