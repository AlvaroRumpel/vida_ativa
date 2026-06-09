# Technology Stack: Supabase Multi-Tenant Spike

**Project:** Vida Ativa v7.0 Spike  
**Researched:** 2026-06-09  
**Confidence:** HIGH (Official Supabase docs, PostgreSQL ANSI standard, Flutter Supabase SDK verified)

## Recommended Stack

### Backend: Supabase (Postgres + Auth + PostgREST)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Supabase** | Cloud (SaaS) | Full managed backend | Zero infrastructure overhead; RLS built-in; Auth managed; PostgREST auto-generates API from schema |
| **PostgreSQL** | 15+ (auto-updated) | Relational database | Industry-standard; ANSI-compliant; RLS native; MVCC handles concurrency; UNIQUE constraints for anti-double-booking |
| **Postgres Row-Level Security** | Native (15+) | Data isolation | Database-enforced access control; RLS policies filter every query at DB level; zero app-level filtering risk |
| **PostgREST** | 12+ (auto) | REST API layer | Auto-generated from schema; RLS-aware (respects policies); no code needed for CRUD |
| **Supabase Auth** | Native | User authentication | Managed OAuth/email; JWT tokens with custom claims support; passwordless options |

### Frontend: Flutter Web (same as v6.0)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **Flutter Web** | 3.22+ | SPA framework | Existing codebase uses Flutter; can reuse Dart business logic; PWA-ready |
| **supabase-flutter** | 2.0+ | Supabase SDK | Official Dart client; RLS-aware (auto-passes JWT); realtime ready |
| **flutter_bloc** | 8.0+ | State management | Existing pattern in codebase; familiar to team |
| **go_router** | 14.0+ | Navigation | Existing pattern; deep linking support for spike testing |

### Testing: psql + PL/pgSQL + Supabase Local Dev

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| **psql** | 15+ | SQL testing | Direct database access; test RLS policies as user context; test concurrent bookings |
| **pgTAP** | 1.3+ (optional) | Automated RLS tests | Framework for writing database tests; pgTAP assertions for RLS policy validation |
| **Supabase Local** | CLI 1.0+ | Local dev environment | Spin up local Postgres + Auth + PostgREST; test entire stack offline |
| **Dart test** | 1.24+ | Flutter unit tests | Spike needs at least smoke tests (auth + booking flow); existing test framework |

## Why NOT: Firebase (v6.0) vs Supabase (v7.0 Spike)

| Aspect | Firebase (v6.0) | Supabase (v7.0) | Decision |
|--------|-----------------|-----------------|----------|
| **Multi-tenancy** | Single tenant per app | RLS native + tenant_id schema | **Supabase** — RLS is industry-standard multi-tenant pattern |
| **Data isolation** | App-level (manual filtering) | Database-level (RLS enforces) | **Supabase** — Database-enforced isolation is more secure |
| **Anti-double-booking** | Firestore transactions | Postgres UNIQUE + MVCC | **Postgres** — Both atomic, but Postgres UNIQUE is simpler |
| **Cost at scale** | Firebase charges per read/write | Supabase charges per compute unit | **Tie** — Spike doesn't have production load data |
| **Ease of migration** | Loose schema (JSON) | Strict schema (SQL DDL) | **Firebase** — Schema-less is easier, but SQL enforces correctness |
| **Developer velocity** | Dart SDK complete | Dart SDK complete + SQL skills needed | **Firebase** — Spike adds SQL learning curve |

**Verdict:** Spike uses Supabase. Assumes team can write SQL and PL/pgSQL at intermediate level.

## Spike-Specific Constraints

### NO Cloud Functions Migration

**Why:** Spike focuses on "Can we isolate tenants and prevent double-booking?" Cloud Functions (Mercado Pago webhooks, FCM notifications, etc.) are post-spike.

**What spike needs:**
- Manual payment confirmation (admin marks booking as confirmed in UI)
- No webhook integrations
- No FCM push notifications

**Production migration adds:**
- Supabase Edge Functions (Node.js alternative to Firebase CF)
- Mercado Pago webhook handler
- FCM via Supabase or external service

### NO Realtime Subscriptions

**Why:** Spike uses polling or manual refresh. Realtime (Postgres Changes) adds complexity (WebSocket, RLS per message authorization).

**Pattern for spike:**
```typescript
// Spike: reload on user action
await supabase.from('bookings').select().eq('tenant_id', tenantId);

// Post-spike: subscribe for live updates
supabase
  .from('bookings')
  .on('*', (payload) => { /* update state */ })
  .subscribe();
```

