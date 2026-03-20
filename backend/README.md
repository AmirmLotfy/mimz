# Mimz Backend

Production backend for the Mimz live voice-and-vision game.

**Stack**: Node.js · TypeScript · Fastify · Firestore · Firebase Auth · Gemini Live API (Vertex on Google Cloud)

## Quick Start

```bash
# Install dependencies
npm install

# Copy environment config
cp .env.example .env
# Edit .env with your values

# Run locally (dev mode)
npm run dev

# Run tests
npm test

# Build for production
npm run build
npm start
```

## Architecture

```
backend/
├── src/
│   ├── server.ts              # Entry point
│   ├── config/index.ts        # Zod-validated env config
│   ├── lib/
│   │   ├── firebase.ts        # Firebase Admin init
│   │   └── db.ts              # Firestore repositories (30+ functions)
│   ├── middleware/
│   │   └── auth.ts            # Firebase ID token verification
│   ├── models/
│   │   └── types.ts           # 20+ Zod domain schemas
│   ├── modules/live/
│   │   ├── executeLiveTool.ts  # 15 tool handlers + registry
│   │   ├── liveService.ts      # Persona + token minting
│   │   └── toolSchemas.ts      # Zod validation for all tools
│   ├── services/
│   │   └── gameService.ts      # Auth, district, reward, scoring, audit
│   └── routes/
│       ├── auth.ts             # POST /auth/bootstrap
│       ├── profile.ts          # GET/PATCH /profile
│       ├── district.ts         # GET/POST district endpoints
│       ├── live.ts             # Ephemeral token + tool execute
│       ├── squads.ts           # Squad CRUD
│       ├── events.ts           # Event endpoints
│       ├── leaderboard.ts      # Leaderboard queries
│       ├── rewards.ts          # Reward history
│       ├── notifications.ts    # Notification feed
│       └── health.ts           # /healthz /readyz
├── test/                       # Vitest test files
├── Dockerfile                  # Multi-stage Cloud Run build
└── .env.example                # All required env vars
```

## API Endpoints

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/auth/bootstrap` | ✅ | Create/retrieve user + district |
| GET | `/profile` | ✅ | Get user profile |
| PATCH | `/profile` | ✅ | Update profile fields |
| GET | `/district` | ✅ | Get user's district + catalog |
| GET | `/district/public/:id` | ✅ | Privacy-safe public view |
| POST | `/district/preview-growth` | ✅ | Preview expansion |
| POST | `/district/unlock-structure` | ✅ | Unlock structure (validates cost) |
| POST | `/live/ephemeral-token` | ✅ | Mint Gemini Live session token |
| POST | `/live/tool-execute` | ✅ | Execute tool call from Live session |
| POST | `/live/session-log` | ✅ | Receive client debug logs |
| GET | `/live/config` | ✅ | Public session config |
| POST | `/squad` | ✅ | Create squad |
| POST | `/squad/join` | ✅ | Join by code |
| GET | `/squad/:id` | ✅ | Get squad |
| POST | `/squad/:id/contribute` | ✅ | Contribute to mission |
| GET | `/events` | ✅ | List events |
| GET | `/events/:id` | ✅ | Event detail |
| POST | `/events/:id/join` | ✅ | Join event |
| POST | `/events/:id/score` | ✅ | Submit score |
| GET | `/leaderboard` | ✅ | Global leaderboard |
| GET | `/leaderboard/:scope` | ✅ | Scoped leaderboard |
| GET | `/rewards` | ✅ | Reward history (7d) |
| GET | `/notifications` | ✅ | Notification feed |
| GET | `/healthz` | ❌ | Liveness probe |
| GET | `/readyz` | ❌ | Readiness probe |

## Cloud Run Deploy

```bash
# Build and deploy
gcloud builds submit --tag gcr.io/YOUR_PROJECT/mimz-backend
gcloud run deploy mimz-backend \
  --image gcr.io/YOUR_PROJECT/mimz-backend \
  --region us-central1 \
  --set-env-vars="GCP_PROJECT_ID=YOUR_PROJECT,GEMINI_AUTH_MODE=vertex,GEMINI_VERTEX_LOCATION=us-central1"
```

## Testing

```bash
npm test              # Run all tests
npm run test:watch    # Watch mode
```

## Required Setup

1. Create Firebase project with Auth + Firestore
2. Create `.env` from `.env.example`
3. Set `GEMINI_AUTH_MODE=vertex` (default in this repo)
4. (Optional) Set `GEMINI_API_KEY` only if using `GEMINI_AUTH_MODE=api_key`
5. `npm install && npm run dev`
