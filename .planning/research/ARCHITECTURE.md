# Architecture: Supabase Multi-Tenant Spike

**Spike:** `/spike-supabase/`  
**Researched:** 2026-06-09  
**Scope:** Isolated technical validation — zero production changes  
**Confidence:** HIGH (Supabase patterns well-documented; Flutter integration confirmed)

---

## Executive Summary

The `/spike-supabase/` spike is a **standalone, self-contained experimental environment** for validating Supabase multi-tenant architecture before any production migration. It exists entirely outside the production Flutter app (`lib/`) and Firebase infrastructure. The spike architecture consists of four tightly integrated layers:

1. **Database Layer** — PostgreSQL schema with tenant isolation via RLS policies
2. **Auth Layer** — Supabase Auth with custom JWT claims (tenant_id) injected via Edge Function hook
3. **Flutter Mini-App Layer** — Minimal Flutter client demonstrating authenticated RLS queries
4. **Testing & Validation Layer** — SQL/Postgres tests for RLS enforcement and anti-double-booking; Flutter integration tests

The critical insight: **RLS policies handle tenant isolation at the database level automatically**. Once a user authenticates and receives a JWT with `tenant_id` in claims, queries to tenant-scoped tables (slots, bookings) automatically filter by that tenant without application-level `.eq('tenant_id', ...)` required. Realtime subscriptions also respect RLS, filtering updates before delivery to clients.

---

## Directory Structure

```
spike-supabase/
├── schema/
│   ├── init.sql                    # Initial schema: tenants, auth.users integration, memberships
│   ├── rls_policies.sql            # RLS policies for all tables (SELECT, INSERT, UPDATE, DELETE)
│   ├── anti_double_booking.sql     # book_slot() function + trigger for UNIQUE(tenant_id, slot_id, date)
│   └── seed_test_data.sql          # 3 tenants, 6 users, 9 slots, test bookings
│
├── functions/
│   └── auth_hook_tenant_id.ts      # Edge Function: custom access token hook → injects tenant_id into JWT
│
├── flutter_app/
│   ├── pubspec.yaml                # Mini-app pubspec (reuses root for common deps)
│   ├── lib/
│   │   ├── main.dart               # Entry point, Supabase init, error handling
│   │   ├── models/
│   │   │   ├── tenant_model.dart
│   │   │   ├── user_model.dart
│   │   │   ├── slot_model.dart
│   │   │   └── booking_model.dart
│   │   ├── repositories/
│   │   │   ├── supabase_auth_repo.dart    # signUp, signIn, getSession, JWT decoding
│   │   │   └── supabase_query_repo.dart   # Queries: slots, bookings (RLS automatic)
│   │   ├── cubits/
│   │   │   ├── auth_cubit.dart            # Auth state: logged in, tenant_id from JWT
│   │   │   └── slots_cubit.dart           # Slot queries respecting user's RLS
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── slots_screen.dart          # List slots for current user's tenant
│   │   │   ├── book_slot_screen.dart      # Call book_slot() function
│   │   │   └── my_bookings_screen.dart    # View user's bookings (RLS filtered)
│   │   └── widgets/
│   │       └── realtime_bookings.dart     # Realtime().onPostgresChanges() — RLS respected
│   └── test/
│       ├── unit/
│       │   ├── auth_cubit_test.dart
│       │   └── slot_model_test.dart
│       └── integration/
│           └── supabase_integration_test.dart
│
├── tests/
│   ├── rls_cross_tenant_attack.sql        # Attack 1: Select user tries to read other tenant's slots
│   ├── rls_write_isolation.sql            # Attack 2: Insert tries to create booking for other tenant
│   ├── rls_update_isolation.sql           # Attack 3: Update tries to modify other tenant's booking
│   ├── book_slot_concurrency.sql          # Anti-double-booking: 5 concurrent threads, same slot
│   └── realtime_rls_filter.sql            # Realtime: verify subscription respects RLS
│
├── docs/
│   ├── ARCHITECTURE.md              # This file
│   ├── BUILD_ORDER.md               # Step-by-step build sequence
│   ├── CREDENTIALS.md               # .env template, security approach
│   └── DECISION_TEMPLATE.md         # Template for final go/no-go decision doc
│
├── .env.example                     # Template: SUPABASE_URL, SUPABASE_ANON_KEY, SERVICE_ROLE_KEY
├── README.md                        # Spike overview, how to run, structure
└── .gitignore                       # Excludes: .env, flutter_app/build, .dart_tool
```

