# Auth Deployment Notes — Mimz

## Providers Implemented

| Provider | Status |
|---|---|
| Email / Password | ✅ Implemented in app |
| Google Sign-In | ✅ Implemented + OAuth client IDs in firebase_options.dart |
| Anonymous / Guest | ❌ Blocked — not implemented, not allowed |
| Apple Sign-In | ❌ Not implemented |

## Auth Providers to Enable in Firebase Console

> These must be enabled in Firebase Console (not automatable via CLI in firebase-tools v14):  
> https://console.firebase.google.com/project/mimzapp/authentication/providers

1. **Email/Password** → Enable
2. **Google** → Enable (use the OAuth client IDs already in firebase_options.dart)

## OAuth Client IDs (already configured)

```
Android: 1012962167727-0p0dn1t5snr5m1r8sb6hcun9t5b6j24n.apps.googleusercontent.com
iOS:     1012962167727-lorb8qhom0cvhe5nnj22ealeajf5uv5a.apps.googleusercontent.com
```

## Android SHA-1 Fingerprint

**Debug key (for development/testing)**:
```
SHA-1:   69:96:33:63:27:1D:EB:88:1C:1F:8D:5F:7C:8C:90:1E:DB:B5:C8:31
SHA-256: 59:57:9E:2C:D9:9A:BC:8D:41:F5:D3:E5:6F:4F:0B:E7:6A:24:0A:39:FE:7E:8F:B6:99:D8:60:8D:22:88:EF:99
```

**How to add SHA-1 to Firebase** (for Google Sign-In on Android):
1. Go to https://console.firebase.google.com/project/mimzapp/settings/general
2. Scroll to "Your apps" → Android app `com.mimz.mimz_app`
3. Click "Add fingerprint"
4. Paste the SHA-1 above

> For production, repeat with the release keystore SHA-1.

## iOS Google Sign-In
iOS Google Sign-In requires `GoogleService-Info.plist` (already downloaded) + URL scheme in Xcode.

**Remaining manual step for iOS:**
1. Open `app/ios/Runner.xcworkspace` in Xcode
2. Select Runner target → Info → URL Types
3. Add a URL Type with:
   - Identifier: your bundle ID (`com.mimz.mimzApp`)
   - URL Schemes: `1012962167727-lorb8qhom0cvhe5nnj22ealeajf5uv5a` (the reversed iOS client ID)

## Security Notes
- Firebase Security Rules are deployed (users can only write their own data)
- No anonymous or guest auth is configured
- Auth tokens are validated server-side on all Firebase Firestore reads
