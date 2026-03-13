# UI/UX GAP AUDIT
> Generated: 2026-03-13

## Design System Consistency

| Token Type | Used Consistently? | Notes |
|---|---|---|
| Colors (MimzColors) | ✅ Yes | `nightSurface`, `cloudBase`, `persimmonHit`, `acidLime`, `mossCore` used uniformly |
| Typography (MimzTypography) | ✅ Yes | `displayLarge`, `displayMedium`, `caption` used correctly |
| Spacing (MimzSpacing) | ✅ Yes | `sm`, `base`, `lg`, `xl`, `xxl` consistent |
| Border radius (MimzRadius) | ✅ Yes | `pill` for chips, rounded for cards |
| Elevation/shadows | ✅ Yes | Consistent boxShadow patterns |
| Icon style | ⚠️ Minor | Mix of Material Icons — acceptable for hackathon |

## Screen-by-Screen UX Gaps

### WorldHomeScreen
- ✅ Beautiful — hex map, growth animation, HUD
- ⚠️ Layers button does nothing
- ⚠️ No tutorial overlay for first-time users
- ⚠️ Structure dots on hex cells are small plain circles — need icons or labels

### LiveQuizScreen
- ✅ Premium dark immersive design
- ✅ Score and streak display
- ✅ Waveform visualizer
- 🔴 Mic button doesn't start a Gemini session
- ⚠️ 5 bottom toolbar icons do nothing (videocam, shield, map, trophy, settings, overflow)
- ⚠️ Question text is static ("Waiting...") — not driven by AI transcript
- ⚠️ "USE A HINT" button not functional

### RoundResultScreen
- ✅ Screen exists
- ⚠️ Unclear if results are populated from actual game state
- ⚠️ No district growth visible from this screen

### VisionQuestCameraScreen
- ✅ Camera UI exists
- ⚠️ Frame analysis feedback unclear
- ⚠️ No "scanning..." indicator during AI analysis

### PlayHubScreen
- ✅ Entry point for quiz + vision
- ⚠️ May show "Recent Activity" that is always empty

### SquadHubScreen
- ⚠️ Always shows empty state — no seed squads
- ⚠️ No way to create a squad from UI

### EventsScreen
- ⚠️ Always empty — no seed events
- ⚠️ No "upcoming events countdown" without data

### ProfileScreen
- ⚠️ Shows user info but XP/streak may not be populated from real backend data
- ⚠️ No avatar / emblem display

### SettingsScreen
- 🔴 Stub — no actual settings implemented
- 🔴 No sign-out button

### AuthScreen
- ✅ Email + Google sign-in UI
- ⚠️ No error message display for wrong credentials

## Missing Loading States

| Screen | State Missing | Priority |
|---|---|---|
| WorldHomeScreen | Loading skeleton while district loads | P2 |
| LiveQuizScreen | "Connecting to Gemini..." state | P1 |
| SquadHubScreen | Loading spinner | P2 |
| EventsScreen | Loading spinner | P2 |
| ProfileScreen | Loading skeleton | P2 |

## Missing Empty States

| Screen | Empty State Missing | Priority |
|---|---|---|
| SquadHubScreen | "You're not in a squad yet" | P1 |
| EventsScreen | "No events right now" | P1 |
| RewardVaultScreen | "No rewards unlocked yet" | P1 |

## CTA Hierarchy Issues

| Screen | Issue |
|---|---|
| PlayHubScreen | Both "Quiz" and "Vision Quest" are same visual weight — quiz should be primary |
| WorldHomeScreen | No explicit CTA to "Start Playing" from the world view |

## Animations Assessment

| Animation | Status | Quality |
|---|---|---|
| District growth hex pop | ✅ Real | Excellent — elasticOut + shockwave |
| Screen fade-ins (flutter_animate) | ✅ Used throughout | Good |
| Waveform visualizer | ✅ Real widget | Good |
| Map centering animation | ✅ Real | Good |
| Auth screen entry | ✅ slideX + fadeIn | Good |

## Summary

- Design system: **Consistent and premium**
- Animations: **Strong** — growth animations especially impressive
- Major UX gaps: **Dead toolbar icons, empty states, missing loading states**
- The biggest UX failure is that the quiz screen has gorgeous UI but literally does nothing when you talk
