# Retrospective: Vida Ativa

---

## Milestone: v1.0 — MVP

**Shipped:** 2026-03-23
**Phases:** 6 | **Plans:** 13

### What Was Built

1. Data models + Firebase wiring + PWA manifest + Firestore bootstrap rules
2. Google + email/password auth with BLoC, persistent sessions, role-based routing
3. Read-only weekly schedule with real-time Firestore streams (available/booked/blocked/price)
4. Booking flow with atomic Firestore transaction preventing double-booking; MyBookings + cancel
5. Admin panel — slot CRUD, blocked dates, booking confirm/reject, automatic/manual mode toggle
6. Production deployment with restrictive Firestore rules (`isAdmin()` via `role`), iOS SnackBar, live URL

### What Worked

- **Phase-by-phase dependency chain** — each phase built cleanly on the previous; no rework across phase boundaries
- **Research-before-planning** caught the critical `role` vs `isAdmin` field mismatch before execution (would have silently broken all admin writes in production)
- **Plan checker** caught `firebase deploy --dry-run` (invalid flag) and the CONTEXT.md/standalone check discrepancy before a subagent wasted time on wrong implementation
- **Atomic commits per task** made it easy to spot-check progress and identify exactly what changed at each step
- **YoloMode + auto_advance** eliminated confirmation bottlenecks for non-interactive steps

### What Was Inefficient

- **ROADMAP.md Phase 5 checkbox**: Phase 5 was left with `[ ]` checkbox in ROADMAP despite completing — small tracking drift that carried through to Phase 6
- **MILESTONES.md CLI extraction**: The `milestone complete` CLI returned zero accomplishments — had to manually fill them in; the one_liner field isn't populated in SUMMARY.md files by gsd-executor
- **Wave 0 Nyquist gap**: VALIDATION.md required a test stub that would have violated `feedback_no_tests.md`; the plan had to explicitly document the exclusion to prevent the executor from creating it anyway

### Patterns Established

- **Cubit-as-constructor-param** for modals/dialogs — prevents context loss when widget unmounts before modal closes (established in Phase 4, extended in Phase 5)
- **MultiBlocProvider at router level** — all admin cubits provided at `/admin` route builder so all 3 tabs share same instances (Phase 5)
- **`(data['price'] as num).toDouble()`** — Firestore returns int or double depending on stored value; always cast via num
- **BookingModel.generateId()** — deterministic `{slotId}_{date}` IDs for anti-double-booking; always use this, never `.add()`

### Key Lessons

- **Firestore field names ≠ Dart getter names**: `UserModel.isAdmin` is a computed getter from `role: String`; the Firestore field is `role`, not `isAdmin`. Rules checking `.data.isAdmin` would silently always return false.
- **dart:js is deprecated** — use `dart:ui_web` for platform detection; no JS interop needed when installed PWAs bypass Safari entirely
- **`firebase deploy --dry-run` does not exist** — the valid verify for a build output is `ls build/web/index.html`
- **Service worker update is free**: `firebase.json` Cache-Control: no-cache on `flutter_service_worker.js` means zero code changes needed for update strategy

### Cost Observations

- Model profile: balanced (sonnet for executor/verifier)
- Sessions: ~3 (discuss-phase, plan-phase, execute-phase + complete-milestone)
- Notable: research agent caught a silent production bug (role field mismatch) before any code was written — high ROI on the research step

---

## Cross-Milestone Trends

| Metric | v1.0 |
|--------|------|
| Phases | 6 |
| Plans | 13 |
| Timeline | 5 days |
| Lines of Dart | ~3,831 |
| Silent bugs caught by research | 1 (role field) |
| Plan checker blockers fixed | 2 |
