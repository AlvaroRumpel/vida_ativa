---
phase: 34-flutter-mini-app-realtime
fixed_at: 2026-06-11T16:57:13.434Z
review_path: .planning/phases/34-flutter-mini-app-realtime/34-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 4
skipped: 1
status: partial
---

# Phase 34: Code Review Fix Report

**Fixed at:** 2026-06-11T16:57:13Z
**Source review:** .planning/phases/34-flutter-mini-app-realtime/34-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5 (CR-01, CR-02, CR-03, WR-01, WR-02)
- Fixed: 4
- Skipped: 1

## Fixed Issues

### CR-01: Missing Null Check After Supabase Initialization

**Files modified:** `spike-supabase/flutter_app/lib/main.dart`
**Commit:** 6bb04df
**Applied fix:** Added `return` after the `debugPrint` when `_supabaseAnonKey.isEmpty`, and added a `_FatalErrorApp` widget class that displays a red error screen with the configuration message. App no longer proceeds to `Supabase.initialize()` with an empty key.

---

### CR-02: Unsafe JWT Base64 Parsing in realtime-test.js

**Files modified:** `spike-supabase/tests/realtime-test.js`, `spike-supabase/tests/isolation-proof.js`, `spike-supabase/tests/concurrency-test.js`
**Commit:** a138c51
**Applied fix:** Added `parseJWT(token)` helper function at module scope in all three test scripts. The helper validates token has exactly 3 segments, wraps `Buffer.from` decode and `JSON.parse` in try/catch, and throws a descriptive `Error` on failure. All inline `JSON.parse(Buffer.from(...split('.')[1]...))` calls replaced with `parseJWT(...)` calls.

---

### CR-03: Type Assertion Without Null Safety in Flutter

**Files modified:** `spike-supabase/flutter_app/lib/main.dart`
**Commit:** 10adc4e
**Applied fix:** Replaced unsafe `rpcResult as List` and bare `as bool?`/`as String?` casts with explicit type guards: `rpcResult is! List` early return, `rawRow is! Map` check, `successRaw is! bool` validation. Used local variable type promotion pattern (`final rawErrorCode = row['error_code']; final errorCode = rawErrorCode is String ? rawErrorCode : null`) to avoid Dart dead-code warnings from `is T ? ... as T` patterns.

---

### WR-01: Unhandled Promise Rejection in Realtime Event Subscriptions

**Files modified:** `spike-supabase/tests/realtime-test.js`
**Commit:** 8bc388c
**Applied fix:** Added error-state handling inside both `.subscribe()` callbacks — throws on `CHANNEL_ERROR`, `TIMED_OUT`, or `CLOSED` status. After the 500ms await, checks `channel.state !== 'joined'` and throws (isolation test) or returns early with `skipped: true` (latency test) if the channel did not reach joined state.

---

## Skipped Issues

### WR-02: Type Coercion Risk in JavaScript RPC Results

**File:** `spike-supabase/flutter_app/lib/main.dart:169-186`
**Reason:** Already addressed by CR-03 fix. The CR-03 fix added `rpcResult is! List` array check, `rawRow is! Map` map validation, and `successRaw is! bool` type guard — covering all the cases WR-02 described. Applying a separate WR-02 fix would be redundant and would conflict with the already-committed CR-03 changes.
**Original issue:** RPC result cast assumes array shape; `rows.first` fails if RPC returns scalar.

---

_Fixed: 2026-06-11T16:57:13Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
