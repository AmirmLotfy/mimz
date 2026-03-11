# Security Model — Mimz

## Authentication Layers

| Layer | Mechanism | Scope |
|-------|-----------|-------|
| **Transport** | HTTPS (Cloud Run managed TLS) | All traffic |
| **Identity** | Firebase Auth ID tokens | All non-public endpoints |
| **Session** | Ephemeral tokens (5-min TTL) | Gemini Live sessions |
| **Authorization** | User ID from verified token | Per-request |

### Why API Keys Never Reach the Client

The `GEMINI_API_KEY` lives only on the backend. The client never sees it. Instead:

1. Client sends Firebase ID token to backend
2. Backend verifies token and mints a short-lived ephemeral session credential
3. Client uses that credential to open a WebSocket to Gemini Live
4. Credential expires after 5 minutes — client must re-request

This prevents token theft, replay attacks, and unauthorized API usage.

---

## Backend-Authoritative Tool Execution

The most important security property: **Gemini proposes, backend disposes.**

```
Gemini: "Award 500 points for correct answer"
  ↓
Backend: Validates args via Zod schema (max 500 per call) ✓
  ↓
Backend: Calculates actual score = base(100) + streak(30) = 130
  ↓
Backend: Checks hourly reward cap (under 5,000?) ✓
  ↓
Backend: Atomic Firestore increment (+130 XP)
  ↓
Backend: Logs reward grant + audit entry
  ↓
Backend: Returns { pointsAwarded: 130 } to client
```

The model cannot:
- Award arbitrary points (bounded by schema + calculation)
- Grant infinite territory (max 3 sectors per round)
- Bypass resource costs (structure unlock validates inventory)
- Skip audit logging (every mutation is traced)

---

## Anti-Abuse Protections

| Protection | Limit | Enforcement |
|-----------|-------|-------------|
| Reward cap | 5,000 XP per hour per user | Checked on every reward grant |
| Territory bounds | Max 3 sectors per round | Zod schema bound |
| Streak cap | Max 10x multiplier | Scoring function cap |
| Material limits | Max 500 per resource per tool call | Zod schema bound |
| Rate limiting | 100 requests per minute per IP | Fastify rate-limit plugin |
| Body size | 1MB max | Fastify body limit |
| Tool name validation | Must be in KNOWN_TOOLS (15 registered) | Registry check |
| Arg validation | Full Zod schema parse with bounds | Before handler dispatch |

---

## Public vs Private Data

| Data | Default Exposure | Public View |
|------|-----------------|-------------|
| User ID | Private | Never exposed |
| Display name | Coarse | Visible in leaderboards |
| XP / Streak | Coarse | Visible in leaderboards |
| District name | Coarse | Visible in public view |
| District structures | Coarse | Count only (no details) |
| District cell coordinates | Private | Never exposed |
| District resources | Private | Never exposed |
| Email | Private | Never exposed |
| Interests | Private | Never exposed |

Default visibility: `coarse`. Users can set `public`, `private`, or `coarse`.

---

## Audit Logging

Every state mutation is logged with:
- `userId` — who
- `action` — what
- `toolName` — which tool
- `sessionId` — which live session
- `correlationId` — end-to-end trace ID
- `detail` — mutation-specific context
- `timestamp` — when

Audit logs live in the `auditLogs` Firestore collection and are never deleted.

---

## Error Response Sanitization

- In **production**: 5xx errors return `"Internal server error"` — never stack traces or internal details
- In **development**: Full error details are included for debugging
- API keys are never logged at any level

---

## Known Security Gaps (MVP)

These are acknowledged and documented for transparency:

1. **Demo auth fallback** — in `NODE_ENV=development`, requests without tokens are accepted with a demo user. Disabled in production.
2. **Ephemeral token scope** — currently wraps the API key rather than using Gemini's proper scoped token exchange endpoint. Production fix is straightforward.
3. **No request signing** — client requests are authenticated but not signed. A man-in-the-middle with a stolen Firebase token could replay requests.
4. **Per-IP rate limiting** — rate limits are per source IP, not per authenticated user. A user behind a shared IP could be unfairly limited.
5. **No Firestore security rules** — using Admin SDK (server-side only), so client-side rules are not needed for current architecture. Would be needed if client ever writes directly.
