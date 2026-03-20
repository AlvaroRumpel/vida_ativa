# External Integrations

**Analysis Date:** 2026-03-19

## APIs & External Services

**Google Firebase:**
- Firebase Authentication - User login and account management
  - SDK/Client: `firebase_auth` 6.2.0
  - Web Implementation: `firebase_auth_web` 6.1.3
  - Config: `lib/firebase_options.dart`

- Cloud Firestore - Real-time document database
  - SDK/Client: `cloud_firestore` 6.1.3
  - Web Implementation: `cloud_firestore_web` 5.1.3
  - Config: `lib/firebase_options.dart`

## Data Storage

**Databases:**
- Cloud Firestore (Google Firebase)
  - Connection: Configured via `lib/firebase_options.dart`
  - Project ID: `vida-ativa-94ba0`
  - Auth Domain: `vida-ativa-94ba0.firebaseapp.com`
  - Database Access: Real-time Firestore client
  - Storage Bucket: `vida-ativa-94ba0.firebasestorage.app`

**File Storage:**
- Firebase Cloud Storage
  - Bucket: `vida-ativa-94ba0.firebasestorage.app`
  - Access: Via Firebase SDK

**Caching:**
- Not detected - Flutter handles in-memory caching via framework

## Authentication & Identity

**Auth Provider:**
- Google Firebase Authentication
  - Implementation: `firebase_auth` package
  - Entry Point: `lib/main.dart` - Firebase initialized on app startup
  - Supported Methods: Email/password, social providers (configured via Firebase Console)
  - Config Location: `lib/firebase_options.dart` with API keys and auth domain

## Monitoring & Observability

**Error Tracking:**
- Not detected - No dedicated error tracking SDK integrated

**Logs:**
- Flutter console logging - Standard `flutter_test` and debug output
- Firebase Analytics (configured but not explicitly imported)
  - Measurement ID: `G-S0J20BFPXD`
  - Used for app usage metrics and crash reporting via Firebase

## CI/CD & Deployment

**Hosting:**
- Firebase Hosting (configured, ready for deployment)
  - Configuration: `firebase.json` present
  - Platform: Web target configured
  - Deploy via: `firebase deploy` CLI

**CI Pipeline:**
- Not detected - No CI/CD configuration found (GitHub Actions, GitLab CI, etc.)

## Environment Configuration

**Required env vars:**
- None explicitly required - Firebase config embedded in `lib/firebase_options.dart`

**Firebase Configuration Values (from firebase_options.dart):**
- `apiKey`: AIzaSyA-fBLM5XTSjQhBKCwIAnh793S7lKcNfUA
- `projectId`: vida-ativa-94ba0
- `appId`: 1:1020952880974:web:05faae57258c3914b8e01f
- `messagingSenderId`: 1020952880974
- `authDomain`: vida-ativa-94ba0.firebaseapp.com
- `storageBucket`: vida-ativa-94ba0.firebasestorage.app
- `measurementId`: G-S0J20BFPXD

**Secrets location:**
- Firebase keys embedded in `lib/firebase_options.dart` (web configuration)
- This is typical for client-side Firebase apps but should use security rules in Firebase Console

## Webhooks & Callbacks

**Incoming:**
- Not detected - No webhook receivers configured

**Outgoing:**
- Firebase Cloud Firestore triggers (available via Firebase Console)
- Firebase Authentication triggers (available via Firebase Console)

## Platform-Specific Firebase Configuration

**Web (Configured):**
- Full Firebase setup complete in `lib/firebase_options.dart`
- Ready for deployment

**iOS (Not Configured):**
- Will require GoogleService-Info.plist configuration
- Firebase options not yet set in code

**Android (Not Configured):**
- Will require google-services.json configuration
- Firebase options not yet set in code

**macOS, Windows, Linux (Not Configured):**
- Placeholder stubs in `lib/firebase_options.dart` throw UnsupportedError

---

*Integration audit: 2026-03-19*
