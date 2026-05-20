# Domain Pitfalls: v5.0 Analytics Dashboard + Optional Fields

**Domain:** Firestore-backed Flutter Web booking app ADDING analytics dashboard and optional fields
**Researched:** 2026-05-19
**Focus:** Cost optimization, performance, data consistency, backward compatibility

---

## Critical Pitfalls

### Pitfall 1: Dashboard Queries Scanning All Bookings (Firestore Cost Explosion)

**What goes wrong:** Dashboard queries scan entire bookings collection. Monthly costs spike 10-100x.

**Why it happens:** Naive implementation with no indexes. Full collection scans on queries like `where('createdAt', '>=', startDate).where('createdAt', '<=', endDate)`.

**Consequences:** Budget overruns (10k bookings = 10k reads per query), dashboard timeout, Firebase billing spike 100x.

**Prevention:**
- Use Firestore **Aggregation Queries** (count, sum, avg) instead of fetching docs
- Create composite indexes ONLY for queries you'll run
- Use **Query Insights** tool to identify high-cost queries before going live
- Cache aggregation results in Firestore `config/dashboardCache` with TTL
- Implement Cloud Functions for off-peak aggregations (2 AM run, dashboard reads cached results)

**Detection:** Firebase Console billing spikes day after dashboard deploy, dashboard loads slowly (>5s), Query Insights shows red flag queries

**Phase to address:** Phase 1 (Dashboard Setup) — query strategy MUST be designed before UI.

---

### Pitfall 2: Over-Indexing Composite Indexes (Storage + Write Overhead)

**What goes wrong:** Too many composite indexes. Writing 1 booking updates 5+ indexes, slow writes + hidden storage cost.

**Why it happens:** Creating index for every dashboard filter combination without auditing which queries need indexes.

**Consequences:** Write latency increases (100ms → 500ms+), storage costs grow silently (indexes consume 2-5x document size), cleanup difficult.

**Prevention:**
- Index audit before launch: list every dashboard query, design ONE index per query pattern
- Use **Query Explain** tool to verify index usage before creating
- Monitor index storage in Firebase Console (>1GB triggers budget warning)
- Use single-field indexes for simple filters only
- Test write latency before/after adding indexes

**Detection:** 10+ composite indexes in Firebase Console, storage cost spike, booking write time increases significantly

**Phase to address:** Phase 1 (Dashboard Setup) — design query strategy, verify indexes BEFORE aggregations.

---

### Pitfall 3: Date Boundary + Timezone Misalignment (Aggregation Accuracy)

**What goes wrong:** Dashboard shows "Revenue Monday" but data spans Monday 9 PM to Tuesday 9 PM. Booking at 11 PM Sao Paulo (UTC-3) appears in next day bucket. Admin sees 10 bookings on dashboard, manually filtering shows 12.

**Why it happens:** Timestamps stored as UTC but filtered by local date without conversion. Week/month/year toggles don't handle timezone boundaries.

**Consequences:** Admin sees conflicting numbers, revenue aggregation off by ±1 day, heatmap shows false patterns, hard to debug (appears location-dependent).

**Prevention:**
- Store all timestamps in UTC only
- Define clear date range semantics: "This week" = Monday 00:00 UTC to Sunday 23:59 UTC (not "7 days from now")
- Dashboard date picker must convert user local time to UTC range
- Add integration test for date boundary: create booking at 11 PM UTC, verify correct bucket
- Heatmap must group by UTC hour and label clearly "Times shown in UTC"
- Test DST transitions: booking before/after DST change should appear on correct date

**Detection:** Admin reports "dashboard X vs manual filter Y", heatmap shows impossible patterns (hour 25), revenue discrepancies between views

**Phase to address:** Phase 1 (Dashboard Setup) — finalize date range logic in query layer BEFORE UI.

---

### Pitfall 4: Chart Rendering Performance with Large Datasets (Flutter Web)

**What goes wrong:** 168 data points (7 days x 24 hours) render fine. 800 points (month) = 3+ second freeze on toggle. Dashboard feels janky.

