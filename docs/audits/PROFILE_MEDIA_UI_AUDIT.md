# Profile Media & UI Audit

## Scope
- Avatar upload, replace, delete, persistence, rendering resilience
- Profile-related overflow/safe-area behavior and cross-surface avatar display consistency

## Current State (as implemented)

### Profile Media
- Upload exists with `ImagePicker` + Firebase Storage in `ProfileStorageService`.
- Profile metadata (`profileImageUrl`, `storagePath`) is persisted via `PATCH /profile`.
- Remove flow exists in UI.
- Critical mismatch exists between storage rules path and app upload path.

### Rendering/UX
- Profile avatar uses `CircleAvatar` with `CachedNetworkImageProvider`.
- Loading indicator exists during upload.
- No explicit network-image error placeholder/retry in avatar itself.
- Failure UX is snackbar-only.

### Layout/Safe Area
- Profile screen has shell-aware bottom spacing, but multiple surrounding surfaces still need full safe-area pass.
- Event detail modal currently risks bottom-nav overlap for long content/CTA reachability.

## Confirmed Gaps
1. Storage upload path policy mismatch can break avatar upload in production.
2. Avatar image load failure state is under-specified.
3. Replace/remove flows need stronger retry and confirmation feedback.
4. Cross-screen avatar parity is limited (many list/profile-related surfaces still initials-only).

## Acceptance Criteria for Hardening
- Profile image upload/replace/remove works reliably with storage policy alignment.
- Avatar display never overflows, stretches, or clips incorrectly.
- Upload/remove has clear loading + success + failure + retry feedback.
- Profile media state remains consistent after refresh and across profile/settings surfaces.
