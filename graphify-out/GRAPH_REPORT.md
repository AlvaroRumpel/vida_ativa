# Graph Report - D:\Projetos\vida_ativa\.claude\worktrees\admin-monthly-view  (2026-11-03)

## Corpus Check
- 112 files · ~207,083 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 965 nodes · 1330 edges · 27 communities detected
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 8 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_Community 0|Community 0]]
- [[_COMMUNITY_Community 1|Community 1]]
- [[_COMMUNITY_Community 2|Community 2]]
- [[_COMMUNITY_Community 3|Community 3]]
- [[_COMMUNITY_Community 4|Community 4]]
- [[_COMMUNITY_Community 5|Community 5]]
- [[_COMMUNITY_Community 6|Community 6]]
- [[_COMMUNITY_Community 7|Community 7]]
- [[_COMMUNITY_Community 8|Community 8]]
- [[_COMMUNITY_Community 9|Community 9]]
- [[_COMMUNITY_Community 10|Community 10]]
- [[_COMMUNITY_Community 11|Community 11]]
- [[_COMMUNITY_Community 12|Community 12]]
- [[_COMMUNITY_Community 13|Community 13]]
- [[_COMMUNITY_Community 14|Community 14]]
- [[_COMMUNITY_Community 15|Community 15]]
- [[_COMMUNITY_Community 16|Community 16]]
- [[_COMMUNITY_Community 17|Community 17]]
- [[_COMMUNITY_Community 18|Community 18]]
- [[_COMMUNITY_Community 19|Community 19]]
- [[_COMMUNITY_Community 20|Community 20]]
- [[_COMMUNITY_Community 21|Community 21]]
- [[_COMMUNITY_Community 22|Community 22]]
- [[_COMMUNITY_Community 23|Community 23]]
- [[_COMMUNITY_Community 24|Community 24]]
- [[_COMMUNITY_Community 25|Community 25]]
- [[_COMMUNITY_Community 26|Community 26]]

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 49 edges
2. `package:cloud_firestore/cloud_firestore.dart` - 46 edges
3. `package:vida_ativa/core/theme/app_theme.dart` - 37 edges
4. `package:flutter_bloc/flutter_bloc.dart` - 34 edges
5. `package:flutter_test/flutter_test.dart` - 26 edges
6. `package:vida_ativa/core/models/booking_model.dart` - 22 edges
7. `dart:async` - 21 edges
8. `package:equatable/equatable.dart` - 17 edges
9. `package:intl/intl.dart` - 17 edges
10. `package:sentry_flutter/sentry_flutter.dart` - 16 edges

## Surprising Connections (you probably didn't know these)
- `obterAuthData()` --calls--> `log`  [INFERRED]
  D:\Projetos\vida_ativa\.claude\worktrees\admin-monthly-view\scripts\capturar.js → D:\Projetos\vida_ativa\.claude\worktrees\admin-monthly-view\scripts\deploy.dart
- `verifyMpSignature()` --calls--> `update`  [INFERRED]
  D:\Projetos\vida_ativa\.claude\worktrees\admin-monthly-view\functions\index.js → D:\Projetos\vida_ativa\.claude\worktrees\admin-monthly-view\test\features\booking\cubit\booking_cubit_test.dart
- `screenshot()` --calls--> `log`  [INFERRED]
  D:\Projetos\vida_ativa\.claude\worktrees\admin-monthly-view\scripts\capturar.js → D:\Projetos\vida_ativa\.claude\worktrees\admin-monthly-view\scripts\deploy.dart
- `log` --calls--> `backup()`  [INFERRED]
  D:\Projetos\vida_ativa\.claude\worktrees\admin-monthly-view\scripts\deploy.dart → F:\_geral\Projetos\vida_ativa\scripts\migrate_slots.js
- `log` --calls--> `migrate()`  [INFERRED]
  D:\Projetos\vida_ativa\.claude\worktrees\admin-monthly-view\scripts\deploy.dart → F:\_geral\Projetos\vida_ativa\scripts\migrate_slots.js

## Communities

### Community 0 - "Community 0"
Cohesion: 0.03
Nodes (70): PriceTierModel, AdminBlockedDateCubit, _startStream, AdminBookingCubit, _toDateString, DashboardCubit, _startStream, PricingCubit (+62 more)

### Community 1 - "Community 1"
Cohesion: 0.03
Nodes (71): AppTheme, display, IconThemeData, mono, ui, build, SportBtn, AdminBookingRow (+63 more)

### Community 2 - "Community 2"
Cohesion: 0.03
Nodes (65): core/pwa/ios_install_detector.dart, core/utils/snack_helper.dart, AccessDeniedScreen, build, Scaffold, SizedBox, build, dispose (+57 more)

### Community 3 - "Community 3"
Cohesion: 0.03
Nodes (65): build, DecoratedBox, HairlineBookingRow, _onTap, SizedBox, build, _buildBookingsList, _buildHeader (+57 more)

### Community 4 - "Community 4"
Cohesion: 0.03
Nodes (59): AdminDaySelector, _AdminDaySelectorState, build, DecoratedBox, didChangeDependencies, didUpdateWidget, Divider, GestureDetector (+51 more)

### Community 5 - "Community 5"
Cohesion: 0.04
Nodes (53): _addTier, _addTierRow, build, Center, Column, copyWith, _daysLabel, didUpdateWidget (+45 more)

### Community 6 - "Community 6"
Cohesion: 0.04
Nodes (46): MonthBookingsSummary, RecurringSeries, AdminBookingError, AdminBookingInitial, AdminBookingLoaded, AdminBookingState, BookingManagementTab, _BookingManagementTabState (+38 more)