**Why it happens:** Canvas/SVG renderer redraws entire chart on state change. No data aggregation for display. RepaintBoundary missing. Aggressive rebuilds on every booking change.

**Consequences:** Dashboard freezes when toggling week/month/year, scrolling heatmap causes jank (60 FPS → 20 FPS), poor user experience, admin clicks once, nothing happens for 3s.

**Prevention:**
- Choose renderer based on data volume: SVG (<500 points), Canvas (>500 points, use CanvasKit not HTML renderer)
- Aggregate data for display: week (hourly: 168 points), month (daily: 30-31 points), year (weekly: 52 points)
- Wrap chart in **RepaintBoundary** to prevent parent rebuilds
- Don't load all 12 months at once; lazy load visible month + next month prefetch
- Test with 1000+ data points before deploy; frame rate should stay >30 FPS
- Consider Syncfusion Flutter Charts (v5.3.0+): Virtual DOM rewrote architecture, 2-10x performance improvement

**Detection:** Dashboard freezes when toggling week/month, scrolling heatmap causes jank, DevTools shows 200+ms frame build time, admin opens month view → 3-5s loading

**Phase to address:** Phase 2 (Dashboard UI/Charts) — test chart library + data volume BEFORE finalizing choice. Don't ship without this test.

---

### Pitfall 5: Optional `sportField` Field Breaks Existing Bookings (Backward Compatibility)

**What goes wrong:** v5.0 adds optional sportField. 3000 existing bookings have no field. New code assumes it exists: `booking.sportField.toUpperCase()` crashes on old bookings. Admin lists bookings → app crash. User views booking history → crash.

**Why it happens:** Optional field not marked as nullable in Dart model. No migration enforced. Firestore rule allows reads of old documents. Code doesn't handle missing field. Firestore returns doc without field, Dart deserializer throws.

**Consequences:** App crash on production when loading old bookings, admin can't see/manage old bookings, rollback required, users see "error loading your bookings".

**Prevention:**
- Always declare optional fields as nullable: `final String? sportField` (NOT `final String sportField`)
- Provide default getter: `String get sportFieldOrDefault => sportField ?? 'Volei'`
- Add one-time migration Cloud Function to set default on old bookings, or lazy-migrate on read
- Test backward compat: create old booking with v4 code, load in v5 → should not crash, should show default value
- Test filtering: filter by sportField with mixed old/new bookings → old bookings should appear with default

**Detection:** Crash logs after deploy: "null is not a member of 'sportField'", admin reports "can't see bookings from last month", crash happens when loading `/bookings` collection

**Phase to address:** Phase 1 (Dashboard Setup) — finalize BookingModel schema changes BEFORE deploying optional field. Add migration function.

---

### Pitfall 6: Admin-Configurable sportField List Out of Sync (Dynamic List Management)

**What goes wrong:** Admin adds "Beach Tennis" to config. New bookings include it. But filters don't know about it (hardcoded enum in code). Client app crashes if it tries to render unknown sport field.

**Why it happens:** List stored in Firestore (dynamic), code has hardcoded enum: `enum SportField { volei, futevolei }`. No listener to sync config changes.

**Consequences:** New sport field created but app doesn't use it, bookings with new sport invisible in filters (can't aggregate them), admin confused why filter doesn't include new sport, dashboard by-sport chart shows incomplete data.

**Prevention:**
- Store sportField list in Firestore `config/sportFields` as array
- Load into SettingsCubit at startup with **stream listener** (not one-time load)
- Dashboard filter cubit listens to sportFields stream, rebuilds filters dynamically
- Validate on booking creation against current config list; reject if not in list
- Firestore security rule validates sportField against config
- Test: admin adds sport field → immediately visible in app without restart

**Detection:** Admin adds sport → not visible in dropdown, bookings with new sport show as "unknown" or blank, filter doesn't update after config change, dashboard "By Sport" chart missing a category

