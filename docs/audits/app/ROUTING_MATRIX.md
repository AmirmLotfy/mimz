# Routing Matrix (Mimz)

## 1. Global Navigation Architecture
Mimz uses `GoRouter` coupled with Riverpod state management. The app is divided structurally into:
1. **Public/Pre-Auth Routes:** Splash, Welcome, Auth, Permissions, Onboarding logic.
2. **Shell Routes (Protected):** Tab-based main application (`AppShell`).
3. **Full-Screen Protected Routes:** Heavy gameplay flows pushed over the shell (Live Quiz, Vision Quest).
4. **Standalone Settings/Detail Routes:** Pushed over the shell.

## 2. Route Definitions

| Route Location | Widget | Auth Required? | Onboard Required? | Description |
| :--- | :--- | :--- | :--- | :--- |
| **`/splash`** | `SplashScreen` | No | No | Entry point. Reads auth/onboarding state and redirects. |
| **`/welcome`** | `WelcomeScreen` | No | No | Editorial hero screen for unauthenticated users. |
| **`/auth`** | `AuthScreen` | No | No | Apple/Google/Email authentication. |
| **`/permissions`** | `PermissionOverviewScreen`| Yes | No | Start of onboarding. Valid auth required, but onboarding not yet completed. |
| **`/permissions/location`**| `LocationPermissionScreen`| Yes | No | Grants location powers for the map. |
| **`/permissions/microphone`**| `MicrophonePermissionScreen`| Yes | No | Grants mic for voice quiz. |
| **`/permissions/camera`**| `CameraPermissionScreen`| Yes | No | Grants camera for vision quests. |
| **`/onboarding/live`** | `LiveOnboardingScreen` | Yes | No | Tutorial video/walkthrough. |
| **`/onboarding/summary`**| `OnboardingSummaryScreen` | Yes | No | Confirms profile mapping. |
| **`/district/emblem`** | `EmblemSelectionScreen` | Yes | No | Select district aesthetic. |
| **`/district/name`** | `DistrictNamingScreen` | Yes | No | **Completion Point.** Sets `isOnboarded` flag to true. |
| **`/world`** | `WorldHomeScreen` | **Yes** | **Yes** | Shell Tab 0. Primary map view. |
| **`/play`** | `PlayHubScreen` | **Yes** | **Yes** | Shell Tab 1. Entry to Live modes. |
| **`/squad`** | `SquadHubScreen` | **Yes** | **Yes** | Shell Tab 2. Team gameplay. |
| **`/events`** | `EventsScreen` | **Yes** | **Yes** | Shell Tab 3. Global ops events. |
| **`/profile`** | `ProfileScreen` | **Yes** | **Yes** | Shell Tab 4. Identity and progression. |
| **`/play/quiz`** | `LiveQuizScreen` | **Yes** | **Yes** | Full-screen voice trivia flow. |
| **`/play/quiz/result`**| `RoundResultScreen` | **Yes** | **Yes** | Full-screen trivia results. Ends back at `/world`. |
| **`/play/vision`** | `VisionQuestCameraScreen`| **Yes** | **Yes** | Full-screen camera hunt flow. |
| **`/play/vision/success`**| `VisionQuestSuccessScreen`| **Yes** | **Yes** | Full-screen camera result. |
| **`/play/vision/history`**| `VisionQuestHistoryScreen`| **Yes** | **Yes** | Pushed history gallery. |
| **`/rewards`** | `RewardVaultScreen` | **Yes** | **Yes** | Standalone loot and cosmetics screen. |
| **`/settings`** | `SettingsScreen` | **Yes** | **Yes** | App preferences and **Sign Out** control. |
| **`/leaderboard`** | `LeaderboardScreen` | **Yes** | **Yes** | Global rank list. |
| **`/squad/leaderboard`**| `SquadLeaderboardScreen`| **Yes** | **Yes** | Local squad rank list. |
| **`/district/detail`** | `DistrictDetailScreen` | **Yes** | **Yes** | Focused stats for the user's specific district. |
| **`/district/share`** | `DistrictShareSheet` | **Yes** | **Yes** | *(Modal Bottom Sheet)* Export format for social proof. |

## 3. Router Guards & Constraints

The `redirect` logic in `appRouter` applies three rigid constraints:
1. Cannot access protected routes unless authenticated (kicked to `/welcome`).
2. Cannot access the `AppShell` or gameplay routes unless the `isOnboardedProvider` flag is true (kicked to `/permissions`).
3. Cannot access pre-auth or onboarding routes (like `/welcome` or `/auth`) if you are already authenticated and onboarded (kicked to `/world`).
