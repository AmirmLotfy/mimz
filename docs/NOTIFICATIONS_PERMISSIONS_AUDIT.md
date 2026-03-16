# Notifications & Permissions Audit

## Scope
- Notifications inbox, provider state, read/unread behavior, notification settings controls
- Permission screens (location/microphone/camera), security biometrics status, and open-settings recovery

## Current State (as implemented)

### Notifications
- `NotificationInboxScreen` exists and is visually polished.
- Data source is local in-memory seed data from `notifications_provider.dart` (not backend-backed).
- Read and mark-all-read behavior is implemented client-side only.
- Empty state exists; explicit loading/error states do not yet exist.
- Notification settings toggle persists preference locally.

### Permissions
- Dedicated onboarding screens exist for location/microphone/camera with request flow and app settings fallback.
- Permission screens have good copy/design but denied/permanently denied states are not surfaced with explicit explanation UI.
- Some permission-related screens miss `SafeArea`.
- Biometrics screen's "Open Settings" action is currently placeholder behavior.

## Confirmed Gaps
1. Notifications are not connected to backend lifecycle (fetch/read/read-all).
2. Notification screen lacks async loading/error/retry state handling.
3. Denied/permanent-denied permission UX is not explicit enough.
4. Security biometric recovery action is not truly wired.

## Acceptance Criteria for Hardening
- Notifications list is backend-backed with loading/empty/error/read/read-all states.
- Notification item actions navigate correctly and persist read state.
- Permission screens clearly explain denied and permanently denied outcomes.
- "Open app settings" actions work from all relevant permission/biometric surfaces.
- Affected screens are safe-area and bottom-inset correct.