---

## Component Architecture & Integration Points

### Layer 1: Database (PostgreSQL + RLS)

**Responsibility:** Store multi-tenant data securely; isolate queries via RLS policies.

**Core Tables:**

```sql
tenants (id UUID, name VARCHAR)
  ├─ memberships (id UUID, user_id UUID, tenant_id FK, role ENUM[admin|client])
  │
  ├─ slots (id UUID, tenant_id FK, day_of_week INT, start_time TIME, end_time TIME, price DECIMAL)
  │
├─ bookings (id UUID, tenant_id FK, user_id FK, slot_id FK, booking_date DATE, status ENUM[pending|confirmed|cancelled])
  │
└─ [Realtime] — subscriptions filtered per client RLS policy
```

**Key RLS Policies:**

| Table | Policy | Effect |
|-------|--------|--------|
| `slots` | SELECT if `tenant_id = auth.jwt()->'tenant_id'` | User sees only their tenant's slots |
| `bookings` | SELECT if `tenant_id = auth.jwt()->'tenant_id'` | User sees only their tenant's bookings |
| `bookings` | INSERT if `tenant_id = auth.jwt()->'tenant_id'` AND calls `book_slot()` | Prevents manual insert outside function |
| `bookings` | UPDATE if `tenant_id = auth.jwt()->'tenant_id'` | User can only update own tenant's data |
| `users` | UPDATE if `auth.uid() = id` | User edits only own profile |

**Anti-Double-Booking Mechanism:**

Function `book_slot(tenant_id, slot_id, booking_date, user_id)` enforces:
- UNIQUE constraint: `UNIQUE(tenant_id, slot_id, booking_date)`
- Atomic insert via `INSERT ... SELECT` transaction
- Returns booking ID on success; raises exception if conflict detected

Trigger `check_booking_conflict` (before insert) double-checks conflict and rejects if race condition detected.

**Integration Point:** RLS queries from Flutter client automatically filter by JWT `tenant_id`. No application logic required; database enforces isolation.

---

### Layer 2: Auth (Supabase Auth + JWT Custom Claims)

**Responsibility:** Authenticate users; inject `tenant_id` into JWT; provide session management.

**Flow:**

```
1. User signs up: signUp(email, password, tenant_id)
   → Supabase Auth creates auth.users record
   → Auth service triggers custom access token hook

2. Custom Access Token Hook (Edge Function)
   → Queries: SELECT tenant_id FROM memberships WHERE user_id = auth.uid()
   → Injects claim: { "sub": "user-uuid", "tenant_id": "tenant-uuid", ... }
   → Issues JWT with custom claim

3. JWT issued to client
   → Contains: { iss, aud, exp, iat, sub, auth_time, tenant_id, ... }

4. Client stores JWT in session storage
   → Used for all Supabase queries via Authorization: Bearer {jwt}

5. RLS policies evaluate claim: auth.jwt()->'tenant_id' = row.tenant_id
   → Database enforces isolation at query time
```

**Custom Claim Injection Approach:**

Auth hook uses `app_metadata` (not `user_metadata`) because:
- `app_metadata`: Server-controlled, cannot be modified by client → suitable for authorization claims
- `user_metadata`: User-modifiable → NOT trusted for security decisions

**Integration Point:** JWT claim `tenant_id` is the only way database knows which tenant a query belongs to. No token ever contains service role key or admin credentials.

---

### Layer 3: Flutter Mini-App

**Responsibility:** Demonstrate authenticated queries respecting RLS; verify Realtime filtering.

**Components:**

#### AuthCubit
```
States: [Uninitialized → Loading → Authenticated(user, tenantId) → Unauthenticated → Error]
```
- Manages signUp, signIn, logout
- Decodes JWT from `supabaseClient.auth.currentSession?.accessToken`
- Extracts and stores `tenant_id` from decoded JWT claims
- Persists session across app restarts

#### SlotsRepository
```dart
Future<List<Slot>> getSlots() async {
  // No .eq('tenant_id', ...) required — RLS handles it automatically
  return supabaseClient
      .from('slots')
      .select()
      .order('start_time');  // Only returns slots for logged-in user's tenant
}
```

