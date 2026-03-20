# Legal, Help & Feedback Audit

## Scope
- `PrivacyPolicyScreen`, `TermsOfServiceScreen`, `HelpSupportScreen`, and settings-linked support actions
- Frontend UX quality, link behavior, and backend integration path for feedback

## Current State (as implemented)

### Legal
- Privacy and Terms are already in-app Flutter screens, not web redirects.
- Content is readable but still lightweight and mostly static.
- Contact text in privacy screen is not currently actionable link UI.
- Safe-area wrapping and bottom inset behavior need consistency checks.

### Help
- Help screen has useful FAQ content and polished visual blocks.
- Primary support CTA ("Send Protocol Log (Feedback)") is placeholder and does nothing.

### Feedback
- Settings screen supports a `mailto:` feedback entry.
- No structured backend feedback endpoint currently wired.
- No form-based validation flow for issue categories, context, or error reports.

## Confirmed Gaps
1. Help CTA is dead in-app action.
2. Feedback path is basic mail compose only.
3. Legal content hierarchy and interaction polish can be improved.
4. No backend-supported feedback submission route yet.

## Acceptance Criteria for Hardening
- Legal pages open instantly in-app, scroll cleanly, and include polished hierarchy.
- Legal contact/action links are tappable and robust.
- Help screen contains only live, actionable controls.
- Feedback flow supports real submission with validation + success/failure states (backend or hardened fallback).
