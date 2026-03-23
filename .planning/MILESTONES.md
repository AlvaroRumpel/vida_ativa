# Milestones

## v1.0 MVP (Shipped: 2026-03-23)

**Phases completed:** 6 phases, 13 plans
**Timeline:** 2026-03-19 → 2026-03-23 (5 days)
**Codebase:** ~3,831 lines of Dart

**Key accomplishments:**

1. Four Firestore data models (UserModel, SlotModel, BookingModel, BlockedDateModel) with bidirectional serialization, Equatable, and deterministic booking ID generation for anti-double-booking
2. Google Sign-In + email/password auth with BLoC, persistent sessions, and role-based route guards (client vs admin)
3. Read-only weekly schedule with real-time Firestore streams — available/booked/blocked/price display per slot
4. Booking flow with atomic Firestore transactions preventing double-booking; MyBookings list with cancel flow
5. Admin panel — slot CRUD + active toggle, blocked date management, booking list with confirm/reject per date, configurable automatic/manual approval mode
6. Production deployment to `vida-ativa-94ba0.web.app` — restrictive Firestore rules with `isAdmin()` role-based access, iOS install SnackBar, PWA title "Vida Ativa"

**Archive:** `.planning/milestones/v1.0-ROADMAP.md`

---
