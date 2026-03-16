# Runbook — Mimz

## Redeploy Backend to Cloud Run
```bash
./scripts/deploy_backend.sh
```
Or manually:
```bash
gcloud run deploy mimz-backend \
  --source ./backend \
  --project=mimzapp \
  --region=europe-west1 \
  --allow-unauthenticated \
  --set-secrets="GEMINI_API_KEY=GEMINI_API_KEY:latest" \
  --quiet
```

## Rerun FlutterFire Config (after Firebase changes)
```bash
./scripts/configure_flutterfire.sh
```
This regenerates `firebase_options.dart`, `google-services.json`, and `GoogleService-Info.plist`.

## Reapply Firebase Rules + Indexes
```bash
./scripts/apply_firebase_rules.sh
```
Or manually:
```bash
firebase deploy --only firestore:rules,storage --project=mimzapp
firebase deploy --only firestore:indexes --project=mimzapp  # if indexes file exists
```

## Update GEMINI_API_KEY Secret
```bash
echo -n "NEW_KEY_HERE" | gcloud secrets versions add GEMINI_API_KEY \
  --project=mimzapp --data-file=-
```
Then redeploy backend so Cloud Run picks up the new version.

## Update Cloud Run Env Vars
```bash
gcloud run services update mimz-backend \
  --project=mimzapp \
  --region=europe-west1 \
  --set-env-vars="KEY=VALUE"
```

## Check Backend Health
```bash
curl https://mimz-backend-[hash]-ew.a.run.app/readyz
```

## View Live Backend Logs
```bash
gcloud logging read \
  "resource.type=cloud_run_revision AND resource.labels.service_name=mimz-backend" \
  --project=mimzapp \
  --limit=50 \
  --format="value(textPayload)"
```

## Run Full Redeploy (all steps)
```bash
./scripts/deploy_all.sh
```

## Enable APIs (if new project)
```bash
gcloud services enable \
  firebase.googleapis.com firestore.googleapis.com run.googleapis.com \
  artifactregistry.googleapis.com cloudbuild.googleapis.com \
  secretmanager.googleapis.com generativelanguage.googleapis.com \
  identitytoolkit.googleapis.com storage-component.googleapis.com \
  --project=mimzapp
```
