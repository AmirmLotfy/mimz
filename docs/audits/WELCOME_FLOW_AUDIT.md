# Welcome Flow Audit — Mimz App

## Screens Inspected
1. `SplashRoute` / `SplashScreen`: Good. Handles initial redirect logic out of the router. 
2. `WelcomeScreen`: Good. Shows editorial copy and a "Get Started" array. 
3. `AuthScreen`: No guest/skip buttons. Has back button to welcome.
4. `EmailAuthScreen`: Well implemented with sliding tabs.

## UX Polish
- The map grid is static. Adding a slight pan animation in the `WelcomeScreen` painter would elevate the premium feel.
- Loading states on Auth screen shake on error — this is good. 
- Ensure button tap handlers do not spam the auth API on multiple rapid taps (disable them during `_loading`. Already mostly handled but can double check).

## Current Issues
- If a user cancels out of a Google sign-in prompt, no error is shown (this is somewhat expected), but verify `is_loading` terminates safely (it does via `finally` block).
- Ensure "Get Started" goes to sign-up tab of `EmailAuthScreen` instead of default sign-in if selected.

## Action Plan
1. Ensure "I already have an account" lands distinctly vs "Continue with Email" (perhaps pass an `initialIndex` to `EmailAuthScreen`).
2. Tweak route push logic so the deep navigation doesn't stack incorrectly (e.g. `go` vs `push`).
