## Inspiration

Most learning and trivia apps still feel flat: you answer something, get points, and move on. We wanted to build something that feels alive.

Mimz came from a simple question: what if learning, curiosity, and live interaction could visibly change a world you care about? Instead of hiding progress in a dashboard, we wanted progress to become a place. That led us to a map-based game where users grow a personal district through real-time voice challenges, camera-powered quests, and shared squad goals.

The Gemini Live Agent Challenge was the perfect fit because the core idea only works if the agent can actually listen, speak, see, adapt in real time, and handle interruptions naturally. That is exactly what the Live Agents category is asking for. 

## What it does

Mimz is a mobile-first live AI game where users build a personal district on a stylized map.

The app starts with a live onboarding conversation. The agent asks about the user’s interests, study or work background, and play style, then personalizes the experience from the beginning.

From there, users can:
- play real-time voice challenge rounds
- interrupt the agent naturally to ask for hints, repeat, or switch difficulty
- complete camera-based quests by showing objects, notes, books, or other real-world signals
- earn territory points and materials
- expand their district on the map
- unlock structures like a Library or Observatory
- join squads and contribute to shared missions
- participate in recurring events and leaderboards

The key idea is that progress is visible. When you do well, your district grows.

## How we built it

We built Mimz as a mobile-first Flutter app with an architecture centered entirely around Gemini Live.

On the client side, the mobile app handles onboarding, permissions, map UI, live round screens, camera quests, district rendering, and squad/event flows. For real-time interaction, the app opens a direct Gemini Live WebSocket session using ephemeral, short-lived credentials securely issued by our backend.

On the backend, we built a Google Cloud-hosted Node/Fastify API that handles authoritative game logic: user profiles, district state, rewards, squads, events, leaderboards, and tool execution. The live model does not directly mutate game state. Instead, the model proposes actions via Tool Calls, our Fastify backend strictly validates and conditionally applies them, and the app updates from confirmed state.

We used:
- Flutter + Dart for the mobile client
- Gemini 2.0 Flash Live API for low-latency voice and vision interaction
- Google GenAI SDK for supporting backend model workflows
- Google Cloud Run for hosting the authoritative, scalable Node/Fastify backend
- Firestore for application and game state persistence
- Firebase Auth for secure identity resolution
- Google Secret Manager for secure API configuration

We also built the UI around a custom map-native design system so the product feels like a premium consumer app instead of a generic AI wrapper.

## Challenges we ran into

The hardest challenge was making the product feel truly live instead of “voice layered on top of a normal app.”

We had to solve for:
- interruption handling during live rounds
- keeping audio, camera, and game state in sync
- designing tool execution so the model feels fluid but the backend stays authoritative
- translating map growth into a system that is visually satisfying but technically practical
- keeping location use privacy-safe without exposing exact user coordinates
- balancing challenge difficulty so the game feels rewarding without becoming punishing

Another major challenge was product scope. The big idea can easily become too broad, so we cut aggressively and focused on the moments that best demonstrate the Live Agents category: live onboarding, real-time voice play, camera quests, district growth, and shared progression.

## Accomplishments that we're proud of

We are proud that Mimz feels like a real product, not just a hackathon demo.

Our favorite accomplishments are:
- building a live onboarding flow that personalizes the game from the first interaction
- getting real-time voice rounds to feel fast and interruptible over a direct WebSocket connection
- making camera quests meaningful instead of gimmicky
- turning progress into visible district growth on the custom map canvas
- creating a design system that feels premium, youth-focused, and unlike a generic AI app
- keeping the system grounded with backend-authoritative validation preventing prompt-injection spoofing

Most importantly, we built something that clearly moves beyond the text box.

## What we learned

We learned that multimodal UX only feels magical when every layer agrees: model behavior, interface timing, audio states, camera states, backend tools, and visual feedback.

We also learned that for live agents, restraint matters. A smaller number of polished interactions is much stronger than a broad feature list. The best moments came from tight cause-and-effect loops: speak, answer, confirm, reward, grow.

On the engineering side, we learned a lot about structuring real-time model interactions so they stay responsive while still keeping product state safe and deterministic.

## What's next for Mimz

Next, we want to deepen the world and the social layer.

Our roadmap includes:
- richer squad missions and team structures
- seasonal city events
- more structure types and district customization
- better progression balancing
- more camera quest categories
- stronger sharing and invite loops
- a companion web layer for public profiles, leaderboards, and event pages

Long term, we want Mimz to become a new kind of daily habit: a live social world where learning and curiosity build something people genuinely care about.
