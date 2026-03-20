# GAMEPLAY FUNCTIONALITY AUDIT — Mimz
> Last updated: 2026-03-15

## Loop 1: First-Use Loop

| Step | Status | Notes |
|------|--------|-------|
| Install → launch | ✅ | Main.dart initializes Firebase, router |
| Auth (Google / email) | ✅ | AuthService, biometric tie-in |
| Permissions (mic, camera) | ✅ | Permission screens in onboarding |
| Onboarding live session | ✅ | startOnboardingSession → Gemini |
| Profile setup (name, interests) | ✅ | 3 onboarding screens |
| District naming + emblem | ✅ | Screens exist, boot saves to Firestore |
| First district reveal | ⚠️ | World map loads, but "first reveal" animation is minimal |
| First round | ✅ | LiveQuizScreen with real session |
| First reward | ✅ | grade_answer + award_territory |
| Visible district growth | ⚠️ | sectors++ in Firestore; map tile update depends on worldProvider sync |

**Loop coverage: 8/10**

---

## Loop 2: Core Daily Loop

| Step | Status |
|------|--------|
| Open app → home map | ✅ WorldHomeScreen |
| Start live round | ✅ PlayHubScreen → LiveQuizScreen |
| Receive reward | ✅ grade_answer backend |
| District grows | ✅ expandTerritory Firestore write |
| Motivation to continue | ⚠️ Streak shown, but "what's next" prompt is weak |

**Loop coverage: 4/5**

---

## Loop 3: Vision Quest Loop

| Step | Status |
|------|--------|
| Enter vision quest | ✅ VisionQuestCameraScreen |
| Camera activates properly | ✅ LiveCameraStreamService |
| Quest prompt is clear | ✅ Gemini speaks quest in voice |
| Input is evaluated | ✅ validate_vision_result tool |
| Reward is granted | ✅ +200 XP on success |
| District changes | ✅ incrementUserXp |
| Quest persistence | ⚠️ Quest not saved to Firestore — just audited |

**Loop coverage: 6/7**

---

## Loop 4: Structure Loop

| Step | Status |
|------|--------|
| User sees requirements | ⚠️ Requirements visible in WorldExpandedSheet but not in-session |
| Unlock flow | ✅ unlock_structure tool handles all checks |
| Resource deduction | ✅ Backend authoritative |
| State updates visibly | ⚠️ District screen shows structures, but live refresh after unlock unclear |
| Structure matters to progression | ✅ calculateResourceRate boosts materials |

**Loop coverage: 3/5**

---

## Loop 5: Squad Loop

| Step | Status |
|------|--------|
| Create / join squad | ✅ squads.ts routes exist |
| View squad state | ✅ squad detail screen |
| Contribute mission progress | ⚠️ contribute_squad_progress writes XP but join_squad_mission is shallow |
| Shared impact visible | ⚠️ Squad leaderboard exists but refresh unclear |

**Loop coverage: 2/4**

---

## Loop 6: Event Loop

| Step | Status |
|------|--------|
| Discover event | ✅ events.ts GET route |
| Join event | ✅ POST /events/:id/join |
| Contribute score | ⚠️ No event-scoring tool in executeLiveTool |
| See leaderboard update | ✅ upsertLeaderboardEntry on end_round |

**Loop coverage: 3/4**

---

## Overall Loop Health

| Loop | Score |
|------|-------|
| First-use | 8/10 |
| Daily core | 4/5 |
| Vision quest | 6/7 |
| Structure | 3/5 |
| Squad | 2/4 |
| Event | 3/4 |

**Primary recommendation:** Focus demo on the first-use + core daily loops. These are the most complete and most impactful.
