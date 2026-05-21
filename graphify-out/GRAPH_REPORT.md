# Graph Report - F:\_geral\Projetos\vida_ativa  (2026-05-21)

## Corpus Check
- 95 files · ~167,988 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 790 nodes · 1078 edges · 28 communities detected
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 6 edges (avg confidence: 0.8)
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
- [[_COMMUNITY_Community 27|Community 27]]

## God Nodes (most connected - your core abstractions)
1. `package:cloud_firestore/cloud_firestore.dart` - 42 edges
2. `package:flutter/material.dart` - 37 edges
3. `package:flutter_bloc/flutter_bloc.dart` - 28 edges
4. `package:vida_ativa/core/theme/app_theme.dart` - 23 edges
5. `dart:async` - 19 edges
6. `package:flutter_test/flutter_test.dart` - 19 edges
7. `package:vida_ativa/core/models/booking_model.dart` - 17 edges
8. `package:equatable/equatable.dart` - 16 edges
9. `package:sentry_flutter/sentry_flutter.dart` - 15 edges
10. `package:intl/intl.dart` - 15 edges

## Surprising Connections (you probably didn't know these)
- `getMpAccessToken()` --calls--> `log`  [INFERRED]
  F:\_geral\Projetos\vida_ativa\functions\index.js → F:\_geral\Projetos\vida_ativa\scripts\deploy.dart
- `getMpWebhookSecret()` --calls--> `log`  [INFERRED]
  F:\_geral\Projetos\vida_ativa\functions\index.js → F:\_geral\Projetos\vida_ativa\scripts\deploy.dart
- `migrate()` --calls--> `batch`  [INFERRED]
  F:\_geral\Projetos\vida_ativa\scripts\migrate_slots.js → F:\_geral\Projetos\vida_ativa\test\features\booking\cubit\booking_cubit_test.dart
- `verifyMpSignature()` --calls--> `update`  [INFERRED]
  F:\_geral\Projetos\vida_ativa\functions\index.js → F:\_geral\Projetos\vida_ativa\test\features\booking\cubit\booking_cubit_test.dart
- `log` --calls--> `backup()`  [INFERRED]
  F:\_geral\Projetos\vida_ativa\scripts\deploy.dart → F:\_geral\Projetos\vida_ativa\scripts\migrate_slots.js

## Communities

### Community 0 - "Community 0"
Cohesion: 0.05
Nodes (45): dart:async, PriceTierModel, AdminBlockedDateCubit, _startStream, AdminBookingCubit, _toDateString, _activateToken, AdminFcmCubit (+37 more)

### Community 1 - "Community 1"
Cohesion: 0.04
Nodes (47): BookingConfirmationSheet, _BookingConfirmationSheetState, build, Container, dispose, _infoRow, initState, _paymentWarningBanner (+39 more)

### Community 2 - "Community 2"
Cohesion: 0.05
Nodes (44): dart:io, _appendDeployHistory, ask, _bold, _chooseTarget, confirm, _cyan, _dim (+36 more)

### Community 3 - "Community 3"
Cohesion: 0.04
Nodes (44): build, _buildBookingsList, Center, _confirmCancel, ListView, MyBookingsScreen, Padding, Scaffold (+36 more)

### Community 4 - "Community 4"
Cohesion: 0.05
Nodes (41): AdminSlotError, AdminSlotInitial, AdminSlotLoaded, AdminSlotState, build, initState, Padding, SizedBox (+33 more)

### Community 5 - "Community 5"
Cohesion: 0.05
Nodes (40): _FakeDoc, main, main, _buildFirestore, _FakeCollRef, _FakeDocRef, FakeDocSnap, _FakeFirestore (+32 more)

### Community 6 - "Community 6"
Cohesion: 0.05
Nodes (39): _AppFooter, _Avatar, _AvatarState, build, CircleAvatar, Column, didUpdateWidget, Divider (+31 more)

### Community 7 - "Community 7"
Cohesion: 0.05
Nodes (30): BlockedDateModel, BookingModel, generateId, DashboardData, RevenueBySportEntry, TopClientEntry, PaymentRecordModel, SlotModel (+22 more)

### Community 8 - "Community 8"
Cohesion: 0.05
Nodes (36): build, Center, dispose, Divider, Icon, initState, Scaffold, _SettingsForm (+28 more)

### Community 9 - "Community 9"
Cohesion: 0.05
Nodes (35): core/pwa/ios_install_detector.dart, core/utils/snack_helper.dart, AppShell, _AppShellState, build, initState, Scaffold, AdminScreen (+27 more)

### Community 10 - "Community 10"
Cohesion: 0.06
Nodes (33): _AuthStateNotifier, BlocProvider, createRouter, dispose, GoRouter, MultiBlocProvider, MyBookingsScreen, _BlockedDatesList (+25 more)

