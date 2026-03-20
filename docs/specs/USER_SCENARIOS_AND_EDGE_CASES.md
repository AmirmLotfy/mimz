# User Scenarios And Edge Cases

Last updated: 2026-03-18

## Scenario Matrix

| Scenario | Expected Behavior | Route Path | Fallback Behavior | Backend/Data Behavior | User Messaging |
|---|---|---|---|---|---|
| First-time solo player | complete onboarding and start world | splash -> welcome -> auth -> onboarding -> world | skip squad prompts | seed profile + district + solo pref | "Your district is ready." |
| First-time social player | same as above with squad preference capture | onboarding includes social pref | suggest squad join later | persist squad preference | "Want to build with a squad?" |
| Returning player | quick bootstrap to world | splash -> world | show retry if bootstrap transient | read profile/district | "Welcome back." |
| Location denied | district still available with coarse anchor | permissions -> world | settings CTA | set coarse region fallback | "Location helps events, not required." |
| Mic denied | live rounds blocked; world still playable | play -> mic gate | retry + settings deep-link | no live session created | "Enable mic to play live voice rounds." |
| Camera denied | vision mode blocked only | play/vision -> camera gate | quiz still available | no vision payload writes | "Camera is only needed for vision quests." |
| Offline on launch | no protected calls until connectivity | splash -> offline recovery | retry loop + cached shell if safe | queue nothing destructive | "You're offline. Reconnect to continue." |
| Backend temporarily unavailable | keep safe routes, block mutations | world with degraded banner | retry/backoff | no fake persistence | "Service is busy, try again." |
| Live session fails | exit/retry without app dead-end | play/live -> live recovery | reconnect or return world | mark session failed + audit | "Live connection dropped, retry?" |
| Squad joined later | progression contributions become visible | profile/settings/squad flows | if fail, stay solo | persist squad membership | "You're now contributing to your squad." |
| Event joined later | event bonuses applied to rewards | events -> detail -> join | if join fail, keep browsing | persist enrollment | "Event joined. Bonuses active." |
| Preferences changed later | new rounds adapt soon | settings/profile edits | if save fail, rollback UI | persist profile updates | "Preferences updated." |
| Traveling user | district stable, events re-contextualized | world unchanged | use prior region if uncertain | update coarse context only | "Local events updated for your area." |
| Google auth | auth + bootstrap seamless | welcome/auth -> world | provider conflict flow if needed | verify token and bootstrap | standard success text |
| Email auth | same as above | auth/email -> world | password reset path | verify token and bootstrap | standard success text |
| Same Gmail multiple providers | linking resolution flow | auth -> email link resolution | clear instructions | pending credential linking | "Sign in with password to link accounts." |
| Live region/model mismatch | live start fails fast with actionable exit | play/live -> live recovery | reset session or back to world | session not mutated, trace id logged | "Live service is unavailable right now. Try again shortly." |

## Critical Failure Edge Cases

### Bootstrap 401 Loop

- Force sign-out, clear token + onboarding cache, and return to welcome.
- Offer retry sign-in immediately.

### District 404

- Show explicit "district missing" recovery with bootstrap replay action.
- Do not hang in loading state.

### Reward Claim Failure

- Keep result screen visible.
- Show non-destructive error and retry.
- Do not navigate to world with fake local grant.

### Live Session Authorization Mismatch

- If tool execution uses stale/foreign session id, backend returns session-expired response.
- Client must reset session and fetch a new token before retry.
