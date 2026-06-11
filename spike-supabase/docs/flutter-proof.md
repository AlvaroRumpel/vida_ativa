# SPIKE-08: Flutter Proof

**Date:** [fill after run]
**Flutter version:** [fill after run — `flutter --version`]
**Supabase project:** fasirsbiadcchfgvktzt (staging)

## Proof Results

### Auth
| Account | tenant_id in JWT | Result |
|---------|-----------------|--------|
| testclient@spike.local | [fill] | PASS / FAIL |
| testadmin@spike.local | [fill] | PASS / FAIL |

### RLS Slots (no .eq() filter)
| Account | Slot Count | Query |
|---------|-----------|-------|
| tenant_1 (testclient) | [fill] | `supabase.from('slots').select()` |
| tenant_2 (testadmin) | [fill] | `supabase.from('slots').select()` |

**Delta:** [count_1 vs count_2 — proves RLS filters automatically]

### book_slot() RPC
| Param | Value |
|-------|-------|
| p_slot_id | 12000000-0000-0000-0000-000000000001 |
| p_booking_date | 2099-12-31 |
| Result | success=[fill], error_code=[fill], booking_id=[fill] |

## SPIKE-13 Audit
```
grep -r 'sb_secret\|service_role' spike-supabase/flutter_app/ || echo PASS
```
Result: [fill — must be PASS]

## Run Command
```bash
cd spike-supabase/flutter_app
flutter pub get
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://fasirsbiadcchfgvktzt.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY \
  --dart-define=TEST_EMAIL_1=testclient@spike.local \
  --dart-define=TEST_PASSWORD_1=$TEST_PASSWORD_1 \
  --dart-define=TEST_EMAIL_2=testadmin@spike.local \
  --dart-define=TEST_PASSWORD_2=$TEST_PASSWORD_2
```
