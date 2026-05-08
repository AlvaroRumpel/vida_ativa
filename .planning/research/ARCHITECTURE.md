# Architecture Patterns

**Domain:** Flutter Web PWA — court booking / scheduling app
**Researched:** 2026-03-19
**Confidence:** HIGH (Flutter/Riverpod/Firestore patterns are mature and well-documented; training cutoff August 2025)

---

## Recommended Architecture

**Pattern: Feature-First with Clean Layering inside each feature**

The project already names this direction in `PROJECT.md`: `lib/features/{auth,schedule,booking,admin}` + `lib/core/{models,services}`. This is the right call. Feature-first (also called "vertical slice") groups all code for a feature together rather than grouping by layer across the whole app. It scales better than a flat layer-first approach because each feature can be developed and tested independently, and Firestore query logic stays close to the UI that needs it.

```
lib/
├── core/
│   ├── models/          # Immutable data classes (Slot, Booking, AppUser, BlockedDate)
│   ├── services/        # Firebase wrappers (AuthService, SlotService, BookingService)
│   ├── utils/           # Date helpers, validators, constants
│   └── router/          # GoRouter configuration and route guards
├── features/
│   ├── auth/
│   │   ├── data/        # auth_repository.dart (wraps AuthService)
│   │   ├── providers/   # auth_provider.dart (Riverpod)
│   │   └── ui/          # login_screen.dart, phone_input_screen.dart
│   ├── schedule/
│   │   ├── data/        # schedule_repository.dart
│   │   ├── providers/   # slots_provider.dart, week_provider.dart
│   │   └── ui/          # schedule_screen.dart, slot_card.dart
│   ├── booking/
│   │   ├── data/        # booking_repository.dart
│   │   ├── providers/   # booking_provider.dart
│   │   └── ui/          # booking_confirm_screen.dart, my_bookings_screen.dart
│   └── admin/
│       ├── data/        # admin_repository.dart
│       ├── providers/   # admin_provider.dart
│       └── ui/          # admin_dashboard.dart, slot_editor.dart, booking_list.dart
└── main.dart
```

---

## Component Boundaries

| Component | Responsibility | Communicates With |
|-----------|---------------|-------------------|
| `core/models/` | Immutable data classes with `fromFirestore` / `toFirestore` factory methods | All layers (read-only) |
| `core/services/` | Direct Firestore/Auth SDK calls, returns raw Dart types or Streams | Repositories only |
| `feature/*/data/` (repositories) | Translates service calls into domain objects; encapsulates query logic | Services (down), Providers (up) |
| `feature/*/providers/` | Riverpod providers that expose state to UI; orchestrate repositories | Repositories (down), UI (up) |
| `feature/*/ui/` | Flutter widgets; read providers, dispatch actions, render state | Providers (read/write) |
| `core/router/` | GoRouter + `redirect` guards that read auth state; only entry point for navigation | Auth provider (read) |

**Boundary rules:**
- UI widgets never call Firestore directly — always through a provider
- Providers never import Firebase packages — only repository interfaces
- Models never import Flutter widgets
- The `admin` feature boundary is enforced at the router level (redirect if not admin)

---

## Data Flow

### Unidirectional Flow

```
Firestore ──Stream──► Service ──Stream──► Repository ──Stream──► Provider ──watch──► Widget
                                                                       │
                                                                    write ◄── Widget (user action)
                                                                       │
                                                              Repository.create/update/delete
                                                                       │
                                                               Service.set/add/delete
                                                                       │
                                                                  Firestore write
```

### Real-Time vs One-Time Reads

| Data | Strategy | Rationale |
|------|----------|-----------|
| Slot availability (schedule screen) | `snapshots()` stream | Multiple users may book simultaneously; stale data causes double-booking UI |
| Current user's bookings | `snapshots()` stream | Admin confirmation changes status — user must see it update live |
| Admin booking list | `snapshots()` stream | New bookings arrive while admin is viewing the list |
| Blocked dates | `get()` one-time read | Changes rarely; re-fetch on screen entry or admin save |
| Slot definitions (recurring config) | `get()` one-time read | Set by admin, not time-critical |
| User profile (`/users/{uid}`) | `snapshots()` stream | Role field determines what UI is shown |

**Rule of thumb:** If two users acting concurrently on the same data would cause problems for one of them, use a stream. Static configuration uses one-time reads.

### Firestore Collections

```
/users/{uid}
  - uid: string
  - displayName: string
  - phoneNumber: string?
  - role: "client" | "admin"
  - createdAt: timestamp

/slots/{slotId}
  - dayOfWeek: 1-7
  - startTime: string  ("08:00")
  - durationMinutes: int
  - price: number
  - confirmationMode: "auto" | "manual"
  - isActive: bool

/bookings/{bookingId}
  - slotId: string
  - userId: string
  - date: string  ("2026-03-24")  ← ISO date, not timestamp (avoids TZ bugs)
  - status: "pending" | "confirmed" | "cancelled"
  - createdAt: timestamp

/blockedDates/{dateStr}
  - date: string   ("2026-03-25")
  - reason: string?
```