**Phase to address:** Phase 1 (Dashboard Setup) → Phase 2 (Booking UI Enhancement) — implement dynamic list sync BEFORE allowing admin to configure sports.

---

## Moderate Pitfalls

### Pitfall 7: Period Toggle State Explosion (BLoC Complexity)

**What goes wrong:** Week/month/year toggle each has separate query + state. Code duplicates aggregation logic across three periods.

**Why it happens:** Easy to copy-paste logic, hard to parameterize different date calculations.

**Consequences:** Bug fix in one period doesn't apply to others, adding new period requires more copy-paste, state explosion (DashboardWeekLoaded, DashboardMonthLoaded, DashboardYearLoaded).

**Prevention:**
- Single parameterized state: `DashboardLoaded(period: 'week', metrics: {...})`
- Extract date range into pure function: `getDateRange(String period) -> ({start, end})`
- Single parameterized query function: `fetchMetrics(String period)`
- Test date calculation edge cases: last day of month, Feb 29 (leap year), year boundary

**Phase to address:** Phase 2 (Dashboard UI) — implement BLoC state management for period toggles.

---

### Pitfall 8: Heatmap (Hour x Day) Interpretation Confusion

**What goes wrong:** Heatmap shows bright cell at "2 AM Tuesday". Admin wonders why customers book at 2 AM. Answer: test data at 2 AM UTC, not local time. Or DST boundary creates ghost pattern.

**Why it happens:** Timestamps stored in UTC, heatmap created without timezone labeling. Test data pollutes heatmap. No DST handling.

**Consequences:** Admin misinterprets peak times, makes wrong business decisions, "Customers love 2 AM bookings" (false), DST transition shows false patterns.

**Prevention:**
- Clear timezone label in UI: "Times shown in UTC" or "Times shown in Sao Paulo (UTC-3)"
- Convert to local time if needed, or clearly label UTC
- Filter out test data or label clearly
- Validate: peak hours should match business hours (8 AM - 10 PM)
- Test DST boundaries: booking before/after DST change, verify heatmap doesn't shift

**Phase to address:** Phase 2 (Dashboard UI/Charts) — finalize heatmap timezone approach.

---

### Pitfall 9: Conversion Rate Calculation Ambiguity

**What goes wrong:** Dashboard shows "Conversion Rate: 75%". Definition unclear: (confirmed/total)? (paid/pending)? (no-show=false/total)?

**Why it happens:** No clear definition, no documentation of what "conversion" means in booking context.

**Consequences:** Admin questions metric reliability, metrics not comparable month-to-month, hard to track if business is improving.

**Prevention:**
- Define every metric explicitly in code with comment
- Label in UI: "Confirmed/Paid Bookings ÷ Total Created"
- Document in code and external metrics reference doc
- Include footnote in dashboard explaining calculation
- Test consistency across week/month/year views

**Phase to address:** Phase 2 (Dashboard UI) — define and document all metrics before display.

---

### Pitfall 10: Client App Doesn't Validate sportField (Data Integrity)

**What goes wrong:** User (or old app version) submits invalid sportField. Booking created with garbage value. Dashboard filter breaks with unknown sport.

**Why it happens:** No validation on write. Firestore rule allows any string in sportField.

**Consequences:** Invalid data pollutes bookings collection, dashboard queries fail or filter results incorrectly, admin can't delete/fix invalid bookings easily, dashboard "By Sport" chart shows "Unknown" category.

**Prevention:**
- Firestore security rule validates sportField against config
- Client-side validation before submit: fetch current list, validate selected option
- Cubit validates on booking create; throw error if not in valid list

**Phase to address:** Phase 1 (Dashboard Setup) → Phase 2 (Booking UI) — add validation layer.

---

## Minor Pitfalls

### Pitfall 11: Aggregation Query Minimum Charge (Empty Collections)

Dashboard has 10 aggregation queries. Admin checks daily even on closed days. 10 queries × 1 read (minimum charge) × 30 days = 300 wasted reads/month.

Prevention: Cache results in Firestore, single aggregation per period, check cache staleness before querying.

---

