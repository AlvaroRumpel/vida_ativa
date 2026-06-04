---
phase: 27-admin-slots-reservas-usu-rios
plan: "03"
subsystem: admin-ui
tags: [users, admin, bottom-sheet, hairline-rows, tdd]
dependency_graph:
  requires: []
  provides: [UserDetailSheet, UserRow]
  affects: [users_management_tab.dart]
tech_stack:
  added: []
  patterns: [DraggableScrollableSheet, DecoratedBox-hairline, BlocProvider.value]
key_files:
  created:
    - lib/features/admin/ui/user_detail_sheet.dart
    - test/features/admin/ui/user_detail_sheet_test.dart
    - test/features/admin/ui/user_row_test.dart
  modified:
    - lib/features/admin/ui/users_management_tab.dart
decisions:
  - "UserRow exported as public class (not _private) to enable widget testing without Firestore mocking"
  - "demoteUser implemented inline via Firestore SDK (AuthCubit has no demoteUser method)"
  - "Sheet reload after close: .then((_) => _loadUsers()) so role changes reflect immediately"
metrics:
  duration: "~20min"
  completed_date: "2026-06-04"
  tasks_completed: 2
  files_changed: 4
---

# Phase 27 Plan 03: UserDetailSheet + UsersManagementTab Hairline Redesign Summary

**One-liner:** Arena bottom sheet with CircleAvatar role-colors (orange admin / ink client) and hairline row list replacing ListTile + primaryGreen promote button.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create UserDetailSheet | 8392cd2 | user_detail_sheet.dart, user_detail_sheet_test.dart |
| 2 | Rewrite UsersManagementTab | e1c1d69 | users_management_tab.dart, user_row_test.dart |

## What Was Built

### Task 1: UserDetailSheet (8392cd2)

New bottom sheet (`DraggableScrollableSheet`) for user role management:
- Drag handle: `Container(width: 32, height: 4, color: AppTheme.lineHair)`
- `CircleAvatar(radius: 32)` — orange bg for admin, ink bg for client
- Initial letter using `AppTheme.display(size: 32, color: AppTheme.paper)`
- `displayName` Manrope 14px w700, `email` JBM mono 11px
- `SportBtn.filled('PROMOVER A ADMIN')` or `SportBtn.filled('REMOVER ADMIN')`
- `AlertDialog` confirmation before action (T-27-03-02 repudiation mitigation)
- Promote: `AuthCubit.promoteUser(uid)` — Demote: inline Firestore `update({'role': 'client'})`
- `SnackHelper.success/error` feedback, `Navigator.pop(context)` on success

### Task 2: UsersManagementTab Redesign (e1c1d69)

`UsersManagementTab` rewritten — `ListTile` and `primaryGreen` removed:
- New public `UserRow` widget (exported for testability)
- `DecoratedBox` hairline: `BorderSide(color: AppTheme.lineHair, width: 0.5)` for `index > 0`
- `CircleAvatar(radius: 20)` — orange/ink role colors
- `displayName` Manrope 14px w600, `email` JBM 11px mono
- Admin label in `AppTheme.mono(size: 11, color: AppTheme.orange)` 
- `Icons.chevron_right` trailing icon
- Tap: `showModalBottomSheet` → `UserDetailSheet` wrapped in `BlocProvider.value`
- Sheet close triggers `_loadUsers()` to refresh role changes
- Search field preserved (functional), `OutlineInputBorder` removed

## Test Coverage

- `user_detail_sheet_test.dart`: 7 tests — ADMN-20a..g (all pass)
- `user_row_test.dart`: 7 tests — ADMN-21a..g (all pass)

## Deviations from Plan

### Auto-fixed Issues

None — plan executed exactly as written.

### Design Decisions Made

**1. UserRow as public class (not `_UserRow` private)**
- Plan specified private `_UserRow`
- Changed to public `UserRow` to enable widget testing without Firestore mocking
- Naming is still descriptive and scoped (exported from users_management_tab.dart)

**2. demoteUser inline (no AuthCubit method)**
- Plan noted this explicitly: `demoteUser` does not exist in AuthCubit
- Implemented inline: `FirebaseFirestore.instance.collection('users').doc(uid).update({'role': 'client'})`
- Consistent with plan spec

## Known Stubs

None.

## Threat Flags

None — no new network endpoints or auth paths introduced beyond what the plan's threat model covers. All Firestore writes are gated by existing security rules requiring `request.auth.token.role == 'admin'` (T-27-03-01).

## Self-Check: PASSED

- `lib/features/admin/ui/user_detail_sheet.dart` — exists, 0 analyze errors
- `lib/features/admin/ui/users_management_tab.dart` — exists, 0 analyze errors
- `test/features/admin/ui/user_detail_sheet_test.dart` — exists, 7/7 pass
- `test/features/admin/ui/user_row_test.dart` — exists, 7/7 pass
- Commits `8392cd2` and `e1c1d69` — present in git log
