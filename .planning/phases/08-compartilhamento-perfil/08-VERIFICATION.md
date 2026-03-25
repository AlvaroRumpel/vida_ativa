---
phase: 08-compartilhamento-perfil
verified: 2026-03-25T09:00:00Z
status: human_needed
score: 8/8 must-haves verified
re_verification: false
gaps: []
scope_note: "ROADMAP SC #3 updated from 'editar nome e telefone' to 'editar telefone' — user explicitly decided phone-only during discuss-phase 8 ('só telefone'). ROADMAP corrected to match."
human_verification:
  - test: "WhatsApp share button opens correct message"
    expected: "Tapping share on a confirmed booking opens WhatsApp (or browser) with pre-formatted message containing date, formatted time, participants (if present), and 'Academia Vida Ativa'"
    why_human: "url_launcher externalApplication mode cannot be tested programmatically without running the app on a device"
  - test: "Phone mask applies correctly during typing"
    expected: "Typing '11999998888' in the phone field displays '(11) 99999-8888'; partial input '119' displays '(11) 9'"
    why_human: "TextInputFormatter behavior requires live keyboard input"
  - test: "Phone edit BottomSheet keyboard avoidance"
    expected: "BottomSheet lifts above the on-screen keyboard so the Save button and input remain visible"
    why_human: "viewInsets.bottom padding requires live keyboard interaction"
---

# Phase 8: Compartilhamento & Perfil — Verification Report

**Phase Goal:** Usuários podem compartilhar reservas via WhatsApp e manter dados de contato atualizados no perfil
**Verified:** 2026-03-25T09:00:00Z
**Status:** human_needed (8/8 verified — scope corrected)
**Re-verification:** No — ROADMAP SC #3 updated to match discuss-phase decision (phone-only)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | RegisterScreen has an optional phone field as the last input before the register button | VERIFIED | `_phoneController`, `PhoneInputFormatter()` in inputFormatters, `'Celular (opcional)'` label at line 171, positioned before `SizedBox(height: 24)` and register button |
| 2 | Phone field applies (XX) XXXXX-XXXX mask automatically as user types | VERIFIED | `PhoneInputFormatter` class in `lib/core/utils/phone_input_formatter.dart` — strips non-digits, applies progressive mask up to 11 digits |
| 3 | Registration with empty phone sends null to Firestore | VERIFIED | `phone: phone.isEmpty ? null : phone` in `_onRegister()` (register_screen.dart line 77); `UserModel.toFirestore()` uses `if (phone != null)` guard |
| 4 | Registration with filled phone stores the phone string in /users/{uid} | VERIFIED | `phone: phone` passed to `UserModel` constructor in `AuthCubit.registerWithEmailPassword`, written via `set(user.toFirestore())` |
| 5 | AuthCubit.updatePhone() can update or delete the phone field in Firestore | VERIFIED | `updatePhone(String? phone)` at auth_cubit.dart line 133 — uses `FieldValue.delete()` for null, re-reads and re-emits `AuthAuthenticated` |
| 6 | BookingCard shows WhatsApp share icon for confirmed and pending bookings | VERIFIED | `Icons.share` IconButton with condition `!booking.isCancelled && booking.status != 'rejected'` at booking_card.dart line 97 |
| 7 | Tapping share icon opens WhatsApp with pre-formatted message containing date, time, and participants | VERIFIED | `_shareWhatsApp()` builds message via `StringBuffer`, encodes with `Uri.encodeComponent`, launches `https://wa.me/?text=...`; participants line is conditionally included |
| 8 | ProfileScreen BottomSheet allows editing telefone | VERIFIED | Phone edit BottomSheet fully implemented. ROADMAP SC #3 corrected to phone-only per discuss-phase decision. |

