# Website Edits: mimzapp.vercel.app → Align With App

Use this checklist to update [https://mimzapp.vercel.app/](https://mimzapp.vercel.app/) so the marketing site accurately reflects the Mimz app (Flutter app + backend in this repo).

---

## 1. Hero & Tagline

| Location | Current (website) | Edit to (app reality) |
|----------|-------------------|------------------------|
| **Page title / meta** | Mimz — Learn Live. Build Your District. | Keep as-is (matches app tagline). |
| **Hero headline** | "Learn live.Build yourdistrict." | **Fix typo:** "Learn live. Build your district." (add space after "live." and space in "your district"). |
| **Subhead** | "Mimz turns what you know into a world of your own. Answer live challenges, complete camera quests, grow your district, and build with friends on a living map." | Optional tweak for consistency with in-app welcome: you could add "Explore the world around you." at the start, but current line is fine. |
| **Below CTA** | "See how it works ↓Available on iPhone and Android" | **Fix:** "See how it works ↓ Available on iPhone and Android" (add space before "Available"). |

---

## 2. App Mockup / Device Frame

| Location | Current | Edit to |
|----------|---------|--------|
| **Bottom nav in mockup** | 3 tabs: ◆District · ⚡Live · ●Squad | **Update to 5 tabs** to match app: **WORLD** (map) · **PLAY** · **SQUAD** · **EVENTS** · **ME** (profile). |
| **Status bar** | "9:41" / "Your District" / "Level 1 · Growing" | OK to keep; ensure "Your District" or "World" matches the first tab (app calls it "World" with map view). |

---

## 3. Value Proposition Block

| Location | Current | Edit to |
|----------|---------|--------|
| **Line** | "Part live companion. Part social game. Part world you build yourself." | Keep. |
| **Feature bullets** | Live voice rounds · Vision quests · District building · Squad missions | **Add:** **Daily Sprint** — "5 quick questions to keep your streak" (app has this as a 4th play mode on Play Hub). So: Live voice rounds · Vision quests · **Daily Sprint** · District building · Squad missions. |

---

## 4. "What is Mimz" / "A new kind of daily game"

| Location | Current | Edit to |
|----------|---------|--------|
| **Bullets** | "Talk to the app naturally" / "Let it challenge you live" / "Show it what's around you" / "Build your district" / "Come back tomorrow stronger." | Keep; aligns with app. |
| **Sub-bullets** | Live spoken gameplay · Camera-powered quests · Map-based progress · Friends, squads, and events | **Add:** "Daily Sprint" or "Quick daily rounds" so all four Play Hub modes are represented (Live Quiz, Vision Quest, Squad Mission, Daily Sprint). |

---

## 5. "How Mimz works" (4 steps)

| Location | Current | Edit to |
|----------|---------|--------|
| **STEP 01** | "Start your district — Choose your name, create your identity, and claim your first space on the map." | Align with real onboarding: "Set up your profile, pick interests, choose an emblem, name your district, and claim your first space on the map." (App flow: permissions → basic profile → interests → gameplay preferences → live onboarding → summary → emblem → district name → world.) |
| **STEP 02** | "Play live rounds — Answer spoken challenges in real time, ask for hints, switch topics, and keep your streak alive." | Keep; matches Live Quiz. |
| **STEP 03** | "Complete vision quests — Use your camera to prove, discover, and unlock extra progress through live world-based missions." | Keep. |
| **STEP 04** | "Grow your world — Expand your district, unlock structures, collect rewards, and build with your squad." | Optional: mention "Reward Vault" and "blueprints" (app uses these terms). |

---

## 6. "Not a quiz app. A living world."

| Location | Current | Edit to |
|----------|---------|--------|
| **Live Voice Challenges** | "AI-powered spoken quizzes that adapt to your level, pace, and interests in real time." | Keep. |
| **Vision Quests** | "Camera-based real-world missions. Show, prove, and discover to earn territory points." | Keep. |
| **Build Your District** | "Watch your territory grow on a stylized map. Unlock structures, earn prestige, own your world." | Keep; app has prestige levels and sector/XP progression. |
| **Squad Up** | "Team missions with friends. Collaborate, compete, and unlock shared goals together." | Keep. Consider adding that **Events** and **leaderboards** (city + squad) are in the app (Events tab, leaderboard screens). |

---

## 7. Structures & Rewards

| Location | Current | Edit to |
|----------|---------|--------|
| **Structures list** | Library · Observatory · Archive · Park Pavilion · Maker Hub | **Keep as-is** — matches backend `STRUCTURE_CATALOG` and in-app copy. |
| **Rewards line** | "Relics · Emblems · Prestige ranks" | **Align with app:** App has **Reward Vault** with **blueprints** (common / rare / master), **emblems** (onboarding + identity), and **prestige ranks** on the district. You can say: "Blueprints · Emblems · Prestige ranks" or keep "Relics" if you use it elsewhere; in code, rewards are often blueprint-based. |
| **Headline** | "Build more than a streak" | Keep. |

---

## 8. Social & Events

| Location | Current | Edit to |
|----------|---------|--------|
| **Social section** | Squads · Events · Leaderboards · Invites | **Keep;** app has Squad Hub, Events screen, leaderboard(s), and share/invite (e.g. district share). |
| **Events section** | "Something new to chase, every week" / City challenges, topic drops, squad builds, etc. | Keep; ensure Events tab is visible in nav/mockup (see §2). |

---

## 9. Auth & Download

| Location | Current | Edit to |
|----------|---------|--------|
| **CTA** | "Download on the App Store" / "GET IT ON Google Play" | If the app is not yet on stores, keep as "Coming soon" or "Get early access" and link to TestFlight/Play internal testing if applicable. |
| **Sign-in** | (If you show sign-in flow) | App supports **Google** and **Email** sign-in (and **Apple** per README when enabled in Firebase). Show "Get started" → Sign in with Google / Continue with Email (and Apple if available). |

---

## 10. Testimonials

| Location | Current | Edit to |
|----------|---------|--------|
| **Quotes** | Three testimonials about feeling alive, district, squad | If these are **placeholder**: add a small line like "Early testers" or replace with real quotes once you have them. If real, keep. |

---

## 11. "Inside Mimz" / App Preview

| Location | Current | Edit to |
|----------|---------|--------|
| **Screens shown** | "Live Round · District Map · Squad View" | **Add:** **Play Hub** (quiz, vision, squad mission, daily sprint), **Round Result**, **Vision Quest success**, **Events list**, **Profile/Me** (settings, reward vault, notifications). At minimum, show 5-tab bar: World · Play · Squad · Events · Me. |

---

## 12. Copy Consistency With In-App Text

Optional alignment with exact in-app strings:

- **Welcome (app):** "YOUR NEIGHBORHOOD IS YOUR SCHOOL." / "Explore the world around you. Answer live challenges. Grow your district on the map."
- **Play Hub (app):** "Choose your challenge." / "Every play grows your district and sharpens your mind."
- **Live Quiz:** "Voice-powered trivia with AI host."
- **Vision Quest:** "Point your camera, discover the world."
- **Squad Mission:** "Team up and tackle bigger challenges."
- **Daily Sprint:** "5 quick questions to keep your streak."

Use these where helpful so website and app feel like one product.

---

## 13. Technical / Honesty (Optional for Marketing)

- README notes: real-time multiplayer (squad missions, live events) is currently single-player demo; no push notifications, AR, or offline mode. You likely **don’t** need this on the marketing site; only add if you want a "Beta" or "Early build" disclaimer.

---

## Summary Checklist

- [ ] Fix hero: "Learn live. Build your district." (spaces).
- [ ] Fix "See how it works ↓ Available on iPhone and Android" (space).
- [ ] Update device mockup nav to 5 tabs: WORLD · PLAY · SQUAD · EVENTS · ME.
- [ ] Add **Daily Sprint** to feature lists and "How you play" copy.
- [ ] Align Step 01 with real onboarding (permissions, profile, interests, emblem, district name).
- [ ] Optionally mention Reward Vault and blueprints in rewards section.
- [ ] Ensure Events and Profile are visible (nav or preview).
- [ ] Auth: Google + Email (and Apple if enabled).
- [ ] Testimonials: label as early testers or replace with real quotes.
- [ ] App preview: include Play Hub, 5-tab bar, and key screens (quiz, vision, map, squad, events, profile).

Once these edits are applied, the website will accurately reflect the Mimz app experience.
