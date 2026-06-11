# SPIKE-09: Supabase Realtime Evaluation

**Date:** [fill after running `node tests/realtime-test.js`]
**Script:** `spike-supabase/tests/realtime-test.js`
**Supabase project:** fasirsbiadcchfgvktzt (staging)
**Reference:** [Supabase Realtime Limits](https://supabase.com/docs/guides/realtime/limits)

---

## Summary

| Property | Result | Notes |
|----------|--------|-------|
| Cross-tenant isolation | [PASS / FAIL] | Fill after run |
| Same-tenant latency | [Xms / N/A] | Fill after run |
| Free tier max connections | 200 | Static — from Supabase docs |
| Free tier monthly messages | 2,000,000 | Static — from Supabase docs |

---

## Test 1: Cross-Tenant Isolation

**Method:** Tenant A subscribes to `bookings.INSERT` via Realtime. Tenant B inserts a booking.
Wait 3 seconds. If Tenant A received the event → FAIL (BLOCKING). If not → PASS.

**Result:** [fill — PASS or FAIL]

```
Event received by Tenant A: [YES / NO]
Verdict: [paste from script output]
```

**Analysis:**
[Fill after run — one of:]
- PASS: RLS policies applied in Phase 31 correctly filter Realtime postgres_changes events.
  Tenant A does not receive Tenant B events. Multi-tenant Realtime is safe without application-level filtering.
- FAIL (BLOCKING): RLS does NOT filter Realtime events at the database broadcast layer.
  Tenant A received Tenant B event. This means application-level filtering is required before
  shipping Realtime to multi-tenant production. See DECISION.md (Phase 35) risk assessment.

---

## Test 2: Same-Tenant Latency Baseline

**Method:** Tenant A subscribes to `bookings.INSERT`. Tenant A inserts a booking.
Measure time from INSERT to event callback receipt.

**Result:** [fill — Xms or N/A if event not received within 5s]

**Analysis:**
[Fill after run — typical values:]
- < 100ms: Excellent — suitable for real-time UX
- 100–500ms: Good — acceptable for most use cases
- 500ms–2s: Marginal — noticeable lag for interactive features
- > 2s or N/A: Poor — may indicate subscription setup issue; re-run to confirm

---

## Test 3: Free Tier Limits

| Limit | Value | Source |
|-------|-------|--------|
| Concurrent peak connections | **200** | [Supabase Realtime Limits](https://supabase.com/docs/guides/realtime/limits) |
| Messages per month | **2,000,000** | Same source |
| Max message size | **256 KB** | Same source |

**Implications for multi-tenant production:**
- 200 concurrent connections = 200 simultaneous browser tabs with open Realtime subscriptions
- Multi-tenant app with 50 tenants × 4 concurrent users each = 200 connections (at capacity)
- **Recommendation:** If going to production, budget Pro tier ($25/mo) for 500 connections
- For the spike (staging, dev use): free tier is sufficient

---

## SPIKE-13 Audit

Service role key must never appear in flutter_app/ code or git history.

```bash
grep -r 'sb_secret\|service_role' spike-supabase/flutter_app/ || echo PASS
```

Result: PASS

---

## Conclusion for DECISION.md (Phase 35)

[Fill after running both scripts:]

| Finding | Severity | Impact on Go/No-Go |
|---------|----------|--------------------|
| Cross-tenant isolation | [PASS/BLOCKING] | [Critical if FAIL — requires app-level filtering] |
| Latency | [OK/MARGINAL] | [Low severity — acceptable range is wide] |
| Free tier limits | DOCUMENTED | [Requires Pro tier if > 200 concurrent users] |

**Overall Realtime verdict:** [VIABLE / REQUIRES MITIGATION / BLOCKING]
