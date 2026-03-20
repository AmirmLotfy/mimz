# Known Limitations — Mimz

Honest assessment of current scope. This is a hackathon build with intentional tradeoffs.

---

## What Is Fully Implemented

- ✅ 20+ screen Flutter app with editorial design system
- ✅ Gemini Live WebSocket integration with voice + 15 tool calls
- ✅ Complete Fastify backend with 25+ endpoints, Zod validation, auth middleware
- ✅ Firestore data access layer (30+ typed repository functions)
- ✅ Backend-authoritative tool execution with anti-abuse protections
- ✅ 33 passing unit tests (tool schemas, scoring logic, domain models, structure catalog)
- ✅ Multi-stage Dockerfile for Cloud Run deployment
- ✅ Riverpod state management across all features
- ✅ Mock live adapter for development without API key

## What Is Demo Mode (Functional, Simplified)

- 🟡 **Firebase Auth** — backend accepts requests without token verification in development. Real verification requires `flutterfire configure` and a Firebase project.
- 🟡 **Google Maps** — rendered as a stylized grid painter. Real map rendering requires Maps API key in platform configs (iOS AppDelegate / Android Manifest).
- 🟡 **Audio capture/playback** — service interfaces are implemented with full state machines. Platform-specific package code (`record`, `just_audio`) is commented until iOS/Android permission config is done.
- 🟡 **Camera stream** — interface and frame handling implemented. `camera` package code commented until platform setup.

## What Is Intentionally Simplified

- **Leaderboard ranking** — simple top-N query, not a globally ranked system
- **Squad missions** — single-player participation, not real-time multiplayer coordination
- **Event participation** — score submission model, not live concurrent competition
- **District map cells** — territory counted numerically, not rendered as specific H3 hexagons on a real map
- **Ephemeral token minting** — returns API key in a session object rather than using Gemini's scoped token exchange endpoint

## What Is Not Yet Implemented

- ❌ Real-time multiplayer (squad missions, live events with concurrent players)
- ❌ Push notifications (FCM)
- ❌ AR preview of unlocked structures on real-world map
- ❌ Offline mode / local caching
- ❌ App Store / Play Store release builds
- ❌ Accessibility audit (basic semantics only)
- ❌ Internationalization (English only)
- ❌ Client-side Flutter widget tests

## What Would Need Production Hardening

- Replace ephemeral token with Gemini's proper scoped token endpoint
- Add Firestore security rules (currently using Admin SDK, not client-side rules)
- Add request signing or client certificate pinning
- Move rate limiting from per-IP to per-user
- Add per-user session limits for Gemini Live
- Implement proper cache headers and ETag support
- Add structured error codes (not just message strings)
- CI/CD pipeline with automated testing
