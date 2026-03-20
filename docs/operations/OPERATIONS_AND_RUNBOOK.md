# Operations And Runbook

## Runtime Endpoints

- Health: `/health`
- Ready: `/readyz`

## Daily Verification

```bash
./scripts/validate_deployment.sh
```

## Deploy Verification

1. Confirm Cloud Run service URL and env vars:
```bash
gcloud run services describe mimz-backend --region=europe-west1
```
2. Confirm health/ready return 200.
3. Run device smoke:
   - sign in
   - open world/district
   - start live session
   - claim rewards
   - profile/settings update

## Incident Playbooks

### Auth/Bootstrap failures spike
- Check backend auth logs (`AUTH_HEADER_MISSING`, `AUTH_TOKEN_INVALID`)
- Confirm Cloud Run policy and Firebase project alignment
- Validate app backend URL and token freshness path

### District load failures
- Check `/district` endpoint status and payload shape
- Verify bootstrap created district records
- Confirm client receives wrapped `district` payload

### Live failures
- Check `/live/ephemeral-token` error rates
- Validate model/env config and token mint path
- Confirm tool-execute session ownership and idempotency paths

## Rollback Criteria

- sustained auth/bootstrap failure
- sustained live session startup failure
- reward mutation errors causing progression inconsistency

Rollback action:
- shift traffic to last known good revision in Cloud Run
- notify support/QA and run smoke checklist on rollback revision
