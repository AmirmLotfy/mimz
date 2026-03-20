# Connectivity and Offline Audit

## Findings
1. **Connectivity State Missing**: The app lacks a unified connectivity awareness. If a user loses internet, HTTP calls simply throw `DioException`s in providers, leading to individual localized errors or silent failures.
2. **Offline vs. Backend Unavailable**: The app does not distinguish between a lack of device internet and the Cloud Run backend being down. Both just result in network errors.
3. **Global Awareness**: There is no global offline banner. A user could sit on a cached screen and not realize their actions are failing silently.

## Action Plan
- **ConnectivityService**: Build a service that monitors `InternetAddress.lookup` or a simple socket ping, AND regularly hits `[backend/src/routes/health.ts](backend/src/routes/health.ts)` to differentiate:
  1. `Online`
  2. `NoInternet`
  3. `BackendUnavailable`
- **Global Banner**: Inject a reactive banner into `AppLifecycleObserver` or `AppShell` that drops down when the state is not `Online`.
- **Interceptors**: Update `ApiClient` or providers to respect this state and prevent unnecessary requests when clearly offline.
