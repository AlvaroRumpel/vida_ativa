---
phase: 08-compartilhamento-perfil
plan: 01
subsystem: auth
tags: [flutter, firestore, text-formatter, phone, registration]

requires:
  - phase: 02-auth
    provides: AuthCubit, UserModel with optional phone field, registerWithEmailPassword
  - phase: 07-visibilidade-social
    provides: FieldValue.delete() pattern via updateParticipants in BookingCubit

provides:
  - PhoneInputFormatter TextInputFormatter with (XX) XXXXX-XXXX mask
  - AuthCubit.registerWithEmailPassword with optional String? phone parameter
  - AuthCubit.updatePhone method for profile edit (Plan 02)
  - RegisterScreen with 5-field form including optional phone field

affects:
  - 08-02-PLAN.md (profile edit UI — uses updatePhone from this plan)

tech-stack:
  added: []
  patterns:
    - FieldValue.delete() for nullable Firestore fields (phone null -> delete field, not store null)
    - TextInputFormatter subclass for phone masking

key-files:
  created:
    - lib/core/utils/phone_input_formatter.dart
  modified:
    - lib/features/auth/cubit/auth_cubit.dart
    - lib/features/auth/ui/register_screen.dart

key-decisions:
  - "PhoneInputFormatter max 11 digits (Brazilian mobile: DDD 2 + number 9) — truncates excess, no error"
  - "updatePhone uses FieldValue.delete() for null/empty — consistent with updateParticipants pattern from Phase 07"
  - "Phone field is optional in RegisterScreen — empty value passes null to cubit, no phone field stored in Firestore"

patterns-established:
  - "Phone masking: PhoneInputFormatter strips non-digits then applies (XX) XXXXX-XXXX mask progressively"
  - "Nullable Firestore fields: use FieldValue.delete() when value is null to avoid storing empty strings"

requirements-completed: [PROF-01, PROF-02]

duration: 2min
completed: 2026-03-25
---

# Phase 08 Plan 01: Compartilhamento de Perfil — Phone Registration Summary

**PhoneInputFormatter with (XX) XXXXX-XXXX mask, optional phone field in RegisterScreen, and AuthCubit.updatePhone using FieldValue.delete() for Firestore null handling**

## Performance

- **Duration:** 2 min
- **Started:** 2026-03-25T08:29:28Z
- **Completed:** 2026-03-25T08:31:56Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Created PhoneInputFormatter that applies progressive (XX) XXXXX-XXXX mask, max 11 digits, cursor always at end
- Extended AuthCubit.registerWithEmailPassword with optional `String? phone` parameter passed to UserModel and Firestore
- Added AuthCubit.updatePhone method that writes or deletes the phone field using FieldValue.delete() pattern
- Added optional phone TextField to RegisterScreen after confirm password, wired to PhoneInputFormatter and cubit

## Task Commits

Each task was committed atomically:

1. **Task 1: Create PhoneInputFormatter and add phone to AuthCubit** - `00abf5c` (feat)
2. **Task 2: Add phone field to RegisterScreen** - `22bc829` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `lib/core/utils/phone_input_formatter.dart` - TextInputFormatter subclass with progressive Brazilian phone mask
- `lib/features/auth/cubit/auth_cubit.dart` - Added phone param to registerWithEmailPassword, added updatePhone method
- `lib/features/auth/ui/register_screen.dart` - Added _phoneController, phone TextField with mask, phone passed to cubit

## Decisions Made

- PhoneInputFormatter truncates to 11 digits silently — Brazilian mobile numbers are always DDD (2) + 9 digits; no error needed
- updatePhone uses `FieldValue.delete()` for null, consistent with updateParticipants pattern established in Phase 07
- Phone field in RegisterScreen passes `null` when empty rather than empty string — aligns with `if (phone != null)` guard in `UserModel.toFirestore()`

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- AuthCubit.updatePhone is ready for Plan 02 (profile edit UI) to wire up
- PhoneInputFormatter is available for reuse in any other phone input fields
- RegisterScreen now collects optional phone on sign-up; Firestore stores it only when provided

---
*Phase: 08-compartilhamento-perfil*
*Completed: 2026-03-25*