### Pitfall 12: Chart Data Point Duplication (Pagination Boundary)

Offset-based pagination: booking at offset=100 appears in page 1 and page 2 of chart data. Chart shows double spike.

Prevention: Cursor-based pagination (last document ID), aggregate data before paginating (month view should have ≤31 points).

---

### Pitfall 13: Dashboard Permission Bypass (Admin-Only View)

Route `/admin/dashboard` guarded by goRouter only. Firestore rules don't enforce admin. Client can navigate to route, read bookings.

Prevention: Firestore rule: `allow read: if role == 'admin'`. goRouter guard is UI only, not security.

---

## Phase-Specific Warnings

| Phase | Topic | Pitfall | Mitigation |
|-------|-------|---------|-----------|
| Phase 1 | Query Strategy | Cost explosion | Aggregation Queries + caching, test cost impact |
| Phase 1 | Firestore Schema | Over-indexing | Audit indexes, use Query Explain, monitor storage |
| Phase 1 | Date Range Logic | Timezone misalignment | UTC-only timestamps, test boundaries, integration test |
| Phase 1 | Optional Field | Backward compat crash | Nullable fields, Cloud Function migration, test |
| Phase 1 | Admin Permissions | Dashboard bypass | Firestore rules enforce admin role |
| Phase 2 | Chart Library | Performance jank | Test with 1000+ points, Canvas vs SVG, RepaintBoundary |
| Phase 2 | BLoC State | Toggle explosion | Parameterized cubit, single state, pure functions |
| Phase 2 | Dynamic List Sync | Admin config out of sync | BLoC listeners to sportField config stream |
| Phase 2 | Data Validation | Invalid sportField | Client + Firestore rules validation |
| Phase 2 | Heatmap | Timezone confusion | Clear labeling, UTC timezone, filter test data |
| Phase 2 | Metrics | Ambiguous calculations | Document all metrics, label in UI, test consistency |

---

## Summary: Highest-Risk Areas for v5.0

1. **Firestore read cost explosion** (Pitfall 1) — Design query strategy first, test cost impact before going live
2. **Chart rendering freeze** (Pitfall 4) — Test data volume before choosing chart library
3. **Optional field crash** (Pitfall 5) — Add graceful null handling, migration function
4. **Admin config sync** (Pitfall 6) — Implement BLoC listener to config changes
5. **Date/timezone bugs** (Pitfall 3) — Test date boundaries exhaustively

All critical pitfalls should be researched/validated in Phase 1 before Phase 2 implementation.

---

## Sources

- [Firestore Aggregation Queries](https://firebase.google.com/docs/firestore/query-data/aggregation-queries) — Cost optimization for dashboards
- [Google Firestore Pricing Guide](https://airbyte.com/data-engineering-resources/google-firestore-pricing) — Over-indexing and cost pitfalls
- [Firestore Query Insights](https://firebase.google.com/docs/firestore/enterprise/query-insights) — Identify high-cost queries
- [Timestamp and Timezone Best Practices](https://www.tinybird.co/blog/database-timestamps-timezones) — Date boundary handling
- [Flutter Performance Optimization 2026](https://dev.to/techwithsam/flutter-performance-optimization-2026-make-your-app-10x-faster-best-practices-2p07) — Chart rendering and RepaintBoundary
- [SVG vs Canvas Performance 2026](https://www.svggenie.com/blog/svg-vs-canvas-vs-webgl-performance-2025) — Chart renderer choice
- [Firestore Data Constraints and Evolvability](https://medium.com/firebase-developers/cloud-firestore-on-data-constraints-and-evolvability-a8f44b34fde8) — Optional field backward compatibility
- [BLoC State Management Best Practices](https://dev.to/kumarharsh/the-complete-guide-to-flutter-bloc-state-management-3lp9) — Period toggle parameterization
- [Flutter Pagination Best Practices](https://medium.com/@mohamedalaacs/the-complete-guide-to-pagination-in-flutter-page-offset-and-cursor-explained-ee893134c358) — Cursor-based pagination
