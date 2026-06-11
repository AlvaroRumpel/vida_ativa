---
phase: 34-flutter-mini-app-realtime
plan: "01"
subsystem: spike-supabase
tags: [flutter, supabase, rls, auth, rpc, spike]
dependency_graph:
  requires:
    - 31-schema-sql-rls (RLS policies, seed UUIDs, test accounts)
    - 32-book-slot-auth-hook (book_slot() RPC signature, auth hook)
    - 33-isolation-concurrency (proof patterns)
  provides:
    - spike-supabase/flutter_app/ — runnable Flutter mini-app (SPIKE-08)
    - spike-supabase/docs/flutter-proof.md — proof template for Wave 2 execution
  affects:
    - 34-02 — Realtime evaluation script uses same .env and test account pattern
tech_stack:
  added:
    - supabase_flutter ^2.14.1 (Flutter SDK for Supabase Auth + DB + RPC)
    - flutter_lints ^3.0.0 (linting)
  patterns:
    - String.fromEnvironment + --dart-define for credential injection
    - StatefulWidget ProofScreen with sequential async proof steps
    - Two-tenant comparative RLS proof (no .eq() required)
key_files:
  created:
    - spike-supabase/flutter_app/pubspec.yaml
    - spike-supabase/flutter_app/lib/main.dart
    - spike-supabase/flutter_app/.env.example
    - spike-supabase/flutter_app/.gitignore
    - spike-supabase/flutter_app/analysis_options.yaml
    - spike-supabase/flutter_app/lib/.gitkeep
    - spike-supabase/docs/flutter-proof.md
  modified: []
decisions:
  - "D-02 honored: credentials via String.fromEnvironment with empty defaultValue for sensitive fields (anon key, passwords)"
  - "D-04 honored: two-tenant comparative proof — same from('slots').select() query, different row counts prove RLS auto-filtering"
  - "SPIKE-13: no sb_secret or service_role string in flutter_app/ — grep audit PASS"
  - "rpc('book_slot') inline on single line to satisfy grep acceptance criteria"
metrics:
  duration: ~15min
  completed: 2026-06-11
  tasks_completed: 2
  tasks_total: 2
  files_created: 7
  files_modified: 0
---

# Phase 34 Plan 01: Flutter Mini-App Scaffold Summary

**One-liner:** Flutter standalone project with Supabase.initialize via String.fromEnvironment, two-tenant RLS proof, book_slot() RPC call, and SPIKE-13 service-key audit passing.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Scaffold Flutter project — pubspec.yaml, .env.example, .gitignore | 1cdb47e | pubspec.yaml, .env.example, .gitignore, analysis_options.yaml, lib/.gitkeep |
| 2 | Create main.dart ProofScreen + flutter-proof.md template | 9ff0ea6 | lib/main.dart, docs/flutter-proof.md |

## What Was Built

### spike-supabase/flutter_app/pubspec.yaml
Flutter project manifest for `spike_flutter`. Declares `supabase_flutter: ^2.14.1` as the only production dependency alongside `flutter_lints: ^3.0.0` for dev. SDK constraint `>=3.0.0 <4.0.0`.

### spike-supabase/flutter_app/lib/main.dart
Full proof implementation with `ProofScreen` StatefulWidget. On mount, runs sequentially:
1. Signs in as `_email1` (testclient@spike.local) — reads `tenant_id` from `user.appMetadata`
2. Calls `supabase.from('slots').select()` — logs row count for tenant_1 (no `.eq()`)
3. Signs out, signs in as `_email2` (testadmin@spike.local) — same query for tenant_2
4. Logs RLS delta: different counts prove RLS filters by tenant automatically (D-04)
5. Re-signs in as tenant_1, calls `rpc('book_slot', params: {...})` with seed fixture slot UUID
6. Logs RPC result: `success`, `error_code` (CONFIRMED or SLOT_ALREADY_BOOKED), `booking_id`
7. Displays all log lines in scrollable monospace ListView with progress indicator and Re-run button

All credentials use `String.fromEnvironment` with empty `defaultValue` for sensitive fields (SPIKE-13, D-02). URL defaults to staging project `fasirsbiadcchfgvktzt` as a convenience.

