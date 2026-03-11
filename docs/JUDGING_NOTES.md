# Judging Notes — Mimz

A companion guide for hackathon judges evaluating Mimz.

---

## 5 Reasons Mimz Is a Strong Live Agents Entry

1. **True real-time voice interaction** — Gemini Live WebSocket, not request/response. The AI speaks and listens simultaneously. Players answer by voice while the AI is still formulating the next question.

2. **Active vision, not passive image upload** — During Vision Quests, the camera streams frames that Gemini analyzes in context. The AI narrates what it sees and makes game decisions based on visual input.

3. **Tool calls with real consequences** — 15 typed tool calls execute against an authoritative backend. When Gemini calls `grade_answer`, the backend calculates score with streak bonuses, writes to Firestore, checks reward caps, and logs an audit entry. This isn't simulated.

4. **Persistent world that grows** — Every correct answer, every vision discovery, every combo streak changes the map. Districts expand, structures unlock, resources accumulate. The game state persists across sessions.

5. **Production architecture, not a prototype** — Zod-validated tool schemas, Firebase Auth middleware, anti-abuse protections (reward caps, territory bounds, streak limits), 33 unit tests, multi-stage Docker build, comprehensive documentation.

---

## 5 Things to Notice During the Demo

1. **The waveform** — When the AI speaks, the waveform animates. When the player speaks, it changes. This isn't decoration — it reflects real audio state.

2. **Score updates are server-confirmed** — When a point total changes, it came from the backend via a tool call response, not from the client guessing.

3. **The AI stays in character** — The Mimz persona is tuned via a detailed system instruction. The AI is enthusiastic but concise, celebrates achievements briefly, and keeps pace moving.

4. **Interruption works** — The player can speak while the AI is talking. The AI detects the barge-in, stops, and adapts. This is native to Gemini Live.

5. **No typing anywhere** — The entire game loop is voice-first. There are no text input fields in the quiz flow.

---

## How the App Goes Beyond Text

| Dimension | How |
|-----------|-----|
| **Voice output** | AI reads questions, gives hints, celebrates answers — with modulated speech |
| **Voice input** | Player answers by speaking naturally, no wake word |
| **Camera input** | Real-time frame capture for object identification |
| **Spatial** | Territory growth is visible on a map — knowledge has geographic consequence |
| **Haptic** | UI responds with animations and state transitions on every game event |
| **Interruption** | True bidirectional audio — player can barge in at any time |

---

## Why the Design Matters

- **20+ screens** with a cohesive editorial design system (dark theme, glassmorphism, gradient accents)
- **Not a chat interface** — the quiz screen, vision quest screen, and world map are purpose-built game UIs
- **Premium feel** — the app looks like a real product, not a hackathon throwaway
- **Information hierarchy** — scores, streaks, resources are always visible during gameplay

---

## How Backend Authority Keeps the Experience Credible

A common weakness in AI game demos: the client trusts whatever the AI says. In Mimz:

1. **Gemini proposes** → "The answer is correct, award 500 points"
2. **Backend validates** → Zod schema checks point value is in range (0-500 max per tool call)
3. **Backend calculates** → Score = base (100) + streak bonus (30) = 130, not whatever the model said
4. **Backend checks caps** → Is this user under the 5,000 XP/hour limit?
5. **Backend persists** → Firestore atomic increment, not client-side
6. **Backend audits** → Logged with correlation ID for debugging

This means a compromised or hallucinating model cannot award a million points or infinite territory.

---

## Technical Decisions for Demo Reliability

| Decision | Why |
|----------|-----|
| Mock adapter available | `USE_MOCK_LIVE=true` replays canned sequences — demo works without API key |
| Demo auth fallback | Backend accepts requests without Firebase in development mode |
| Bounded tool arguments | Zod schemas cap max values — even bad model output is safe |
| Correlation IDs | Every tool call is traceable end-to-end for debugging |
| Exponential backoff | WebSocket reconnects automatically with jitter |
| Ephemeral tokens | 5-minute TTL prevents stale session issues during demo |
