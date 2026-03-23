---
phase: 06-pwa-hardening
plan: 01
subsystem: security, pwa
tags: [firestore-rules, pwa, ios-install, role-based-access]
dependency_graph:
  requires: []
  provides: [firestore-rbac, ios-install-banner, pwa-title]
  affects: [firestore.rules, web/index.html, lib/app_shell.dart]
tech_stack:
  added: [dart:ui_web]
  patterns: [isAdmin-role-check, StatefulWidget-initState-SnackBar]
key_files:
  created: [lib/core/pwa/ios_install_detector.dart]
  modified: [firestore.rules, web/index.html, lib/app_shell.dart]
decisions:
  - "isAdmin() checks .data.role == 'admin' (string field in Firestore), NOT .data.isAdmin bool"
  - "navigator.standalone check omitted — standalone mode bypasses Safari entirely, making the check redundant"
  - "dart:ui_web used for iOS detection — avoids dart:js/dart:js_interop complexity"
metrics:
  duration: 2 min
  completed: "2026-03-23"
  tasks_completed: 3
  files_modified: 4
---

# Phase 06 Plan 01: PWA Hardening — Security Rules and iOS Install Banner Summary

**One-liner:** Role-based Firestore security rules with isAdmin() + iOS install SnackBar using dart:ui_web + "Vida Ativa" PWA title.

## What Was Built

Three hardening changes for production readiness:

1. **Firestore security rules** — Complete rewrite replacing the Phase 1 bootstrap. Added `isAdmin()` helper that reads `.data.role == "admin"` from the user document. All admin-only collections (slots, blockedDates, config) now gate writes to admins. Bookings enforce per-user ownership on create and owner-or-admin on update/delete. Users can only read their own profile (or admins can read any). The `/config` collection was missing from Phase 1 and is now included.

2. **PWA title fix** — Both the `<title>` tag and the `apple-mobile-web-app-title` meta in `web/index.html` changed from `vida_ativa` to `Vida Ativa`. No other lines modified.

3. **iOS install banner** — Created `lib/core/pwa/ios_install_detector.dart` using `dart:ui_web` BrowserDetection. Converted `AppShell` from `StatelessWidget` to `StatefulWidget`; `initState` shows a 15-second dismissible SnackBar on iOS Safari. Non-iOS users see nothing. Installed PWA users never reach this code path (standalone mode bypasses Safari).

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Rewrite Firestore rules with isAdmin() | 43d2142 | firestore.rules |
| 2 | Fix PWA title in web/index.html | bee8588 | web/index.html |
| 3 | Add iOS install banner | fd1cd16 | lib/core/pwa/ios_install_detector.dart, lib/app_shell.dart |

## Decisions Made

- **isAdmin() checks `.data.role == "admin"`** — UserModel stores `role: String` in Firestore. The Dart getter `isAdmin` does not exist as a Firestore field. Using `.data.isAdmin` would silently fail for all users.
- **`navigator.standalone` check omitted** — Once an iOS user installs the PWA, iOS opens it in its own standalone window, completely bypassing Safari. Since `isIosInstallBannerNeeded()` only runs in browser context, executing on iOS guarantees the user is in Safari and has NOT installed the app. The check is redundant and would require `dart:js_interop`.
- **`dart:ui_web` for OS detection** — Flutter Web's BrowserDetection API provides `ui_web.browser.operatingSystem` without any JS interop, matching the research recommendation (Pattern 2).

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check

- [x] `firestore.rules` exists and contains `isAdmin()` with `.data.role == "admin"`
- [x] `web/index.html` contains "Vida Ativa" in both meta tag and title; zero occurrences of `vida_ativa`
- [x] `lib/core/pwa/ios_install_detector.dart` exists with `bool isIosInstallBannerNeeded()`
- [x] `lib/app_shell.dart` is `StatefulWidget` with `addPostFrameCallback` and `showSnackBar`
- [x] Commits 43d2142, bee8588, fd1cd16 exist

## Self-Check: PASSED
