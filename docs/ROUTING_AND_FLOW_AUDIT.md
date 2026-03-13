# ROUTING AND FLOW AUDIT
> Generated: 2026-03-13

## Route Graph

```
/splash → auth check → /welcome (unauthenticated) or /world (authenticated + onboarded)
/welcome → /auth
/auth → /permissions → /permissions/location → /permissions/microphone → /permissions/camera
      → /onboarding/live → /onboarding/summary → /district/emblem → /district/name → /world
/world (tab shell) → /play → /squad → /events → /profile
/play → /play/quiz → /play/quiz/result → /world (or back)
/play → /play/vision → /play/vision/success → /world (or back)
/rewards (pushed over shell)
/settings (pushed over shell)
/leaderboard (pushed over shell)
```

## Auth Gating Assessment

| Check | Status | Notes |
|---|---|---|
| GoRouter redirect defined | ❌ MISSING | No redirect callback — unauthenticated users can navigate to /world |
| Splash screen checks auth state | ✅ Yes | Reads authStateProvider |
| Post-auth landing in /world | ✅ Yes | Navigation from auth screen |
| On sign-out → redirect to /welcome | ❓ Unknown | Depends on settings sign-out implementation |

## Critical Routing Issues

### GAP-04: No Auth Guard
The `GoRouter` has no `redirect` function. This means deep-linking or manual navigation to `/world` while unauthenticated will not redirect to `/welcome`.

**Fix:**
```dart
final appRouter = GoRouter(
  initialLocation: '/splash',
  redirect: (context, state) {
    final isAuthenticated = // read auth state
    final isGoingToAuth = state.location.startsWith('/splash') || 
                          state.location.startsWith('/welcome') ||
                          state.location.startsWith('/auth');
    if (!isAuthenticated && !isGoingToAuth) return '/welcome';
    return null;
  },
  ...
```

## Core User Journey Assessment

| Journey | Status | Breaking Point |
|---|---|---|
| First install → auth → permissions → district name → world | ✅ Routes exist | Name not persisted |
| World → play → quiz → answer → result → district grows | 🔴 BROKEN | Quiz never starts Gemini |
| World → play → vision → camera → success → world | ⚠️ Partial | AI wiring unclear |
| World → squads | ⚠️ Empty | No squads in DB |
| World → events | ⚠️ Empty | No events in DB |
| World → profile → settings → sign out | 🔴 Broken | Settings is a stub |

## Bottom Navigation Assessment

| Tab | Icon | Route | Status |
|---|---|---|---|
| World | Globe | /world | ✅ Working |
| Play | Gamepad | /play | ✅ Working |
| Squad | Group | /squad | ✅ Route works, screen empty |
| Events | Calendar | /events | ✅ Route works, screen empty |
| Profile | Person | /profile | ✅ Working |

## Back Navigation

- Close button in quiz → `context.go('/play')` ✅
- Round result back → needs testing
- Vision quest back → needs testing
- Onboarding cannot go back (correct pattern) ✅

## Summary

- All 24 routes resolve to real screens
- **Critical: No auth guard** — security flaw and demo risk
- **Critical: Main gameplay journey broken** because quiz screen doesn't start Gemini
- Several tabs work but show empty state due to missing seed data