#### BookingsRepository
```dart
Future<void> bookSlot(slotId, date) async {
  // Calls Postgres function — function enforces UNIQUE constraint
  final result = await supabaseClient.rpc('book_slot', params: {
    'slot_id': slotId,
    'booking_date': date,
    'user_id': currentUser.id,  // Server derives tenant_id from JWT
  });
  return result['booking_id'];
}
```

#### RealtimeBookings Widget
```dart
StreamBuilder(
  stream: supabaseClient
      .from('bookings')
      .on(RealtimeListenTypes.all, ...)
      .stream(),
  // Realtime respects RLS — only updates for current user's tenant received
  builder: (context, snapshot) { ... }
)
```

**Integration Point:** All queries implicitly filter by user's `tenant_id` via RLS. App never needs to attach `.eq('tenant_id', ...)`. This proves RLS is working and eliminates tenant_id filter errors at app level.

---

### Layer 4: Testing & Validation

**Responsibility:** Provide evidence of security (RLS isolation) and correctness (anti-double-booking).

#### RLS Isolation Tests (SQL)
```sql
-- rls_cross_tenant_attack.sql
-- Setup: Two tenants, User A in Tenant 1, User B in Tenant 2
-- Attack: User A tries to SELECT slots belonging to Tenant 2
-- Expected: Returns 0 rows (RLS blocks access)
-- Result: [PASS | FAIL] — documented in decision doc
```

#### Anti-Double-Booking Tests (SQL)
```sql
-- book_slot_concurrency.sql
-- Setup: One slot (tenant=T1, date=2026-06-15)
-- Attack: 5 concurrent transactions, all try to book the same slot
-- Expected: 1 succeeds, 4 fail with UNIQUE constraint violation
-- Result: [PASS | FAIL] — timing and error messages logged
```

#### Flutter Integration Tests
```dart
// supabase_integration_test.dart
test('logged-in user queries only own tenant slots', () async {
  // 1. Sign in as User A (Tenant 1)
  // 2. Query slots
  // 3. Assert all returned slots belong to Tenant 1
  // 4. Sign in as User B (Tenant 2)
  // 5. Query slots
  // 6. Assert all returned slots belong to Tenant 2 (different from User A's)
});

test('booking realtime respects RLS', () async {
  // 1. Open realtime subscription as User A
  // 2. Trigger booking update in Tenant 2 via separate client
  // 3. Assert User A's stream does NOT receive update
});
```

**Integration Point:** Tests provide proof-of-security for decision doc. Each test can succeed or fail; failures are documented in risk assessment.

---

## Build Order & Dependencies

Build must respect this strict dependency order. Each phase blocks the next.

### Phase 1: Database Schema & RLS (Week 1, Day 1–2)
**Blockers:** None  
**Outputs:** `init.sql`, `rls_policies.sql` deployed to Supabase  
**Validates:** Schema compiles; RLS policies syntactically correct

**Steps:**
1. Create Supabase project (manual, takes ~2 min)
2. Run `init.sql` → creates tables, foreign keys, indexes
3. Run `rls_policies.sql` → enables RLS on all tables, creates policies
4. Run `seed_test_data.sql` → 3 tenants, 6 users, test slots
5. Verify schema in Supabase dashboard

### Phase 2: Anti-Double-Booking Function & Tests (Week 1, Day 3)
**Blockers:** Phase 1 (schema must exist)  
**Outputs:** `anti_double_booking.sql`, `book_slot_concurrency.sql` PASS  
**Validates:** Function handles concurrent writes correctly

**Steps:**
1. Deploy `anti_double_booking.sql` → `book_slot()` function + trigger
2. Run `book_slot_concurrency.sql` → 5 concurrent inserts, 1 succeeds
3. Document timing and error messages
4. If FAIL: debug and retry; if PASS: proceed

### Phase 3: Auth Hook Edge Function (Week 1, Day 4)
**Blockers:** Phase 1 (schema must exist; need user records)  
**Outputs:** Edge Function deployed, test JWT contains `tenant_id` claim  
**Validates:** Custom claim injection working

**Steps:**
1. Deploy `auth_hook_tenant_id.ts` to Supabase Edge Functions
2. Create test user via Supabase Auth dashboard
3. Trigger sign-in flow manually
4. Decode JWT: `jwt_decode(token)` — verify `tenant_id` present
5. If missing: debug hook; if present: proceed