## Installation & Setup

### Local Development (Supabase Local)

```bash
# Install Supabase CLI
npm install -g @supabase/cli

# Initialize local Supabase environment
cd spike-supabase/
supabase init

# Start local stack (Postgres + Auth + PostgREST on localhost)
supabase start

# Open Studio UI to design schema
open http://localhost:54323

# Pull schema after changes
supabase db pull
```

### Flutter SDK Integration

```bash
# Add Supabase to Flutter project
flutter pub add supabase

# Initialize Supabase client in main.dart
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  await Supabase.initialize(
    url: 'https://YOUR_PROJECT.supabase.co',
    anonKey: 'YOUR_ANON_KEY',
  );
  runApp(MyApp());
}
```

### Testing RLS Policies (psql)

```bash
# Connect to Supabase Postgres
psql "postgresql://postgres:password@localhost:5432/postgres"

-- Simulate user context for RLS
SET LOCAL request.jwt.claims = '{"sub":"user-uuid","tenant_id":"tenant-uuid"}';

-- Test SELECT isolation
SELECT * FROM bookings;  -- Should filter by tenant_id from JWT
```

### Testing Concurrent Bookings

```bash
# Terminal 1: Start transaction A
psql -c "BEGIN; SELECT book_slot(...);"

# Terminal 2: Try concurrent insert (before A commits)
psql -c "SELECT book_slot(...);  -- Should fail with SLOT_ALREADY_BOOKED"

# Terminal 1: Commit
psql -c "COMMIT;"
```

## Migration Path (Firebase → Supabase)

### Passwords: NOT Migrated

Firebase does NOT export password hashes (security design). Options:
1. **Spike:** Use new test accounts on Supabase (no migration)
2. **Production:** Parallel auth or force password reset campaign

### User Data: Migrated via CLI

```bash
# Export Firebase users to JSON
firebase:utils:export-users supabase

# Import to Supabase
supabase db seed < import_users.sql
```

### Bookings, Slots, Config: Migrated via SQL

```sql
-- Firebase had flat structure, Supabase has normalized schema
-- Data transformation needed:
-- /users → auth.users + public.user_profiles
-- /slots → public.slots (add tenant_id foreign key)
-- /bookings → public.bookings (add tenant_id foreign key)

INSERT INTO public.slots (id, tenant_id, day_of_week, start_time, price)
SELECT id, 'default-tenant-uuid', day_of_week, start_time, price
FROM import_firebase_slots;
```

## Spike Deliverables

### SQL Schema & RLS Policies
- `schema.sql` — Tables (tenants, memberships, slots, bookings) with RLS enabled
- `policies.sql` — Client + admin RLS policies
- `functions.sql` — book_slot() PL/pgSQL function

### Supabase Project Setup
- `.env.spike` — Supabase credentials (gitignored)
- Supabase local stack configured and tested

### Flutter Test App
- `lib/features/auth_spike/` — Login + tenant selection
- `lib/features/booking_spike/` — List slots + book + concurrent test
- Spike tests: RLS isolation (3 attacks), concurrent booking (2 simultaneous inserts)

### Evidence Document
- `spike-results.md` — Screenshots + logs proving RLS isolation and anti-double-booking work

## Sources

### Official Documentation
- [Supabase Documentation](https://supabase.com/docs)
- [PostgreSQL 15 Documentation](https://www.postgresql.org/docs/15/)
- [PostgREST Documentation](https://postgrest.org/)
- [Flutter Supabase SDK](https://github.com/supabase/supabase-flutter)

### Postgres Performance & Concurrency
- [PostgreSQL Multi-Version Concurrency Control (MVCC)](https://www.postgresql.org/docs/15/mvcc.html)
- [PostgreSQL UNIQUE Constraints](https://www.postgresql.org/docs/15/ddl-constraints.html#DDL-CONSTRAINTS-UNIQUE-CONSTRAINTS)

### RLS & Multi-Tenancy
- [Row-Level Security in PostgreSQL](https://www.postgresql.org/docs/15/ddl-rowsecurity.html)
- [Supabase RLS Guide](https://supabase.com/docs/guides/database/postgres/row-level-security)
- [Multi-Tenant RLS Patterns](https://dev.to/blackie360/-enforcing-row-level-security-in-supabase-a-deep-dive-into-lockins-multi-tenant-architecture-4hd2)
