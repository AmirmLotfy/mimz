# Profile and Settings Specification

## Current State
- `ProfileScreen` shows a mock graph and a hardcoded district name if empty.
- `SettingsScreen` stores toggles (haptics, sounds, location) locally via `SettingsService` but does not synchronize these strongly to a backend Account / Profile document.
- `User` DTO inside `types.ts` has minimal fields: `displayName`, `handle`, `email`, `xp`, `streak`, `sectors`, `districtName`, `interests`, `visibility`.

## Required Fields & Architecture

We must expand the `User` document in Firestore to capture the personalization layer:

### Account Group
- `email`: string
- `provider`: 'google' | 'password' | 'apple'
- `profileImageUrl`: string (Derived from Firebase Storage reference)
- `storagePath`: string (The actual path in bucket)

### Personalization Group
- `preferredName`: string
- `ageBand`: string (e.g. '18-24', '25-34')
- `studyWorkStatus`: string (e.g. 'student', 'professional', 'creator')
- `majorOrProfession`: string
- `coreInterests`: string[] (IDs that map to the Taxonomy)

### Gameplay Preferences Group
- `difficultyPreference`: 'easy' | 'dynamic' | 'hard'
- `squadPreference`: 'solo' | 'social'

### Privacy & App Settings Group
- `districtVisibility`: 'public' | 'friends' | 'private'
- `locationPrecision`: 'exact' | 'coarse' | 'off'
- `appSettings`: Map containing haptics, notifications, sound

## UI Adjustments
- `SettingsScreen` requires a `SaveProfile` behavior that writes these nested groups back to `PATCH /profile`.
- `ProfileScreen` needs a real edit mode overriding any remaining placeholders.
