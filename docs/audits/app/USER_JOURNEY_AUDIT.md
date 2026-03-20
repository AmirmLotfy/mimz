# User Journey Audit (Mimz)

## 1. First Install Journey
**Flow:** Splash → Welcome → Auth → Permissions → Live Onboarding → Profile Summary → Emblem → District Name → Home Map
**Audit Finding:** 
- The journey visually flowed well but structurally had no "completion" flag.
- The `OnboardingSummaryScreen` used hardcoded data (`Explorer`, `user@mimz.app`), breaking the immersion of having just signed up.
**Resolution:** 
- The `DistrictNamingScreen` now sets `isOnboardedProvider = true` securely.
- `OnboardingSummaryScreen` uses `currentUserProvider` to dynamically fetch the newly registered user's name, email, and handle.

## 2. Returning User Journey
**Flow:** App Open → Splash → Home Map
**Audit Finding:**
- **Critical Failure:** `SplashScreen` was entirely decoupled from authentication state. It always delayed for 2 seconds and unconditionally routed to `/welcome`. Returning users had to manually skip the welcome and hit the skip button on auth every time.
**Resolution:**
- `SplashScreen` is now a smart router. It awaits the Firebase `authStatusProvider`.
- If `isAuthenticated == true` AND `isOnboarded == true`, it bypasses `/welcome`, `/auth`, and `/permissions`, immediately sending the user to `/world`.

## 3. Auth Journeys
**Flow:** Email Login / Google Login / Sign Out
**Audit Finding:**
- Signing out (`SettingsScreen`) cleared the `AuthService` session but did not clear the local onboarding state flag.
- "Skip" auth button incorrectly pushed the user into the onboarding flow (`/permissions`), bypassing all constraints.
**Resolution:**
- Sign Out now calls `resetOnboarding()` to wipe the local `flutter_secure_storage` flag.
- "Skip" authentication action has been wired to evaluate `isOnboardedProvider` to conditionally bounce the ghost user to `/world`.

## 4. Core Gameplay Journeys
**Flow:** Home → Live Quiz → Result → Home Updates
**Audit Finding:**
- Gameplay transitions (`/play/quiz` → `/play/quiz/result`) functioned flawlessly. They are correctly implemented as top-level routes pushed *over* the `AppShell` so the bottom navigation bar doesn't distract the user during live rounds.

## 5. Error & Retry Journeys
**Flow:** App Open (No Internet / Stale Token)
**Audit Finding:**
- If network connection fails and `AuthService` throws or returns `null`/unauthenticated, `appRouter` safely catches the user on the next context read and drops them at `/welcome`.
**Resolution:** Flow is robust. No modifications required.