### Phase 4: Flutter Mini-App & RLS Integration Tests (Week 2, Day 1–3)
**Blockers:** Phase 2 (book_slot must work) + Phase 3 (Auth hook must inject tenant_id)  
**Outputs:** Flutter app boots, logs in, queries slots (RLS filters); `supabase_integration_test.dart` PASS  
**Validates:** RLS policies work end-to-end from Flutter client

**Steps:**
1. Create `flutter_app/pubspec.yaml` — include `supabase_flutter` + dependencies
2. Implement `AuthCubit` + `SlotsRepository` + login screen
3. Run Flutter app, sign in as test user
4. In Slots screen: verify only slots from user's tenant displayed
5. Run `rls_cross_tenant_attack.sql` — User A tries to query Tenant 2 data
6. If RLS blocks: proceed; if exposed: debug policy, repeat

### Phase 5: Realtime Subscription Testing (Week 2, Day 4)
**Blockers:** Phase 4 (Flutter app connected) + RLS policies working  
**Outputs:** `realtime_bookings.dart` subscribes; `realtime_rls_filter.sql` PASS  
**Validates:** Realtime respects RLS (updates for other tenants not delivered)

**Steps:**
1. Implement `RealtimeBookings` widget in Flutter app
2. Open realtime subscription as User A
3. Trigger booking change in Tenant 2 (background client)
4. Assert User A's stream does NOT update
5. If stream updates: Realtime not respecting RLS (critical issue); if silent: proceed

### Phase 6: Decision Document (Week 3, Day 1)
**Blockers:** All previous phases must complete (pass or fail documented)  
**Outputs:** `DECISION.md` with go/no-go recommendation  
**Validates:** Evidence collected, risks assessed, recommendation clear

**Steps:**
1. Gather all test results: RLS isolation (PASS/FAIL), anti-double-booking (PASS/FAIL), Flutter integration (PASS/FAIL)
2. Assess risks: password migration (Firebase→Supabase), Realtime under load
3. Write decision: GO (if all PASS + risks acceptable) or NO-GO (if critical failure)
4. Present to team

---

## Dependency Graph

```
Phase 1 (Schema + RLS)
    ↓
Phase 2 (book_slot function) ——→ Phase 4 (Flutter)
    ↓                                ↑
Phase 3 (Auth Hook) ———————————————→ Phase 5 (Realtime)
                                    ↑
                              All Phases
                                    ↓
                          Phase 6 (Decision Doc)
```

**Critical Path:**
- Schema (1–2 days)
- Auth Hook (1 day) — *can run in parallel with Phase 2*
- Flutter integration (2–3 days)
- Realtime validation (1 day)
- **Total: ~5–6 days elapsed**

---

## Credentials & Environment Variables

### Security Model

- **Service Role Key** — NEVER stored in app, NEVER in git
  - Used only on backend Edge Functions (during auth hook)
  - Stored in Supabase console (not in spike repo)

- **Anon Key** — Safe for public client
  - Included in app; scoped by RLS policies, not by key permissions
  - RLS policies (not API key scopes) determine what user can access

- **JWT** — Issued to client, contains `tenant_id` claim
  - Used by RLS policies to filter queries
  - Never hardcoded; derived from Auth session

### .env File

```bash
# .env.example (checked in)
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=eyJ...abc  # Public; safe to expose in Flutter app

# .env (gitignored — Flutter dev only)
SUPABASE_URL=https://...
SUPABASE_ANON_KEY=...

# SERVICE_ROLE_KEY (for Edge Function only, not in spike repo)
# Kept in Supabase dashboard; accessed via CLI during deployment
```

### Flutter Initialization

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  const url = String.fromEnvironment('SUPABASE_URL');
  
  await Supabase.initialize(url: url, anonKey: anonKey);
  
  runApp(const MyApp());
}
```

**Never use dart-define for sensitive credentials. Use `.env` + flutter_dotenv or String.fromEnvironment() only for non-secret config.**

---

## Critical Integration Points

### 1. RLS Policies ↔ Flutter Queries (No Application Filter Needed)

**Before (Firebase):**
```dart
// Application layer enforces tenant isolation
final bookings = await firestore
    .collection('bookings')
    .where('tenant_id', isEqualTo: currentTenantId)  // Manual filter
    .get();
```

**After (Supabase + RLS):**
```dart
// Database layer enforces isolation; app just queries
final bookings = await supabaseClient
    .from('bookings')
    .select();  // RLS automatically filters by auth.jwt()->'tenant_id'
