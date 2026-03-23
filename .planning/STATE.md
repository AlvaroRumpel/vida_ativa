---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: milestone_complete
stopped_at: v1.0 milestone archived
last_updated: "2026-03-23"
progress:
  total_phases: 6
  completed_phases: 6
  total_plans: 13
  completed_plans: 13
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-23)

**Core value:** Clientes conseguem reservar um horário de quadra em segundos, sem depender do WhatsApp.
**Current focus:** v1.0 milestone complete — planning v2.0

## Current Position

Phase: 06 (PWA Hardening) — COMPLETE
Plan: 2 of 2

## Performance Metrics

**Velocity:**

- Total plans completed: 3
- Average duration: 6 min
- Total execution time: 0.29 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 2/2 | 12 min | 6 min |

**Recent Trend:**

- Last 5 plans: 8 min, 4 min, 5 min
- Trend: stable

*Updated after each plan completion*
| Phase 01-foundation P01 | 8 | 3 tasks | 9 files |
| Phase 01-foundation P02 | 4 | 2 tasks | 10 files |
| Phase 02-auth P03 | 5 | 3 tasks | 5 files |
| Phase 03-schedule P01 | 3 | 2 tasks | 3 files |
| Phase 03-schedule P02 | 3 | 2 tasks | 8 files |
| Phase 04-booking P01 | 4 | 2 tasks | 5 files |
| Phase 04-booking P02 | 12 | 2 tasks | 6 files |
| Phase 05-admin P01 | 6 | 2 tasks | 10 files |
| Phase 06-pwa-hardening P01 | 2 | 3 tasks | 4 files |
| Phase 06-pwa-hardening P02 | 5 | 2 tasks | 1 files |

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Roadmap]: Phone Auth (OTP) deferred to v2 — web reCAPTCHA complexity; v1 uses Google + email/password only
- [Roadmap]: Firestore security rules started in Phase 1 (not deferred) — open rules before real user data is project-ending risk
- [Roadmap]: PWA manifest and firebase.json set up in Phase 1 — cheap now, expensive to retrofit, requires deployed URL to validate
- [Roadmap]: Double-booking prevention via Firestore transaction with `slotId_dateString` doc ID — required in Phase 4, not optional
- [01-01]: flutter_bloc chosen for state management (flutter_bloc ^9.1.1, go_router ^17.1.0, equatable ^2.0.8 installed)
- [01-01]: BookingModel.generateId() enforces {slotId}_{date} pattern — always use this, never Firestore .add()
- [01-01]: price cast uses (data['price'] as num).toDouble() — Firestore may return int or double
- [01-01]: Firestore rules Phase 1 bootstrap — authentication-only guards, Phase 6 adds isAdmin() role checks
- [Phase 01-foundation]: flutter_bloc chosen for state management (flutter_bloc ^9.1.1, go_router ^17.1.0, equatable ^2.0.8 installed)
- [Phase 01-foundation]: BookingModel.generateId() enforces {slotId}_{date} pattern — always use .doc(id).set() inside Transaction, never .add()
- [01-02]: No ProviderScope in main.dart — BLoC does not require root wrapper; BlocProviders added at feature level in Phase 2+
- [01-02]: StatefulShellRoute.indexedStack keeps each tab branch alive independently — tab state preserved on switch
- [01-02]: /admin has no guard in Phase 1 — role check added in Phase 2 with AuthBloc redirect
- [02-02]: BlocConsumer used in auth screens (listener + builder) to reduce widget nesting vs separate BlocListener + BlocBuilder
- [02-02]: Auth error routing uses lowercase message keyword inspection to assign errors to email vs password field
- [02-02]: Loading state shows inline CircularProgressIndicator inside FilledButton — avoids layout shift, keeps button size stable
- [02-03]: ProfileScreen accesses FirebaseAuth.instance.currentUser?.photoURL directly since UserModel does not store photoURL — avoids changing model interface
- [02-03]: SplashScreen uses AppTheme.primaryGreen constant instead of hardcoded Color literal for brand consistency
- [03-01]: ScheduleCubit uses cache-then-recompute — all three stream values must be non-null before emitting ScheduleLoaded
- [03-01]: Cancelled bookings excluded at Firestore query level (whereIn: pending/confirmed) — never seen by _resolveStatus()
- [03-01]: date.weekday used directly as dayOfWeek filter — both Dart and SlotModel use 1=Mon..7=Sun, no adjustment needed
- [Phase 03-02]: intl added as explicit direct dependency for NumberFormat.currency(locale: pt_BR) — transitive-only usage is fragile
- [Phase 03-02]: BlocProvider<ScheduleCubit> at GoRoute /home builder level — cubit scoped to route lifetime, matches Phase 2 pattern
- [Phase 03-02]: SlotList uses Dart sealed class exhaustive switch expression — compile-time exhaustiveness guarantee for all ScheduleState variants
- [Phase 04-booking]: BookingCubit queries without .orderBy() to avoid composite index — sorted locally in Dart in Plan 02 UI
- [Phase 04-booking]: bookSlot and cancelBooking do not emit cubit state — reactive stream subscription handles UI updates
- [Phase 04-booking]: BookingCubit provided at StatefulShellRoute level so Schedule and Bookings tabs share the same instance
- [Phase 04-booking]: BookingConfirmationSheet is a StatefulWidget managing its own isSubmitting/errorMessage — keeps cubit state clean, sheet stays open on error
- [Phase 04-booking]: context.read<BookingCubit>() captured before showModalBottomSheet builder — bottom sheet subtree has no BlocProvider access
- [Phase 04-booking]: String.compareTo() used for YYYY-MM-DD date comparisons — Dart String does not define >= / < operators
- [Phase 05-admin]: AdminBookingCubit.selectDate cancels previous StreamSubscription before starting new date stream — avoids duplicate emissions
- [Phase 05-admin]: bookSlot reads /config/booking before transaction (not inside) — Firestore transactions only support tx.get() reads on passed refs
- [Phase 05-admin]: setConfirmationMode re-emits AdminBookingLoaded immediately with new mode — UI toggle responds without waiting for Firestore round-trip
- [Phase 06-pwa-hardening]: isAdmin() checks .data.role == 'admin' string field in Firestore, not .data.isAdmin bool — avoids silent failure for all users
- [Phase 06-pwa-hardening]: dart:ui_web used for iOS detection in install banner — avoids dart:js_interop complexity, navigator.standalone check omitted as redundant
- [Phase 06-pwa-hardening]: firebase deploy --only hosting,firestore:rules deploys web app and rules atomically in a single command

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 2]: Flutter Web HTML vs. CanvasKit renderer choice affects auth form autofill — must be tested on deployed URL, not localhost
- [Phase 4]: Firestore offline persistence on Flutter Web interacts with booking transactions — must be tested in real browser early; disable web persistence for booking writes

## Session Continuity

Last session: 2026-03-23T18:35:41.647Z
Stopped at: Completed 06-02-PLAN.md
Resume file: None
