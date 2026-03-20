# Map District World Spec

Last updated: 2026-03-18

## District Model Goals

- Map reflects real progression, not decoration.
- Privacy-safe location anchoring.
- Scalable globally across countries and regions.

## District Seeding

- On first successful bootstrap (post-auth):
  - create starter district if absent
  - set default sectors/materials/structures
  - assign coarse locality context (region/city bucket), never precise coordinates

## Growth Model

- District grows via backend-confirmed rewards.
- Growth represented as additional hex cells/clusters.
- New growth flagged for one-time animation in client (`newSectors` visual only).
- Structures unlocked via milestone thresholds and resource costs.

## Rendering Model

- Client renders from district snapshot:
  - sectors
  - structures
  - area
  - prestige
  - emblem/name
- Camera behavior:
  - center on district on entry
  - pan to growth center on reward animation
  - preserve user pan/zoom intent after animation

## Persistence

- Backend stores canonical district state in Firestore.
- Public district endpoint returns coarse-safe data only.
- No direct client writes to district canonical fields.

## Privacy and Visibility

- Modes:
  - `private`: full owner view only
  - `coarse_public`: sector/prestige/structure count only
- Never expose exact coordinates or owner identifiers in public endpoint.

## World Context

- Events can be region-scoped using coarse locality.
- Travel scenario:
  - district ownership remains stable
  - local event recommendations may change by current coarse region

## Failure Behavior

- Loading state must transition to:
  - success, or
  - explicit error with retry, or
  - explicit empty state (district missing) with recovery action
- No indefinite loading loops.
- Retry paths must preserve last known district snapshot until backend confirmation arrives.
