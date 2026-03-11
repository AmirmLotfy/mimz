# API Reference — Mimz Backend

Base URL: `http://localhost:8080` (dev) · Cloud Run URL (prod)

All endpoints require `Authorization: Bearer <firebase-id-token>` unless marked Public.

---

## Health (Public)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/healthz` | Liveness probe. Returns `{ status: "ok" }` |
| GET | `/readyz` | Readiness probe. Returns `{ status: "ready" }` or 503 |

---

## Auth

| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth/bootstrap` | Create user + starter district if new, return existing if found |

**Response**: `{ user: User, district: District }`

---

## Profile

| Method | Path | Description |
|--------|------|-------------|
| GET | `/profile` | Get current user profile |
| PATCH | `/profile` | Update profile fields (displayName, handle, interests, visibility, districtName) |

**PATCH body**: `{ displayName?: string, interests?: string[], visibility?: "public" | "private" | "coarse" }`
**Error**: 404 if user not found

---

## District

| Method | Path | Description |
|--------|------|-------------|
| GET | `/district` | Get user's district + resource rates + structure catalog |
| GET | `/district/public/:districtId` | Privacy-safe public view (name, sectors, structure count — no owner ID) |
| POST | `/district/preview-growth` | Preview what expansion would look like |
| POST | `/district/unlock-structure` | Unlock structure (validates cost, requirements, deducts resources) |

**Unlock body**: `{ structureId: string }`
**Unlock errors**: 400 if unknown structure, insufficient resources, requirements unmet, or already unlocked

---

## Live (Gemini Integration)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/live/ephemeral-token` | Mint Gemini Live session credential (5-min TTL) |
| POST | `/live/tool-execute` | Execute a validated tool call from Gemini session |
| POST | `/live/session-log` | Receive client-side debug session logs |
| GET | `/live/config` | Return supported modes and voice config |

**Ephemeral token body**: `{ sessionType?: "onboarding" | "quiz" | "vision_quest" }`
**Ephemeral token response**: `{ session: { token, model, expiresAt, tools } }`

**Tool execute body**: `{ toolName: string, args: object, sessionId: string, correlationId?: string }`
**Tool execute response**: `{ success: boolean, data: object, error?: string, correlationId: string, executedAt: string }`

**Tool execute errors**:
- 400: Invalid request body (Zod validation)
- Unknown tool name: `{ success: false, error: "Unknown tool: ..." }`
- Invalid args: `{ success: false, error: "Invalid args for ...: ..." }`
- Business rule violation: `{ success: false, error: "Reward cap exceeded" }`

---

## Squads

| Method | Path | Description |
|--------|------|-------------|
| POST | `/squad` | Create a new squad (auto-generates join code) |
| POST | `/squad/join` | Join a squad by code |
| GET | `/squad/:squadId` | Get squad details |
| POST | `/squad/:squadId/contribute` | Contribute progress to a squad mission |

**Create body**: `{ name: string, displayName?: string }`
**Join body**: `{ joinCode: string, displayName?: string }`
**Contribute body**: `{ missionId: string, amount?: number }`

---

## Events

| Method | Path | Description |
|--------|------|-------------|
| GET | `/events` | List active/upcoming events |
| GET | `/events/:eventId` | Get event detail |
| POST | `/events/:eventId/join` | Join an event |
| POST | `/events/:eventId/score` | Submit contribution score |

**Join error**: 400 if event is completed
**Score body**: `{ score: number }`

---

## Leaderboard

| Method | Path | Description |
|--------|------|-------------|
| GET | `/leaderboard` | Global leaderboard (top 20) |
| GET | `/leaderboard/:scope` | Scoped leaderboard (e.g., event-specific) |

---

## Rewards

| Method | Path | Description |
|--------|------|-------------|
| GET | `/rewards` | Last 7 days of reward history with summary totals |

**Response**: `{ rewards: RewardGrant[], summary: { period, totalXp, totalTerritory, totalRewards } }`

---

## Notifications

| Method | Path | Description |
|--------|------|-------------|
| GET | `/notifications` | User's notification feed (last 50) |

---

## Error Format

All errors return:
```json
{ "error": "Human-readable message", "statusCode": 400 }
```

In production, 5xx errors return `"Internal server error"` — never leak internals.
