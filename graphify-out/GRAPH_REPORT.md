# Graph Report - F:\_geral\Projetos\vida_ativa  (2026-05-08)

## Corpus Check
- 73 files · ~144,643 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 605 nodes · 808 edges · 25 communities detected
- Extraction: 100% EXTRACTED · 0% INFERRED · 0% AMBIGUOUS · INFERRED: 4 edges (avg confidence: 0.8)
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

## God Nodes (most connected - your core abstractions)
1. `package:flutter/material.dart` - 35 edges
2. `package:flutter_bloc/flutter_bloc.dart` - 26 edges
3. `package:cloud_firestore/cloud_firestore.dart` - 22 edges
4. `package:vida_ativa/core/theme/app_theme.dart` - 21 edges
5. `package:intl/intl.dart` - 15 edges
6. `package:vida_ativa/core/models/booking_model.dart` - 14 edges
7. `package:equatable/equatable.dart` - 13 edges
8. `package:sentry_flutter/sentry_flutter.dart` - 12 edges
9. `package:vida_ativa/core/theme/app_spacing.dart` - 12 edges
10. `package:go_router/go_router.dart` - 9 edges

## Surprising Connections (you probably didn't know these)
- `getMpAccessToken()` --calls--> `log`  [INFERRED]
  F:\_geral\Projetos\vida_ativa\functions\index.js → F:\_geral\Projetos\vida_ativa\scripts\deploy.dart
- `getMpWebhookSecret()` --calls--> `log`  [INFERRED]
  F:\_geral\Projetos\vida_ativa\functions\index.js → F:\_geral\Projetos\vida_ativa\scripts\deploy.dart
- `log` --calls--> `backup()`  [INFERRED]
  F:\_geral\Projetos\vida_ativa\scripts\deploy.dart → F:\_geral\Projetos\vida_ativa\scripts\migrate_slots.js
- `log` --calls--> `migrate()`  [INFERRED]
  F:\_geral\Projetos\vida_ativa\scripts\deploy.dart → F:\_geral\Projetos\vida_ativa\scripts\migrate_slots.js

## Communities

### Community 0 - "Community 0"
Cohesion: 0.04
Nodes (54): dart:async, PriceTierModel, AdminBlockedDateCubit, _startStream, AdminBookingCubit, _toDateString, _activateToken, AdminFcmCubit (+46 more)

### Community 1 - "Community 1"
Cohesion: 0.04
Nodes (48): dart:math, build, Chip, Column, _DatePickerButton, _HourDropdown, InkWell, InputDecorator (+40 more)

### Community 2 - "Community 2"
Cohesion: 0.04
Nodes (45): BookingCard, build, Card, Container, _formatDate, Icon, launchUrl, _showEditParticipantsDialog (+37 more)

### Community 3 - "Community 3"
Cohesion: 0.05
Nodes (32): core/pwa/ios_install_detector.dart, core/utils/snack_helper.dart, AppShell, _AppShellState, build, initState, Scaffold, AppTheme (+24 more)

### Community 4 - "Community 4"
Cohesion: 0.05
Nodes (36): ScheduleError, ScheduleInitial, ScheduleLoaded, ScheduleLoading, ScheduleState, AnimatedBuilder, build, _buildDayView (+28 more)

### Community 5 - "Community 5"
Cohesion: 0.06
Nodes (34): AdminBookingError, AdminBookingInitial, AdminBookingLoaded, AdminBookingState, AdminBookingCard, build, Card, Icon (+26 more)

### Community 6 - "Community 6"
Cohesion: 0.06
Nodes (32): AccessDeniedScreen, build, Scaffold, SizedBox, _AppFooter, _Avatar, _AvatarState, build (+24 more)

### Community 7 - "Community 7"
Cohesion: 0.06
Nodes (24): BlockedDateModel, BookingModel, generateId, SlotModel, UserModel, AdminSlotError, AdminSlotInitial, AdminSlotLoaded (+16 more)

### Community 8 - "Community 8"
Cohesion: 0.06
Nodes (29): _AuthStateNotifier, BlocProvider, createRouter, dispose, GoRouter, MultiBlocProvider, MyBookingsScreen, build (+21 more)

### Community 9 - "Community 9"
Cohesion: 0.08
Nodes (25): dart:io, _appendDeployHistory, ask, _bold, _chooseTarget, confirm, _cyan, _dim (+17 more)

