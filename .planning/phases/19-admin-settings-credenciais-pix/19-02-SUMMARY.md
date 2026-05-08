---
phase: 19
plan: 02
subsystem: backend
tags: [firestore-rules, cloud-functions, mercadopago, credentials, security]
dependency_graph:
  requires: []
  provides:
    - firestore-rule-mercadopago-write-only
    - getMpAccessToken-helper
    - getMpWebhookSecret-helper
  affects:
    - createPixPayment
    - handlePixWebhook
tech_stack:
  added: []
  patterns:
    - Firestore-as-primary-credential-source with Secret-Manager-fallback
    - Per-invocation Firestore read (no global caching)
    - Write-only Firestore rules for sensitive config docs
key_files:
  created: []
  modified:
    - firestore.rules
    - functions/index.js
decisions:
  - "Firestore read per invocation — no global caching. Simpler, stateless, no cache invalidation"
  - "mpWebhookSecret.value() in getMpWebhookSecret helper is the intended fallback — not an error"
  - "cancelPixPayment and adminConfirmPixPayment intentionally keep mpAccessToken.value() — out of D-12 scope"
  - "db variable declared once at credential-read point in handlePixWebhook — duplicate removed"
metrics:
  duration: 15min
  completed_date: "2026-05-07"
  tasks_completed: 2
  files_modified: 2
---

# Phase 19 Plan 02: Firestore Rules + CF Credential Helpers Summary

**One-liner:** Write-only Firestore rule for `config/mercadopago` + `getMpAccessToken`/`getMpWebhookSecret` helpers with Firestore-primary / Secret-Manager-fallback pattern.

## What Was Built

### Task 1 — Firestore Rules (commit d81ef32)

Added specific rule for `config/mercadopago` at the `/databases/{database}/documents` level:

```
match /config/mercadopago {
  allow read: if false;
  allow write: if isAdmin();
}
```

Firestore rules specificity: `match /config/mercadopago` (literal path) takes precedence over `match /config/{docId}` (wildcard), so client reads of MP credentials are denied even for authenticated admins. Cloud Functions Admin SDK bypasses rules entirely — reads in CFs still work.

Existing `match /config/{docId}` rule untouched — `config/booking`, `config/settings`, `config/pricing` remain readable by authenticated users.

### Task 2 — Cloud Functions Helpers (commit a6c148a)

Added two helper functions after `admin.initializeApp()`:

- `getMpAccessToken(db)`: reads `config/mercadopago.accessToken` from Firestore; falls back to `mpAccessToken.value()` (Secret Manager) if empty or document missing.
- `getMpWebhookSecret(db)`: reads `config/mercadopago.webhookSecret` from Firestore; falls back to `mpWebhookSecret.value()` if empty or document missing.

Updated functions per D-12:
- **`createPixPayment`**: replaces `mpAccessToken.value()` with `await getMpAccessToken(db)` + guard throwing `HttpsError('failed-precondition', 'MP_ACCESS_TOKEN not configured')`.
- **`handlePixWebhook`**: fetches both credentials via `Promise.all([getMpAccessToken(db), getMpWebhookSecret(db)])` before signature verification; guards return 202 silently if either credential missing; removed duplicate `const db = admin.firestore()` that would have shadowed the new declaration.
- **`expireUnpaidBookings`**: confirmed no MP credential usage — no changes needed.

Functions out of D-12 scope (unchanged):
- `cancelPixPayment` — keeps `mpAccessToken.value()` directly
- `adminConfirmPixPayment` — keeps `mpAccessToken.value()` directly

## Deviations from Plan

None — plan executed exactly as written.

The plan noted a potential issue with `handlePixWebhook` having a `const db = admin.firestore()` that would be declared twice after the changes. This was handled as part of Task 2 execution: the original declaration at the booking-update section was removed since `db` was already declared earlier for the credential reads.

## Known Stubs

None — no placeholder values or mock data in any modified files.

## Threat Surface Scan

No new network endpoints, auth paths, or schema changes introduced. Changes are:
1. A Firestore security rule (restricts access — reduces surface)
2. Helper functions that read from existing Firestore path `config/mercadopago` (already planned in threat model T-19-06)

All threat model mitigations from the plan's `<threat_model>` section are implemented:
- T-19-06: `allow read: if false` in firestore.rules — DONE
- T-19-07: `getMpWebhookSecret()` provides correct secret for signature verification — DONE
- T-19-08: Helpers log only the SOURCE (Firestore vs Secret Manager), never the credential value — DONE
- T-19-09: Accepted (per-invocation read cost negligible for small academy)
- T-19-10: `allow write: if isAdmin()` for config/mercadopago — DONE

## Self-Check: PASSED

| Check | Result |
|-------|--------|
| firestore.rules exists | FOUND |
| functions/index.js exists | FOUND |
| commit d81ef32 exists | FOUND |
| commit a6c148a exists | FOUND |
