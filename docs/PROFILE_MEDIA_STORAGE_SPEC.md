# Profile Media Storage Specification

## Current State
Profile images are not built natively into the app. Avatar logic falls back to initials or demo URLs. Unmanaged URLs lead to broken links, security risks, or 404s.

## Required Architecture

1. **Frontend Capture**: 
   - Integrate `image_picker` (if not already present).
   - Allow user to pick from Gallery or Camera.
   - Compress the image locally to a max dimension (e.g., 512x512) and JPEG format to save bandwidth.

2. **Storage Pipeline**:
   - Utilize a standard cloud bucket (Firebase Storage or GCS).
   - Expected path convention: `user-profile-images/{userId}/avatar.jpg`.
   - On upload, a fresh token/URL is generated.

3. **Backend Metadata**:
   - The user record is updated via `PATCH /profile`.
   - Update `profileImageUrl` to the public or signed URL.
   - Store `profileImageStoragePath` to allow the backend to securely govern deleting the old image if replaced or the user deletes their account.
   - Store `profileImageUpdatedAt` integer timestamp to force cache breaking in the Flutter `NetworkImage` provider.

4. **Security Rules**:
   - Storage Rules: `match /user-profile-images/{uid}/{allPaths=**} { allow read: if true; allow write: if request.auth.uid == uid; }`
