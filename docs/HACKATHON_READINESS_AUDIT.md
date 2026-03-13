# HACKATHON READINESS AUDIT
> Generated: 2026-03-13

## Judging Criteria (Gemini Live Agent Challenge)

| Criterion | Current State | Score | Notes |
|---|---|---|---|
| Uses Gemini Live API | Controller exists but quiz screen not wired | 4/10 | **FIX IMMEDIATELY** |
| Voice-first experience | Audio pipeline exists | 6/10 | Needs quiz wiring |
| Vision utilization | Camera screen exists, wiring unclear | 5/10 | Needs verification |
| Product quality | World map is premium | 7/10 | Several stubs remain |
| Architecture clarity | Google Cloud + Gemini Live well documented | 8/10 | Very strong |
| Demo readiness | Empty events/squads + broken quiz = not ready | 3/10 | **Critical fixes needed** |
| Overall impression | Beautiful design, clearly ambitious | 7/10 | Very close to great |

## "Wow Path" Analysis

The intended demo path:
1. Open app → AI greets you by voice (onboarding)
2. Answer spoken quiz questions → district grows on map
3. Take a camera quest → AI recognizes real-world object
4. Return to map → see new sectors, structures

**Current reality:**
1. ✅ App opens beautifully
2. ⚠️ Onboarding AI voice — needs verification
3. 🔴 Quiz screen: mic does nothing, no Gemini session
4. ❌ No way for district to grow (result screen doesn't trigger growth)
5. ⚠️ Vision quest: camera works, AI analysis unclear
6. ✅ Map is beautiful with growth animations

## What Wows Judges

✅ **Already wow**: 
- Hex district map with growth animation and shockwave effect
- Premium dark live quiz UI design
- Real ephemeral token + proxied tool execution architecture
- 36 documentation files covering every aspect
- Deployed, live Cloud Run backend with real Gemini key

🔴 **What kills it currently:**
- Quiz screen mic does nothing
- Events and squads are empty
- District doesn't grow after playing

## Remaining Work for Hackathon Win

| Priority | Task | Impact |
|---|---|---|
| P0 | Wire live_quiz_screen to controller | Gemini actually works |
| P0 | Seed demo events + squad | Tabs aren't empty |
| P0 | Fix round result → growth trigger | Core loop is visible |
| P1 | Add auth router guard | No crashes from direct navigation |
| P1 | Fix settings sign out | Demo can be reset |
| P1 | Wire onboarding name save | District shows real name |
| P2 | Create district detail screen | More depth |
| P2 | Fix empty states | No blank screens |

## Architecture Story (Strong)

The project already has a compelling architecture story:
- Flutter mobile → Gemini Live API (via ephemeral token proxy)
- Gemini makes tool calls → Cloud Run backend validates them
- Backend uses Firebase Admin SDK → Firestore persistent game state
- Auth via Firebase Authentication
- Secret management via GCP Secret Manager

This is a textbook "right way to use Gemini Live" pattern and will impress technical judges.

## Summary

**Current hackathon readiness: 45%**
**After GAP-01, GAP-06, GAP-09, GAP-10, GAP-07 fixes: ~85%**

The bones are excellent. The architecture is correct. The design is premium. The code quality is high. The single most impactful fix is wiring the live quiz screen to the LiveSessionController — after that, everything else is polish.
