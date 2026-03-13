# State Transition Audit (Mimz)

## 1. Overview
This audit examines how the application handles data staleness, screen-reopen behavior, and auth state mutations during the component lifecycle.

## 2. Global State Gates

### `isAuthenticatedProvider`
- Evaluated as a top-level `GoRouter` redirect constraint.
- Transitions cleanly from `loading` → `authenticated` via the `AuthService` stream.
- **Fix Applied:** `appRouter` now actively evaluates `isAuthenticatedProvider` without context dependency by referencing `_routerRef` (a `ProviderContainer`).

### `isOnboardedProvider`
- **Missing Architecture Addressed:** The application previously had no concept of an "Onboarded" state. A user either had an active token or didn't. This meant returning users were thrown back into `/permissions` to reallocate a district.
- **Implementation:** Built an `OnboardingNotifier` inside `auth_provider.dart` backed by `flutter_secure_storage`.
- State mutation occurs EXACTLY once: when the user hits "Establish District" (`/district/name`), the local storage flag commits to `true` and forces the router to dump the onboarding stack.

## 3. Provider Integrity Hand-offs

### `currentUserProvider`
The `CurrentUserNotifier` initiates `fetchUser()` ONLY if the `AuthStatus` resolves to authenticated.
- **Fix Applied:** The `OnboardingSummaryScreen` mapping was disconnected. It now observes `currentUserProvider` ensuring that when the auth screen passes hand-off to permissions, the local state correctly binds to the auth state.

### Bottom Navigation Tab State
The `AppShell` relies on `GoRouterState` to parse the `uri` segment string to highlight the correct `BottomNavigationBarItem`.
- **Status:** Rock solid. Tapping tabs correctly resets the nested history of that shell stack, preventing unresolvable back-buttons.

## 4. Conclusion
State-driven navigation is now highly rigid and mathematically sound. A user cannot exist in the `/world` shell without an active auth token and an active onboarding completion flag. Unauthenticated states physically cannot paint protected screens.
