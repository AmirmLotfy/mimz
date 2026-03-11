# Demo Script — Mimz

**Target duration**: 3–4 minutes
**Format**: Screen recording with voiceover, or live on device

---

## Pre-Demo Checklist

- [ ] Backend running (`cd backend && npm run dev`)
- [ ] Flutter app installed on device/simulator
- [ ] `.env` has valid `GEMINI_API_KEY`
- [ ] Microphone permission will be granted on first prompt
- [ ] Camera permission will be granted on first prompt
- [ ] Screen recorder running (if recording)
- [ ] Quiet room (no background noise for voice recognition)
- [ ] Backup: mock mode ready (`--dart-define=USE_MOCK_LIVE=true`)

---

## Script

### 0:00 – 0:20 | Problem + Hook

**Show**: Title slide or splash screen
**Say**: "Learning apps are passive — you read, you tap, you forget. Mimz changes that. It's a live AI game where you speak, point your camera, and build a real neighborhood on a map. Powered by Gemini Live."
**Duration**: 20 seconds

### 0:20 – 0:40 | App Launch + Auth

**Show**: Splash animation → Welcome screen → Sign in
**Say**: "One-tap sign-in. The app launches into an animated map grid. Clean, fast, no friction."
**Do**: Tap Apple/Google sign-in
**If stuck**: Skip auth — demo mode auto-assigns a user
**Duration**: 20 seconds

### 0:40 – 1:10 | Permissions + Live Onboarding

**Show**: Permission screens → Live onboarding (dark AI screen)
**Say**: "First time? Mimz onboards you with a real voice conversation. Not a form. Not a tutorial. Gemini Live greets you, learns your interests, and sets up your world."
**Do**: Grant mic + camera → Watch AI speak and respond
**Key moment**: Show the waveform animating as the AI speaks
**If live fails**: "The onboarding conversation adapts to each player. Here it's learning that I'm interested in architecture and geography."
**Duration**: 30 seconds

### 1:10 – 1:40 | District Creation + Map

**Show**: District naming → World Home map view
**Say**: "Based on what Mimz learned, it suggests a district name. Mine is 'Verdant Reach.' I can see it on the map — my territory, ready to grow."
**Do**: Accept name → Show map with district boundary
**Duration**: 30 seconds

### 1:40 – 2:30 | Live Quiz (Core Loop)

**Show**: Play Hub → Live Quiz screen
**Say**: "This is the core gameplay. Gemini reads a question out loud. I answer by speaking. Watch — no buttons, no multiple choice."
**Do**:
1. Tap "Join Challenge"
2. AI reads question aloud (waveform animates)
3. Speak the answer clearly
4. Watch score update in real-time
5. Show streak counter incrementing

**Key moment**: "That `grade_answer` tool call just went to my backend, calculated 130 points with a streak bonus, wrote to Firestore, and came back — all in under a second."

**If live recognition fails**: "In a live session the AI hears and scores instantly. Let me show you what the scored result looks like." → Show result screen.
**Duration**: 50 seconds

### 2:30 – 2:50 | Interruption Demo

**Show**: AI mid-sentence
**Say**: "Watch what happens when I interrupt."
**Do**: Start speaking while AI is still talking
**Key moment**: AI stops, acknowledges the barge-in, continues flow
**Say**: "That's real-time interruption handling. Not turn-based. Live."
**If timing is tricky**: Skip — come back to it in Q&A
**Duration**: 20 seconds

### 2:50 – 3:20 | Vision Quest

**Show**: Vision    Quest → Camera opens
**Say**: "Vision Quests: point your camera at something real. The AI identifies it and rewards discovery."
**Do**: Point camera at an architectural object or interesting item
**Key moment**: AI calls `validate_vision_result` → Blueprint awarded
**Say**: "Gemini just looked through my camera, identified what I showed it, and awarded an architectural blueprint."
**If camera fails**: "The camera captures frames that Gemini analyzes. When it identifies something meaningful, it unlocks a blueprint for my district."
**Duration**: 30 seconds

### 3:20 – 3:50 | Growth + Social

**Show**: District map expanding → Reward Vault → Squad Hub → Leaderboard
**Say**: "Every quiz and quest grows my district. New sectors, new structures, new resources. I can join a squad, compete in live events, climb leaderboards."
**Duration**: 30 seconds

### 3:50 – 4:10 | Backend Proof

**Show**: Terminal with backend logs OR Cloud Run console
**Say**: "Everything runs on Google Cloud. Cloud Run backend, Firestore persistence, Firebase Auth. Here you can see tool calls being executed, rewards being logged."
**Do**: Show a tool execution log line with `grade_answer` or `award_territory`
**Duration**: 20 seconds

### 4:10 – 4:30 | Close

**Say**: "Mimz makes learning live. It's voice-first, camera-capable, and every interaction grows your world. Powered by Gemini Live, built on Google Cloud. Thank you."
**Duration**: 20 seconds

---

## Failure Recovery Lines

| Failure | Recovery |
|---------|----------|
| AI doesn't respond | "The AI connects via WebSocket — let me restart the session." |
| Voice not recognized | "In a live environment the AI would hear and respond. Let me show the result." |
| Camera not working | "The vision pipeline captures frames for Gemini analysis — here's what a successful quest looks like." |
| Backend down | Switch to mock mode: `flutter run --dart-define=USE_MOCK_LIVE=true` |
| Score doesn't update | "The tool call is in flight — in production this resolves in under 200ms." |

## What to Screen-Record Beforehand

If live demo is risky, record these clips in advance:
1. Live onboarding conversation (30 seconds)
2. Quiz round with 3 questions answered by voice (45 seconds)
3. One interruption moment (10 seconds)
4. One vision quest completion (20 seconds)
5. Backend terminal showing tool execution logs (10 seconds)
