---
phase: 09-gest-o-de-usu-rios-admin
plan: 02
subsystem: admin
tags: [flutter, firestore, firebase, bloc, admin-panel]

# Dependency graph
requires:
  - phase: 09-01
    provides: ViewMode toggle and AuthAuthenticated state extensions

provides:
  - UsersManagementTab with searchable user list and admin promotion
  - AdminScreen expanded to 4 tabs including Usuarios
  - promoteUser method in AuthCubit
  - Firestore rules split into create/update/delete for /users collection

affects: [future admin phases, firestore-rules]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Client-side search filtering over Firestore snapshot (load all, filter locally)
    - Firestore write split into create/update/delete for granular access control
    - StatefulWidget with _loadUsers() reused for initial load and post-action refresh

key-files:
  created:
    - lib/features/admin/ui/users_management_tab.dart
  modified:
    - lib/features/admin/ui/admin_screen.dart
    - lib/features/auth/cubit/auth_cubit.dart
    - firestore.rules

key-decisions:
  - "promoteUser emits no cubit state — promoted user picks up role change on next auth refresh; admin UI refreshes via _loadUsers() re-query"
  - "User search is client-side filtering over full Firestore snapshot — acceptable for small user base, avoids composite index"
  - "Firestore /users write split into create/update/delete — create restricted to self, update allows admin, delete permanently blocked"
  - "withValues(alpha:) used instead of deprecated withOpacity() for Chip background color"

patterns-established:
  - "StatefulWidget admin tabs load on initState and expose _load*() method for post-action refresh"

requirements-completed: [ADMN-08]

# Metrics
duration: 10min
completed: 2026-03-25
---

# Phase 09 Plan 02: Users Management Admin Tab Summary

**Searchable user list with admin promotion dialog in a new Usuarios tab, backed by Firestore rules allowing admin to update any user's role.**

## Performance

- **Duration:** ~10 min
- **Started:** 2026-03-25T20:00:00Z
- **Completed:** 2026-03-25T20:10:00Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- New Usuarios tab in AdminScreen (now 4 tabs: Slots, Bloqueios, Reservas, Usuarios)
- UsersManagementTab with real-time name/email search (client-side filter)
- Promote button per non-admin user with confirmation AlertDialog
- Admin badge chip shown for already-promoted users
- promoteUser(uid) method added to AuthCubit writing `role: admin` to Firestore
- Firestore /users rules split into create/update/delete with admin write access on update

## Task Commits

Each task was committed atomically:

1. **Task 1: Update Firestore rules and add promoteUser to AuthCubit** - `04ae5a5` (feat)
2. **Task 2: Create UsersManagementTab and wire into AdminScreen** - `2de0792` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified
- `lib/features/admin/ui/users_management_tab.dart` - New StatefulWidget: user list, search field, promote button, confirmation dialog
- `lib/features/admin/ui/admin_screen.dart` - Added 4th tab (Usuarios) and UsersManagementTab child
- `lib/features/auth/cubit/auth_cubit.dart` - Added promoteUser(String uid) method
- `firestore.rules` - Split /users write into create/update/delete; admin can update any user doc

## Decisions Made
- promoteUser emits no cubit state — the promoted user's session refreshes their own role on next auth state change; the admin's UI refreshes via `_loadUsers()` re-query after promotion.
- User search is client-side filtering over a full Firestore snapshot. Avoids composite index requirement and is acceptable for a small user base.
- Firestore /users write rule split into three: `create` (self-only), `update` (self or admin), `delete` (never). This is a security improvement over the previous blanket `write` rule.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced deprecated withOpacity() with withValues()**
- **Found during:** Task 2 (UsersManagementTab creation)
- **Issue:** IDE diagnostic flagged `withOpacity(0.2)` as deprecated — use `.withValues(alpha:)` to avoid precision loss
- **Fix:** Changed `AppTheme.primaryGreen.withOpacity(0.2)` to `AppTheme.primaryGreen.withValues(alpha: 0.2)` on the Admin chip background
- **Files modified:** lib/features/admin/ui/users_management_tab.dart
- **Verification:** No deprecation warning in IDE diagnostics after fix
- **Committed in:** 2de0792 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - deprecated API)
**Impact on plan:** Trivial — single line replacement, no behavioral change.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required. Firestore rules update is deployed separately via `firebase deploy --only firestore:rules`.

## Next Phase Readiness
- Phase 09 complete — user management (view mode toggle + admin promotion) fully implemented
- Firestore rules now allow admin to update any user doc; deployment to production required to take effect
- No blockers for subsequent phases

---
*Phase: 09-gest-o-de-usu-rios-admin*
*Completed: 2026-03-25*
