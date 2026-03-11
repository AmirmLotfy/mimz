# Architecture — Mimz

## System Overview

Mimz uses a split architecture where the Flutter app handles media and UI, Gemini Live handles real-time conversation, and the Cloud Run backend remains the single authority for game state.

```mermaid
graph TB
    subgraph "Flutter Mobile App"
        UI["Screen Layer<br>20+ screens"]
        DS["Design System<br>Tokens + Components"]
        RP["Riverpod<br>State Management"]
        LIVE["Live Stack<br>WebSocket + Audio + Camera"]
        SVC["Services<br>API / Auth / Location"]
    end

    subgraph "Gemini Live API"
        WS["WebSocket<br>Bidirectional Audio + Text"]
        TOOLS["15 Tool Declarations<br>grade_answer, award_territory, etc."]
        PERSONA["Mimz Persona<br>Game Host Instructions"]
    end

    subgraph "Cloud Run Backend"
        API["Fastify API<br>10 Route Modules, 25+ Endpoints"]
        AUTH["Auth Middleware<br>Firebase Token Verification"]
        EXEC["Tool Executor<br>15 Handlers + Zod Validation"]
        GSVC["Game Services<br>Scoring, Rewards, Territory, Audit"]
    end

    subgraph "Google Cloud"
        FS[("Firestore<br>10 Collections")]
        FA["Firebase Auth"]
        GCS["Cloud Storage"]
    end

    UI --> DS
    UI --> RP
    RP --> SVC
    SVC -->|"REST + Firebase ID Token"| API
    LIVE -->|"WebSocket"| WS
    LIVE -->|"Tool results"| API
    API --> AUTH
    AUTH -->|"Verify"| FA
    API --> EXEC
    EXEC --> GSVC
    GSVC --> FS
    WS --> TOOLS
    WS --> PERSONA
```

## Why This Split

| Responsibility | Who Owns It | Why |
|---------------|------------|-----|
| Audio/video capture | Flutter app | Platform APIs require native access |
| Conversation persona | Gemini Live | Real-time voice requires direct WebSocket |
| Game state mutations | Backend only | Prevents cheating; model output can hallucinate values |
| Score calculation | Backend only | Streak bonuses, combo multipliers enforced server-side |
| Resource deduction | Backend only | Structure costs validated against actual inventory |
| UI rendering | Flutter app | 60fps native rendering |

Key insight: **Gemini proposes, backend disposes**. The AI suggests game actions via tool calls, but the backend validates and executes them authoritatively.

---

## Live Session Flow

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant BE as Cloud Run Backend
    participant GM as Gemini Live API

    App->>BE: POST /live/ephemeral-token<br>Authorization: Bearer <firebase_token>
    BE->>BE: Verify Firebase ID token
    BE->>BE: Mint token (5-min TTL)
    BE-->>App: { token, model, expiresAt, tools }

    Note over App,GM: Direct WebSocket — backend never proxies media

    App->>GM: WebSocket connect (ephemeral token)
    App->>GM: Setup { model, systemInstruction, tools }
    GM-->>App: setupComplete

    loop Quiz Round
        GM-->>App: Audio: "Which architect designed Fallingwater?"
        App-->>GM: Audio: "Frank Lloyd Wright"
        GM->>GM: Decide answer correctness
        GM-->>App: toolCall: grade_answer { answer: "Frank Lloyd Wright", isCorrect: true }
        App->>BE: POST /live/tool-execute { toolName, args, sessionId }
        BE->>BE: Validate args (Zod schema)
        BE->>BE: Calculate score + streak bonus
        BE->>BE: Firestore: increment XP, update streak
        BE->>BE: Log reward + audit entry
        BE-->>App: { success: true, data: { pointsAwarded: 130, streak: 4 } }
        App->>GM: toolResponse { result: data }
        GM-->>App: Audio: "Correct! 130 points! You're on a 4-answer streak!"
    end
```

## Tool Execution Flow

Every tool call follows a 7-step validation pipeline:

```mermaid
flowchart LR
    A["Tool call from<br>Gemini"] --> B["1. Known tool?<br>KNOWN_TOOLS check"]
    B --> C["2. Valid args?<br>Zod schema parse"]
    C --> D["3. User context<br>Auth middleware"]
    D --> E["4. Business rules<br>Requirements, caps"]
    E --> F["5. Firestore<br>Atomic mutations"]
    F --> G["6. Reward log<br>Anti-abuse cap"]
    G --> H["7. Audit entry<br>Correlation ID"]
