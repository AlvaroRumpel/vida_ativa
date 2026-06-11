---
phase: 34-flutter-mini-app-realtime
reviewed: 2026-06-11T00:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - spike-supabase/flutter_app/pubspec.yaml
  - spike-supabase/flutter_app/lib/main.dart
  - spike-supabase/flutter_app/.env.example
  - spike-supabase/flutter_app/.gitignore
  - spike-supabase/flutter_app/analysis_options.yaml
  - spike-supabase/docs/flutter-proof.md
  - spike-supabase/tests/realtime-test.js
  - spike-supabase/docs/realtime-evaluation.md
  - spike-supabase/package.json
findings:
  critical: 3
  warning: 2
  info: 1
  total: 6
status: issues_found
---

# Phase 34: Code Review Report

**Reviewed:** 2026-06-11
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Phase 34 implements SPIKE-08 (Flutter proof-of-concept) and SPIKE-09 (Realtime evaluation). Review found 3 critical issues related to error handling and JWT parsing robustness, plus 2 warnings on type safety. No hardcoded secrets detected. Security isolation measures look correct (RLS + anon-only keys).

## Critical Issues

### CR-01: Missing Null Check After Supabase Initialization

**File:** `spike-supabase/flutter_app/lib/main.dart:46-49`

**Issue:** When `_supabaseAnonKey` is empty, the app calls `debugPrint()` but **continues to initialize Supabase with an empty key**. This will cause the Supabase client to fail silently later (lines 102, 125, 155). The `debugPrint()` warning is not fatal — app crashes at first RPC/query attempt, not at startup. User sees blank screen or confusing error.

**Fix:**
```dart
if (_supabaseAnonKey.isEmpty) {
  debugPrint('FATAL: SUPABASE_ANON_KEY not set. '
      'Run with --dart-define=SUPABASE_ANON_KEY=<key>');
  runApp(const FatalErrorApp()); // Show error UI instead
  return;
}

await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
runApp(const SpikeApp());
```

Or throw exception to prevent app launch.

---

### CR-02: Unsafe JWT Base64 Parsing in realtime-test.js

**File:** `spike-supabase/tests/realtime-test.js:71`

**Issue:** JWT is parsed by splitting on `.` and decoding the middle segment:
```javascript
const jwtA = JSON.parse(Buffer.from(siA.session.access_token.split('.')[1], 'base64').toString('utf8'));
```

If `access_token` format is malformed (missing segments, invalid base64), this crashes with "Cannot read property `[1]` of undefined" or `JSON.parse()` error. No try/catch wraps this operation.

Same issue at lines 76 (jwtB), and in `isolation-proof.js:58, 63` and `concurrency-test.js:44`.

**Fix:**
```javascript
function parseJWT(token) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) throw new Error('Invalid JWT format');
    const decoded = Buffer.from(parts[1], 'base64').toString('utf8');
    return JSON.parse(decoded);
  } catch (err) {
    throw new Error(`JWT parse failed: ${err.message}`);
  }
}

const jwtA = parseJWT(siA.session.access_token);
```

---

### CR-03: Type Assertion Without Null Safety in Flutter

**File:** `spike-supabase/flutter_app/lib/main.dart:106-107, 130-131, 159-160, 171-174`

**Issue:** Multiple unsafe casts of dynamic values:
```dart
final user1 = auth1.user!;  // Line 106 — null assertion, ok
final tenant1Id = user1.appMetadata['tenant_id'] as String? ?? 'MISSING';  // Line 107

final success = row['success'] as bool? ?? false;  // Line 172 — maps to bool
final errorCode = row['error_code'] as String?;  // Line 173
```

The `as String?` casts assume the RPC response structure is correct. If Supabase returns a different shape (e.g., `error_code` is an int), the cast silently fails and `errorCode` is null (line 182 checks `if (success)` but doesn't validate success type).

**Fix:**
```dart
final row = rows.first as Map<String, dynamic>;

// Validate types before using
if (row is! Map) {
  _append('RPC response not a map');
  return;
}

final successRaw = row['success'];
if (successRaw is! bool) {
  _append('RPC error: success is ${successRaw.runtimeType}, expected bool');
  return;
}
final success = successRaw;
final errorCode = row['error_code'] is String ? row['error_code'] : null;
```

---

## Warnings

### WR-01: Unhandled Promise Rejection in Realtime Event Subscriptions

**File:** `spike-supabase/tests/realtime-test.js:139-145, 237-245`

**Issue:** The `.subscribe()` calls don't chain `.catch()`:
```javascript
const channel = clientA.channel('bookings-isolation').on(...).subscribe((status) => {
  if (status === 'SUBSCRIBED') { ... }
});
```

If subscription fails (network error, auth failure), the promise rejects. This is caught by the outer `try/catch` in `main()`, but silently. The test continues as if the subscription succeeded, leading to false "isolation pass" results.

**Fix:**
```javascript
const channel = clientA.channel('bookings-isolation')
  .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'bookings' }, (payload) => {
    // ...
  })
  .subscribe((status) => {
    if (status === 'SUBSCRIBED') { console.log('✓ Subscribed'); }
  });

if (channel.state !== 'joined') {
  throw new Error(`Channel subscription failed: ${channel.state}`);
}
```

Or add error handler to `.subscribe()` callback.

---

### WR-02: Type Coercion Risk in JavaScript RPC Results

**File:** `spike-supabase/tests/realtime-test.js:169-186`

**Issue:** RPC result type assumption:
```javascript
const rows = rpcResult as List;  // Assumes rpcResult is always array
if (rows.isNotEmpty) {
  final row = rows.first as Map<String, dynamic>;
```

If the RPC returns a scalar (e.g., `booking_id` as single string) instead of `[{success:true, booking_id:...}]`, `rows.first` fails with "Cannot read property first of undefined".

**Fix:**
```javascript
if (!Array.isArray(rpcResult)) {
  _append(`RPC returned non-array: ${typeof rpcResult}`);
  return;
}
if (rpcResult.length === 0) {
  _append('RPC returned empty array');
  return;
}
const row = rpcResult[0];
if (typeof row !== 'object' || row === null) {
  _append(`RPC row[0] is not an object: ${typeof row}`);
  return;
}
```

---

## Info

### IN-01: Hardcoded Test Password in Scripts

**File:** `spike-supabase/tests/realtime-test.js:41`, `isolation-proof.js:31`, `concurrency-test.js:30`

**Issue:** All test scripts use the same plaintext password `TestPassword123!`. While these are test-only scripts (not production code), documenting this pattern for future reference:

```javascript
const password = 'TestPassword123!';
```

**Fix:** Move to environment variable or .env:
```javascript
const password = process.env.TEST_PASSWORD || 'TestPassword123!';
if (!process.env.TEST_PASSWORD) {
  console.warn('Using hardcoded test password. Set TEST_PASSWORD=... to override.');
}
```

This prevents accidental production usage if test scripts are copied.

---

## Summary of Findings

| Severity | Count | Items |
|----------|-------|-------|
| Critical | 3 | Missing nil check on Supabase init; Unsafe JWT parsing; Type assertion without validation |
| Warning | 2 | Unhandled subscription promise; Type coercion in RPC results |
| Info | 1 | Hardcoded test passwords |

**Recommendation:** Fix CR-01 and CR-02 before running tests. CR-03 requires validation layer for RPC responses. All fixes are straightforward — no architecture changes needed.

---

_Reviewed: 2026-06-11_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