### Community 10 - "Community 10"
Cohesion: 0.08
Nodes (23): core/router/app_router.dart, core/theme/app_theme.dart, SlotSeeder, SettingsError, SettingsInitial, SettingsLoaded, SettingsState, DefaultFirebaseOptions (+15 more)

### Community 11 - "Community 11"
Cohesion: 0.07
Nodes (25): PricingError, PricingInitial, PricingLoaded, PricingState, _addTier, build, Card, Center (+17 more)

### Community 12 - "Community 12"
Cohesion: 0.08
Nodes (23): build, Column, dispose, initState, ListTile, _loadUsers, _onSearchChanged, UsersManagementTab (+15 more)

### Community 13 - "Community 13"
Cohesion: 0.08
Nodes (22): build, Column, _endDateLabel, FilterChip, _HiddenItemsSummary, initState, Padding, _PreviewDateItem (+14 more)

### Community 14 - "Community 14"
Cohesion: 0.11
Nodes (17): AdminScreen, _AdminScreenState, build, Container, dispose, Expanded, _goToReservas, Icon (+9 more)

### Community 15 - "Community 15"
Cohesion: 0.12
Nodes (14): AdminBlockedDateError, AdminBlockedDateInitial, AdminBlockedDateLoaded, AdminBlockedDateState, _BlockedDatesList, BlockedDatesTab, build, Center (+6 more)

### Community 16 - "Community 16"
Cohesion: 0.13
Nodes (14): BookingConfirmationSheet, _BookingConfirmationSheetState, build, Container, dispose, _infoRow, _paymentWarningBanner, Row (+6 more)

### Community 17 - "Community 17"
Cohesion: 0.13
Nodes (14): build, _clearErrors, dispose, Expanded, _handleAuthError, LoginScreen, _LoginScreenState, _onForgotPassword (+6 more)

### Community 18 - "Community 18"
Cohesion: 0.17
Nodes (11): _backgroundColor, build, _buildContent, Container, _formatPrice, GestureDetector, Icon, InkWell (+3 more)

### Community 19 - "Community 19"
Cohesion: 0.33
Nodes (5): _applyMask, formatEditUpdate, PhoneInputFormatter, TextEditingValue, package:flutter/services.dart

### Community 20 - "Community 20"
Cohesion: 0.67
Nodes (2): dart:ui_web, isIosInstallBannerNeeded

### Community 21 - "Community 21"
Cohesion: 1.0
Nodes (1): AppSpacing

### Community 22 - "Community 22"
Cohesion: 1.0
Nodes (0): 

### Community 23 - "Community 23"
Cohesion: 1.0
Nodes (0): 

### Community 24 - "Community 24"
Cohesion: 1.0
Nodes (0): 

## Knowledge Gaps
- **479 isolated node(s):** `AppShell`, `_AppShellState`, `initState`, `build`, `Scaffold` (+474 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **Thin community `Community 21`** (2 nodes): `app_spacing.dart`, `AppSpacing`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 22`** (1 nodes): `admin_fcm_state.dart`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 23`** (1 nodes): `generate-sw.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.
- **Thin community `Community 24`** (1 nodes): `firebase-messaging-sw.js`
  Too small to be a meaningful cluster - may be noise or needs more connections extracted.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `package:flutter/material.dart` connect `Community 3` to `Community 1`, `Community 2`, `Community 4`, `Community 5`, `Community 6`, `Community 8`, `Community 10`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 15`, `Community 16`, `Community 17`, `Community 18`?**
  _High betweenness centrality (0.303) - this node is a cross-community bridge._
- **Why does `package:flutter_bloc/flutter_bloc.dart` connect `Community 0` to `Community 1`, `Community 4`, `Community 5`, `Community 6`, `Community 8`, `Community 10`, `Community 11`, `Community 12`, `Community 14`, `Community 15`, `Community 16`, `Community 17`?**
  _High betweenness centrality (0.144) - this node is a cross-community bridge._
- **Why does `package:vida_ativa/core/theme/app_theme.dart` connect `Community 2` to `Community 1`, `Community 3`, `Community 4`, `Community 5`, `Community 6`, `Community 11`, `Community 12`, `Community 13`, `Community 14`, `Community 16`, `Community 17`, `Community 18`?**
  _High betweenness centrality (0.093) - this node is a cross-community bridge._
- **What connects `AppShell`, `_AppShellState`, `initState` to the rest of the system?**
  _479 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Community 0` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Community 1` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._
- **Should `Community 2` be split into smaller, more focused modules?**
  _Cohesion score 0.04 - nodes in this community are weakly interconnected._