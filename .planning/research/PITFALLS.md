# Domain Pitfalls

**Domain:** Flutter Web PWA + Firebase — Court Booking / Scheduling App
**Researched:** 2026-03-19
**Confidence note:** Web/WebFetch tools unavailable this session. All findings draw on training knowledge (cutoff August 2025) of Flutter Web, FlutterFire, and Firebase. Confidence levels reflect that source limit.

---

## Critical Pitfalls

Mistakes that cause rewrites, data integrity failures, or security holes.

---

### Pitfall 1: Firestore Double Booking (Race Condition on Slot Reservation)

**What goes wrong:** Two users simultaneously tap "Book" on the same available slot. Both read the booking document as `status: available`, both pass the client-side availability check, and both write a booking — resulting in two confirmed bookings for the same slot/date.

**Why it happens:** Firestore reads and writes are not atomic by default. A client-side check (`if slot is available, then create booking`) is a non-atomic read-modify-write. Any concurrent request that reads between your read and your write will see the same "available" state.

**Consequences:** Two clients own the same court hour. Admin discovers the conflict at check-in. Trust in the system collapses; the app gets abandoned in favor of WhatsApp again.

**Prevention:**
Use a Firestore Transaction (or a Cloud Function as a transactional gate) to enforce single-writer semantics:

```dart
// Correct approach — transaction-based booking
await FirebaseFirestore.instance.runTransaction((transaction) async {
  final bookingRef = FirebaseFirestore.instance
      .collection('bookings')
      .doc('${slotId}_${dateString}');

  final snapshot = await transaction.get(bookingRef);

  if (snapshot.exists && snapshot.data()?['status'] != 'available') {
    throw Exception('slot_taken');
  }

  transaction.set(bookingRef, {
    'slotId': slotId,
    'date': dateString,
    'userId': currentUserId,
    'status': 'pending', // or 'confirmed' if auto-confirm
    'createdAt': FieldValue.serverTimestamp(),
  });
});
```

The document ID `${slotId}_${dateString}` serves as the natural uniqueness key. The transaction retries automatically on contention and throws if the document was written between read and write.

**Alternative (simpler for small scale):** Use a Cloud Function triggered by an HTTP call instead of direct Firestore writes. The function reads and writes atomically server-side, and returns a typed error on conflict.

**Detection (warning signs):**
- Client does an `if (available) { write }` pattern without a transaction
- Booking status is computed on client before the write
- No uniqueness constraint on `slotId + date` document ID

**Phase to address:** Booking feature implementation phase (Phase 2/3 of roadmap). Do not ship booking writes without this. Confidence: HIGH (core Firestore behavior, well-documented).

---

### Pitfall 2: Firestore Security Rules Left Open or Overly Permissive

**What goes wrong:** Default Firestore rules in test mode allow all reads/writes to anyone. Deploying to production with `allow read, write: if true` means any person with the Firebase project config (which is in your compiled JS bundle) can read all bookings, impersonate users, delete data, or spam the database.

**Why it happens:** FlutterFire `flutterfire configure` creates `firebase_options.dart` with the API key visible in the bundle. Firebase API keys are not secret — they identify the project. Security must come entirely from Firestore rules. This is already flagged in CONCERNS.md but the risk is higher than stated: **rules are your only server-side enforcement layer.**

**Consequences:** PII leak (phone numbers, user profiles), data corruption, runaway Firestore read/write costs from abuse.

**Prevention:**
Write rules that:
1. Enforce authentication for all writes
2. Scope reads to the authenticated user's own data OR admin role
3. Validate fields server-side (type, length, no extra fields)
4. Use a custom claim or a `/users/{uid}` role field to gate admin operations

