# Auth And Account Production Spec

## Supported Auth Modes

- Email/password (sign up, sign in, reset password)
- Google Sign-In
- Provider linking for same email conflict

## Canonical Account Rules

- Firebase UID is canonical identity key.
- Backend profile bootstrap is idempotent by userId.
- Same user must not create duplicate profile/district records across providers.
- Sign-out must clear:
  - firebase token cache
  - token expiry cache
  - pending provider link state
  - onboarding cache

## Auth Flows

### Email Sign Up
1. Create Firebase account
2. Cache token
3. Bootstrap backend profile/district
4. Route by onboarding status

### Google Sign-In
1. Google credential -> Firebase sign-in
2. Cache token
3. Bootstrap backend profile/district
4. Route by onboarding status

### Account Conflict (Same Email Different Provider)
1. Capture pending credential
2. Prompt password sign-in
3. Link credential to existing account
4. Clear pending link state

## Failure Handling

- 401 bootstrap -> force sign-out and return to welcome
- transient backend failure -> retry affordance
- 403 access restricted -> show explicit access error (no synthetic local user)

## Post-Auth Routing Contract

- authenticated user must not enter protected shell until bootstrap succeeds
- onboarded users are redirected away from auth/onboarding routes
- unauthenticated users are redirected away from protected routes
