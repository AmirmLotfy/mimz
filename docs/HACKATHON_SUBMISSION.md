# Hackathon Submission — Mimz

> Copy/paste source for Devpost submission forms.

---

## Project Name

**Mimz — Learn live. Build your district.**

## One-Line Pitch

A live voice-and-vision mobile game where Gemini hosts real-time quizzes, identifies real-world objects through your camera, and grows your personal district on a map — all through natural spoken conversation.

## Category

**Live Agents**

## Why Live Agents

Mimz is not a chatbot. It is a real-time bidirectional AI game host that:
- Speaks and listens simultaneously over a persistent WebSocket connection
- Processes camera frames during Vision Quests
- Executes 15 typed tool calls that mutate authoritative backend state
- Handles mid-sentence interruptions and adapts its flow
- Maintains a consistent game host persona across multi-turn voice sessions

This is a Live Agent, not request/response.

## What Makes Mimz Beyond Text

| Modality | How It's Used |
|----------|--------------|
| **Voice (output)** | Gemini reads quiz questions, celebrates correct answers, gives hints |
| **Voice (input)** | Players speak answers — no typing, no buttons |
| **Vision** | Camera captures real-world objects during Vision Quests for AI identification |
| **Interruption** | Players can barge in mid-question — AI stops, acknowledges, continues |
| **Spatial** | Territory growth is visible on a map — progression has geographic meaning |

## What the Live Agent Actually Does

The Mimz AI host:
1. Greets new players and collects interests through natural conversation (onboarding)
2. Reads quiz questions aloud with appropriate difficulty
3. Listens to spoken answers and evaluates correctness
4. Calls `grade_answer` to score — backend awards XP, updates streak
5. Calls `award_territory` when the player earns expansion
6. Calls `grant_materials` to award building resources
7. Calls `apply_combo_bonus` when streaks reach 3+
8. Initiates Vision Quests and guides camera exploration
9. Calls `validate_vision_result` when the player shows an object
10. Calls `unlock_structure` when a blueprint is earned
11. Ends rounds with summary and calls `end_round` for leaderboard update

## How Google Cloud Is Used

| Service | Role | Evidence |
|---------|------|---------|
| **Cloud Run** | Hosts Fastify backend (containerized, auto-scaling) | `backend/Dockerfile`, deploy commands |
| **Firestore** | Persists users, districts, squads, events, rewards, audit logs | 10 collections, 30+ repository functions |
| **Firebase Auth** | Identity (Apple/Google/Email sign-in) | Auth middleware verifies ID tokens |
| **Gemini 2.0 Flash Live** | Real-time multimodal AI via WebSocket | Persona, 15 tool definitions, ephemeral tokens |

## Key Technologies

`flutter` `dart` `gemini-2.0-flash-live` `google-cloud-run` `firestore` `firebase-auth` `fastify` `typescript` `zod` `riverpod` `go-router` `websocket` `vitest`

## Inspiration

Learning apps are passive. Games are fun but shallow. Map games are solitary. We wanted to build something where AI doesn't just quiz you — it *hosts* you. Where correct answers literally expand your territory. Where pointing your camera at the real world earns rewards. Gemini Live made this possible: a real-time, multimodal AI that can listen, speak, see, and execute game logic in a single conversation.

## How We Built It

1. Designed a 20+ screen Flutter app with an editorial design system
2. Built a production Fastify backend with Zod-validated schemas, Firebase Auth, and Firestore
3. Implemented a full Gemini Live WebSocket integration with 15 typed tool calls
4. Created a domain-driven live interaction stack (audio capture, playback, turn detection, reconnect policy)
5. Wired tool calls to backend-authoritative game logic with anti-abuse protections
6. Wrote 33 backend unit tests and comprehensive documentation

## Challenges

- **Latency**: Keeping voice interactions snappy required careful audio buffering and optimistic UI
- **Persona consistency**: Tuning the system instruction to keep Mimz in character across topics
- **Authoritative tool execution**: Balancing responsive client UX with server-side-only state mutations
- **Multi-modal coordination**: Syncing camera input, voice output, and map updates in one screen
- **Anti-abuse**: Validating unbounded model outputs (Gemini can propose any score — backend must verify)

## Accomplishments

- 20+ production screens with editorial design system (dark theme, glassmorphism, micro-animations)
- Full Gemini Live integration with 15 custom tool definitions and Zod-validated execution
- Backend-authoritative game state with reward caps, territory bounds, and audit logging
- 33 passing unit tests covering tool schemas, scoring logic, and domain models
- Comprehensive documentation: architecture diagrams, API reference, security model, demo script

## What We Intentionally Scoped Out

- Real-time multiplayer (squad missions demo as single-player)
- Push notifications (FCM)
- AR structure preview on real-world map
- App Store / Play Store release builds
- Internationalization (English only)
- Offline mode

These are real future work items, not missing features. The core Live Agent experience is complete.

## Built With

flutter, dart, gemini, google-cloud, cloud-run, firestore, firebase-auth, typescript, fastify, websocket, google-maps
