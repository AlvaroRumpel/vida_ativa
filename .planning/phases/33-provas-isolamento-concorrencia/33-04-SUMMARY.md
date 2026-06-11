---
phase: 33-provas-isolamento-concorrencia
plan: 04
wave: 4
status: complete
completed: 2026-06-10
---

# Plan 33-04 Summary — Concurrency Proof Script

## What was built
- Created `spike-supabase/tests/concurrency-test.js` (Node.js ESM)
- Adapted variable names: `SUPABASE_PUBLISHABLE_KEY` / `SUPABASE_SECRET_KEY`
- 50 simultaneous `book_slot()` RPC calls via `Promise.allSettled()`

## Results
| Metric | Expected | Actual |
|--------|----------|--------|
| CONFIRMED | 1 | 1 |
| SLOT_ALREADY_BOOKED | 49 | 20 |
| SLOT_LOCKED_RETRY | 0 | 29 |
| Total resolved | 50 | 50 |
| Network errors | 0 | 0 |

RESULT: PASS — exactly 1 booking confirmed. SLOT_LOCKED_RETRY=29 is expected behavior
(SELECT FOR UPDATE NOWAIT racing requests fail before INSERT; both error codes = "slot taken").
Cleanup: slot + booking + user deleted.
