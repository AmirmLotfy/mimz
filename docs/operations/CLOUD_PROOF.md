# Cloud Deployment Proof — Mimz

How to prove Mimz uses Google Cloud for hackathon judging.

---

## What's Running on Google Cloud

| Service | What It Does | How to Prove |
|---------|-------------|-------------|
| **Cloud Run** | Hosts the Fastify backend (25+ endpoints) | Cloud Run console → show running service |
| **Firestore** | Persists users, districts, rewards, audit logs | Firestore console → show collections with real data |
| **Firebase Auth** | Manages user identity (Apple/Google/Email) | Firebase console → Authentication tab |
| **Gemini 2.5 Flash Native Audio** | Real-time voice + vision AI via WebSocket | Backend logs showing ephemeral token mints |

---

## Step-by-Step Cloud Proof

### 1. Deploy the Backend

```bash
# Set your project
export PROJECT_ID=your-project-id

# Build container image
gcloud builds submit --tag gcr.io/$PROJECT_ID/mimz-backend \
  --project=$PROJECT_ID

# Deploy to Cloud Run
gcloud run deploy mimz-backend \
  --image gcr.io/$PROJECT_ID/mimz-backend \
  --region us-central1 \
  --platform managed \
  --no-invoker-iam-check \
  --memory 512Mi \
  --set-env-vars="NODE_ENV=production,GCP_PROJECT_ID=$PROJECT_ID,GEMINI_API_KEY=YOUR_KEY"
```

### 2. Verify Deployment

```bash
# Get service URL
SERVICE_URL=$(gcloud run services describe mimz-backend \
  --region us-central1 --format='value(status.url)')

# Health check
curl $SERVICE_URL/healthz
# Expected: {"status":"ok","timestamp":"..."}

# Readiness check
curl $SERVICE_URL/readyz
# Expected: {"status":"ready","timestamp":"..."}
```

### 3. Show Cloud Run Console

**Navigate**: [console.cloud.google.com/run](https://console.cloud.google.com/run)

**What judges see**:
- Service name: `mimz-backend`
- Status: Active (green)
- Region: us-central1
- Last deployed: recent timestamp
- Revision: currently serving traffic

### 4. Show Firestore Collections

**Navigate**: [console.cloud.google.com/firestore](https://console.cloud.google.com/firestore)

**What judges see** (after running the app):
- `users` — player documents with XP, streak, interests
- `districts` — territory data with structures and resources
- `rewards` — reward grant audit trail
- `auditLogs` — tool execution log entries with correlation IDs

### 5. Show Firebase Auth

**Navigate**: [console.firebase.google.com](https://console.firebase.google.com) → Authentication

**What judges see**:
- Enabled providers: Apple, Google, Email
- User list with recent sign-ins

### 6. Show Backend Logs

**Navigate**: Cloud Run → Logs tab, or:

```bash
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=mimz-backend" \
  --limit=20 --format="table(timestamp,textPayload)"
```

**What judges see**:
- `Ephemeral token minted` — proves Gemini Live integration
- `Tool execution: grade_answer` — proves tool call pipeline
- `request completed` — proves API traffic

---

## What to Screen-Record for Submission

Capture a 30-second clip showing:

1. Cloud Run console with `mimz-backend` running (**5 seconds**)
2. `curl` hitting `$SERVICE_URL/healthz` and getting `{"status":"ok"}` (**5 seconds**)
3. Firestore console with user/district documents (**10 seconds**)
4. Backend logs showing `grade_answer` tool execution (**10 seconds**)

### Redaction Guide

Before recording, redact:
- `GEMINI_API_KEY` — never show this
- Billing account IDs
- Service account private keys
- Any personal email addresses in Firebase Auth

Safe to show:
- Project ID
- Service URLs
- Collection names and document shapes
- Log entries (tool names, timestamps)

---

## Cost Summary

| Service | Tier | Estimated Monthly Cost |
|---------|------|----------------------|
| Cloud Run | Free tier (2M requests/month) | $0 |
| Firestore | Free tier (1GB, 50K reads/day) | $0 |
| Firebase Auth | Free tier (50K MAU) | $0 |
| Gemini API | Pay-per-use | ~$5–20 for hackathon |
| Google Maps | $200/month credit | $0 |

**Total hackathon cost**: Under $20
