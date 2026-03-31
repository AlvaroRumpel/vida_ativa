---
gsd_state_version: 1.0
milestone: v3.0
milestone_name: Rebrand Visual
status: planning_next
stopped_at: v2.0 milestone complete
last_updated: "2026-03-31T00:00:00.000Z"
progress:
  total_phases: 0
  completed_phases: 0
  total_plans: 0
  completed_plans: 0
---

# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-03-31)

**Core value:** Clientes conseguem reservar um horário de quadra em segundos, sem depender de mensagens no WhatsApp.
**Current focus:** Planning v3.0 — awaiting client logo + color palette assets before Phase 12 can begin

**Core value:** Clientes conseguem reservar um horário de quadra em segundos, sem depender do WhatsApp.
**Current focus:** Phase 11 — melhorias-visuais

## Current Position

Phase: 11 (melhorias-visuais) — EXECUTING
Plan: 2 of 2

## Performance Metrics

**Velocity (v1.0 reference):**

- Total plans completed: 13
- Average duration: 5 min
- Total execution time: ~1.08 hours

**By Phase (v1.0):**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-foundation | 2/2 | 12 min | 6 min |
| 02-auth | 3/3 | — | — |
| 03-schedule | 2/2 | — | — |
| 04-booking | 2/2 | — | — |
| 05-admin | 2/2 | — | — |
| 06-pwa-hardening | 2/2 | — | — |

*v2.0 metrics will be tracked starting Phase 07*
| Phase 07-visibilidade-social P01 | 3 | 2 tasks | 5 files |
| Phase 07-visibilidade-social P02 | 5 | 2 tasks | 4 files |
| Phase 08-compartilhamento-perfil P01 | 2 | 2 tasks | 3 files |
| Phase 09-gest-o-de-usu-rios-admin P01 | 25min | 2 tasks | 4 files |
| Phase 09-gest-o-de-usu-rios-admin P02 | 10min | 2 tasks | 4 files |
| Phase 10-monitoramento-de-erros P01 | 3min | 2 tasks | 3 files |
| Phase 10-monitoramento-de-erros P02 | 5min | 2 tasks | 5 files |
| Phase 11-melhorias-visuais P01 | 5min | 2 tasks | 5 files |
| Phase 11-melhorias-visuais P02 | 6min | 2 tasks | 9 files |

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
- [v2.0 Roadmap]: SOCIAL-01 requires Firestore Security Rules update — bookings collection must be readable by any authenticated user (was admin-only in v1)
- [v2.0 Roadmap]: SOCIAL-02 and ADMN-09 are in the same phase — participants field written during booking creation must appear in admin listing
- [v2.0 Roadmap]: UI-01 (rebrand) placed last (Phase 12) and BLOCKED — cannot start until client delivers logo + color palette
- [v2.0 Roadmap]: OPS-01 placed in standalone Phase 10 — no feature dependencies, can be implemented independently
- [Phase 07-01]: bookerName set only for SlotStatus.booked (not myBooking) — user sees own badge, not their own name
- [Phase 07-01]: _resolveStatus removed — inlined in _recompute() for single-pass O(n) booking lookup
- [Phase 07-01]: updateParticipants uses FieldValue.delete() for null/empty — no empty-string fields stored in Firestore
- [Phase 07-02]: BookingCard.bookingCubit is optional (nullable) — preserves backward compatibility, all current call sites pass the cubit
- [Phase 07-02]: Edit icon shown for all non-cancelled bookings (future and past) — retroactive participant editing is valid UX
- [Phase 08-01]: PhoneInputFormatter max 11 digits (Brazilian mobile: DDD 2 + number 9) — truncates excess, no error
- [Phase 08-01]: updatePhone uses FieldValue.delete() for null/empty — consistent with updateParticipants pattern from Phase 07
- [Phase 08-01]: Phone field optional in RegisterScreen — empty value passes null to cubit, no phone field stored in Firestore
- [Phase 08-02]: WhatsApp share uses wa.me/?text= URL (no phone number) — universal link, no WhatsApp install required for web fallback
- [Phase 08-02]: context.read<AuthCubit>() captured before showModalBottomSheet builder — avoids context access in sheet subtree
- [Phase 08-02]: _showEditPhoneSheet is a top-level function (not a method) — ProfileScreen is StatelessWidget, consistent with existing pattern
- [Phase 08-02]: Share button omits 👥 line entirely when participants null/empty — cleaner message for solo bookings
- [Phase 08]: PROF-02 scoped to phone-only (not name+phone) — user decided "só telefone" during discuss-phase; ROADMAP SC #3 corrected accordingly
- [Phase 09-01]: ViewMode is ephemeral (BLoC in-memory only) — not persisted to Firestore; fresh login always starts in admin mode
- [Phase 09-01]: Admin in client mode redirects to /home (not /access-denied) — cleaner UX for intentional mode switch
- [Phase 09-01]: AppShell BottomNav unchanged (3 tabs) — admin access is via ProfileScreen button, not a dedicated nav tab
- [Phase 09-gest-o-de-usu-rios-admin]: promoteUser emits no cubit state — promoted user picks up role change on next auth refresh; admin UI refreshes via _loadUsers() re-query
- [Phase 09-gest-o-de-usu-rios-admin]: Firestore /users write split into create/update/delete — create restricted to self, update allows admin, delete permanently blocked
- [Phase 10-monitoramento-de-erros]: Sentry DSN passed via --dart-define at build time — never stored in source code
- [Phase 10-monitoramento-de-erros]: kReleaseMode guard bypasses Sentry entirely in debug/profile — no DSN noise in dashboard
- [Phase 10-monitoramento-de-erros]: tracesSampleRate set to 0.0 — error-only monitoring, performance tracing disabled
- [Phase 10-monitoramento-de-erros]: SentryUser set with Firebase UID only — no PII sent to Sentry
- [Phase 10-monitoramento-de-erros]: onError lambdas are synchronous — captureException called without await (stream listener context, not async method)
- [Phase 11-melhorias-visuais]: calendar_view: 2.0.0 exact pin — pub.dev warns 2.x may have breaking changes per minor version
- [Phase 11-melhorias-visuais]: BookingCubit captured as _bookingCubit instance field in build() — DayView subtree has no BlocProvider access, follows Phase 4 pattern
- [Phase 11-melhorias-visuais]: AppSpacing file paths in plan were wrong; applied tokens to actual files (auth/ui/profile_screen.dart and admin/ui/*_management_tab.dart)
- [Phase 11-melhorias-visuais]: users_management_tab.dart has only EdgeInsets.all(12) not on token scale — no substitutions made

### Pending Todos

None yet.

### Blockers/Concerns

- [Phase 7]: SOCIAL-01 requires Firestore Security Rules update — bookings were private (admin-only) in v1; must open reads to authenticated users without exposing write operations
- [Phase 12]: UI-01 BLOCKED — client has not yet provided logo and color palette assets; phase cannot be planned or executed until assets are received
- [Phase 2]: Flutter Web HTML vs. CanvasKit renderer choice affects auth form autofill — must be tested on deployed URL, not localhost
- [Phase 4]: Firestore offline persistence on Flutter Web interacts with booking transactions — must be tested in real browser early; disable web persistence for booking writes

## Session Continuity

Last session: 2026-03-26T21:07:40.206Z
Stopped at: Completed 11-02-PLAN.md (AppSpacing tokens)
Resume file: None