**Score:** 8/8 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/core/utils/phone_input_formatter.dart` | PhoneInputFormatter TextInputFormatter | VERIFIED | 43 lines; `class PhoneInputFormatter extends TextInputFormatter`; `formatEditUpdate` override; `_applyMask` with progressive (XX) XXXXX-XXXX logic; truncates at 11 digits |
| `lib/features/auth/cubit/auth_cubit.dart` | registerWithEmailPassword with phone param + updatePhone method | VERIFIED | `String? phone` param at line 99; `phone: phone` to UserModel at line 115; `Future<void> updatePhone(String? phone)` at line 133; `FieldValue.delete()` at line 139 |
| `lib/features/auth/ui/register_screen.dart` | Phone TextField with PhoneInputFormatter | VERIFIED | Imports `phone_input_formatter.dart`; `_phoneController` declared and disposed; `PhoneInputFormatter()` in `inputFormatters`; `phone.isEmpty ? null : phone` passed to cubit |
| `lib/features/booking/ui/booking_card.dart` | WhatsApp share button with url_launcher | VERIFIED | Imports `url_launcher/url_launcher.dart`; `_shareWhatsApp()` method with `wa.me` URL and `launchUrl`; `Icons.share` IconButton with correct visibility condition |
| `lib/features/auth/ui/profile_screen.dart` | Edit phone BottomSheet with PhoneInputFormatter | VERIFIED | Phone display + edit present; `_showEditPhoneSheet` function with `PhoneInputFormatter`, `updatePhone`, SnackBar — verified. Phone-only scope per discuss-phase decision. |
| `pubspec.yaml` | url_launcher dependency | VERIFIED | `url_launcher: ^6.2.0` present in dependencies section |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `register_screen.dart` | `auth_cubit.dart` | `registerWithEmailPassword` call with phone parameter | VERIFIED | `context.read<AuthCubit>().registerWithEmailPassword(... phone: phone.isEmpty ? null : phone)` at line 73–78 |
| `auth_cubit.dart` | Firestore /users/{uid} | `updatePhone` method | VERIFIED | `_firestore.collection('users').doc(uid).update({'phone': phone ?? FieldValue.delete()})` at lines 138–140 |
| `booking_card.dart` | url_launcher | `launchUrl` with WhatsApp URL | VERIFIED | `await launchUrl(url, mode: LaunchMode.externalApplication)` at line 154; `url = Uri.parse('https://wa.me/?text=$encoded')` |
| `profile_screen.dart` | `auth_cubit.dart` | `AuthCubit.updatePhone` call | VERIFIED | `authCubit.updatePhone(phone.isEmpty ? null : phone)` at line 133; `authCubit` captured before `showModalBottomSheet` at line 97 |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| PROF-01 | 08-01 | Optional phone field in registration | SATISFIED | `_phoneController` + `PhoneInputFormatter` in `register_screen.dart`; phone passed to `registerWithEmailPassword` |
| PROF-02 | 08-01, 08-02 | Phone display and edit in profile | SATISFIED | Phone edit BottomSheet fully implemented. Scope is phone-only per discuss-phase decision; ROADMAP SC #3 updated accordingly. |
| SOCIAL-03 | 08-02 | Compartilhar reserva via WhatsApp | SATISFIED | `_shareWhatsApp()` in `booking_card.dart` with `wa.me` deep link, date/time/participants message, correct visibility condition |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None found | — | — | — | — |

No TODO/FIXME/PLACEHOLDER comments or stub implementations found in any modified file. All methods are fully implemented with real logic.

### Commit Verification

All four task commits confirmed in git history:
- `00abf5c` — feat(08-01): create PhoneInputFormatter and add phone to AuthCubit
- `22bc829` — feat(08-01): add optional phone field to RegisterScreen
- `745315e` — feat(08-02): add WhatsApp share button to BookingCard
- `fa02803` — feat(08-02): add phone edit BottomSheet to ProfileScreen

### Human Verification Required

#### 1. WhatsApp Share Opens Correct Message

**Test:** On a device with WhatsApp installed, open a confirmed booking card and tap the share icon.
**Expected:** WhatsApp opens (or browser as fallback) with pre-filled message: emoji + "Reserva confirmada para {nome} — Academia Vida Ativa", date, time, optionally participants, "Nos vemos na quadra!"
**Why human:** `url_launcher` with `LaunchMode.externalApplication` cannot be exercised programmatically

#### 2. Phone Mask During Live Input

**Test:** In RegisterScreen, tap the phone field and type digits one by one.
**Expected:** "(11) 99999-8888" for "11999998888"; partial "(11) 9" for "119"; input beyond 11 digits is ignored
**Why human:** `TextInputFormatter` requires live keyboard events via Flutter engine

#### 3. BottomSheet Keyboard Avoidance

**Test:** Tap edit phone icon in ProfileScreen on mobile; observe BottomSheet position when soft keyboard appears.
**Expected:** BottomSheet content (text field + save button) remains above the keyboard
**Why human:** `MediaQuery.of(sheetContext).viewInsets.bottom` behavior requires running app with real keyboard

### Gaps Summary

No gaps. All 8 must-haves verified.

ROADMAP SC #3 was corrected from "editar nome e telefone" to "editar telefone" to match the explicit discuss-phase 8 decision (user: "só telefone"). The plans correctly scoped PROF-02 to phone-only; the ROADMAP had a stale description that did not reflect the decided scope.

---

_Verified: 2026-03-25T09:00:00Z_
_Verifier: Claude (gsd-verifier)_
