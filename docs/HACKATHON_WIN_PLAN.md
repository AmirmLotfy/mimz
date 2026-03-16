# HACKATHON WIN PLAN — Mimz
> Gemini Live Agent Challenge

## Why Mimz Should Win

1. **Gemini Live is the core**, not a feature — every round of gameplay uses live voice/vision
2. **Tools actually change game state** — grade_answer, award_territory, unlock_structure are backend-authoritative
3. **The world responds** — district grows visibly after correct answers
4. **It's a real product** — not a chatbot or demo toy; a full game with progression, squads, events, map
5. **Multi-modal** — voice + camera (vision quests analyze real-world images)

---

## Judging Criteria vs Mimz

| Criterion | Mimz Score | Evidence |
|-----------|-----------|---------|
| Gemini Live integration depth | 9/10 | Full duplex audio, tool calls, vision, barge-in |
| Real-world usefulness | 8/10 | Learning game, knowledge growth, community |
| Technical quality | 8/10 | Real audio pipeline, Firestore, 66 passing tests |
| Product coherence | 9/10 | One map, one district, everything feeds progression |
| Demo impact | 9/10 | Visible: voice in, district grows, map changes |

---

## Demo Strategy

**The angle:** "This isn't a chatbot. It's a voice game where your voice builds a world."

**The moment:** User answers a question correctly → Gemini celebrates → district grows on screen.

**The hook:** "You're talking to an AI, and the world is changing around you in real time."

---

## Competitive Differentiation

| vs Generic Voice App | Mimz |
|---------------------|------|
| Static chat UI | Live map that grows |
| One turn = one response | Tools execute real state changes |
| No persistence | Firestore district, XP, streak |
| No real game loop | 6 complete gameplay loops |
| Single modality | Voice + vision (camera) |

---

## Win Conditions

1. **Live voice works in demo** — mic captures, Gemini responds audibly
2. **Tool execution is visible** — panel shows "Grading..." then "+150 XP"
3. **District changes on screen** — sector count increases
4. **Judges can interact** — one question answered live, demo not pre-recorded
5. **Vision quest fires** — camera opens, analyzes, responds

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Gemini API down | Mock adapter (useMock: true) shows same UX |
| Mic permission fails on demo device | Pre-grant in Settings before demo |
| Network latency | Demo on good WiFi; connecting overlay reassures |
| Model gives wrong answer | grade_answer uses isCorrect from model + backend validates |
| App crashes | Always have backup device; build in release mode |

---

## Pre-Demo Checklist

- [ ] Real GEMINI_API_KEY in backend env
- [ ] Backend deployed (Cloud Run URL in app config)
- [ ] Firebase project connected
- [ ] Demo user pre-registered with interests set
- [ ] Mic permission granted on demo device
- [ ] test round completed privately (model responds, district grows)
- [ ] Mock adapter disabled in production build
- [ ] Release build installed (not debug)
