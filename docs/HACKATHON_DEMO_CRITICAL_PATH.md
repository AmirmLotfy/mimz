# HACKATHON DEMO CRITICAL PATH — Mimz
> Last updated: 2026-03-15

## The Strongest 3-Minute Demo

### Step 1: Auth (15s)
- Open app on clean device
- Sign in with Google
- Bootstrap auto-creates user + district in Firestore
- **What judges see:** fast login, no "loading..." hell

### Step 2: Onboarding (30s)
- Select 3 interests (Technology, Science, History)
- Pick "Dynamic" difficulty
- **Gemini speaks:** "Welcome, [name]! Your district is ready."
- **What judges see:** real voice response tailored to the user

### Step 3: First Quiz Round (90s)
- Tap "Play Live Round"
- Session starts — CONNECTING → LIVE ROUND chip appears
- **Gemini asks:** "What programming language is Flutter built on?"
- **User speaks:** "Dart"
- **Gemini grades → grade_answer tool fires**
- **Panel shows:** "✅ CORRECT! +150 XP"
- **award_territory fires** → district grows 1 sector
- **Map on screen updates** sector counter
- Repeat 1-2 more questions
- **What judges see:** real voice in, real world change out

### Step 4: Round Result (15s)
- End round
- RoundResultScreen shows: total XP, streak, territory gained
- Map animates the growth
- **What judges see:** tangible progress from one voice session

### Step 5: Vision Quest (30s)
- Switch to Vision Quest tab
- Camera opens
- Gemini speaks: "Show me something made of metal"
- User points camera at laptop / phone
- Gemini responds: "Verified! +200 XP"
- **What judges see:** multimodal input (voice + vision) changing game state

### Step 6: District Map (15s)
- Show the district map with updated sectors
- Point to structure requirements: "I'm 3 sectors from unlocking the Library"
- **What judges see:** the world state reflects everything we did

---

## Primary Demo Path

```
Auth → Onboarding Voice → Quiz Round (3 questions) → Result → Vision Quest → District Map
```

---

## Backup Path (If Live API Fails)

1. Toggle `useMock: true` in LiveSession providers
2. MockAdapter replays pre-recorded session events
3. Same UI: voice transcript shows, reward fires, district grows
4. **Important:** Always test backup path before demo

---

## What Must Work Live (Non-Negotiable)

- Gemini responds audibly (the app makes sound)
- grade_answer tool fires and XP appears
- award_territory fires and district grows
- Barge-in works (interrupt Gemini mid-sentence)

## Can Fail Gracefully

- Vision quest (can say "let me show you in settings")
- Squad/event screens (say "deeper features — squads, events")
- Leaderboard (not core to demo)

---

## Pre-Demo Verification Commands

```bash
# Backend health
curl https://your-backend-url/healthz

# Auth + bootstrap
curl -X POST https://your-backend-url/auth/bootstrap \
  -H "Authorization: Bearer YOUR_TOKEN"

# Ephemeral token
curl -X POST https://your-backend-url/live/ephemeral-token \
  -H "Authorization: Bearer YOUR_TOKEN"

# Run all tests
cd backend && npm test

# Flutter analyze
flutter analyze lib/
```

---

## Timing Reference

| Segment | Time |
|---------|------|
| Auth | 15s |
| Onboarding voice | 30s |
| Quiz (3 questions) | 90s |
| Round result | 15s |
| Vision quest | 30s |
| District map reveal | 15s |
| **Total** | **~3 min** |

---

## Things to Say to Judges

- "Unlike a chatbot, every voice answer changes the world state — backed by Firestore."
- "The AI isn't just talking — it's executing tool calls that our backend validates."
- "This is Gemini Live at the center of an entire game engine, not just a voice UI."
- "Barge-in works — watch what happens when I interrupt the AI mid-sentence."
