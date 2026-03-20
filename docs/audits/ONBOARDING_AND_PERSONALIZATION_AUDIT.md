# Onboarding and Personalization Audit

## Current State
The onboarding flow exists but is strictly permission-and-setup focused, lacking any real personalization or interest tracking.

**Existing Frontend Flow:**
1. Permission Overview -> Mic -> Camera -> Location
2. District Naming (`district_naming_screen.dart`)
3. Emblem Selection (`emblem_selection_screen.dart`)
4. Live Onboarding Intro (`live_onboarding_screen.dart`)
5. Onboarding Summary (`onboarding_summary_screen.dart`)

**Missing Onboarding Steps:**
- Welcome/Intro explicit step
- Preferred Name capture
- Age Band / Stage of life
- Study / Work Status
- Major / Field / Profession
- Core Interests / Topics
- Preferred difficulty or competitiveness
- Solo vs Squad preference
- Voice/Language preference

## Required Implementation
We need to build a comprehensive, multi-step `PersonalizationOnboardingFlow` injected before or after the District setup.

**New Screens Required:**
- `BasicProfileSetupScreen`: (Name, Age Band, Status, Major/Profession)
- `InterestSelectionScreen`: (Taxonomy-driven grid of selectable topics)
- `GameplayPreferencesScreen`: (Difficulty, Solo/Squad, Voice settings)
- `OnboardingSummaryScreen`: (Updated to reflect the new personalization data and allow edits)

**Backend Requirements:**
- DTOs and routes for capturing this data.
- User/Profile Firestore document updates to include these new fields.
- Storage of the taxonomy and interest IDs.
