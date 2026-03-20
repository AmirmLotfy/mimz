# Backend Production Checklist

## Auth/Security

- [x] Firebase ID token verification enforced
- [x] No implicit non-prod auth bypass in production
- [x] live tool execution validates session ownership
- [x] request payload validation on critical endpoints

## Reliability

- [x] health and ready endpoints operational
- [x] structured request logging enabled
- [x] live tool idempotency extended for reward-affecting tools
- [ ] live session storage resilient across restarts (currently in-memory)

## Data Integrity

- [x] event/squad join logic idempotent for participant/member counts
- [x] mission contribution missing mission returns controlled error
- [ ] unify reward mutation API into single transactional endpoint where needed

## Configuration

- [x] production env vars set on Cloud Run
- [x] model role registry defaults updated
- [ ] ensure service URL source-of-truth sync across scripts/docs/app defaults

## Operations

- [ ] alerting thresholds for auth/bootstrap/live failures
- [ ] log dashboards for critical endpoints
- [ ] rollback playbook rehearsed
