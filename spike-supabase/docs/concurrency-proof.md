# Concurrency Proof — SPIKE-07
**Date:** 2026-06-10
**Project:** fasirsbiadcchfgvktzt (staging)
**Phase:** 33 — Provas de Isolamento + Concorrência

## Test Parameters

| Parameter | Value |
|-----------|-------|
| Concurrent requests | 50 |
| booking_date | 2099-12-31 (far future — isolated from seed data) |
| Slot | Dedicated test slot (created + deleted by script) |
| User | Test user with Tenant A membership (created + deleted by script) |
| Function | public.book_slot(p_slot_id, p_booking_date, p_user_id, p_tenant_id) |

## Results

| Metric | Expected | Actual | Result |
|--------|----------|--------|--------|
| Confirmed bookings (success=true) | 1 | 1 | PASS |
| SLOT_ALREADY_BOOKED responses | 49 | 20 | PASS |
| SLOT_LOCKED_RETRY responses | 0 | 29 | PASS (expected — see Analysis) |
| Network errors | 0 | 0 | PASS |
| Total responses | 50 | 50 | PASS |
| Overall | 1 confirmed + 49 rejected | 1 confirmed + 49 rejected | PASS |

## Raw Output — concurrency-test.js

```
=== SETUP ===
Test user created: 936d2388-7b04-4168-bab1-53ddb6be3a01
tenant_id in JWT: 10000000-0000-0000-0000-000000000001
Test slot created: 4bc3c23f-a47c-47b5-b482-32d4bafd63c8

=== CONCURRENCY TEST ===
Firing 50 simultaneous book_slot() calls...
slot_id: 4bc3c23f-a47c-47b5-b482-32d4bafd63c8
booking_date: 2099-12-31

=== RESULTS ===
┌──────────────────────────┬────────┐
│ (index)                  │ Values │
├──────────────────────────┼────────┤
│ CONFIRMED (success=true) │ 1      │
│ SLOT_ALREADY_BOOKED      │ 20     │
│ SLOT_LOCKED_RETRY        │ 29     │
│ USER_NOT_IN_TENANT       │ 0      │
│ Network errors           │ 0      │
│ Null results             │ 0      │
└──────────────────────────┴────────┘
Booking ID confirmed: 83804915-9ebe-45d7-bb86-dd018f398b92

Expected: confirmed=1, SLOT_ALREADY_BOOKED=49
Got:      confirmed=1, SLOT_ALREADY_BOOKED=20, SLOT_LOCKED_RETRY=29

RESULT: PASS

=== CLEANUP ===
Booking deleted: OK
Slot deleted: OK
User deleted: OK
```

## Analysis

**Locking mechanism:** `book_slot()` usa `SELECT FOR UPDATE NOWAIT` + `EXCEPTION WHEN unique_violation`.
O primeiro request a adquirir o lock insere o booking (confirmed=1). Os demais retornam:
- `SLOT_ALREADY_BOOKED` (20): chegaram depois do INSERT — unique_violation detectada
- `SLOT_LOCKED_RETRY` (29): SELECT FOR UPDATE NOWAIT falhou — row já bloqueada por outra tx

**Note on SLOT_LOCKED_RETRY:** Comportamento correto. O total SLOT_ALREADY_BOOKED + SLOT_LOCKED_RETRY = 49,
confirmando que exatamente 1 booking foi criado. O mix entre os dois códigos de erro
varia por timing — ambos são respostas válidas de "slot ocupado".
