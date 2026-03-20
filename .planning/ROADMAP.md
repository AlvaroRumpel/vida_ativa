# Roadmap: Vida Ativa

## Overview

Six phases derived from a strict dependency chain: data models and infrastructure must exist before auth, auth before reading the schedule, schedule before writing bookings, bookings before admin tools that manage what gets booked. PWA setup and Firestore security rules start in Phase 1 because retrofitting them is expensive and insecure Firestore rules are a project-ending risk. Each phase delivers one complete, independently verifiable capability — nothing is left half-built at a phase boundary.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Foundation** - Data models, Firebase wiring, PWA manifest, Firestore security rules bootstrap, go_router + BLoC structural setup
- [x] **Phase 2: Auth** - Google Sign-In and email/password auth, route scaffold with role-based guards, persistent session
- [x] **Phase 3: Schedule** - Read-only weekly slot display with available/booked/blocked states and price display (completed 2026-03-20)
- [ ] **Phase 4: Booking** - Reserve a slot (atomic transaction), cancel own booking, view my bookings
- [ ] **Phase 5: Admin** - Slot CRUD, blocked dates, booking list with confirm/reject, configurable approval mode
- [ ] **Phase 6: PWA Hardening** - Final security rules deploy, service worker update strategy, iOS install banner, production deployment

## Phase Details

### Phase 1: Foundation
**Goal**: The structural skeleton of the app exists — data models, Firebase wiring, PWA configuration, security rules, and navigation framework — so every subsequent feature builds on a tested base
**Depends on**: Nothing (first phase)
**Requirements**: INFRA-01, INFRA-02, PWA-01, PWA-02
**Success Criteria** (what must be TRUE):
  1. All four Dart model classes (UserModel, SlotModel, BookingModel, BlockedDateModel) round-trip correctly through Firestore serialization in a test or manual verification
  2. App opens in browser, navigates to a placeholder home screen, and the URL bar updates correctly on route changes (go_router wired)
  3. The app shell renders correctly on a 390px mobile viewport without horizontal scroll (mobile-first layout baseline)
  4. `firestore.rules` file exists in the repo, is deployed, and denies unauthenticated writes to all collections
  5. `web/manifest.json` has maskable icons and `display: standalone`; `firebase.json` has SPA rewrite and no-cache header for the service worker file
**Plans:** 2/2 plans executed
Plans:
- [x] 01-PLAN-01.md — Dependencies, data models, PWA config, Firestore security rules
- [x] 01-PLAN-02.md — AppTheme, go_router, app shell with BottomNav, BLoC setup

### Phase 2: Auth
**Goal**: Users can securely access their accounts using Google or email/password, and the app enforces role boundaries so only admins reach admin routes
**Depends on**: Phase 1
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05
**Success Criteria** (what must be TRUE):
  1. User can sign in with a Google account and land on the home screen
  2. User can create an account with email and password and land on the home screen
  3. User can log in with existing email/password credentials
  4. User can request a password reset email and receives it
  5. User closes the browser, reopens the app, and is still logged in without re-authenticating
**Plans:** 3/3 plans complete
Plans:
- [x] 02-01-PLAN.md — AuthCubit + AuthState, GoRouter auth guards, main.dart BlocProvider wiring, test stubs
- [x] 02-02-PLAN.md — Login screen (Google + email/password) and Register screen
- [x] 02-03-PLAN.md — Splash, Profile, AccessDenied screens + human verification checkpoint

### Phase 3: Schedule
**Goal**: Users can browse the weekly schedule and see which slots are available, booked, or blocked, with prices, before committing to a booking
**Depends on**: Phase 2
**Requirements**: SCHED-01, SCHED-02, SCHED-03
**Success Criteria** (what must be TRUE):
  1. User sees a weekly calendar view and can navigate between weeks by swiping or tapping arrows
  2. Tapping a day shows the slots for that day, each labeled as available, booked, or blocked
  3. Each slot card displays its price
  4. Blocked dates (e.g., holidays) suppress their slots so no available slots appear for that day
**Plans:** 2/2 plans complete
Plans:
- [ ] 03-01-PLAN.md — SlotViewModel, ScheduleState, ScheduleCubit with three-stream Firestore architecture
- [ ] 03-02-PLAN.md — Schedule UI widgets (screen, week header, day chips, slot list, slot card, skeleton) + router wiring

### Phase 4: Booking
**Goal**: Users can reserve an available slot, view their own bookings, and cancel a booking — with zero risk of double-booking due to concurrent reservations
**Depends on**: Phase 3
**Requirements**: BOOK-01, BOOK-02, BOOK-03
**Success Criteria** (what must be TRUE):
  1. User taps an available slot, confirms, and the slot transitions to "booked" in the UI; a second user attempting the same slot at the same time receives an error — not a silent double booking
  2. User can see a list of their upcoming and past bookings with current status (Pending / Confirmed / Cancelled)
  3. User can cancel one of their own bookings and it disappears from their upcoming list
  4. The app never shows a booking as confirmed before the server write is acknowledged (no ghost bookings)
**Plans**: TBD

### Phase 5: Admin
**Goal**: Admins can configure the schedule (slots, blocked dates) and manage bookings (view, confirm, reject) through a protected admin interface
**Depends on**: Phase 4
**Requirements**: ADMN-01, ADMN-02, ADMN-03, ADMN-04, ADMN-05, ADMN-06
**Success Criteria** (what must be TRUE):
  1. Admin can create a recurring slot (day of week + time + price) and it appears in the schedule for future matching dates
  2. Admin can deactivate a slot without deleting it, causing it to stop appearing in the schedule
  3. Admin can block a specific date and all slots for that date disappear for all users
  4. Admin can view all bookings filtered by date and see the requester and status for each
  5. Admin can confirm or reject a pending booking, and the client's booking status updates accordingly
  6. Admin can toggle the confirmation mode (automatic vs. manual approval) and newly created bookings reflect the active mode
**Plans**: TBD

### Phase 6: PWA Hardening
**Goal**: The app is safe for real users — Firestore rules are restrictive and deployed, the service worker update flow works, and the app installs cleanly as a PWA on iOS and Android
**Depends on**: Phase 5
**Requirements**: PWA-01 (finalized), INFRA-01 (finalized)
**Success Criteria** (what must be TRUE):
  1. Deploying a new version of the app causes existing PWA installs to show updated content within one session (service worker update flow verified end-to-end)
  2. On iOS Safari, the app displays a prompt guiding the user to "Add to Home Screen"
  3. Firestore security rules pass a manual review: unauthenticated users cannot write anything; clients cannot read other users' bookings; admin writes are gated by the `isAdmin()` rule
  4. `firebase deploy` runs cleanly from the repo and produces a working production URL
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 2/2 | Complete | 2026-03-19 |
| 2. Auth | 3/3 | Complete    | 2026-03-20 |
| 3. Schedule | 2/2 | Complete   | 2026-03-20 |
| 4. Booking | 0/TBD | Not started | - |
| 5. Admin | 0/TBD | Not started | - |
| 6. PWA Hardening | 0/TBD | Not started | - |
