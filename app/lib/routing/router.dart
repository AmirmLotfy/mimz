import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/auth/presentation/welcome_screen.dart';
import '../features/auth/presentation/auth_screen.dart';
import '../features/auth/presentation/email_auth_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/onboarding/presentation/permission_overview_screen.dart';
import '../features/onboarding/presentation/location_permission_screen.dart';
import '../features/onboarding/presentation/microphone_permission_screen.dart';
import '../features/onboarding/presentation/camera_permission_screen.dart';
import '../features/onboarding/presentation/live_onboarding_screen.dart';
import '../features/onboarding/presentation/onboarding_summary_screen.dart';
import '../features/onboarding/presentation/emblem_selection_screen.dart';
import '../features/onboarding/presentation/district_naming_screen.dart';
import '../features/onboarding/presentation/district_reveal_screen.dart';
import '../features/onboarding/presentation/basic_profile_setup_screen.dart';
import '../features/onboarding/presentation/interest_selection_screen.dart';
import '../features/onboarding/presentation/gameplay_preferences_screen.dart';
import '../features/world/presentation/world_home_screen.dart';
import '../features/world/presentation/leaderboard_screen.dart';
import '../features/live/presentation/play_hub_screen.dart';
import '../features/live/presentation/live_quiz_screen.dart';
import '../features/live/presentation/round_result_screen.dart';
import '../features/live/presentation/vision_quest_camera_screen.dart';
import '../features/live/presentation/vision_quest_success_screen.dart';
import '../features/live/presentation/vision_quest_history_screen.dart';
import '../features/squads/presentation/squad_hub_screen.dart';
import '../features/squads/presentation/squad_leaderboard_screen.dart';
import '../features/events/presentation/events_screen.dart';
import '../features/events/presentation/event_detail_screen.dart';
import '../data/models/event.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/rewards/presentation/reward_vault_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/security_screen.dart';
import '../features/settings/presentation/profile_edit_screen.dart';
import '../features/settings/presentation/privacy_policy_screen.dart';
import '../features/settings/presentation/terms_of_service_screen.dart';
import '../features/settings/presentation/help_support_screen.dart';
import '../features/settings/presentation/feedback_screen.dart';
import '../features/notifications/presentation/notification_inbox_screen.dart';
import '../features/district/presentation/district_detail_screen.dart';
import '../features/profile/presentation/player_search_screen.dart';
import 'app_shell.dart';

// Protected routes that require authentication
const _protectedRoutePrefixes = [
  '/world',
  '/play',
  '/squad',
  '/events',
  '/profile',
  '/rewards',
  '/settings',
  '/leaderboard',
  '/district/detail',
];

// Public routes that don't require authentication
const _publicRoutePrefixes = [
  '/splash',
  '/welcome',
  '/auth',
  '/permissions',
  '/onboarding',
  '/district/emblem',
  '/district/name',
  '/district/reveal',
];

/// Holds a reference to the app's ProviderContainer so the router's
/// redirect guard can read isAuthenticatedProvider without BuildContext.
/// Set this before the first navigation in app.dart.
ProviderContainer? _routerRef;
void setRouterRef(ProviderContainer container) => _routerRef = container;



final rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) {
    final container = _routerRef;
    if (container == null) return null;

    final isAuthenticated = container.read(isAuthenticatedProvider);
    final currentUser = container.read(currentUserProvider);
    final location = state.matchedLocation;

    final isProtected = _protectedRoutePrefixes.any((p) => location.startsWith(p));
    final isPublic = _publicRoutePrefixes.any((p) => location.startsWith(p));
    final isSplash = location == '/splash';

    // Splash handles its own async bootstrap decision tree.
    if (isSplash) return null;

    // 1. Unauthenticated users
    if (!isAuthenticated) {
      if (isProtected) return '/welcome';
      return null;
    }

    // 2. Authenticated but bootstrap unresolved/error:
    // always route through splash, which owns deterministic retry/signout decisions.
    if (!currentUser.hasValue) {
      if (!isSplash) return '/splash';
      return null;
    }

    final user = currentUser.valueOrNull!;
    final nextRoute = nextRouteForUser(user);
    final isOptionalMeetMimz = location == '/onboarding/live';

    // 4. Authenticated but NOT onboarded
    if (!user.onboardingCompleted) {
      if (isOptionalMeetMimz) return nextRoute;
      if (isProtected) return nextRoute;
      return null;
    }

    // 5. Authenticated AND onboarded
    if (user.onboardingCompleted) {
      // If fully onboarded, do not allow re-entry into auth or onboarding screens
      if (isPublic && !isOptionalMeetMimz) return '/world';
    }

    return null;
  },
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
    GoRoute(
      path: '/auth/email',
      builder: (context, state) => const EmailAuthScreen(),
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
      path: '/district/emblem',
      builder: (context, state) => const EmblemSelectionScreen(),
    ),
    GoRoute(
      path: '/district/name',
      builder: (context, state) => const DistrictNamingScreen(),
    ),
    GoRoute(
      path: '/district/reveal',
      builder: (context, state) => const DistrictRevealScreen(),
    ),
    GoRoute(
      path: '/onboarding/profile-setup',
      builder: (context, state) => const BasicProfileSetupScreen(),
    ),
    GoRoute(
      path: '/onboarding/interests',
      builder: (context, state) => const InterestSelectionScreen(),
    ),
    GoRoute(
      path: '/onboarding/preferences',
      builder: (context, state) => const GameplayPreferencesScreen(),
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
      path: '/play/sprint',
      builder: (context, state) => const LiveQuizScreen(sprintMode: true),
    ),
    GoRoute(
      path: '/play/sprint/result',
      builder: (context, state) => const RoundResultScreen(),
    ),
    GoRoute(
      path: '/play/event/:eventId',
      builder: (context, state) {
        final eventId = state.pathParameters['eventId']!;
        final eventTitle =
            state.uri.queryParameters['title'] ?? 'Event Challenge';
        return LiveQuizScreen(eventId: eventId, eventTitle: eventTitle);
      },
    ),
    GoRoute(
      path: '/play/vision',
      builder: (context, state) => const VisionQuestCameraScreen(),
    ),
    GoRoute(
      path: '/play/vision/success',
      builder: (context, state) => const VisionQuestSuccessScreen(),
    ),

    // Standalone screens (pushed over shell)
    GoRoute(
      path: '/rewards',
      builder: (context, state) => const RewardVaultScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/settings/security',
      builder: (context, state) => const SecurityScreen(),
    ),
    GoRoute(
      path: '/settings/profile-edit',
      builder: (context, state) => const ProfileEditScreen(),
    ),
    GoRoute(
      path: '/settings/privacy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/settings/terms',
      builder: (context, state) => const TermsOfServiceScreen(),
    ),
    GoRoute(
      path: '/settings/help',
      builder: (context, state) => const HelpSupportScreen(),
    ),
    GoRoute(
      path: '/settings/feedback',
      builder: (context, state) => const FeedbackScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationInboxScreen(),
    ),
    GoRoute(
      path: '/social/discover',
      builder: (context, state) => const PlayerSearchScreen(),
    ),
    GoRoute(
      path: '/leaderboard',
      builder: (context, state) => const LeaderboardScreen(),
    ),
    GoRoute(
      path: '/events/detail',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final event = extra?['event'];
        if (event is! MimzEvent) {
          return const EventsScreen();
        }
        return EventDetailScreen(
          event: event,
          isLive: extra?['isLive'] == true,
        );
      },
    ),
    GoRoute(
      path: '/district/detail',
      builder: (context, state) => const DistrictDetailScreen(),
    ),
    // P5: Squad leaderboard
    GoRoute(
      path: '/squad/leaderboard',
      builder: (context, state) => const SquadLeaderboardScreen(),
    ),
    // P5: Vision quest history gallery
    GoRoute(
      path: '/play/vision/history',
      builder: (context, state) => const VisionQuestHistoryScreen(),
    ),
  ],
);
