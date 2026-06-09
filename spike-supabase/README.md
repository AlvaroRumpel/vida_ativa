# Spike: Supabase Multi-Tenant Validation

**Milestone:** v7.0 — Spike Supabase Multi-tenant  
**Scope:** Isolated technical validation — zero production changes  
**Directory:** spike-supabase/ (no imports from lib/ or Firebase)

## Purpose

Validate by evidence whether migrating from Firebase to Supabase (Postgres + RLS) is viable for SaaS multi-tenant — producing a go/no-go decision document before any production change.

## Credential Setup

1. Create a Supabase cloud project at https://supabase.com (staging — do NOT use production)
2. Copy `.env.example` to `.env` in this directory
3. Fill in real values from Supabase Dashboard > Project Settings > API:
   - `SUPABASE_URL` — your project URL
   - `SUPABASE_ANON_KEY` — public anon key (safe for client use)
   - `SUPABASE_DB_URL` — connection string from Database > Connection string (URI, Session mode)
4. **NEVER commit `.env`** — it is gitignored
5. **Service role key** (`sb_secret_*`) stays in Supabase dashboard ONLY — never in any file

## Apply Order

Run in this order against your Supabase cloud staging project:

```bash
# 1. Schema: creates 4 tables, indexes, enables RLS
psql "$SUPABASE_DB_URL" -f schema/01_schema.sql

# 2. RLS Policies: client/admin access control on all 4 tables
psql "$SUPABASE_DB_URL" -f schema/02_rls.sql

# 3. Seed Data: 2 tenants, 4 users, 4 slots, 8 bookings (all 7 statuses)
psql "$SUPABASE_DB_URL" -f schema/03_seed.sql
```

## After Applying — Update Seed User IDs

The seed data uses placeholder user_id UUIDs. After creating real auth.users in Supabase:

1. Go to Supabase Dashboard > Authentication > Users
2. Create 4 test users (email+password for spike testing):
   - client-a@spike.test (client role, Tenant A)
   - admin-a@spike.test (admin role, Tenant A)
   - client-b@spike.test (client role, Tenant B)
   - admin-b@spike.test (admin role, Tenant B)
3. Copy the UUIDs from the Auth dashboard
4. Update memberships table with real user_ids:
   ```sql
   UPDATE memberships SET user_id = 'real-uuid' WHERE id = '11000000-0000-0000-0000-000000000001';
   -- repeat for each membership
   ```
5. Update bookings table with same real user_ids

**Note:** Phase 32 will add an Auth Hook that injects `tenant_id` into JWT automatically.
Until then, RLS tests require manual JWT simulation via psql (see Testing section below).

## Testing RLS Isolation

**IMPORTANT:** Never test RLS policies from the SQL Editor — it uses admin credentials that bypass RLS.
Always test via psql with JWT claim simulation (as shown below) or from the Flutter app (Phase 34).

```bash
# Run isolation attack tests (after schema + RLS + seed applied)
psql "$SUPABASE_DB_URL" -f tests/rls_isolation_test.sql

# Run INSERT isolation test (WITH CHECK verification)
psql "$SUPABASE_DB_URL" -f tests/rls_insert_isolation_test.sql
```

Expected output: All tests print PASS. Any FAIL indicates a policy misconfiguration.

## Structure

```
spike-supabase/
├── schema/
│   ├── 01_schema.sql        # Tables: tenants, memberships, slots, bookings
│   ├── 02_rls.sql           # RLS policies: client/admin differentiation
│   └── 03_seed.sql          # Test data: 2 tenants, 4 users, 4 slots, 8 bookings
├── tests/
│   ├── rls_isolation_test.sql        # 3 cross-tenant attack scenarios
│   └── rls_insert_isolation_test.sql # WITH CHECK absence detection
├── .env.example             # Credential template (safe to commit)
├── .env                     # Real credentials (gitignored — create locally)
└── README.md                # This file
```

## Phases

| Phase | Content | Status |
|-------|---------|--------|
| Phase 31 (this) | Schema + RLS + Seed | Complete |
| Phase 32 | book_slot() PL/pgSQL + Auth Hook | Pending |
| Phase 33 | Isolation proofs (3 attacks) + Concurrency proofs | Pending |
| Phase 34 | Flutter mini-app + Realtime evaluation | Pending |
| Phase 35 | Risk assessment + Decision document | Pending |

## Security Notes

- `anon_key` is safe to include in client code — access controlled by RLS policies
- `service_role` key **bypasses ALL RLS** — never in app code, never in git
- RLS policies use `auth.jwt() -> 'app_metadata' -> 'tenant_id'` — server-set, immutable
- All INSERT/UPDATE policies have WITH CHECK clause (prevents cross-tenant writes)
- Zero touch to `lib/`, `functions/`, or Firebase production
