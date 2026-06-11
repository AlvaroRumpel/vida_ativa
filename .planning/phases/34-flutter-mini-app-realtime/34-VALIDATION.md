---
phase: 34
slug: flutter-mini-app-realtime
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-11
---

# Phase 34 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Manual (Node.js + Flutter/Dart — no test runner config) |
| **Config file** | None — spike uses `--dart-define` + `.env` |
| **Quick run command** | `flutter run -d chrome` (Flutter app) |
| **Full suite command** | `flutter run -d chrome` + `node tests/realtime-test.js` + SPIKE-13 grep |
| **Estimated runtime** | ~3 min (Flutter build) + ~30s (Node.js realtime test) |

---

## Sampling Rate

- **After every task commit:** Run quick command relevant to task (flutter or node)
- **After every plan wave:** Run full suite command
- **Before `/gsd-verify-work`:** Both proofs executed, output documented in markdown; SPIKE-13 grep passes
- **Max feedback latency:** ~3 minutes (Flutter web build)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 34-01-01 | 01 | 1 | SPIKE-08 | SPIKE-13 | No service role key in flutter_app/ | grep audit | `grep -r 'sb_secret\|service_role' spike-supabase/flutter_app/ \|\| echo PASS` | ❌ W0 | ⬜ pending |
| 34-01-02 | 01 | 1 | SPIKE-08 | — | Auth succeeds + slot list loads (2 tenants) | manual | `flutter run -d chrome` (observe console) | ❌ W0 | ⬜ pending |
| 34-01-03 | 01 | 1 | SPIKE-08 | — | book_slot() RPC returns CONFIRMED or SLOT_ALREADY_BOOKED | manual | `flutter run -d chrome` (observe console) | ❌ W0 | ⬜ pending |
| 34-02-01 | 02 | 2 | SPIKE-09 | — | Cross-tenant isolation: tenant_1 does NOT receive tenant_2 events | manual | `node tests/realtime-test.js` (observe timeout = no event) | ❌ W1 | ⬜ pending |
| 34-02-02 | 02 | 2 | SPIKE-09 | — | Latency measured and logged (ms) | manual | `node tests/realtime-test.js` (latency output) | ❌ W1 | ⬜ pending |
| 34-02-03 | 02 | 2 | SPIKE-09 | — | Free tier 200 concurrent limit documented | manual | Output in realtime-evaluation.md | ❌ W1 | ⬜ pending |
| 34-02-04 | 02 | 2 | SPIKE-13 | SPIKE-13 | No service role key anywhere in flutter_app/ | grep audit | `grep -r 'sb_secret\|service_role' spike-supabase/flutter_app/ \|\| echo PASS` | ✅ reuse | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `spike-supabase/flutter_app/pubspec.yaml` — supabase_flutter ^2.14.1 dependency
- [ ] `spike-supabase/flutter_app/lib/main.dart` — Supabase.initialize() + proof_screen.dart (auth + slots + RPC)
- [ ] `spike-supabase/flutter_app/.env.example` — template for SUPABASE_URL, SUPABASE_ANON_KEY
- [ ] `spike-supabase/tests/realtime-test.js` — scaffolding from Phase 33 concurrency-test.js pattern

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| RLS filters slots by tenant without .eq() | SPIKE-08 D-04 | Flutter web output requires browser observation | Login as testclient@spike.local → log slot count; logout; login as testadmin@spike.local → log slot count; verify counts differ |
| Realtime cross-tenant isolation | SPIKE-09 D-06 | Requires 2 concurrent Supabase clients + timing | Run realtime-test.js; verify tenant_1 subscriber does NOT receive tenant_2 insert (timeout = isolation OK) |
| book_slot() RPC call succeeds | SPIKE-08 D-03 | Requires live Supabase staging + authenticated session | Observe console.log for `{success: true, booking_id: ...}` or `SLOT_ALREADY_BOOKED` |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 200s (Flutter build dominant factor)
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