**Composite query needed:** Schedule screen queries `bookings` where `date == selectedDate` AND `status != "cancelled"`. Firestore requires a composite index for `(date ASC, status ASC)`. Create this index before the schedule screen is built.

---

## State Management Approach

**Use Riverpod (riverpod + flutter_riverpod + riverpod_annotation + riverpod_generator)**

Riverpod is the correct choice for this project because:
1. It integrates cleanly with `StreamProvider` to expose Firestore streams to widgets
2. `AsyncValue<T>` handles loading/error/data states without boilerplate
3. Providers can depend on other providers (e.g., booking provider depends on auth provider for `userId`)
4. No `BuildContext` required for provider access — important for router guards

### Provider Shape for Core Flows

```dart
// Auth — single source of truth for current user
@riverpod
Stream<AppUser?> currentUser(CurrentUserRef ref) =>
    ref.watch(authRepositoryProvider).watchCurrentUser();

// Schedule screen — slots for a given week filtered by blocked dates
@riverpod
Future<List<SlotViewModel>> weekSlots(WeekSlotsRef ref, DateTime weekStart) async { ... }

// Booking mutation — notifier handles pending state during write
@riverpod
class BookingNotifier extends _$BookingNotifier {
  Future<void> createBooking(String slotId, DateTime date) async { ... }
}
```

### Booking Flow State Machine

```
idle
  └─ user taps slot ──► confirming (show confirmation sheet)
       ├─ user cancels ──► idle
       └─ user confirms ──► submitting
             ├─ success ──► idle (stream update shows booking in list)
             └─ failure ──► error (show snackbar, return to confirming)
```

The `BookingNotifier` manages this state. The schedule screen watches the `weekSlots` stream — once a booking is created in Firestore, the stream emits a new snapshot automatically, so the slot card updates to "booked" without any manual refresh.

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Writing to Firestore Directly from Widgets
**What:** Widget calls `FirebaseFirestore.instance.collection('bookings').add(...)` directly.
**Why bad:** Untestable, skips validation, bypasses the repository layer, security rules become the only guard against bad data.
**Instead:** Widget calls `ref.read(bookingNotifierProvider.notifier).createBooking(slotId, date)`.

### Anti-Pattern 2: One-Time Read for the Schedule Screen
**What:** Using `.get()` instead of `.snapshots()` for the slot availability display.
**Why bad:** Two users see the same slot as available; both book it; one gets a confirmed booking for a full slot. Double-booking is the core problem this app solves.
**Instead:** Always stream slot+booking data on the schedule screen. Use a Firestore transaction or Cloud Function for the actual booking write if atomic guarantees are needed.

### Anti-Pattern 3: Storing Date as Timestamp for Booking.date
**What:** `date: Timestamp.fromDate(DateTime(2026, 3, 24))` in Firestore.
**Why bad:** Timezone handling during serialization causes booking to appear on wrong day for users in UTC-offset zones. Querying "all bookings for March 24" becomes fragile.
**Instead:** Store date as ISO string `"2026-03-24"`. Query with `where('date', isEqualTo: '2026-03-24')`.

### Anti-Pattern 4: Single `admin` Boolean on User
**What:** `isAdmin: bool` field instead of `role: string`.
**Why bad:** Future roles (staff, moderator) require a schema migration. Security rules become `resource.data.role == 'admin'` which is more readable than `resource.data.isAdmin == true`.
**Instead:** Use `role: "client" | "admin"` string from day one.

### Anti-Pattern 5: Client-Side Role Check Without Firestore Rules
**What:** Only checking `user.role == 'admin'` in Flutter to show/hide admin UI.
**Why bad:** Anyone can call Firestore REST API directly with their auth token and bypass Flutter UI entirely.
**Instead:** Enforce roles in Firestore security rules as the authoritative gate. Flutter role check is only for UX.

---

