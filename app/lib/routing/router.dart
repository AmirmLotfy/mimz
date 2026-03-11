import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/onboarding/presentation/permission_overview_screen.dart';
import '../features/onboarding/presentation/location_permission_screen.dart';
import '../features/onboarding/presentation/microphone_permission_screen.dart';
import '../features/onboarding/presentation/camera_permission_screen.dart';
import '../features/onboarding/presentation/live_onboarding_screen.dart';
import '../features/onboarding/presentation/onboarding_summary_screen.dart';
import '../features/onboarding/presentation/district_naming_screen.dart';
import '../features/world/presentation/world_home_screen.dart';
import '../features/live/presentation/play_hub_screen.dart';
import '../features/live/presentation/live_quiz_screen.dart';
import '../features/live/presentation/round_result_screen.dart';
import '../features/live/presentation/vision_quest_camera_screen.dart';
import '../features/live/presentation/vision_quest_success_screen.dart';
import '../features/squads/presentation/squad_hub_screen.dart';
import '../features/events/presentation/events_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/rewards/presentation/reward_vault_screen.dart';
import 'app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    // Pre-auth flow
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) => const AuthScreen(),
    ),

    // Onboarding flow
    GoRoute(
      path: '/permissions',
      builder: (context, state) => const PermissionOverviewScreen(),
    ),
    GoRoute(
      path: '/permissions/location',
      builder: (context, state) => const LocationPermissionScreen(),
    ),
    GoRoute(
      path: '/permissions/microphone',
      builder: (context, state) => const MicrophonePermissionScreen(),
    ),
    GoRoute(
      path: '/permissions/camera',
      builder: (context, state) => const CameraPermissionScreen(),
    ),
    GoRoute(
      path: '/onboarding/live',
      builder: (context, state) => const LiveOnboardingScreen(),
    ),
    GoRoute(
      path: '/onboarding/summary',
      builder: (context, state) => const OnboardingSummaryScreen(),
    ),
    GoRoute(
      path: '/district/name',
      builder: (context, state) => const DistrictNamingScreen(),
    ),

    // Main app shell with bottom navigation
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/world',
          builder: (context, state) => const WorldHomeScreen(),
        ),
        GoRoute(
          path: '/play',
          builder: (context, state) => const PlayHubScreen(),
        ),
        GoRoute(
          path: '/squad',
          builder: (context, state) => const SquadHubScreen(),
        ),
        GoRoute(
          path: '/events',
          builder: (context, state) => const EventsScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),

    // Full-screen live experiences (no bottom nav)
    GoRoute(
      path: '/play/quiz',
      builder: (context, state) => const LiveQuizScreen(),
    ),
    GoRoute(
      path: '/play/quiz/result',
      builder: (context, state) => const RoundResultScreen(),
    ),
    GoRoute(
      path: '/play/vision',
      builder: (context, state) => const VisionQuestCameraScreen(),
    ),
    GoRoute(
      path: '/play/vision/success',
      builder: (context, state) => const VisionQuestSuccessScreen(),
    ),
    GoRoute(
      path: '/rewards',
      builder: (context, state) => const RewardVaultScreen(),
    ),
  ],
);
