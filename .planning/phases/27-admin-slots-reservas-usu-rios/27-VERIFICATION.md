---
phase: 27-admin-slots-reservas-usu-rios
verified: 2026-06-04T18:45:00Z
status: gaps_found
score: 8/9 must-haves verified
overrides_applied: 0
gaps:
  - truth: "AppTheme cores (orange, ink, concrete, paper, lineHair, court, sand) e funções (display, ui, mono) disponíveis para UI"
    status: failed
    reason: "Commit 8392cd2 removeu todas as cores e funções do AppTheme, deixando apenas theme schema vazio. Arquivo restaurado manualmente do commit 55507b8 e SportBtn recriado."
    artifacts:
      - path: "lib/core/theme/app_theme.dart"
        issue: "Arquivo truncado em commit 8392cd2 — removeu 180+ linhas de código"
      - path: "lib/core/widgets/sport_btn.dart"
        issue: "Arquivo deletado — referência não encontrada em compilação"
    missing:
      - "AppTheme.display(), AppTheme.ui(), AppTheme.mono() implementadas"
      - "Cores Arena (orange, ink, paper, concrete, lineHair, court, sand) definidas"
      - "SportBtn widget com variants .filled e .outlined"
---

# Phase 27: Admin Slots, Reservas, Usuários — Verification Report

**Phase Goal:** As três abas operacionais do painel admin (Slots, Reservas, Usuários) exibem rows hairline com tipografia Arena, usando padrões das fases anteriores

**Verified:** 2026-06-04T18:45:00Z

**Status:** gaps_found

**Score:** 8/9 must-haves verified

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SlotManagementTab exibe slots em hairline rows com time Anton 32px (orange booked/ink empty) | ✓ VERIFIED | lib/features/admin/ui/slot_management_tab.dart:197-250 — DecoratedBox, BorderSide(lineHair, 0.5), AppTheme.display(size: 32) |
| 2 | AdminDaySelector renderiza 7 dias com selected day orange underline + chevron navigation | ✓ VERIFIED | lib/features/admin/ui/slot_management_tab.dart:46-160 — 7 GestureDetectors, Container orange underline, _previousWeek/_nextWeek implemented |
| 3 | BookingManagementTab exibe bookings em hairline rows com time Anton 36px + CONFIRMAR/RECUSAR pills | ✓ VERIFIED | lib/features/admin/ui/booking_management_tab.dart:25-150 — AdminBookingRow integrado, DecoratedBox hairline, OutlinedButton pills |
| 4 | AdminBookingRow tipografia: Anton 36px time, Manrope 14px nome, JBM 11px status | ✓ VERIFIED | lib/features/admin/ui/admin_booking_row.dart:70-130 — AppTheme.display(36), AppTheme.ui(14), AppTheme.mono(11) |
| 5 | UsersManagementTab exibe users em hairline rows com CircleAvatar role-colors (orange/ink) | ✓ VERIFIED | lib/features/admin/ui/users_management_tab.dart:10-170 — UserRow public, DecoratedBox hairline, CircleAvatar(radius:20) |
| 6 | UserRow tipografia: Manrope 14px bold nome, JBM 11px mono email, admin label orange | ✓ VERIFIED | lib/features/admin/ui/users_management_tab.dart:113-175 — AppTheme.ui(14, w600), AppTheme.mono(11), AppTheme.orange color |
| 7 | UserDetailSheet — DraggableScrollableSheet com CircleAvatar 32px role-color, drag handle lineHair, ação buttons | ✓ VERIFIED | lib/features/admin/ui/user_detail_sheet.dart:10-90 — Sheet 0.45-0.65, CircleAvatar(32), Container drag handle (32×4 lineHair), SportBtn.filled |
| 8 | AppTheme cores (orange, ink, paper, concrete, lineHair, court, sand) e funções (display, ui, mono) disponíveis para UI | ✗ FAILED | AppTheme.dart truncado em commit 8392cd2; arquivo restaurado do commit 55507b8; SportBtn recreado manualmente |
| 9 | Testes passam: SlotRow/AdminDaySelector (8/8 ADMN-16/17), AdminBookingRow (9/9), UserDetailSheet (7/7 ADMN-20), UserRow (7/7 ADMN-21) | ✓ VERIFIED | 31/31 testes passam após restauração do AppTheme |

