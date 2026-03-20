# Screen Mapping — Mimz

How design source screens map to implemented Flutter routes and widgets.

---

## Screen Inventory

| # | Design Screen | Route Path | Widget File | Status |
|---|--------------|-----------|-------------|--------|
| 1 | Splash | `/` | `splash_screen.dart` | ✅ Implemented |
| 2 | Welcome | `/welcome` | `welcome_screen.dart` | ✅ Implemented |
| 3 | Sign Up | `/signup` | `sign_up_screen.dart` | ✅ Implemented |
| 4 | Permission Overview | `/permissions` | `permission_overview_screen.dart` | ✅ Implemented |
| 5 | Location Permission | `/permissions/location` | `location_permission_screen.dart` | ✅ Implemented |
| 6 | Mic Permission | `/permissions/mic` | `mic_permission_screen.dart` | ✅ Implemented |
| 7 | Camera Permission | `/permissions/camera` | `camera_permission_screen.dart` | ✅ Implemented |
| 8 | Live Onboarding | `/onboarding/live` | `live_onboarding_screen.dart` | ✅ Implemented |
| 9 | Profile Summary | `/onboarding/summary` | `profile_summary_screen.dart` | ✅ Implemented |
| 10 | District Naming | `/onboarding/district` | `district_naming_screen.dart` | ✅ Implemented |
| 11 | World Home | `/world` | `world_home_screen.dart` | ✅ Implemented |
| 12 | Play Hub | `/play` | `play_hub_screen.dart` | ✅ Implemented |
| 13 | Live Quiz | `/play/quiz` | `live_quiz_screen.dart` | ✅ Implemented |
| 14 | Quiz Result | `/play/result` | `quiz_result_screen.dart` | ✅ Implemented |
| 15 | Vision Quest | `/play/vision` | `vision_quest_screen.dart` | ✅ Implemented |
| 16 | Vision Success | `/play/vision/success` | `vision_success_screen.dart` | ✅ Implemented |
| 17 | Squad Hub | `/squads` | `squad_hub_screen.dart` | ✅ Implemented |
| 18 | Events | `/events` | `events_screen.dart` | ✅ Implemented |
| 19 | Profile | `/profile` | `profile_screen.dart` | ✅ Implemented |
| 20 | Reward Vault | `/rewards` | `reward_vault_screen.dart` | ✅ Implemented |

---

## User Flow

```
Splash → Welcome → Sign Up → Permission Overview
    → Location → Mic → Camera
    → Live Onboarding → Profile Summary → District Naming
    → World Home (shell)
        ├── Play Hub → Live Quiz → Quiz Result
        │            → Vision Quest → Vision Success
        ├── Squad Hub
        ├── Events
        ├── Profile → Reward Vault
        └── (map always visible in background)
```

---

## Design Decisions

### What Was Preserved from Source Designs
- Dark editorial aesthetic with gradient accents
- Card-based layouts with glassmorphism effects
- Waveform animation during live interactions
- Map grid as district visualization
- Tiered reward system (Common / Rare / Master)

### What Changed from Source Designs
- Permission screens were split into individual focused screens (one per permission) instead of a single settings-style list
- Live onboarding was separated from profile creation — AI conversation happens on its own dedicated dark screen
- Quiz result was made a distinct screen rather than an overlay on the quiz screen
- Squad and Events got their own navigation tabs in the app shell

### What Was Removed
- Settings screen (deferred to post-hackathon)
- Friends list (replaced by squad-based social)
- Achievement badges (simplified to reward vault)
- Tutorial overlay system (replaced by live onboarding conversation)