### Community 7 - "Community 7"
Cohesion: 0.04
Nodes (47): build, _buildDashboard, _buildHeatmap, _buildKpiCell, _buildKpiGrid, _buildPeriodSelector, _buildRevenueChart, _buildSportRows (+39 more)

### Community 8 - "Community 8"
Cohesion: 0.04
Nodes (42): _FakeDoc, main, _make, _FakeDoc, main, _FakeDoc, main, main (+34 more)

### Community 9 - "Community 9"
Cohesion: 0.06
Nodes (24): BlockedDateModel, BookingModel, generateId, DashboardData, RevenueBySportEntry, TopClientEntry, PaymentRecordModel, StateError (+16 more)

### Community 10 - "Community 10"
Cohesion: 0.08
Nodes (28): esperar(), obterAuthData(), screenshot(), _appendDeployHistory, ask, _bold, _chooseTarget, confirm (+20 more)

### Community 11 - "Community 11"
Cohesion: 0.07
Nodes (28): build, _eyebrowDate, _goToNextWeek, _goToPreviousWeek, initState, _onDaySelected, Scaffold, ScheduleScreen (+20 more)

### Community 12 - "Community 12"
Cohesion: 0.07
Nodes (28): _applyMask, formatEditUpdate, PhoneInputFormatter, TextEditingValue, build, _buildError, _buildLoading, _buildQrContent (+20 more)

### Community 13 - "Community 13"
Cohesion: 0.07
Nodes (23): core/router/app_router.dart, core/services/fcm_navigation.dart, core/theme/app_theme.dart, SlotSeeder, SettingsError, SettingsInitial, SettingsLoaded, SettingsState (+15 more)

### Community 14 - "Community 14"
Cohesion: 0.07
Nodes (27): build, ClientBookingDetailSheet, _ClientBookingDetailSheetState, FilledButton, _handleCancelRecurrent, _handleCancelSingle, _infoRow, launchUrl (+19 more)

### Community 15 - "Community 15"
Cohesion: 0.08
Nodes (23): AdminBlockedDateError, AdminBlockedDateInitial, AdminBlockedDateLoaded, AdminBlockedDateState, _BlockedDatesList, BlockedDatesTab, build, Center (+15 more)

### Community 16 - "Community 16"
Cohesion: 0.07
Nodes (23): build, Column, DecoratedBox, dispose, initState, _onSearchChanged, SizedBox, UserRow (+15 more)

### Community 17 - "Community 17"
Cohesion: 0.07
Nodes (26): AdminScreen, _AdminScreenState, BlockedDatesTab, BlocProvider, BookingManagementTab, build, _buildInlineBanner, Container (+18 more)

### Community 18 - "Community 18"
Cohesion: 0.09
Nodes (18): expectLater, _FakeCollRef, _FakeDocRef, _FakeDocSnapshot, _FakeFirestore, _FakeQuery, _FakeQuerySnapshot, _FakeTx (+10 more)

### Community 19 - "Community 19"
Cohesion: 0.09
Nodes (21): AdminBookingDetailSheet, _AdminBookingDetailSheetState, build, _infoRow, Padding, Row, SizedBox, SnackBar (+13 more)

### Community 20 - "Community 20"
Cohesion: 0.09
Nodes (20): PricingError, PricingInitial, PricingLoaded, PricingState, _FakeDoc, main, dart:math, build (+12 more)

### Community 21 - "Community 21"
Cohesion: 0.1
Nodes (20): _BookingChip, BookingMonthView, _BookingMonthViewState, build, Center, Column, _DayCell, DecoratedBox (+12 more)

### Community 22 - "Community 22"
Cohesion: 0.11
Nodes (17): _addSport, build, Center, Column, dispose, Icon, initState, ListView (+9 more)

### Community 23 - "Community 23"
Cohesion: 0.67
Nodes (2): isIosInstallBannerNeeded, dart:ui_web

### Community 24 - "Community 24"
Cohesion: 1.0
Nodes (1): AppSpacing

### Community 25 - "Community 25"
Cohesion: 1.0
Nodes (0): 

### Community 26 - "Community 26"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **769 isolated node(s):** `AppShell`, `_AppShellState`, `initState`, `build`, `Scaffold` (+764 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 24`** (2 nodes): `app_spacing.dart`, `AppSpacing`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 25`** (1 nodes): `admin_fcm_state.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 26`** (1 nodes): `generate-sw.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 1` to `Community 0`, `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 15`, `Community 16`, `Community 17`, `Community 19`, `Community 20`, `Community 21`, `Community 22`?**
  _High betweenness centrality (0.283) - this node is a cross-community bridge._
- **Why does `package:cloud_firestore/cloud_firestore.dart` connect `Community 0` to `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 9`, `Community 11`, `Community 12`, `Community 13`, `Community 15`, `Community 16`, `Community 17`, `Community 18`, `Community 19`, `Community 20`?**
  _High betweenness centrality (0.208) - this node is a cross-community bridge._
- **Why does `package:vida_ativa/core/theme/app_theme.dart` connect `Community 1` to `Community 2`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 7`, `Community 8`, `Community 11`, `Community 12`, `Community 14`, `Community 16`, `Community 17`, `Community 19`, `Community 20`, `Community 21`, `Community 22`?**
  _High betweenness centrality (0.139) - this node is a cross-community bridge._
- **What connects `AppShell`, `_AppShellState`, `initState` to the rest of the system?**
  _769 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.03 - nodes in this community are weakly interconnected._