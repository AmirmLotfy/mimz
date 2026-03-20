# Threat Model — Mimz

## Authentication & Authorization

| Threat | Mitigation |
|--------|-----------|
| Token forgery | Firebase Auth handles JWT verification; backend validates with Admin SDK |
| Token replay | Short-lived ID tokens (1hr), ephemeral Gemini tokens (5min TTL) |
| Privilege escalation | All game-state mutations go through backend — client is read-only |
| Missing auth | Auth middleware runs on every request (except `/healthz`) |

## API Security

| Threat | Mitigation |
|--------|-----------|
| DDoS / abuse | Rate limiting: 100 req/min per user via `@fastify/rate-limit` |
| Injection | Zod schema validation on all request bodies |
| CORS abuse | CORS configured with explicit origins in production |
| Data exposure | API returns only user's own data; no cross-user access |

## Data Privacy

| Threat | Mitigation |
|--------|-----------|
| Location tracking | Position used only for district placement; not stored continuously |
| Audio recording | Audio streamed to Gemini in real-time; never persisted to disk or cloud |
| Camera access | Frames sent to Gemini Live for vision quest only during active session |
| PII leakage | Firebase Auth handles credentials; app stores only display name + handle |

## Gemini Live Sessions

| Threat | Mitigation |
|--------|-----------|
| Session hijack | Ephemeral tokens scoped to single user, 5-minute TTL |
| Tool call spoofing | Tool execution is server-side only; client forwards calls to authenticated backend endpoint |
| Prompt injection | System instruction locked server-side; user input treated as untrusted |
| Cost runaway | Session duration capped; rate limiting on token minting endpoint |

## Infrastructure

| Threat | Mitigation |
|--------|-----------|
| Container compromise | Minimal Alpine image; no shell access in production |
| Secret exposure | Secrets via Cloud Run env vars / Secret Manager; never in source code |
| Network sniffing | HTTPS enforced (Cloud Run default); WebSocket over WSS |
