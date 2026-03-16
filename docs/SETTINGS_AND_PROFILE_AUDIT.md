# Settings & Profile Audit — Mimz App

## Profile Features
- **Data Rendering**: Uses `currentUserProvider` to fetch. (Correct)
- **Menu Items**:
  - `My District`: Functional. (Navigates to `/world`)
  - `Reward Vault`: Functional. (Navigates to `/rewards`)
  - `My Squad`: Functional. (Navigates to `/squad`)
  - `Leaderboard`: Functional. (Navigates to `/leaderboard`)
  - `Settings`: Functional. (Navigates to `/settings`)
  - `Help`: DEAD BUTTON. 

## Settings Features
- **Profile / Security List Tiles**:
  - Profile -> Nav to `/profile` (redundant but works)
  - Security -> Nav to `/settings/security` (Screen exists)
  - Email -> Read only. 
- **Preferences Toggles**:
  - `Notifications` -> Updates SettingsService state
  - `Haptic` -> Updates SettingsService state
  - `Sound` -> Updates SettingsService state
  - Missing logic: Do these toggles actually control the `flutter_local_notifications` or other native plugins? Need to verify. 
- **Privacy Toggles**:
  - `Location Sharing` -> Updates SettingsService state. Need to verify this propagates to backend.
- **External Links**:
  - Help/Feedback -> URLs (placeholder?)
  - About -> Built in `showAboutDialog`
- **Sign Out**: 
  - Hits `authService.signOut()`. 
  - Resets onboarding via `isOnboardedProvider`. 
  - Gaps: `currentUserProvider` might retain old user info locally on next rapid relogin.

## Action Plan
1. Fix "Help" dead button in Profile.
2. Clear `currentUserProvider` explicit state on signout.
3. Verify SettingsService persistence actually impacts real app behaviors (haptics, sounds, permissions). 
