---
phase: 25-estrutura-admin
reviewed: 2026-05-27T00:00:00Z
depth: standard
files_reviewed: 1
files_reviewed_list:
  - lib/features/admin/ui/admin_screen.dart
findings:
  critical: 0
  warning: 2
  info: 3
  total: 5
status: issues_found
---

# Phase 25: Code Review Report

**Reviewed:** 2026-05-27
**Depth:** standard
**Files Reviewed:** 1
**Status:** issues_found

## Summary

Single file reviewed: `admin_screen.dart`. The file is a Flutter `StatefulWidget` that renders the admin panel with a 7-tab `TabBar`, an FCM cubit for push notifications, and an inline banner for new bookings. Overall structure is sound. No security vulnerabilities or crashes were found. Two warnings address real logic/lifecycle concerns; three info items cover minor quality issues.

## Warnings

### WR-01: `AdminFcmCubit` created outside `BlocProvider` — not properly scoped

**File:** `lib/features/admin/ui/admin_screen.dart:43-44`
**Issue:** `_fcmCubit` is instantiated directly in `initState` (`AdminFcmCubit()`) and manually closed in `dispose`. It is then injected via `BlocProvider.value`. This pattern bypasses Bloc's lifecycle management: if the widget is hot-reloaded or rebuilt by the framework before `dispose` is called, `_fcmCubit.init()` may be called a second time on the same (or a stale) cubit instance, potentially double-subscribing to FCM streams. The idiomatic Flutter/Bloc approach is to let `BlocProvider(create: ...)` own the lifecycle, or at minimum ensure `init()` is idempotent and guarded.
**Fix:**
```dart
// Option A — let BlocProvider own it (preferred):
BlocProvider(
  create: (_) => AdminFcmCubit()..init(),
  child: ...,
)
// Then retrieve it inside the tree with context.read<AdminFcmCubit>()
// Remove _fcmCubit field, _foregroundSub subscription setup moves to
// a child widget or BlocListener.

// Option B — guard init against double-call (minimal change):
// Inside AdminFcmCubit.init(), add:
// if (_initialized) return;
// _initialized = true;
```

---

### WR-02: `_foregroundSub` listener references `_fcmCubit` stream after cubit may be closed

**File:** `lib/features/admin/ui/admin_screen.dart:47-56`
**Issue:** The stream subscription `_foregroundSub` is set up in `initState`. If `_fcmCubit.close()` is called (in `dispose`) while the stream still has pending events or a delayed callback is in flight (e.g., the 5-second `_bannerTimer`), the timer callback at line 54 calls `setState` on a potentially-disposed widget. The `if (mounted)` guard on line 54 mitigates the crash, but the timer itself is not cancelled when the cubit closes — only in `dispose`. If `dispose` runs before the 5-second timer fires, the cancel in `dispose` (line 108) handles it correctly. However, if `dispose` is somehow called _after_ the timer fires but before `mounted` becomes false (a narrow but possible race on some platforms), a `setState` call on an unmounted widget can still occur. The `mounted` check does protect against the setState crash, but relying on ordering is fragile.
**Fix:**
```dart
// Ensure timer is always cancelled before cubit close:
@override
void dispose() {
  _bannerTimer?.cancel();   // move BEFORE stream cancel
  _foregroundSub?.cancel();
  navigateToReservasNotifier.removeListener(_onFcmNavigation);
  _tabController.dispose();
  _fcmCubit.close();
  super.dispose();
}
```
More importantly, the timer callback should be wrapped in an explicit cancel-on-dispose pattern or use a `mounted` guard (already present), which is acceptable for now.

---

## Info

### IN-01: `TabController` length hard-coded — mismatches tab list if a tab is added or removed

**File:** `lib/features/admin/ui/admin_screen.dart:42`
**Issue:** `TabController(length: 7, ...)` is a magic number. The `tabs:` list in `TabBar` (lines 170-178) and the `children:` list in `TabBarView` (lines 211-226) both have 7 items. If a developer adds or removes a tab in one list but forgets to update the `length` constant, Flutter throws a runtime assertion. A named constant or deriving length from the list would make this safer.
**Fix:**
```dart
// Define tab list as a constant and derive length:
static const _tabs = ['DASHBOARD', 'SLOTS', 'BLOQUEIOS', 'RESERVAS',
                       'USUÁRIOS', 'PREÇOS', 'AJUSTES'];
// Then:
_tabController = TabController(length: _tabs.length, vsync: this);
// And in TabBar:
tabs: _tabs.map((t) => Tab(text: t)).toList(),
```

---

### IN-02: `_reservasTabIndex` constant value must stay in sync manually

**File:** `lib/features/admin/ui/admin_screen.dart:37`
**Issue:** `static const int _reservasTabIndex = 3;` is a magic index. If tab order changes (e.g., RESERVAS moves), this constant silently points to the wrong tab and FCM navigation navigates the admin to the wrong screen. This is a latent bug waiting for a refactor.
**Fix:**
```dart
// Derive from the same _tabs list in IN-01:
static int get _reservasTabIndex => _tabs.indexOf('RESERVAS');
```

---

### IN-03: Duplicate inline banner layout between `_buildInlineBanner` and `_NotificationBanner`

**File:** `lib/features/admin/ui/admin_screen.dart:77-103` and `237-274`
**Issue:** Both `_buildInlineBanner` (instance method) and `_NotificationBanner` (private `StatelessWidget`) share nearly identical `IntrinsicHeight > Row > Container(width:2, orange) > SizedBox(12) > Expanded > Padding > Row` structure. This is code duplication. If the banner design changes (e.g., border width, padding), it must be updated in both places.
**Fix:** Extract a shared `_AdminBanner` widget that accepts a `child` widget for the right-side content, and reuse it in both banners.

---

_Reviewed: 2026-05-27_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
