# Auth Deployment Notes

The Mimz Flutter application supports the following authentication methods:
1. **Email / Password**
2. **Google Sign-In**
3. **Apple Sign-In**

## Automated Setup Limitations
Because OAuth providers and iOS identity systems require console-level configurations that cannot be entirely automated via the `firebase` or `gcloud` CLI, the following manual steps MUST be completed in the Firebase Console:

### 1. Enable Providers
- Go to **Firebase Console > Authentication > Sign-in method**
- Enable **Email/Password**
- Enable **Google** (Configure the OAuth consent screen and Web client ID)
- Enable **Apple** (You will need to register a Service ID and upload a p8 key from your Apple Developer account)

### 2. Configure Android Fingerprints for Google Sign-In
- Go to **Firebase Console > Project Settings > General**
- Under your Android App (`com.mimz.mimz_app`), click **Add fingerprint**
- Add your release and debug SHA-1 / SHA-256 fingerprints to enable Google Sign-In to function properly on Android devices.

### 3. Provider Linking
- If you want users to seamlessly link their Google/Apple accounts to the same email address, ensure **Link accounts that use the same email** is enabled in the Authentication Settings tab in the Firebase Console.