Example skeleton:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    function isAdmin() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
      allow read: if isAdmin();
    }

    match /bookings/{bookingId} {
      allow read: if request.auth != null &&
        (resource.data.userId == request.auth.uid || isAdmin());
      allow create: if request.auth != null; // further validated in transaction/CF
      allow update, delete: if isAdmin() ||
        (resource.data.userId == request.auth.uid && resource.data.status == 'pending');
    }

    match /slots/{slotId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }

    match /blockedDates/{dateId} {
      allow read: if request.auth != null;
      allow write: if isAdmin();
    }
  }
}
```

**Detection:**
- `firebase.rules` file contains `allow read, write: if true`
- Rules not version-controlled (no `firestore.rules` file in repo)
- No `isAdmin()` helper enforced on admin-only collections

**Phase to address:** Before any feature that writes user data goes to a deployed environment. Confidence: HIGH.

---

### Pitfall 3: Phone Auth on Flutter Web — reCAPTCHA and Domain Whitelist Failures

**What goes wrong:** `signInWithPhoneNumber()` on Flutter Web requires an invisible or visible reCAPTCHA challenge rendered in the browser. This fails or behaves unexpectedly in several scenarios:
- The app domain is not whitelisted in Firebase Console → Auth silently fails or throws `auth/unauthorized-domain`
- `localhost` works during dev but the deployed domain is not added → breaks immediately after first deploy
- The `RecaptchaVerifier` widget is attached to a DOM element that Flutter Web's canvas renderer doesn't expose cleanly → `recaptcha-container` div is never rendered
- Ad blockers and privacy browsers (Firefox strict mode, Brave) block reCAPTCHA scripts → user gets stuck with no feedback

**Why it happens:** Flutter Web renders via HTML Canvas or HTML renderer. The `firebase_auth` web plugin injects a standard JS reCAPTCHA, but if the Flutter widget tree doesn't expose a real DOM element with the right ID, the verifier can't mount.

**Consequences:** Phone Auth appears to work in dev, breaks on first user trial in production. Debugging is hard because the error is in the JS layer, not in Dart.

**Prevention:**
1. Add all deployment domains to Firebase Console → Authentication → Settings → Authorized domains (including custom domains, not just `*.web.app`)
2. Use the invisible reCAPTCHA approach: `RecaptchaVerifier(auth, 'recaptcha-container', {'size': 'invisible'})` and ensure the container element actually exists in the DOM — use `HtmlElementView` if needed
3. Test Phone Auth explicitly in a deployed preview environment before declaring it done, not just on localhost
4. Have a fallback UX message when reCAPTCHA fails (ad blocker detected)
5. Consider making Google Sign-In the primary auth method and treating Phone Auth as secondary, since Google Sign-In has fewer web-specific failure modes

**Detection:**
- `auth/unauthorized-domain` error in browser console
- reCAPTCHA spinner never resolves
- Works on localhost, fails on `*.web.app` domain

**Phase to address:** Auth implementation phase. Test on deployed URL, not only locally. Confidence: HIGH (documented Flutter Web + Firebase Auth known issue).

---

### Pitfall 4: PWA Service Worker Caches Stale App Shell After Deployment

**What goes wrong:** Flutter Web generates a service worker (`flutter_service_worker.js`) that aggressively caches the app shell. After deploying an update, users with the PWA installed continue running the old version indefinitely — they never see the update. This is especially painful if a critical bug fix or data model change is deployed.

**Why it happens:** The Flutter Web service worker uses a cache-first strategy. The browser only checks for updates when the service worker script itself changes — but if the user already has the old worker active, the update check may be deferred until the tab is closed and reopened. Many mobile PWA users never close tabs.

**Consequences:** User books a slot with old UI behavior while backend data model has changed. Booking failures, confusing errors. Admin sees data that clients can't see.

**Prevention:**
1. In `web/index.html`, configure the service worker registration to use `serviceWorkerVersion` and check for updates on page focus:
```javascript
// Force reload when new service worker is available
navigator.serviceWorker.addEventListener('controllerchange', () => {
  window.location.reload();
});
```
2. Add an in-app "update available" banner that prompts the user to refresh
3. Use Firebase Hosting's cache headers on `flutter_service_worker.js` with `Cache-Control: no-cache` so the worker file is always re-fetched
4. Test the update flow explicitly: deploy v1, install PWA, deploy v2, verify v2 loads
5. Keep the data model backwards-compatible during the transition window when users may be on different app versions

**Detection:**
- Users reporting "it worked yesterday but not today" after a deploy
- Browser DevTools → Application → Service Workers shows old version still active
- `flutter_service_worker.js` served with long cache TTL from Firebase Hosting

**Phase to address:** First deployment phase and any phase that changes the data model. Confidence: HIGH (well-known Flutter Web PWA issue).

---

### Pitfall 5: Firestore Offline Behavior Creates Ghost Bookings

**What goes wrong:** Firestore SDK has built-in offline persistence enabled by default on web (in newer SDK versions) and always on mobile. When a user creates a booking while offline, the write is queued locally and the UI shows "success." When connectivity returns, the write is flushed — but if the slot was taken by someone else in the meantime, the booking write may conflict with existing data. The user already saw "booking confirmed."

**Why it happens:** Offline persistence optimistically reflects writes locally. The conflict is only detected server-side when the offline queue flushes. Without proper error handling on the write promise, the user never learns the booking failed.

**Consequences:** User shows up for a slot that was taken by someone else. Both users believe they have a valid booking.

**Prevention:**
1. For the booking creation flow specifically, disable offline persistence or use `serverTimestamp` + transaction to detect conflicts
2. After a booking write, listen to the booking document's `status` field with a real-time listener — if status reverts or the doc disappears, show an error
3. Show a "confirming..." state after the write, not "confirmed", until the server round-trip completes
4. For web specifically, consider disabling offline persistence for the booking collection since false-positive confirmations are worse than write failures:
```dart
// Disable persistence for web to avoid stale booking state
if (kIsWeb) {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: false,
  );
}
```
5. Always handle the transaction Future's error case and display it to the user

**Detection:**
- Booking write does not await the result or ignores the Future
- UI transitions to "confirmed" state before server acknowledgment
- No error handling on `runTransaction()` or `set()` calls

**Phase to address:** Booking implementation phase. Confidence: MEDIUM (offline behavior is documented; specific interaction with booking transactions requires careful testing).

---

## Moderate Pitfalls

---

### Pitfall 6: Admin Role Enforcement Only on Client Side

**What goes wrong:** Admin screens are hidden from the UI for non-admin users, but the Firestore writes for admin actions (create slot, block date, confirm booking) are not gated server-side. Any user who discovers the API can call those writes directly.

**Prevention:**
- Never use UI visibility as a security boundary
- All admin writes must be gated by the `isAdmin()` rule in Firestore security rules (see Pitfall 2)
- Consider using a Cloud Function for sensitive admin operations so business logic runs server-side

**Phase to address:** Admin feature phase. Confidence: HIGH.

---

### Pitfall 7: Recurring Slot Generation — Unbounded Document Creation

**What goes wrong:** If recurring slots are expanded eagerly (creating one booking-slot document per occurrence per day for the next year), you quickly accumulate thousands of documents. Querying "this week's available slots" becomes expensive and slow.

**Why it happens:** Simple implementation: "create weekly slots" → loop over next 52 weeks → write 52 documents per slot type.

**Prevention:**
- Store slots as recurring rules (`dayOfWeek`, `time`, `price`) in `/slots` — do NOT pre-expand them
- Generate the actual available dates dynamically in the client query or a Cloud Function: query `/slots` for recurring config, then check `/bookings` and `/blockedDates` to determine availability
- This is already the data model described in PROJECT.md (slots = recurring config, bookings = instances) — do not deviate from this

**Detection:**
- Code that loops `DateTime.now()` + 7 days for N weeks and creates documents
- `/slots` collection growing unboundedly

**Phase to address:** Schedule display and admin slot management phases. Confidence: HIGH.

---

### Pitfall 8: Flutter Web Canvas Renderer — Touch Event and Input Field Issues

**What goes wrong:** Flutter Web defaults to the CanvasKit renderer, which renders everything in a `<canvas>` element. This causes:
- Native browser autofill does not work on form fields (phone number, name)
- Some virtual keyboards on mobile browsers behave incorrectly
- Pinch-to-zoom and long-press context menus are intercepted by Flutter
- Copy-paste from password managers fails for phone number inputs

**Why it happens:** CanvasKit renders Flutter's own text fields, not HTML `<input>` elements, so the browser cannot apply autofill heuristics.

**Prevention:**
- Use the HTML renderer for web (`flutter build web --web-renderer html`) or the auto renderer which falls back to HTML on mobile
- Alternatively, accept the limitation and ensure phone number input has a clear numeric keyboard hint and a format hint label
- Test all auth flows on actual mobile browsers (Chrome Android, Safari iOS) before considering a phase done

**Detection:**
- Phone number field does not trigger numeric keypad on mobile
- Browser autofill popup never appears
- Users complain they can't paste their phone number

**Phase to address:** Auth UI phase. Confidence: MEDIUM (renderer behavior changes between Flutter versions; verify with current Flutter Web release).

---

### Pitfall 9: Firebase Hosting Cache — API Responses Served Stale

**What goes wrong:** Firebase Hosting serves static files with aggressive CDN caching. If you accidentally configure it to cache dynamic content (e.g., a Cloud Function URL proxied through Hosting), you get stale responses served to all users globally until the CDN edge cache expires.

**Prevention:**
- Separate static assets (Flutter app bundle) from dynamic endpoints in `firebase.json` rewrites
- Always set `Cache-Control: no-cache` on any rewrite that proxies to Cloud Functions
- Test booking availability display after making a change to the database — if it shows stale data, check Hosting cache headers

**Detection:**
- Data displayed in the app doesn't reflect recent Firestore writes
- `curl -I` on the app URL shows `Cache-Control: max-age=3600` on dynamic routes

**Phase to address:** Deployment / Firebase Hosting configuration phase. Confidence: MEDIUM.

---

### Pitfall 10: Missing Loading and Error States on Firestore Streams

**What goes wrong:** `StreamBuilder` widgets that listen to Firestore collections show a blank or broken UI during the initial load or when the stream errors. Users see an empty schedule and assume there are no slots, then book via WhatsApp anyway — defeating the app's purpose.

**Prevention:**
- Every `StreamBuilder` must handle `ConnectionState.waiting`, `ConnectionState.active` with no data, and `snapshot.hasError` explicitly
- Use a skeleton loader or shimmer during initial load
- For the schedule view (most critical screen), prioritize a clear "loading" → "available" → "empty" → "error" state machine

**Phase to address:** Schedule display phase. Confidence: HIGH.

---

## Minor Pitfalls

---

### Pitfall 11: Firestore Timestamps — Client Clock Skew

**What goes wrong:** Using `DateTime.now()` for `createdAt` fields stores the client device's time, which may be wrong. Time-ordered queries return incorrect results.

**Prevention:** Always use `FieldValue.serverTimestamp()` for any timestamp that will be used in ordering or business logic. Confidence: HIGH.

---

### Pitfall 12: PWA Install Prompt — iOS Safari Limitations

**What goes wrong:** iOS Safari does not support the `beforeinstallprompt` event. The standard "Add to Home Screen" PWA install prompt does not appear on iOS. Users must manually use the Share menu.

**Prevention:**
- On iOS, show a custom in-app banner explaining how to install ("Tap Share → Add to Home Screen")
- Use `navigator.standalone` detection to know if the app is already installed and hide the banner
- Do not block functionality behind PWA installation

**Phase to address:** PWA installation / onboarding phase. Confidence: HIGH.

---

### Pitfall 13: Firestore Security Rules `get()` Calls Add Read Costs

**What goes wrong:** The `isAdmin()` helper using `get()` in rules executes a Firestore read for every security evaluation. On a busy app, admin role checks on list queries trigger many additional reads.

**Prevention:**
- For v1 scale (small academy, low traffic), this is acceptable
- If costs become a concern: use Firebase Auth custom claims for the admin role instead of a Firestore document lookup — custom claims are available in rules as `request.auth.token.admin`

**Phase to address:** Auth / admin phase. Low priority for v1. Confidence: HIGH.

---

### Pitfall 14: `go_router` (or any router) Losing State on PWA Hard Reload

**What goes wrong:** If the user navigates to `/booking/slotId` and refreshes the page (or the PWA relaunches), Flutter Web needs to handle the deep-link URL. Without proper `go_router` path configuration and a Firebase Hosting rewrite rule for SPAs, the hard reload returns a 404.

**Prevention:**
- Add a catch-all rewrite in `firebase.json`:
```json
{
  "hosting": {
    "rewrites": [{"source": "**", "destination": "/index.html"}]
  }
}
```
- Configure `go_router` with named routes and ensure all deep-linkable paths are handled

**Phase to address:** Routing / navigation phase (early). Confidence: HIGH.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|-------------|---------------|------------|
| Auth implementation | Phone Auth reCAPTCHA fails on deployed domain | Add all domains to Firebase Console before testing; test on deployed URL |
| Auth implementation | Canvas renderer blocks autofill/keyboard | Switch to HTML renderer for web builds |
| Booking write flow | Double booking race condition | Firestore Transaction with deterministic document ID as uniqueness key |
| Booking write flow | Ghost bookings from offline queue | Disable web persistence for booking collection; listen to booking status post-write |
| Schedule display | Empty UI during stream load | Handle all ConnectionState cases in StreamBuilder |
| Admin features | Admin writes unprotected server-side | Enforce `isAdmin()` in Firestore security rules before shipping admin UI |
| Slot management | Eager slot expansion creates thousands of documents | Keep slots as recurring rules; expand dynamically in queries |
| First deployment | PWA caches old app shell after updates | Configure service worker update strategy; test the update flow explicitly |
| Deployment config | SPA hard reload returns 404 | Add catch-all `**` → `index.html` rewrite in `firebase.json` |
| Firestore rules | Rules never version-controlled or deployed | Commit `firestore.rules` to repo; deploy with `firebase deploy --only firestore:rules` |

---

## Sources

- Training knowledge: Flutter Web documentation (flutter.dev), FlutterFire documentation (firebase.flutter.dev), Firebase documentation (firebase.google.com) — knowledge cutoff August 2025
- Project context: `f:/_geral/Projetos/vida_ativa/.planning/PROJECT.md`
- Existing concerns: `f:/_geral/Projetos/vida_ativa/.planning/codebase/CONCERNS.md`
- Confidence: HIGH for Firestore transaction behavior, security rules enforcement, Phone Auth domain requirements, and PWA service worker caching (all stable, well-documented behaviors). MEDIUM for Flutter renderer-specific input behavior (changes between Flutter versions) and Firestore offline/transaction interaction (requires project-specific testing to confirm).
- Note: External search tools unavailable this session. Recommend verifying Phone Auth reCAPTCHA behavior against current FlutterFire changelog before the auth implementation phase.
