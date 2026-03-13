# How I Built Mimz: A Voice-First Live Agent Game with Gemini Live, Firebase, and Cloud Run

**By Amir Lotfy**
• March 10, 2026 • 7 min read • Gemini Live API, Firebase, Cloud Run

`Gemini Live API` `Google AI` `Cloud Run` `Firebase` `Firestore` `Flutter` `Dart` `Fastify`

Mimz is a voice-first, map-native mobile app where players answer live spoken challenges, complete optional camera quests, and grow a personal district in realtime.

I built Mimz for the Google Gemini Live Agent Challenge with a simple product principle: the experience must feel live, multimodal, and game-like from the first interaction.

*Hackathon note: This article was created specifically for the purpose of entering the Gemini Live Agent Challenge. If you share this on social media, use #GeminiLiveAgentChallenge.*

### Why this architecture
Most AI demos feel like chat UIs with a skin. Mimz needed to feel like a realtime game loop, not a chatbot. That drove three architecture decisions:

1. **Low latency voice UX**: The mobile app connects directly to Gemini Live over WebSockets.
2. **Backend authority**: All persistent state updates go through API tools, never model-owned memory.
3. **Multimodal by default**: Voice is primary, camera quests are optional but native.

This gave us the best of both worlds: fast conversational turn-taking plus deterministic, auditable game state.

### Tech stack

**Mobile (Frontend)**
* Flutter + Dart
* GoRouter for deep-linking and route orchestration
* Riverpod for reactive state management and dependency injection
* Flutter Audio plugins for low-latency push-to-talk recording
* Flutter Camera plugin for native vision quest input
* Custom Hex Geometry Canvas rendering for district growth visualization

**Backend**
* Node.js + TypeScript + Fastify
* Cloud Run deployment (fully automated via shell scripts)
* Firebase Admin SDK for auth token verification
* Firestore for persistent game state
* Google Secret Manager for secure API Key binding
* Tool execution layer with strict Zod validation, caps, idempotency, and audit logs

**AI**
* Gemini 2.0 Flash Live API for realtime voice sessions
* Gemini Vision models for asynchronous visual validation and tool-driven decisions
* Ephemeral token minting pattern for secure, temporary session establishment

### System design in one sentence
The mobile app speaks directly to Gemini Live for low latency, but every single game mutation is executed and validated by the backend via explicit tool calls.

That pattern protects consistency and enables aggressive anti-abuse controls while preserving a realtime, magical feel.

### Realtime flow: from speech to game state
1. User starts a live round in the app.
2. App requests an ephemeral token from the Fastify API.
3. API mints a short-lived token and returns it.
4. App opens a direct WebSocket session to Gemini Live.
5. The model emits a tool intent (e.g., `grade_answer`, `award_territory`).
6. App forwards the tool call to our `/live/tool-execute` endpoint.
7. Backend validates the input with Zod, checks caps/limits, updates Firestore, and writes an audit log.
8. Backend returns the authoritative result payload.
9. App sends the tool response event back to Gemini Live.
10. UI updates from the backend-confirmed state (not speculative model text).

This flow was critical for preventing drift between what the model says and what the game actually stores.

### Data model and trust boundaries
Core Firestore collections:
* `users`
* `districts`
* `squads`
* `events`
* `leaderboards`
* `rewards`
* `liveSessions`
* `auditLogs`

**Trust model:**
* **Client**: presentation + capture (voice/camera) + transport
* **Model**: reasoning + tool intent generation
* **Backend**: validation + policy + authoritative writes
* **Firestore**: source of truth

### Hard problems and what solved them

**1) Live UX race conditions**
*Issue*: UI navigation changes and socket callbacks can race, causing stale or ghost updates.
*Fix*: We gated callbacks via Riverpod lifecycle hooks, added explicit WebSocket disconnects on screen transitions, and implemented reconnect support with the last known session config.

**2) Audio format mismatch in mobile capture**
*Issue*: The recording output MIME from the device may not match the expected Gemini live payload.
*Fix*: The Flutter audio pipeline explicitly serializes the PCM audio with explicit MIME metadata, and the session sender transmits raw `{ base64Audio, mimeType }` payloads.

**3) Backend safety under hackathon speed**
*Issue*: Rapid endpoint growth can create fragile validation and replay bugs.
*Fix*: Strict Zod schemas per endpoint, rate limit middleware, anti-abuse caps (e.g., max 5,000 XP/hr), and correlation IDs on every audit log around sensitive tool actions.

**4) App-store readiness**
*Fixes included*: Explicit iOS `Info.plist` usage descriptions (microphone, camera), automated FlutterFire provisioning, legal screens linked from the profile, and a complete account deletion flow.

### Performance and reliability choices
* Direct Live WebSocket avoids proxy latency for speech interaction.
* Stateless Fastify API supports Cloud Run multi-instance auto-scaling.
* Atomic district/session updates reduce concurrent write conflicts in Firestore.
* CI-friendly shell scripts (`deploy_all.sh`) ensure reproducible infrastructure-as-code deployments for judges.

### What made the product believable
* Voice-first onboarding and live rounds with native interruption support.
* Visible world progression mapped to beautifully rendered hex district territories.
* Vision quest loop with backend structure unlocks + rewards.
* Squad/event/leaderboard surfaces tied directly to persisted global state.
* An end-to-end flow that feels like a polished production app, not a static prototype.

### If you want to build this pattern
Start with architecture, not UI:
1. Define trust boundaries early.
2. Keep model outputs non-authoritative.
3. Design tools as strictly-typed contracts.
4. Make every mutation rate-limited and auditable.

You will move faster and break less.

### Final thoughts
Mimz was built to demonstrate that live multimodal AI can power a polished mobile product, not just a standalone tech demo.

The key insight was simple: realtime interaction belongs on the client-to-model path, while truth belongs on the backend-to-data path.

That split made it possible to ship something that is fast, expressive, and ready for production.
