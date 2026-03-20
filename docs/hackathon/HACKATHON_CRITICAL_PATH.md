# Hackathon Critical Path

Last updated: 2026-03-18

## 3-4 Minute Demo Sequence

1. Launch + authenticate quickly.
2. Fast personalization/onboarding moment.
3. District reveal on world map.
4. Live round with speaking, hearing, and interruption.
5. Backend-confirmed reward grant.
6. Visible district growth animation.
7. Camera/vision quest sample.
8. Squad/event progression proof.
9. Cloud architecture credibility proof.
10. Close with product value statement.

## Demo Script Notes

### 1) Launch and Auth (0:00-0:30)

- Show splash-to-auth flow without friction.
- Demonstrate clean successful sign-in (no bootstrap loop).

### 2) Personalization (0:30-1:00)

- Complete one meaningful onboarding signal (interests or difficulty).
- Explain this changes live challenge quality.

### 3) District Reveal (1:00-1:20)

- Enter world and show named district + emblem + sector count.
- State that backend persists this as authoritative map state.

### 4) Live Gameplay (1:20-2:20)

- Start live round.
- Demonstrate app hearing and concise AI response.
- Show interruption (barge-in) working.

### 5) Reward and Growth (2:20-2:50)

- Claim rewards from result screen.
- Highlight backend confirmation and immediate map growth.

### 6) Vision + Social (2:50-3:25)

- Trigger short camera quest.
- Show event/squad contribution UI proof.

### 7) Architecture Credibility (3:25-3:45)

- Show Cloud Run + Firebase + model routing statement.
- Mention backend-authoritative progression and auditability.

## Demo Reliability Checklist

- Auth/bootstrap success verified.
- District load success verified.
- Live token issuance verified.
- Reward claim endpoint verified.
- Vision permission path verified.
- Event/squad screen loads verified.

## Contingency Paths

- If live service degrades: use `Retry Session` once, then `Reset Session`; if still unavailable, `Back to World` and continue map/social proof.
- If camera permission denied: continue with quiz-only branch and explain graceful degradation.
- If backend latency spikes: show retry UX and continue with preserved state.