```

**Impact:** Eliminates entire class of bugs (forgetting `.eq('tenant_id', ...)`). Database is source of truth for access control.

---

### 2. Auth Hook ↔ JWT Custom Claims ↔ RLS Policies

**Flow:**
```
signUp(email, password, tenant_id)
  → Supabase Auth creates user record
  → Auth hook Edge Function runs (5-second timeout)
  → Hook queries: SELECT tenant_id FROM memberships WHERE user_id = auth.uid()
  → Hook injects: { "tenant_id": "..." } into JWT
  → JWT returned to client
  → Client stores JWT in session
  → All subsequent queries include JWT
  → RLS policies evaluate: auth.jwt()->'tenant_id' vs row.tenant_id
  → Rows not matching user's tenant filtered out at database level
```

**Critical:** If auth hook fails or doesn't inject tenant_id, RLS policies will fail to evaluate correctly. Test this in Phase 3.

---

### 3. book_slot() Function ↔ Realtime Trigger

**Scenario:** Two users try to book the same slot simultaneously.

```
User A calls book_slot(slot_id=123, date=2026-06-15)
  → Function executes: INSERT INTO bookings WHERE UNIQUE(tenant_id, slot_id, date)
  → Database constraint violation → transaction aborts
  → Function raises exception
  → Flutter app catches error, shows "Slot already booked"

Simultaneously: Realtime subscription triggers
  → postgres_changes event: INSERT bookings row
  → Realtime checks: Should User B receive this change?
  → Evaluates RLS: Is this booking in User B's tenant?
  → If NO → event filtered out, User B doesn't know
  → If YES → event delivered, User B's UI updates
```

**Impact:** Realtime events are RLS-filtered before delivery. This proves RLS is active and working in real-time context (not just query time).

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why Bad | What to Do Instead |
|--------------|---------|-------------------|
| Storing `tenant_id` in `user_metadata` | User can modify; not secure for authorization | Use `app_metadata` (server-controlled) OR inject into JWT via auth hook |
| Hardcoding `tenant_id` in queries | Defeats RLS; ignores user's actual tenant | Remove filter; let RLS policies enforce isolation |
| Using service role key in Flutter app | Bypasses all RLS; exposes data to all users | Use anon key + RLS policies; keep service key server-only |
| Skipping RLS on `users` or `memberships` tables | Allows users to see/modify each other's records | Enable RLS on ALL tables; implement UPDATE policy: `auth.uid() = id` |
| Not indexing `tenant_id` in RLS policies | Query performance degrades at scale (3+ min queries) | Add index: `CREATE INDEX ON bookings(tenant_id, booking_date)` |

---

## Sources

- [Supabase RLS Best Practices: Production Patterns for Secure Multi-Tenant Apps](https://makerkit.dev/blog/tutorials/supabase-rls-best-practices)
- [Enforcing Row Level Security in Supabase: A Deep Dive into LockIn's Multi-Tenant Architecture - DEV Community](https://dev.to/blackie360/-enforcing-row-level-security-in-supabase-a-deep-dive-into-lockins-multi-tenant-architecture-4hd2)
- [Supabase Row Level Security Guide](https://designrevision.com/blog/supabase-row-level-security)
- [Supabase Multi-Tenancy Guide - Bootstrapped](https://bootstrapped.app/guide/how-to-set-up-supabase-with-a-multi-tenant-architecture)
- [Implementing Multi-Tenant Authentication Using Supabase in Flutter](https://vibe-studio.ai/insights/implementing-multi-tenant-authentication-using-supabase-in-flutter)
- [Supabase Auth Advanced — Custom Claims and RLS - DEV Community](https://dev.to/kanta13jp1/supabase-auth-advanced-custom-claims-row-level-security-and-session-management-32di)
- [Realtime Authorization - Supabase Docs](https://supabase.com/docs/guides/realtime/authorization)
- [How Supabase auth, RLS and real-time works - Hrekov Blog](https://hrekov.com/blog/supabase-auth-rls-real-time)
- [Supabase Edge Functions & Auth Hooks - Restack Docs](https://www.restack.io/docs/supabase-knowledge-supabase-edge-functions-auth)
- [Flutter Authorization with RLS - Supabase Blog](https://supabase.com/blog/flutter-authorization-with-rls)
- [Multi-Tenant Authentication with Supabase: A Production Implementation - Medium](https://medium.com/@kriryk/multi-tenant-authentication-with-supabase-a-production-implementation-0f6064f50d55)
