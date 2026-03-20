# SCREEN COVERAGE AUDIT
> Generated: 2026-03-13

## All Declared Screens

| Screen | Route | Status | Notes |
|---|---|---|---|
| SplashScreen | /splash | ✅ Real | Checks auth state, routes appropriately |
| WelcomeScreen | /welcome | ✅ Real | Animated intro with CTAs |
| AuthScreen | /auth | ✅ Real | Email + Google sign-in |
| PermissionOverviewScreen | /permissions | ✅ Real | Permission summary |
| LocationPermissionScreen | /permissions/location | ✅ Real | Location request |
| MicrophonePermissionScreen | /permissions/microphone | ✅ Real | Mic request |
| CameraPermissionScreen | /permissions/camera | ✅ Real | Camera request |
| LiveOnboardingScreen | /onboarding/live | ⚠️ Partial | AI voice greeting — wiring unverified |
| OnboardingSummaryScreen | /onboarding/summary | ✅ Real | Summary before world |
| EmblemSelectionScreen | /district/emblem | ⚠️ Visual Only | Selection not persisted |
| DistrictNamingScreen | /district/name | ⚠️ Visual Only | Name not sent to API |
| WorldHomeScreen | /world | ✅ Real + High Quality | Hex map, growth animation, real data |
| PlayHubScreen | /play | ✅ Real | Quiz + vision quest entry |
| SquadHubScreen | /squad | ⚠️ Thin | No real data, no empty state |
| EventsScreen | /events | ⚠️ Thin | No seed data, always empty |
| ProfileScreen | /profile | ⚠️ Basic | Shows user info but not wired to real XP/streak |
| LiveQuizScreen | /play/quiz | 🔴 BROKEN | UI is beautiful but Gemini session never started |
| RoundResultScreen | /play/quiz/result | ⚠️ Partial | Shows results but doesn't trigger map growth |
| VisionQuestCameraScreen | /play/vision | ⚠️ Partial | Camera works — AI wiring unclear |
| VisionQuestSuccessScreen | /play/vision/success | ✅ Visual | Success UI |
| RewardVaultScreen | /rewards | ⚠️ Visual | Shows reward types, no real data |
| SettingsScreen | /settings | 🔴 Stub | No functionality implemented |
| LeaderboardScreen | /leaderboard | ✅ Real | Wired to leaderboard provider |

## Missing Screens (Should Exist)

| Screen | Why Needed | Priority |
|---|---|---|
| DistrictDetailScreen | Show structures, resources, prestige — core game loop | P1 |
| StructureUnlockScreen | Browse and unlock structures with resource costs | P2 |
| SquadDetailScreen | View squad members, missions, progress | P2 |
| EventDetailScreen | Join specific events, see leaderboard | P2 |
| NotificationScreen | View notifications | P3 |

## Missing States Within Existing Screens

| Screen | Missing State | Priority |
|---|---|---|
| SquadHubScreen | Empty state (no squad yet / not in squad) | P1 |
| EventsScreen | Empty state (no events live) | P1 |
| RewardVaultScreen | Empty state (no rewards unlocked) | P1 |
| LiveQuizScreen | Loading/connecting state | P1 |
| LiveQuizScreen | Error/reconnect state | P1 |
| ProfileScreen | Loading state | P2 |
| WorldHomeScreen | First-time tutorial overlay | P2 |
| AuthScreen | Error state (wrong password, network error) | P1 |

## Summary

- **23 screens declared** — all routes resolve (no 404s)
- **5 screens are real and high quality** (world, router, leaderboard, splash, auth)
- **8 screens are partial or weak** (quiz, onboarding, result, vision, reward, squad, events, profile)
- **2 screens are stubs or broken** (settings, live_quiz Gemini wiring)
- **5 screens are missing entirely** (district detail, structure unlock, squad detail, event detail, notifications)