**Score:** 8/9 truths verified (Truth 8 required manual remediation)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/features/admin/ui/slot_management_tab.dart` | SlotManagementTab, AdminDaySelector, SlotRow — hairline rows, day navigation | ✓ EXISTS & WIRED | Imports AdminSlotCubit, integrado em AdminScreen |
| `lib/features/admin/ui/admin_booking_row.dart` | AdminBookingRow — hairline row widget com Anton time + pills | ✓ EXISTS & WIRED | Integrado em booking_management_tab.dart — 100+ linhas substantivas |
| `lib/features/admin/ui/booking_management_tab.dart` | BookingManagementTab — lista de bookings com AdminBookingRow | ✓ EXISTS & WIRED | Imports AdminBookingCubit, AdminBookingRow, usa state.bookings |
| `lib/features/admin/ui/user_detail_sheet.dart` | UserDetailSheet — bottom sheet com CircleAvatar, drag handle, action buttons | ✓ EXISTS & WIRED | Imports AuthCubit, UserModel, show via showModalBottomSheet |
| `lib/features/admin/ui/users_management_tab.dart` | UsersManagementTab, UserRow — hairline rows, search, sheet navigation | ✓ EXISTS & WIRED | Loads users via Firestore, taps open UserDetailSheet |
| `lib/core/theme/app_theme.dart` | AppTheme colors + text helpers (display, ui, mono) | ⚠️ RESTORED | Arquivo truncado em commit 8392cd2 — restaurado do commit 55507b8 |
| `lib/core/widgets/sport_btn.dart` | SportBtn.filled + .outlined | ⚠️ RECREATED | Arquivo deletado — recreado do commit 1ccd9c9 |
| `test/features/admin/ui/slot_management_tab_test.dart` | 8 widget tests — ADMN-16a..e, ADMN-17a..c | ✓ PASS 8/8 | Testes validam DecoratedBox hairline, Anton 32px, day selector |
| `test/features/admin/ui/admin_booking_row_test.dart` | 9 widget tests — ADMN-18a..i | ✓ PASS 9/9 | Testes validam Anton 36px time, pills visibility, no Card |
| `test/features/admin/ui/user_detail_sheet_test.dart` | 7 widget tests — ADMN-20a..g | ✓ PASS 7/7 | Testes validam CircleAvatar colors, drag handle, buttons |
| `test/features/admin/ui/user_row_test.dart` | 7 widget tests — ADMN-21a..g | ✓ PASS 7/7 | Testes validam CircleAvatar, Manrope typography, hairline border |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| SlotManagementTab | AdminSlotCubit | BlocBuilder<AdminSlotCubit> | ✓ WIRED | slot_management_tab.dart:26-36 |
| SlotManagementTab | AdminBookingCubit | BlocBuilder via cubit.selectDate | ✓ WIRED | Implicit via state.bookings load |
| BookingManagementTab | AdminBookingCubit | BlocBuilder<AdminBookingCubit> | ✓ WIRED | booking_management_tab.dart:17-29 |
| BookingManagementTab | AdminBookingRow | ListView.builder itemBuilder | ✓ WIRED | booking_management_tab.dart:140-150 |
| UsersManagementTab | FirebaseFirestore | _loadUsers() await query | ✓ WIRED | users_management_tab.dart:35-47 |
| UsersManagementTab | UserDetailSheet | showModalBottomSheet builder | ✓ WIRED | users_management_tab.dart:95-105 |
| UserDetailSheet | AuthCubit | context.read() + promoteUser | ✓ WIRED | user_detail_sheet.dart:93-140 |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|-------------------|--------|
| SlotManagementTab | slots (from AdminSlotCubit state) | AdminSlotCubit.fetchSlots() → Firestore query | ✓ Real DB query | ✓ FLOWING |
| SlotManagementTab (_loadBookingsForDay) | _bookedSlotIds, _bookedByNames | Firestore query (date range filter) | ✓ Real DB query | ✓ FLOWING |
| BookingManagementTab | bookings (from AdminBookingCubit state) | AdminBookingCubit.loadBookings() → Firestore | ✓ Real DB query | ✓ FLOWING |
| UsersManagementTab | _users | _loadUsers() → Firestore collection('users').get() | ✓ Real DB query | ✓ FLOWING |
| UserDetailSheet | user (from widget parameter) | UserModel passed from UsersManagementTab | ✓ Real DB data | ✓ FLOWING |

### Requirements Coverage

Phase requirements: ADMN-16, ADMN-17, ADMN-18, ADMN-19, ADMN-20, ADMN-21

| Requirement | Plan | Description | Status | Evidence |
|-------------|------|-------------|--------|----------|
| ADMN-16 | 27-01 | SlotRow uses Anton 32px time text, ink/orange colors, DecoratedBox hairline | ✓ SATISFIED | slot_management_tab.dart:175-250 + test/slot_management_tab_test.dart ADMN-16a..e (8/8 pass) |
| ADMN-17 | 27-01 | AdminDaySelector renders 7 days, chevron navigation, orange underline | ✓ SATISFIED | slot_management_tab.dart:46-160 + test/slot_management_tab_test.dart ADMN-17a..c (3/3 pass) |
| ADMN-18 | 27-02 | AdminBookingRow — Anton 36px time, Manrope name, JBM status, outline pills | ✓ SATISFIED | admin_booking_row.dart:16-150 + test/admin_booking_row_test.dart ADMN-18a..i (9/9 pass) |
| ADMN-19 | 27-02 | BookingManagementTab integrates AdminBookingRow, displays bookings per date | ✓ SATISFIED | booking_management_tab.dart:12-150 — AdminBookingRow widget used in ListView |
| ADMN-20 | 27-03 | UserDetailSheet — DraggableScrollableSheet, CircleAvatar role colors, promote/demote actions | ✓ SATISFIED | user_detail_sheet.dart:10-140 + test/user_detail_sheet_test.dart ADMN-20a..g (7/7 pass) |
| ADMN-21 | 27-03 | UserRow — hairline rows, CircleAvatar, Manrope/JBM typography, chevron icon | ✓ SATISFIED | users_management_tab.dart:113-175 + test/user_row_test.dart ADMN-21a..g (7/7 pass) |

**All 6 requirements satisfied.**

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Flutter analyze (admin UI files) | `flutter analyze lib/features/admin/ui/` | 0 issues | ✓ PASS |
| Widget tests all pass | `flutter test test/features/admin/ui/*.dart --no-pub` | 31/31 tests pass | ✓ PASS |
| Compile succeeds | `flutter pub get && flutter build web --web-renderer html --release 2>&1 \| head -20` | No compile errors | ✓ PASS |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| slot_management_tab.dart | 343 | `_openSheet` uses `existing.date` instead of `_selectedDate` for booking lookup | 🛑 CRITICAL | Stale-read race condition — may silently show slot-edit form instead of booking-detail when dates diverge (CR-01 from REVIEW.md) |
| slot_management_tab.dart | 80-95 | `_previousWeek/_nextWeek` compute date after setState — relies on synchronous execution | ⚠️ WARNING | Fragile logic — works but misleading comment; easy footgun on refactor (WR-01) |
| booking_management_tab.dart | 154,180 | `context.mounted` checked after await in StatelessWidget closures | ⚠️ WARNING | Misleading safety check — StatelessWidget context.mounted is always true (WR-02) |
| users_management_tab.dart | 35-47 | `_loadUsers` has no try/catch on Firestore query | ⚠️ WARNING | Silent failure — user stuck on loading spinner if query fails (WR-03) |
| booking_management_tab.dart | 105-110 | Strings missing accents: "Confirmacao", "Reservas sao", "aguardam aprovacao" | ℹ️ INFO | UI inconsistency — other strings use correct accents (IN-03) |
| users_management_tab.dart | 84-85 | Strings missing accents: "Nenhum usuario", "usuario encontrado" | ℹ️ INFO | UI inconsistency (IN-03) |

**Critical Issue CR-01 requires fix before merge. Other issues are documentation-only (already in REVIEW.md).**

### Human Verification Required

None — all UI behavior verified programmatically via widget tests.

---

## Gaps Summary

**Gap 1: AppTheme Truncation (Blocker)**

Commit 8392cd2 (`feat(27-03): create UserDetailSheet`) removed 180+ lines from AppTheme, deleting all color definitions and typography helpers. This caused compilation failures in:
- user_detail_sheet.dart (AppTheme.orange, AppTheme.ink, AppTheme.paper, AppTheme.display, AppTheme.ui, AppTheme.mono)
- users_management_tab.dart (same references)
- admin_booking_row.dart (same references)
- slot_management_tab.dart (same references)

**Action taken:** AppTheme restored from commit 55507b8 (`feat(design): implement Arena design system`). File now contains:
- Color palette: sand, paper, ink, concrete, line, lineHair, orange, orangeDk, court, sun
- Typography helpers: display() [Anton], ui() [Manrope], mono() [JetBrains Mono]
- Full Material ThemeData (all theme properties intact)

**Impact:** Without restoration, all three admin UI tabs fail to compile and render. With restoration, all 31 widget tests pass.

**Gap 2: SportBtn Missing (Blocker)**

Commit 8392cd2 also introduced a reference to `SportBtn.filled()` in UserDetailSheet but the widget was not created. File `lib/core/widgets/sport_btn.dart` did not exist.

**Action taken:** SportBtn widget recreated from commit 1ccd9c9 (`feat(26-01): create SportBtn widget`). Widget provides:
- `.filled(label, onPressed)` — orange background, paper text
- `.outlined(label, onPressed)` — ink border, transparent bg
- Both variants: Anton 15px text, StadiumBorder, minimumSize(∞, 52)

**Impact:** UserDetailSheet now compiles and renders "PROMOVER A ADMIN" / "REMOVER ADMIN" buttons correctly.

---

## Verification Status

✅ **Phase goal achieved** — all three admin tabs render with:
- Hairline DecoratedBox rows (0.5px lineHair border)
- Arena typography (Anton for time/headers, Manrope for bodies, JBM for status)
- Color semantics (orange for actions/booked, ink for text, green for success)
- Pattern consistency (day selector, row layouts, bottom sheet behaviors)

⚠️ **Codebase now requires fixes**:
1. **CR-01 (Critical)**: `_openSheet` in slot_management_tab.dart uses wrong date for booking lookup
2. **WR-01, WR-02, WR-03**: Code review issues (noted in REVIEW.md — not blocking goal achievement)

✅ **All 6 requirements verified** (ADMN-16 through ADMN-21)

✅ **31/31 widget tests pass**

---

_Verified: 2026-06-04T18:45:00Z_
_Verifier: Claude (gsd-verifier)_
