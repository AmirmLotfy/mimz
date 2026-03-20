# Mimz Product Logic Source Of Truth

Last updated: 2026-03-18

## Purpose

This document is the canonical product contract for Mimz.  
If implementation and this spec disagree, this spec wins until explicitly revised.

## Core Product Truths

- Mimz is a live voice-and-vision game, not a chatbot.
- Mimz is a game loop with visible progression, not a static quiz feed.
- Mimz does not expose exact location ownership; district geography is privacy-safe and gameified.
- The district map is the player's world state and must visibly change after meaningful actions.
- Backend state is authoritative for progression, rewards, and long-term persistence.
- Gemini Live is the realtime interaction layer, not the persistence layer.
- Every major action should create player-visible consequence within the same session.
- Short sessions must still create momentum (materials, sectors, streaks, or unlock progress).

## Product Pillars

1. **Live**: low-latency talking/hearing loop with interruption support.
2. **Map-native**: district map is first-class, not decorative.
3. **Backend-authoritative**: rewards and progression are server-validated.
4. **Social**: squads and events affect progress and motivation.
5. **Premium UX**: concise voice, clear feedback, polished recovery states.

## Non-Goals

- Long-form assistant conversations that block gameplay pace.
- Fake local-only progression in release mode.
- Hidden failures where buttons appear to work but state does not persist.
- Permission spam without user-facing value explanation.

## Authoritative Data Ownership

- **Firebase Auth**: user identity and ID token issuance.
- **Backend (Cloud Run + Firestore)**:
  - user profile bootstrap/persistence
  - district state and growth
  - reward grants and balancing rules
  - squad/event/leaderboard data
  - live tool execution
- **Flutter client**:
  - UI state and transitions
  - permissions and hardware interaction
  - live session client transport and playback
  - optimistic presentation only when explicitly safe

## Product Success Criteria

- First-time user reaches world map with named district and first meaningful reward in under 3 minutes.
- A live round always ends with a clear result: reward granted, no reward with reason, or recoverable failure.
- Any auth/bootstrap failure provides an immediate recoverable action (retry/sign out).
- District loading never hangs indefinitely; it resolves into data, explicit error, or guided recovery.
- The 3-4 minute demo path runs reliably on a fresh install.

## Release Readiness Gate

Release is blocked if any of the following are true:

- auth/bootstrap loop produces unrecoverable state.
- district map can remain infinite-loading without user action path.
- rewards can be granted locally without backend confirmation.
- live session failure has no reconnect/retry exit path.
- model routing is hardcoded in multiple conflicting places.

## Current Implementation Alignment

- Live startup now requires backend token mint + websocket handshake + explicit recovery UI.
- Live failures must expose at least one deterministic action: `Retry Session`, `Reset Session`, or `Back to World`.
- Backend-issued live session IDs are treated as authoritative for tool execution authorization.
- Vertex live region is decoupled from Cloud Run region (`GEMINI_LIVE_VERTEX_LOCATION`) to avoid regional model mismatch outages.
