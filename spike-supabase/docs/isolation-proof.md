# Isolation Proof — SPIKE-06
**Date:** 2026-06-10
**Project:** fasirsbiadcchfgvktzt (staging)
**Phase:** 33 — Provas de Isolamento + Concorrência

## Attack Results

| # | Attack | Method | Expected | Result |
|---|--------|--------|----------|--------|
| SQL-1 | Cross-tenant SELECT em bookings (Tenant A → Tenant B) | SQL (MCP execute_sql) | 0 rows | PASS |
| SQL-2 | Cross-tenant SELECT em slots (Tenant A → Tenant B) | SQL (MCP execute_sql) | 0 rows | PASS |
| SQL-3 | Admin vê todas as bookings do próprio tenant | SQL (MCP execute_sql) | >= 7 rows | PASS |
| SQL-4 | Cross-tenant INSERT em bookings (Tenant A → Tenant B) | SQL (MCP execute_sql) | RLS bloqueia | PASS |
| HTTP-1 | Cross-tenant SELECT em bookings via publishable key | Node.js HTTP | 0 rows | PASS |
| HTTP-2 | Cross-tenant INSERT em bookings via publishable key | Node.js HTTP | RLS error | PASS |
| HTTP-3 | Cross-tenant UPDATE em bookings via publishable key | Node.js HTTP | 0 rows ou error | PASS |

## Raw Output — SQL Tests (MCP execute_sql)

### rls_isolation_test.sql

```
SQL-1 (SELECT bookings cross-tenant):
  PASS: Cross-tenant SELECT blocked (0 rows from Tenant B)

SQL-2 (SELECT slots cross-tenant):
  PASS: Cross-tenant SELECT on slots blocked (0 rows from Tenant B)

SQL-3 (Admin sees all tenant bookings):
  PASS: Admin sees 7 Tenant A bookings (all users)
```

### rls_insert_isolation_test.sql

```
SQL-4 (INSERT cross-tenant WITH CHECK):
  ERROR: 42501: new row violates row-level security policy for table "bookings"
  → PASS: RLS WITH CHECK blocked cross-tenant INSERT

Control (own-tenant INSERT):
  PASS: Own-tenant INSERT succeeded (id: 70d398d2-2cc8-4b4d-b66b-432f25b1cfbb) — ROLLBACK applied
```

## Raw Output — HTTP Tests (Node.js isolation-proof.js)

```
=== SETUP ===
User A created: 420961ec-854a-42c5-bb7f-04cd2c79c5e6 (test-a-1781137730352@example.com)
User B created: d0403bc6-c1ee-4103-bcb0-35a9805e5e67 (test-b-1781137730352@example.com)
Membership A inserted (tenant: 10000000-0000-0000-0000-000000000001)
Membership B inserted (tenant: 20000000-0000-0000-0000-000000000001)
User A signed in. tenant_id in JWT: 10000000-0000-0000-0000-000000000001
User B signed in. tenant_id in JWT: 20000000-0000-0000-0000-000000000001

=== ATTACKS ===

Attack 1 (SELECT cross-tenant bookings):
  rows returned: 0
  error: none
  RESULT: PASS — expected 0 rows

Attack 2 (INSERT cross-tenant bookings):
  inserted rows: 0
  error: new row violates row-level security policy for table "bookings"
  RESULT: PASS — expected RLS error

Attack 3 (UPDATE cross-tenant bookings):
  rows affected: 0
  error: none
  RESULT: PASS — expected 0 rows affected

=== SUMMARY ===
Attack 1 (SELECT): PASS
Attack 2 (INSERT): PASS
Attack 3 (UPDATE): PASS

OVERALL RESULT: PASS — RLS blocks all cross-tenant attacks

=== CLEANUP ===
User A deleted: OK
User B deleted: OK
```
