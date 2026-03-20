# Routing And Gating Spec

Last updated: 2026-03-18

## Objective

Define deterministic route behavior from splash through authenticated gameplay and recovery.

## Route Classes

- **Public**: `/splash`, `/welcome`, `/auth`, onboarding and permission routes.
- **Protected shell**: `/world`, `/play`, `/squad`, `/events`, `/profile`.
- **Protected standalone**: result screens, settings, district detail, leaderboard.

## Global Gate Inputs

- `authStatus`: `unknown | authenticated | unauthenticated`
- `bootstrapStatus`: `idle | loading | success | error`
- `isOnboarded`: persistent gate flag
- `requiredPermissionsSatisfied`: mic/location baseline for world+live
- `connectivity`: `online | offline`

## Splash Behavior

1. Play splash animation budget (minimum 1.8s).
2. Resolve auth stream with short timeout.
3. If unauthenticated -> `/welcome`.
4. If authenticated -> attempt bootstrap.
5. Bootstrap success:
   - onboarded -> `/world`
   - not onboarded -> `/permissions`
6. Bootstrap failure:
   - 401 -> sign-out recovery then `/welcome`
   - transient -> retry affordance
   - backend unavailable -> degraded recovery route

## First Install

- `/splash` -> `/welcome` -> `/auth` -> bootstrap -> `/permissions` -> onboarding stack -> `/world`.

## Returning Launch

- valid auth + successful bootstrap + onboarded -> `/world`.
- valid auth + bootstrap 401 -> forced sign-out -> `/welcome`.
- valid auth + transient bootstrap failure -> retry modal with trace id.

## Post Sign-In

- must run bootstrap before entering shell route.
- bootstrap result seeds user profile and district.
- route guard blocks `/world` if bootstrap unresolved.

## Post Sign-Out

- clear secure token cache + onboarding gate cache.
- invalidate user/district providers.
- navigate to `/welcome`.
- prevent stale back-stack navigation into protected screens.

## Permission Denial Handling

- Denied: keep user in permission explainer with retry and skip policy.
- Permanently denied: show settings deep-link CTA.
- For gameplay requiring denied permission:
  - mic denied -> live play blocked with clear message
  - camera denied -> vision mode blocked, quiz mode still allowed
  - location denied -> district anchored in coarse fallback region

## Backend Reachable, Live Unavailable

- `/world` remains accessible.
- `/play` shows live status + retry and fallback practice mode.
- no global auth sign-out on live subsystem failures.

## Recovery Routes

- `authRecovery`: bootstrap 401, token invalid.
- `backendRecovery`: backend unavailable with retries.
- `permissionRecovery`: blocked feature route to permission explainer.
- `liveRecovery`: failed session with reconnect or safe exit.

## Alternate Journeys

- **Location denied:** App remains usable; district uses coarse fallback region. No forced re-onboarding.
- **Mic denied:** Live play blocked; overlay shows "Voice is core to the experience" and Open Settings CTA. Quiz/vision flows that need mic show same recovery.
- **Returning user:** Valid auth + bootstrap restores user and district; redirect to `/world`. No "start over" or re-onboarding.
- **Long absence:** No punishment; re-entry shows where they left off (world, district, streak) and clear next action (e.g. Play, daily streak nudge).

## Required Guard Rules

- No protected route access while `authStatus != authenticated`.
- No shell/protected route access while bootstrap user state is unresolved; redirect to `/splash` for deterministic recovery.
- No onboarding routes when user is fully onboarded (redirect `/world`).
- No auth routes while fully onboarded + authenticated (redirect `/world`).
- If onboarding state is unresolved, route through `/splash` until gate resolution is known.
