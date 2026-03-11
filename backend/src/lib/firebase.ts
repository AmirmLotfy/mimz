import { initializeApp, cert, getApps, App } from 'firebase-admin/app';
import { getFirestore, Firestore } from 'firebase-admin/firestore';
import { getAuth, Auth } from 'firebase-admin/auth';
import { config } from '../config/index.js';

let app: App;
let db: Firestore;
let auth: Auth;

/**
 * Initialize Firebase Admin SDK.
 * Uses Application Default Credentials on Cloud Run.
 * Uses GOOGLE_APPLICATION_CREDENTIALS or emulators locally.
 */
export function initFirebase(): { db: Firestore; auth: Auth } {
  if (getApps().length === 0) {
    app = initializeApp({
      projectId: config.gcpProjectId,
    });
  } else {
    app = getApps()[0];
  }

  db = getFirestore(app);
  auth = getAuth(app);

  // Use Firestore emulator if configured
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    console.log(`🔧 Using Firestore emulator: ${process.env.FIRESTORE_EMULATOR_HOST}`);
  }

  return { db, auth };
}

export function getDb(): Firestore {
  if (!db) throw new Error('Firebase not initialized — call initFirebase() first');
  return db;
}

export function getFirebaseAuth(): Auth {
  if (!auth) throw new Error('Firebase not initialized — call initFirebase() first');
  return auth;
}
