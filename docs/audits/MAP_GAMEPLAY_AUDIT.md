# Map & Gameplay Hardening Pass

## Executive Summary
This document details the complete end-to-end hardening of the Mimz map and gameplay systems. Previously, the map and all game metrics (territory growth, population, resources, squad progress, structures) were entirely decorative and hardcoded. 

**The primary achievement of this hardening pass is wiring the beautifully polished Flutter UI to real, deterministic game state via Riverpod providers and the backend API, transforming Mimz from a UI prototype into a functional game loop without breaking the demo experience.**

---

## 1. Data-Driven Map Architecture

### The Problem
The `_WorldMapPainter` was drawing a static, decorative line grid, and `_DistrictBoundaryPainter` was drawing a fixed-size rounded rectangle. It did not reflect actual territory size or growth.

### The Solution: Hex-Cell Territory Renderer
- **Domain Model**: Enhanced `District` with `HexCell` generation using an axial coordinate spiral algorithm.
- **Data-Driven Painter**: Replaced static painters with `_HexDistrictPainter` in `WorldHomeScreen`. It now paints individual hex cells based precisely on the `district.sectors` count.
- **Visual Polish**: 
  - The center cell receives an anchor indicator.
  - Cells fade in brightness based on distance from the center.
  - A subtle outer glow defines the territory boundary.

---

## 2. The Core Gameplay Loop

### The Problem
`RoundResultScreen` showed hardcoded rewards ("+1 Sector", "+120 Stone"). Tapping "CLAIM" did not communicate with the backend, and navigating back to the world showed no change.

### The Solution: Deterministic Reward Processing
- **Reward Calculation**: Created `roundRewardsProvider` that deterministically calculates rewards from `QuizState`:
  - `Sectors`: 1 sector per 2,000 score points (capped at 5/round).
  - `Materials`: Base amounts scaled by score + streak multiplier.
  - `XP & Streak`: Directly tied to gameplay performance.
- **Backend Sync**: 
  - Added `expandTerritory` and `addResources` to `apiClient`.
  - Added `claimRewards()` to `worldProvider`, which calls the backend and *optimistically updates local state instantly*.
- **The "Feel" (Animation)**: Created `districtGrowthEventProvider`. When `claimRewards()` finishes, returning to the map triggers a 1.2-second expanding `Acid Lime` pulse animation across the newly expanded hex cluster.

---

## 3. World Expanded Sheet (Stats & Progression)

### The Problem
The stats sheet showed "14.2k POP", "+4.2% GROWTH", and "Next Structure: Great Library" for every user, regardless of actual progress.

### The Solution: Computed District Properties
- **Derived Stats**: Enhanced the `District` model with computed properties:
  - `population`: `(sectors * 850) + (structures.length * 1200)`
  - `growthRate`: Base 1.0 + structure bonuses
  - `prestigeLevel`: Derived from total XP
- **Structure Progression**: Implemented a progression ladder in `world_expanded_sheet.dart` (`_getNextStructure`) that calculates exactly which structure the user can build next based on their sector count and XP, matching the backend `STRUCTURE_CATALOG`.

---

## 4. Play Hub & Squads/Events

### The Problem
Cards in the Play Hub showed hardcoded strings like "ROUND 7 • 8x STREAK". Squad and Event lists were entirely fake mock data, and dialogs didn't attempt API calls.

### The Solution: State Injection & Fallback Architecture
- **Play Hub**: Challenge cards now read actual `user.streak` and `district.sectors` to dynamically generate detail strings and XP estimates.
- **Squads & Events**: 
  - Restructured `squadProvider`, `squadMissionsProvider`, `eventsProvider`, and `activeEventProvider` to attempt `apiClient` calls first.
  - Provided robust, realistic `demo` fallback data ensuring the UI never breaks or shows loading spinners if the backend is unreachable during a live demo.
  - The map's "LIVE EVENT" chip perfectly reflects `activeEventProvider` state.

---

## Conclusion
The Mimz gameplay loop is now mathematically sound and visually responsive. When a user answers questions correctly, their score calculates real territory rewards, syncing with the backend, updating local state, and triggering a satisfying expansion animation on a dynamically painted hex grid map.
