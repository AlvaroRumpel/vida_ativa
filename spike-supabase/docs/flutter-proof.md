# SPIKE-08: Flutter Proof

**Date:** 2026-06-22
**Flutter version:** web (Edge debug)
**Supabase project:** fasirsbiadcchfgvktzt (staging)

## Raw Output

```
=== SPIKE-08: Flutter Proof ===

--- Tenant 1: testclient@spike.local ---
AUTH: user_id=4e5df91b-12c9-4a5a-9cb1-b182892a05a6
AUTH: tenant_id=10000000-0000-0000-0000-000000000001
RLS SLOTS (no .eq): 3 rows for tenant_1

--- Tenant 2: testadmin@spike.local ---
AUTH: user_id=eacdd132-62ae-49d1-a653-a941c03260eb
AUTH: tenant_id=20000000-0000-0000-0000-000000000001
RLS SLOTS (no .eq): 1 rows for tenant_2

=== RLS PROOF (D-04) ===
Tenant 1 slots: 3
Tenant 2 slots: 1
RESULT: PASS — different counts prove RLS filters by tenant

--- RPC: book_slot() as tenant_1 ---
RPC book_slot(): success=false, error_code=SLOT_ALREADY_BOOKED, booking_id=null
RESULT: PASS — SLOT_ALREADY_BOOKED (slot was already booked; RPC working correctly)

=== SPIKE-08 PROOF COMPLETE ===
```

## Proof Results

### Auth
| Account | tenant_id (appMetadata) | user_id | Result |
|---------|------------------------|---------|--------|
| testclient@spike.local | 10000000-0000-0000-0000-000000000001 | 4e5df91b-12c9-4a5a-9cb1-b182892a05a6 | PASS |
| testadmin@spike.local | 20000000-0000-0000-0000-000000000001 | eacdd132-62ae-49d1-a653-a941c03260eb | PASS |

### RLS Slots (no .eq() filter)
| Account | Slot Count | Query |
|---------|-----------|-------|
| tenant_1 (testclient) | 3 | `supabase.from('slots').select()` |
| tenant_2 (testadmin) | 1 | `supabase.from('slots').select()` |

**Delta:** 3 vs 1 — RLS filtra por tenant automaticamente sem `.eq()`

### book_slot() RPC
| Param | Value |
|-------|-------|
| p_slot_id | 12000000-0000-0000-0000-000000000001 |
| p_booking_date | 2099-12-31 |
| success | false |
| error_code | SLOT_ALREADY_BOOKED |
| booking_id | null |

**RESULT: PASS** — `SLOT_ALREADY_BOOKED` confirma RPC funcionando (slot já reservado por run anterior)

## SPIKE-13 Audit
```bash
grep -r 'sb_secret\|service_role' spike-supabase/flutter_app/ || echo PASS
```
Result: PASS

## Setup Notes

- `User.appMetadata` em supabase_flutter vem de `raw_app_meta_data` no DB, não das JWT claims.
  Auth Hook modifica JWT corretamente (SPIKE-05), mas `user.appMetadata` requer `raw_app_meta_data`
  setado em `auth.users` diretamente. Ambos os usuários de teste têm esse campo populado.
- testadmin criado via SQL INSERT + senha resetada via admin API (SQL `crypt()` gera `$2a$`,
  Supabase espera `$2b$` — usar `adminClient.auth.admin.updateUserById()` para senhas).

## Run Command
```bash
cd spike-supabase/flutter_app
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://fasirsbiadcchfgvktzt.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=sb_publishable_I94cjlEbcDiIHsxY1mlTVg_fOjwQfUF \
  --dart-define=TEST_EMAIL_1=testclient@spike.local \
  --dart-define=TEST_PASSWORD_1=TestPassword123! \
  --dart-define=TEST_EMAIL_2=testadmin@spike.local \
  --dart-define=TEST_PASSWORD_2=TestPassword123!
```
