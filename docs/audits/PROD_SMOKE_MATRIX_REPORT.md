# Production Smoke Matrix Report

**Date:** 2026-03-18  
**Environment:** Production (`mimzapp`)  
**Device:** SM_A205F (`R58M436LAHA`)

## Build/Install
- Release APK built successfully (`app/build/app/outputs/flutter-apk/app-release.apk`).
- Installed successfully on device via `adb install -r`.
- Backend fixes deployed to Cloud Run revision `mimz-backend-00007-4w8` before final smoke capture.
- Live reliability hardening now includes:
  - dedicated live region config (`GEMINI_LIVE_VERTEX_LOCATION`)
  - clean session retry/reset controls in live quiz UI
  - backend session-id propagation for tool-execution authorization

## Scenario Matrix

| Scenario | Method | Evidence file | Result |
|---|---|---|---|
| Cold start (authenticated path) | clear logcat → force-stop → launch → capture | `app/device_e2e_logs/scenario1_cold_start.log` | App launches, but production backend previously observed bootstrap 400/401 in Cloud Run logs |
| Offline bootstrap failure simulation | disable wifi/data → launch → capture → re-enable | `app/device_e2e_logs/scenario2_offline_bootstrap.log` | Offline behavior reproducible; bootstrap/auth dependent calls fail as expected |
| Transient network flap | launch → disable network 5s → enable → capture | `app/device_e2e_logs/scenario3_network_flap.log` | Network flap reproduced; release logcat has limited app-level detail |

## Correlated backend evidence (Cloud Run logs)

Queried `mimz-backend` request logs:
- `/auth/bootstrap` had repeated **401** responses and at least one **400** response for user `GVDSOlG8fbaQbu2fmbmTcrmQV193`.
- `/live/ephemeral-token` had repeated **401** responses in the same period, with occasional **200** once auth context was valid.

This confirms the primary production instability chain:
1. auth token/header invalid/missing intermittently →
2. bootstrap returns 401/400 →
3. live token endpoint returns 401 →
4. app surfaces **Connection Lost / Retry Session**.

## Primary root cause (current evidence)
- Production failures are currently dominated by auth/bootstrap precondition failures rather than websocket-only transport faults.
- Live reliability improvements help classification/recovery, but stable auth/bootstrap is mandatory to eliminate the user-facing retry loop.

## Immediate pass/fail gates
- **Gate A:** `/auth/bootstrap` success rate from real device > 99% over repeated cold starts.
- **Gate B:** `/live/ephemeral-token` returns 200 when authenticated; zero 401s for valid sessions.
- **Gate C:** On forced invalid auth, app fails fast with explicit message (no reconnect loop).
- **Gate D:** live websocket setup completes (or fails fatally) within handshake timeout, with retry/reset/back-to-world actions.

