# Haptics Spec

## Intent
Mimz haptics should feel premium, sparse, and meaningful. The app should never buzz on every tap. Haptics should reinforce important intent, state transitions, and confidence moments.

## Source of Truth
- Use centralized `HapticsService` only.
- Never call `HapticFeedback.*` directly from feature screens.
- Service must respect `SettingsService.getHaptic()` before emitting feedback.

## Trigger Matrix

| Interaction | Haptic | Why |
| --- | --- | --- |
| Standard tile/tab selection | `selection()` | Lightweight navigation acknowledgment. |
| Primary CTA submission | `mediumImpact()` | Marks meaningful forward action. |
| Destructive confirmation | `heavyImpact()` | Adds weight to high-consequence actions. |
| Successful save/upload/update | `success()` | Confirms completion and reliability. |
| Soft warning/validation nudge | `lightImpact()` | Signals attention without alarm feel. |
| Error/failed action | `error()` | Distinguishes failure from success. |

## Usage Rules
1. Emit one haptic per meaningful action, not per widget in the same action chain.
2. Do not stack success + selection for the same tap.
3. For toggles/switches, use subtle selection only.
4. For permission flows, use:
   - `mediumImpact` when requesting,
   - `success` when granted,
   - `error` for denied/permanently denied.
5. For upload flows, only fire success/error on final outcome.

## Hardening Checklist
- Replace direct `HapticFeedback` calls in settings/profile/security and other touched features.
- Ensure route/tab interactions use subtle selection only.
- Verify haptics disable correctly when settings toggle is off.
