# Final Settings/Profile Hardening Fixes

## Purpose
This document captures the final production-hardening changes across Profile, Settings, Legal, Help, Feedback, Notifications, Permissions, and Haptics.

## Completion Checklist
- [ ] Profile display/edit/update flow is fully real and error-safe.
- [ ] Profile image upload/replace/remove is stable and storage-backed.
- [ ] Settings items have no fake toggles or dead actions.
- [ ] Legal/help/feedback actions are real and polished.
- [ ] Event detail content is never hidden behind bottom nav.
- [ ] Notifications are backend-backed with robust UI states.
- [ ] Permission states are clear for granted/denied/permanently denied.
- [ ] Haptic behavior is centralized, subtle, and consistent.
- [ ] Safe-area and bottom inset issues are resolved on target screens.
- [ ] Backend profile/notification/feedback endpoints are validated and typed.

## Verification Flow
1. Sign in and open `Profile`.
2. Change avatar from camera/gallery, then remove it.
3. Edit profile fields, save, force close app, re-open, and verify persisted state.
4. Open settings: toggle notifications/haptics/sound/location and verify persistence.
5. Open legal/help/feedback routes and verify all CTAs are actionable.
6. Open events and event details; verify no CTA/content overlap with floating nav.
7. Open notifications; verify loading, read/unread, mark all read, empty and error handling.
8. Walk through permission routes and denied/permanent-denied recoveries.
9. Confirm haptic behavior matches `docs/HAPTICS_SPEC.md`.

## Remaining Manual Dependencies
- Store listing legal copy review (if policy text updates are required by compliance).
- Support inbox ownership for backend feedback triage.
- Push notification infrastructure (FCM/APNs) rollout if required beyond inbox parity.