## Firestore Security Rules Structure

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Helper functions
    function isSignedIn() {
      return request.auth != null;
    }
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    function isAdmin() {
      return isSignedIn() &&
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }

    // Users — can read own profile; admins can read all
    match /users/{userId} {
      allow read: if isOwner(userId) || isAdmin();
      allow create: if isOwner(userId) && request.resource.data.role == 'client'; // no self-promotion
      allow update: if (isOwner(userId) && !('role' in request.resource.data.diff(resource.data).affectedKeys()))
                    || isAdmin();
    }

    // Slots — public read; admin write
    match /slots/{slotId} {
      allow read: if true;
      allow write: if isAdmin();
    }

    // Bookings — client creates own; client reads/cancels own; admin full access
    match /bookings/{bookingId} {
      allow read: if isOwner(resource.data.userId) || isAdmin();
      allow create: if isSignedIn()
                    && request.resource.data.userId == request.auth.uid
                    && request.resource.data.status == 'pending';
      allow update: if (isOwner(resource.data.userId)
                        && request.resource.data.status == 'cancelled'
                        && resource.data.status != 'confirmed') // can't cancel confirmed
                    || isAdmin();
      allow delete: if isAdmin();
    }

    // Blocked dates — public read; admin write
    match /blockedDates/{dateStr} {
      allow read: if true;
      allow write: if isAdmin();
    }
  }
}
```

**Key rule decisions:**
- `isAdmin()` reads the user document on every privileged operation — this is a Firestore read cost. Acceptable for a low-traffic internal tool; revisit if volume grows.
- Clients can only create bookings with `status == 'pending'` — prevents clients from self-confirming.
- Clients cannot cancel a `confirmed` booking unilaterally — must go through admin (or this policy can be relaxed later).
- `role` field cannot be changed by a non-admin — prevents privilege escalation.

---

## Build Order

The component dependency graph determines build order. Each phase must deliver working, tested code before the next begins.

```
[1] Core Models + Firebase wiring
     └─ SlotModel, BookingModel, AppUser, BlockedDate
     └─ fromFirestore/toFirestore on each
     └─ Unit-testable with no Flutter dependency

[2] Auth feature (login screen + auth provider + router scaffold)
     └─ Depends on: [1] AppUser model
     └─ Enables: Route guards for all subsequent screens
     └─ GoRouter with redirect based on auth state

[3] Schedule feature (read-only slot display)
     └─ Depends on: [1] SlotModel, [2] Auth (user must be logged in to view)
     └─ Firestore streams for slots + bookings for selected week
     └─ No write operations yet — just display

[4] Booking feature (create + cancel bookings)
     └─ Depends on: [3] Schedule screen (booking is triggered from it)
     └─ BookingNotifier with create/cancel mutations
     └─ Confirmation sheet UI
     └─ My Bookings screen

[5] Admin feature (slot management + booking approval)
     └─ Depends on: [1-4] (admin manages what clients use)
     └─ Router guard: redirect non-admins
     └─ Slot CRUD, blocked dates, booking confirm/reject

[6] PWA polish + Firestore rules hardening
     └─ Depends on: [1-5] (rules reference all collections)
     └─ Security rules deployment
     └─ Offline behavior, install prompt
```

**Why this order:**
- Auth must exist before any authenticated screen — the router `redirect` is the security gate for admin routes
- Schedule (read) before Booking (write) — the booking flow is triggered from the schedule screen; the schedule must work first
- Admin last — it manages data the other features consume; its absence doesn't block client flows
- Security rules in the final phase is a pragmatic choice for development speed, but **test rules in emulator from phase 1** — don't deploy to production until phase 6 hardens them

---

## Scalability Considerations

| Concern | At ~50 users (current) | At 500 users | At 5K users |
|---------|----------------------|--------------|-------------|
| Firestore reads | Negligible cost | Still low — streams cache locally | Consider pagination on admin booking list |
| Double-booking prevention | Firestore stream + client check is sufficient | Add server-side check via Cloud Function | Required: atomic transaction in Cloud Function |
| Admin approval queue | Simple list query | Same | Add Firestore index on `(status, createdAt)` |
| Real-time streams per client | 3-4 active listeners is fine | Fine | Fine (Firestore handles fan-out server-side) |

For v1 (single gym, ~50 users), client-side double-booking prevention with optimistic UI is acceptable. Flag for phase-specific research before implementing: if two users submit a booking for the same slot within the same second, a Firestore transaction or Cloud Function is needed for a guaranteed atomic check. The current scope (manual admin confirmation) mitigates this naturally — pending bookings don't lock the slot.

---

## Sources

- Flutter feature-first architecture: https://codewithandrea.com/articles/flutter-project-structure/ (Andrea Bizzotto — canonical reference, HIGH confidence)
- Riverpod official docs: https://riverpod.dev/docs/introduction/getting_started (HIGH confidence)
- FlutterFire Firestore with Riverpod: https://firebase.flutter.dev/docs/firestore/usage/ (HIGH confidence)
- Firestore security rules with custom claims vs document reads: https://firebase.google.com/docs/firestore/security/rules-conditions (HIGH confidence)
- GoRouter redirect for auth guards: https://pub.dev/packages/go_router (HIGH confidence)
- Timezone bug with Timestamp for date-only fields: training data + confirmed by Firestore docs on data types (MEDIUM confidence — verify during implementation)