### Community 11 - "Community 11"
Cohesion: 0.06
Nodes (30): AppTheme, Color, error, info, _show, SizedBox, SnackHelper, success (+22 more)

### Community 12 - "Community 12"
Cohesion: 0.06
Nodes (29): AdminBookingCard, build, Card, Icon, SizedBox, _statusColor, _statusLabel, BookingManagementTab (+21 more)

### Community 13 - "Community 13"
Cohesion: 0.06
Nodes (29): dart:convert, _applyMask, formatEditUpdate, PhoneInputFormatter, TextEditingValue, build, _buildCountdown, _buildError (+21 more)

### Community 14 - "Community 14"
Cohesion: 0.07
Nodes (28): _addTier, build, Card, Center, Column, copyWith, didUpdateWidget, DropdownMenuItem (+20 more)

### Community 15 - "Community 15"
Cohesion: 0.07
Nodes (27): BookingCard, build, Card, Container, _formatDate, Icon, launchUrl, _showEditParticipantsDialog (+19 more)

### Community 16 - "Community 16"
Cohesion: 0.08
Nodes (23): core/router/app_router.dart, core/theme/app_theme.dart, SlotSeeder, SettingsError, SettingsInitial, SettingsLoaded, SettingsState, DefaultFirebaseOptions (+15 more)

### Community 17 - "Community 17"
Cohesion: 0.07
Nodes (23): build, Scaffold, SplashScreen, build, Column, _endDateLabel, FilterChip, _HiddenItemsSummary (+15 more)

### Community 18 - "Community 18"
Cohesion: 0.09
Nodes (20): dart:math, PricingError, PricingInitial, PricingLoaded, PricingState, build, Chip, Column (+12 more)

### Community 19 - "Community 19"
Cohesion: 0.1
Nodes (18): DashboardError, DashboardInitial, DashboardLoaded, DashboardLoading, DashboardState, main, _FakeConfigColl, _FakeDashboardDoc (+10 more)

### Community 20 - "Community 20"
Cohesion: 0.17
Nodes (11): AdminBookingDetailSheet, _AdminBookingDetailSheetState, build, _infoRow, Padding, Row, SizedBox, SnackBar (+3 more)

### Community 21 - "Community 21"
Cohesion: 0.18
Nodes (10): batch, _FakeCollRef, _FakeDocRef, _FakeFirestore, _FakeQDocSnapshot, _FakeQuery, _FakeQuerySnapshot, _FakeWriteBatch (+2 more)

### Community 22 - "Community 22"
Cohesion: 0.22
Nodes (7): AdminBlockedDateError, AdminBlockedDateInitial, AdminBlockedDateLoaded, AdminBlockedDateState, _FakeDoc, main, package:vida_ativa/core/models/blocked_date_model.dart

### Community 23 - "Community 23"
Cohesion: 0.67
Nodes (2): dart:ui_web, isIosInstallBannerNeeded

### Community 24 - "Community 24"
Cohesion: 1.0
Nodes (1): AppSpacing

### Community 25 - "Community 25"
Cohesion: 1.0
Nodes (0): 

### Community 26 - "Community 26"
Cohesion: 1.0
Nodes (0): 

### Community 27 - "Community 27"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **625 isolated node(s):** `AppShell`, `_AppShellState`, `initState`, `build`, `Scaffold` (+620 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 24`** (2 nodes): `app_spacing.dart`, `AppSpacing`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 25`** (1 nodes): `admin_fcm_state.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 26`** (1 nodes): `generate-sw.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 27`** (1 nodes): `firebase-messaging-sw.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:cloud_firestore/cloud_firestore.dart` connect `Community 0` to `Community 1`, `Community 2`, `Community 4`, `Community 5`, `Community 7`, `Community 8`, `Community 9`, `Community 10`, `Community 12`, `Community 13`, `Community 14`, `Community 16`, `Community 17`, `Community 18`, `Community 19`, `Community 21`, `Community 22`?**
  _High betweenness centrality (0.260) - this node is a cross-community bridge._
- **Why does `package:flutter/material.dart` connect `Community 11` to `Community 1`, `Community 3`, `Community 4`, `Community 6`, `Community 8`, `Community 9`, `Community 10`, `Community 12`, `Community 13`, `Community 14`, `Community 15`, `Community 16`, `Community 17`, `Community 18`, `Community 20`?**
  _High betweenness centrality (0.254) - this node is a cross-community bridge._
- **Why does `package:flutter_bloc/flutter_bloc.dart` connect `Community 0` to `Community 1`, `Community 3`, `Community 4`, `Community 6`, `Community 8`, `Community 9`, `Community 10`, `Community 11`, `Community 12`, `Community 14`, `Community 16`, `Community 18`?**
  _High betweenness centrality (0.117) - this node is a cross-community bridge._
- **What connects `AppShell`, `_AppShellState`, `initState` to the rest of the system?**
  _625 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.05 - nodes in this community are weakly interconnected._