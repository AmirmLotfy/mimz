# Onboarding And Permissions Spec

Last updated: 2026-03-18

## Onboarding Principles

- Purposeful and gameplay-linked, never decorative.
- Resumable at every step.
- Backend-persisted progressively (save-as-you-go).
- Each step explains gameplay impact.

## Onboarding Steps

| Step | Purpose | Backend Persistence | Skippable | Gameplay Impact | Retry/Reopen |
|---|---|---|---|---|---|
| Preferred name | identity + voice personalization | `users.displayName` | No | host addressing + profile UI | resume from saved draft |
| Study/work status | context for challenge framing | `users.profileStatus` | Yes | prompt framing | optional edit later |
| Major/field | domain weighting | `users.majorField` | Yes | topic prioritization | editable in settings |
| Interests/topics | topic pools | `users.interests[]` | No | challenge selection and events | must complete before first live |
| Difficulty preference | baseline tuning | `users.difficultyPreference` | Yes | question complexity | dynamic adjustments allowed |
| Solo vs squad preference | social intent | `users.playModePreference` | Yes | squad nudges, event targeting | editable |
| Language/voice preference | speech and UX tone | `users.voiceLocale`, `users.voiceStyle` | Yes | TTS/STT defaults | editable |
| District naming | map identity | `district.name` | No | map headline + social identity | hard gate |
| Emblem choice | visual identity | `district.emblem` | Yes | map/profile cosmetics | editable |
| Onboarding summary | confirmation and trust | completion flag + audit | No | unlock world route | final checkpoint |

## Onboarding Live Moments

- Short live welcome after interests selection.
- One low-stakes sample question to establish interaction model.
- District reveal voice line after naming/emblem confirmation.

## Permission Strategy

### Rule Set

- Never request permission without contextual value explanation.
- Request only when entering relevant capability.
- Denied/permanent-denied must be recoverable from settings and feature entry points.
- Settings screen must show current permission statuses.

### Permission Timing

- **Location**: during district anchoring/setup (coarse-level only).
- **Microphone**: immediately before first live voice interaction.
- **Camera**: before first vision quest launch.
- **Notifications**: after first meaningful progression event (not at first launch).
- **Biometrics**: opt-in only from security settings.

### Degraded Behavior

- No location: assign coarse region and keep gameplay available.
- No microphone: disable live voice rounds, allow non-voice paths.
- No camera: disable vision quests, keep quiz and map progression active.
- No notifications: in-app inbox remains source of truth.

## Persistence Contract

- Save onboarding draft after each step.
- Bootstrap should return onboarding completion and current draft status.
- Completion sets immutable audit event with timestamp and app version.
- Live session start must be blocked with actionable messaging if profile bootstrap is unresolved.