### spike-supabase/flutter_app/.env.example
Template with 6 env vars: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `TEST_EMAIL_1`, `TEST_PASSWORD_1`, `TEST_EMAIL_2`, `TEST_PASSWORD_2`. All values are placeholders — no real credentials. `.env` is gitignored.

### spike-supabase/docs/flutter-proof.md
Template document for executor to fill after running `flutter run -d chrome`. Contains Auth table, RLS slots table with delta column, book_slot() RPC result table, and SPIKE-13 audit result field.

## Acceptance Criteria Verification

| Criterion | Result |
|-----------|--------|
| `grep "supabase_flutter: ^2.14" pubspec.yaml` | PASS — `supabase_flutter: ^2.14.1` |
| `grep "name: spike_flutter" pubspec.yaml` | PASS |
| `grep "SUPABASE_URL" .env.example` | PASS |
| `grep "TEST_EMAIL_1" .env.example` | PASS |
| `grep "TEST_EMAIL_2" .env.example` | PASS |
| `.env` on own line in `.gitignore` | PASS |
| `grep -c "Supabase.initialize" main.dart` | 1 — PASS |
| `grep -c "String.fromEnvironment" main.dart` | 6 — PASS |
| `grep -c "from('slots')" main.dart` | 2 — PASS |
| `grep -c "rpc('book_slot'" main.dart` | 1 — PASS |
| `grep -c "SPIKE-13" main.dart` | 1 — PASS |
| `grep -r "sb_secret\|service_role" flutter_app/` | No files found — PASS |
| `grep -c "SUPABASE_ANON_KEY" main.dart` | 1 (String.fromEnvironment only) — PASS |
| `flutter-proof.md` exists with "SPIKE-08" | PASS |

## SPIKE-13 Audit

Command: `grep -r 'sb_secret\|service_role' spike-supabase/flutter_app/ || echo PASS`

Result: **PASS** — zero matches. No privileged key is present in any flutter_app/ file.

The SPIKE-13 comment in main.dart was reworded to avoid containing the grep pattern strings themselves, which would have caused a false positive. Comment reads: `// SPIKE-13: Only anon key used. No privileged key is present in this file.`

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] SPIKE-13 grep comment caused false positive**
- **Found during:** Task 2 verification
- **Issue:** The plan's comment template included literal strings `sb_secret` and `service_role` inside the audit comment, causing the grep audit to report a match on its own source file
- **Fix:** Rewrote SPIKE-13 comment to say "No privileged key is present" without containing the grep pattern strings. Moved audit command reference to PLAN.md
- **Files modified:** spike-supabase/flutter_app/lib/main.dart
- **Commit:** 9ff0ea6

**2. [Rule 1 - Bug] rpc() call split across lines failed grep acceptance criterion**
- **Found during:** Task 2 verification
- **Issue:** Plan acceptance criterion `grep -c "rpc('book_slot'" main.dart` expects 1, but the original code had `rpc(` on one line and `'book_slot',` on the next — grep found 0 matches
- **Fix:** Inlined the rpc call: `_supabase.rpc('book_slot', params: {` on a single line
- **Files modified:** spike-supabase/flutter_app/lib/main.dart
- **Commit:** 9ff0ea6

## Known Stubs

**flutter-proof.md** — all result fields marked `[fill]` are intentional placeholders. This document is a template to be completed by the executor after running `flutter run -d chrome` in Wave 2 with real `--dart-define` credentials. The template exists; the data does not yet.

This is by design per the plan: `flutter-proof.md status (template only — to be filled after flutter run in Wave 2)`.

## Threat Flags

No new network endpoints, auth paths, or trust boundary surfaces beyond what the plan's threat model covers. All surfaces identified in STRIDE register T-34-01-01 through T-34-01-05.

## Self-Check: PASSED

Files confirmed present:
- spike-supabase/flutter_app/pubspec.yaml — FOUND
- spike-supabase/flutter_app/lib/main.dart — FOUND
- spike-supabase/flutter_app/.env.example — FOUND
- spike-supabase/flutter_app/.gitignore — FOUND
- spike-supabase/flutter_app/analysis_options.yaml — FOUND
- spike-supabase/flutter_app/lib/.gitkeep — FOUND
- spike-supabase/docs/flutter-proof.md — FOUND

Commits confirmed:
- 1cdb47e — feat(34-01): scaffold Flutter project
- 9ff0ea6 — feat(34-01): create main.dart ProofScreen + flutter-proof.md template