```

**15 registered tools:**

| Tool | Category | Mutates State |
|------|----------|:---:|
| `start_onboarding` | Onboarding | ✅ |
| `save_user_profile` | Onboarding | ✅ |
| `get_current_district` | District | ❌ |
| `start_live_round` | Quiz | ✅ |
| `grade_answer` | Quiz | ✅ |
| `award_territory` | Quiz | ✅ |
| `apply_combo_bonus` | Quiz | ✅ |
| `grant_materials` | Quiz | ✅ |
| `end_round` | Quiz | ✅ |
| `start_vision_quest` | Vision | ❌ |
| `validate_vision_result` | Vision | ✅ |
| `unlock_structure` | District | ✅ |
| `join_squad_mission` | Social | ❌ |
| `contribute_squad_progress` | Social | ✅ |
| `get_event_state` | Social | ❌ |

---

## District State Persistence

```mermaid
flowchart TB
    CORRECT["Player answers correctly"] --> SCORE["Backend calculates score<br>(base + streak bonus)"]
    SCORE --> XP["Firestore: increment user.xp"]
    SCORE --> STREAK["Firestore: update user.streak"]

    COMBO["Streak reaches 3+"] --> BONUS["apply_combo_bonus<br>Bonus XP + materials"]
    BONUS --> MAT["Firestore: increment district.resources"]

    TERRITORY["award_territory called"] --> EXPAND["Firestore: increment district.sectors"]
    EXPAND --> AREA["Recalculate area"]

    UNLOCK["unlock_structure called"] --> CHECK["Validate: sectors >= min, xp >= min, resources >= cost"]
    CHECK --> DEDUCT["Deduct resource cost"]
    DEDUCT --> ADD["Add structure to district.structures"]
    ADD --> PRESTIGE["Recalculate prestige level"]
```

## Auth / Bootstrap Flow

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant FA as Firebase Auth
    participant BE as Backend
    participant FS as Firestore

    App->>FA: Sign in (Apple/Google/Email)
    FA-->>App: Firebase ID token
    App->>BE: POST /auth/bootstrap<br>Authorization: Bearer <token>
    BE->>FA: verifyIdToken(token)
    FA-->>BE: { uid, email }

    alt New User
        BE->>FS: Create user document
        BE->>FS: Create starter district (1 sector, starter resources)
        BE-->>App: { user, district }
    else Existing User
        BE->>FS: Read user document
        BE-->>App: { user, district }
    end
```

---

## Firestore Collections

| Collection | Key Fields | Role |
|-----------|-----------|------|
| `users/{uid}` | xp, streak, sectors, interests | Player identity and progression |
| `districts/{id}` | sectors, structures, resources | Territory and inventory |
| `liveSessions/{id}` | topic, score, questions | Round tracking |
| `rewards/{id}` | type, amount, source | Reward audit trail |
| `squads/{id}` | name, joinCode, members | Team management |
| `events/{id}` | title, status, participants | Community challenges |
| `leaderboards/{scope}/entries/{uid}` | score, rank | Rankings |
| `auditLogs/{id}` | action, toolName, correlationId | Security audit |
| `notifications/{id}` | type, title, read | User notifications |

See [FIRESTORE_SCHEMA.md](FIRESTORE_SCHEMA.md) for full document shapes and indexes.

---

## Security and Trust Boundaries

1. **Transport**: All Cloud Run traffic is HTTPS with managed TLS
2. **Identity**: Firebase Auth tokens verified on every request
3. **Session**: Ephemeral tokens (5-min TTL) for Gemini Live — no long-lived API keys on client
4. **Authorization**: Backend extracts `userId` from verified token — no client-supplied user IDs trusted
5. **Validation**: All tool call args validated by Zod schemas with bounded ranges
6. **Anti-abuse**: Reward cap (5,000 XP/hour), territory cap (3 sectors/round), streak cap (10x)
7. **Privacy**: Public district views return only coarse data — never owner ID or cell coordinates
8. **Audit**: Every state mutation logged with correlation ID

See [SECURITY_MODEL.md](SECURITY_MODEL.md) for the full model.

---

## Failure and Retry Handling

| Failure | Client Behavior | Backend Behavior |
|---------|----------------|-----------------|
| WebSocket disconnect | Exponential backoff (max 5 retries) + token refresh | N/A (stateless) |
| Tool call timeout | Retry once, then show error pill | Return timeout error |
| Invalid tool args | Display error, continue session | Reject with Zod error message |
| Firebase token expired | Transparent re-auth via refresh token | 401 → client re-authenticates |
| Reward cap hit | Show "slow down" message | Return cap error with details |
| Firestore error | N/A (handled server-side) | Log error, return safe error response |

---

## Scale Notes

- Cloud Run auto-scales from 0 to 10 instances (configurable)
- Firestore handles up to 10,000 writes/sec per collection
- Ephemeral tokens prevent token replay attacks
- Rate limiting: 100 requests/minute per IP
- Backend is stateless — any instance handles any request
- Body limit: 1MB per request
