# Architecture Patterns: Dashboard & Sport Field Integration

**Project:** Vida Ativa (vida_ativa)
**Researched:** 2026-05-19
**Scope:** v5.0 Dashboard (real-time metrics, aggregation strategy) + Sport Field (optional booking attribute)
**Confidence:** HIGH (existing codebase analysis + Firestore official docs)

---

## Executive Summary

Two integrations required:

1. **Dashboard Aggregation:** Admin sees real-time metrics (revenue, conversion, occupancy, sport splits). Firestore aggregation queries cannot use real-time listeners, so we use **write-time aggregation** (updating counter documents on each booking state change) + Cloud Functions scheduled batch refresh (hourly/daily) for non-real-time breakdowns.

2. **Sport Field:** Add optional `sport: String?` field to BookingModel. No schema migration needed—Firestore tolerates optional fields on existing documents. Store admin-configurable sport list in `/config/sports` (following existing `/config/pricing` pattern).

---

## Recommended Architecture

```
┌─────────────────────────────────────┐
│  Flutter Web (Admin Dashboard)      │
│  - DashboardCubit (StreamBuilder)   │
│  - Real-time counter listen         │
│  - Period filtering (week/month/year)│
└──────────────┬──────────────────────┘
               │
               ├─→ Real-Time: /config/dashboard/{period}
               │   (write-time aggregation counters)
               │
               └─→ Batch: Scheduled CF (hourly/daily)
                   updates /config/dashboard/{period}

Booking Flow (no UI changes needed):
  BookingModel.sport ← (OPTIONAL)
  /bookings/{id}     ← {sport: "Futevôlei" OR null}
  /config/sports     ← ["Futevôlei", "Vôlei", "Beach Tênis"]

Cloud Functions:
  - onBookingStateChange() → update /config/dashboard/realtime
  - onBookingPaymentConfirm() → increment revenue counters
  - scheduledDailyAggregation() → refresh /config/dashboard/day|week|month
```

---

## Component Boundaries

### Data Layer

#### 1. BookingModel (Modified)
**Current:** slotId, date, userId, status, price, paymentMethod, expiresAt, paymentId, participants, recurrenceGroupId
**Add:** `sport: String?` (optional, nullable, defaults to null for backward compatibility)

```dart
// Add to BookingModel
final String? sport; // 'Futevôlei' | 'Vôlei' | 'Beach Tênis' | null

// toFirestore() — only writes if non-null
if (sport != null) 'sport': sport,

// fromFirestore() — handles missing field gracefully
sport: data['sport'] as String?,
```

**Migration:** Zero friction. Existing bookings remain unmodified. New bookings can include sport. Read-time filtering is optional.

#### 2. DashboardMetrics (New)
Store counters in `/config/dashboard/{period}` as independent documents:

```firestore
/config/dashboard/realtime
  ├─ totalRevenue: 5000.00 (double)
  ├─ confirmedCount: 42 (int)
  ├─ pendingPaymentCount: 3 (int)
  ├─ cancelledCount: 2 (int)
  ├─ rejectedCount: 1 (int)
  ├─ expiredCount: 4 (int)
  ├─ refundedCount: 0 (int)
  ├─ pixCount: 25 (Pix payments)
  ├─ onArrivalCount: 17 (on_arrival payments)
  ├─ uniqueClientCount: 38 (distinct userIds)
  ├─ newClientCount: 3 (first-time bookers this period)
  ├─ totalSlotCount: 50 (all created slots)
  ├─ occupiedSlotCount: 45 (booked + confirmed)
  ├─ occupancyPercent: 90.0 (calculated field)
  ├─ conversionPercent: 95.2 (confirmed / total)
  ├─ avgTicket: 119.05 (totalRevenue / confirmedCount)
  ├─ avgTicketPix: 125.00
  ├─ avgTicketOnArrival: 110.00
  ├─ sportBreakdown: {
  │   "Futevôlei": 30,
  │   "Vôlei": 10,
  │   "Beach Tênis": 5,
  │   "null": 2
  │ }
  ├─ noShowRate: 0.08 (expired / total)
  ├─ abandonmentRate: 0.04 (pending_payment / total)
  ├─ hourlyGrid: {
  │   "08:00": {Mon: 8, Tue: 7, Wed: 9, Thu: 10, Fri: 8, Sat: 11, Sun: 12},
  │   "09:00": {Mon: 7, Tue: 8, ...},
  │   ...
  │ }
  ├─ topFrequentClients: [{uid, count, name}, ...]
  ├─ returnClientCount: 12
  ├─ dayOfWeekBreakdown: {Mon: 15, Tue: 12, ...}
  ├─ lastUpdatedAt: Timestamp
  ├─ period: 'realtime' | 'day' | 'week' | 'month'
  ├─ date: '2026-05-19'
```

**Why this structure:**
- Single document read = dashboard loads in 1 read instead of filtering thousands of bookings
- Write-time updates keep real-time metrics fresh (within seconds)
- Batch functions update period views hourly (cost-effective)
- Heatmap grid is pre-computed, not calculated on read

#### 3. SportConfigModel (New)
Store admin-configurable sports list:

```firestore
/config/sports
  ├─ sports: ["Futevôlei", "Vôlei", "Beach Tênis"]
  ├─ updatedAt: Timestamp
```

---

### Cubit Layer

#### 1. DashboardCubit (New)
Manages dashboard state with period selection + real-time listen.

```dart
class DashboardCubit extends Cubit<DashboardState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<DocumentSnapshot>? _sub;
  String _activePeriod = 'realtime';

  Future<void> setPeriod(String period) async {
    _sub?.cancel();
    _activePeriod = period;
    _startStream(period);
  }

  void _startStream(String period) {
    _sub = _firestore
        .collection('config')
        .doc('dashboard')
        .collection(period)
        .doc('current')
        .snapshots()
        .listen(
          (snap) {
            final metrics = DashboardMetricsModel.fromFirestore(snap);
            emit(DashboardLoaded(metrics));
          },
          onError: (e, s) => emit(DashboardError('Erro ao carregar dashboard.')),
        );
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
```

#### 2. SportConfigCubit (New)
Manages admin sport list configuration.

```dart
class SportConfigCubit extends Cubit<SportConfigState> {
  final FirebaseFirestore _firestore;
  StreamSubscription<DocumentSnapshot>? _sub;

  SportConfigCubit({required FirebaseFirestore firestore})
      : _firestore = firestore,
        super(const SportConfigInitial()) {
    _startStream();
  }

  void _startStream() {
    _sub = _firestore
        .collection('config')
        .doc('sports')
        .snapshots()
        .listen(
          (snap) {
            if (!snap.exists) {
              emit(const SportConfigLoaded([]));
              return;
            }
            final sports = List<String>.from(snap.data()?['sports'] ?? []);
            emit(SportConfigLoaded(sports));
          },
          onError: (e, s) => emit(const SportConfigError('Erro ao carregar esportes.')),
        );
  }

  Future<void> saveSports(List<String> sports) async {
    try {
      await _firestore.collection('config').doc('sports').set({
        'sports': sports,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, s) {
      Sentry.captureException(e, stackTrace: s);
      rethrow;
    }
  }
}
```

#### 3. Modified BookingCubit & AdminBookingCubit
Add sport parameter to bookSlot() and display sport in booking cards.

---

### UI Layer

#### 1. DashboardScreen (New)
Admin panel with metrics cards, heatmap, sport distribution chart.

#### 2. BookingForm (Modified)
Add sport dropdown to booking confirmation.

#### 3. BookingCard (Modified)
Display sport badge if present.

---

### Cloud Functions Layer

#### 1. onBookingStateChange (New/Modified)
Triggered on `/bookings/{docId}` write. Updates counter atomically.

```javascript
export const onBookingStateChange = functions
  .firestore
  .document('bookings/{docId}')
  .onWrite(async (change, context) => {
    const oldBooking = change.before.data();
    const newBooking = change.after.data();

    if (!oldBooking || !newBooking) return;

    const oldStatus = oldBooking.status;
    const newStatus = newBooking.status;

    const updates: { [key: string]: FieldValue } = {
      lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    // Decrement old status count
    if (oldStatus) {
      updates[`${oldStatus}Count`] = 
        admin.firestore.FieldValue.increment(-1);
    }

    // Increment new status count
    updates[`${newStatus}Count`] = 
      admin.firestore.FieldValue.increment(1);

    // Adjust revenue
    const oldPrice = oldStatus === 'confirmed' ? oldBooking.price : 0;
    const newPrice = newStatus === 'confirmed' ? newBooking.price : 0;
    if (newPrice !== oldPrice) {
      updates['totalRevenue'] = admin.firestore.FieldValue.increment(
        newPrice - oldPrice
      );
    }

    // Handle sport breakdown
    const oldSport = oldBooking.sport || 'null';
    const newSport = newBooking.sport || 'null';
    if (oldStatus !== 'confirmed' && newStatus === 'confirmed') {
      updates[`sportBreakdown.${newSport}`] = 
        admin.firestore.FieldValue.increment(1);
    }

    // Atomic update
    await admin.firestore()
      .collection('config')
      .doc('dashboard')
      .collection('realtime')
      .doc('current')
      .update(updates);
  });
```

#### 2. scheduledDailyAggregation (New)
Runs daily to compute non-real-time breakdowns (heatmap, sport, top clients).

```javascript
export const scheduledDailyAggregation = functions
  .pubsub
  .schedule('0 1 * * *')  // 01:00 UTC daily
  .timeZone('UTC')
  .onRun(async (context) => {
    const db = admin.firestore();
    
    const now = new Date();
    const yesterday = new Date(now.getTime() - 24 * 60 * 60 * 1000);
    
    const snapshots = await db
      .collection('bookings')
      .where('status', '==', 'confirmed')
      .where('createdAt', '>=', yesterday)
      .where('createdAt', '<=', now)
      .get();

    let totalRevenue = 0;
    const sportBreakdown: { [key: string]: number } = {};
    const hourlyGrid: { [key: string]: { [day: string]: number } } = {};

    snapshots.forEach((doc) => {
      const booking = doc.data();
      totalRevenue += booking.price || 0;

      const sport = booking.sport || 'null';
      sportBreakdown[sport] = (sportBreakdown[sport] || 0) + 1;

      const hour = booking.startTime;
      const dayName = getDayName(booking.date);
      if (!hourlyGrid[hour]) hourlyGrid[hour] = {};
      hourlyGrid[hour][dayName] = (hourlyGrid[hour][dayName] || 0) + 1;
    });

    await db
      .collection('config')
      .doc('dashboard')
      .collection('day')
      .doc('current')
      .set({
        totalRevenue,
        sportBreakdown,
        hourlyGrid,
        lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      }, { merge: true });
  });
```

---

## Data Flow

### Booking → Dashboard (Real-Time)

```
User books slot (sport: "Futevôlei")
    ↓
BookingCubit.bookSlot(sport: "Futevôlei")
    ↓
/bookings/{id} written (status: pending_payment)
    ↓
onBookingStateChange trigger
    ↓
/config/dashboard/realtime updated atomically:
  - pendingPaymentCount +1
  - sportBreakdown.Futevôlei +1 (if becomes confirmed)
    ↓
DashboardCubit listens to /config/dashboard/realtime
    ↓
UI rebuilds with new metrics
```

### Admin Configures Sports

```
Admin opens Settings → Sports tab
    ↓
SportConfigCubit.saveSports(["Futevôlei", "Vôlei"])
    ↓
/config/sports written
    ↓
SportConfigCubit stream emits new list
    ↓
BookingForm dropdown updates
```

---

## Patterns to Follow

### 1. Write-Time Aggregation (Real-Time Metrics)
**What:** Update counter documents as bookings change, rather than computing on read.
**When:** You need real-time updates, low latency, <1K updates/hour per metric.
**Implementation:** Firestore trigger on `/bookings/{id}` changes, atomic increment on `/config/dashboard/realtime` counters.

### 2. Scheduled Batch Aggregation (Period Views)
**What:** Run Cloud Functions on schedule (hourly/daily) to compute summaries.
**When:** Complex aggregations (heatmaps), or if real-time not critical for that metric.
**Implementation:** Cloud Functions `pubsub.schedule()`, query last N hours/days, write to `/config/dashboard/{period}`.

### 3. Optional Field Backward Compatibility
**What:** Add nullable field (`sport?: String`) without migrating existing documents.
**When:** Schema evolution without downtime.
**Implementation:** toFirestore() only writes if non-null, fromFirestore() treats missing as null.

### 4. Admin-Configurable Lists in /config
**What:** Store enumeration in Firestore under `/config/{type}`.
**When:** Admin controls allowed values, values change infrequently.
**Implementation:** `/config/sports` with array, stream with Cubit, validate in Cloud Functions.

---

## Anti-Patterns to Avoid

### ❌ Real-Time Listeners on Aggregation Queries
Firestore aggregation queries do NOT support real-time listeners. Use write-time aggregation instead.

### ❌ Computing Dashboard on Every Read
Querying 10K bookings and filtering locally is slow and expensive. Pre-compute in Cloud Functions, store in `/config/dashboard`, read single document.

### ❌ Denormalizing All Metrics to Bookings
This creates duplicate writes, consistency issues. Keep BookingModel as single source of truth, aggregate separately.

### ❌ Overwriting Counter Documents
Use `FieldValue.increment()` instead of fetch + update to avoid contention and lost updates.

---

## Scalability

| Concern | 100 bookings/month | 1K bookings/month | 10K+ bookings/month |
|---------|-----|-----|-----|
| Dashboard reads | 1 read/load | 1 read/load | 1 read/load |
| Aggregation triggers | ~0.15/hr | ~1.5/hr | ~15/hr |
| Metric contention | None | None | Add shards if >1 write/sec |
| Batch job frequency | Daily OK | Daily OK | Hourly or sharded |

---

## Integration Points

### 1. BookingModel Modification
**File:** `lib/core/models/booking_model.dart`
- Add: `final String? sport;`
- Update serialization

### 2. New Cubits
**Files:** 
- `lib/features/admin/cubit/dashboard_cubit.dart` + state
- `lib/features/admin/cubit/sport_config_cubit.dart` + state

### 3. Cloud Functions
**File:** `functions/src/aggregations.ts` (new)
- `onBookingStateChange`
- `scheduledDailyAggregation`

### 4. UI Integration
- `lib/features/admin/ui/admin_screen.dart` — DashboardTab
- `lib/features/booking/ui/booking_confirmation_sheet.dart` — sport dropdown
- `lib/features/booking/cubit/booking_cubit.dart` — sport param

### 5. Firestore Rules
```
match /config/dashboard/{period} {
  allow read: if request.auth != null && isAdmin();
  allow write: if request.auth != null && isAdmin();
}

match /config/sports {
  allow read: if request.auth != null;
  allow write: if request.auth != null && isAdmin();
}
```

---

## Suggested Build Order

### Phase 1: Backend (Week 1)
1. Add `sport: String?` to BookingModel
2. Create DashboardMetricsModel
3. Create SportConfigModel
4. Write Cloud Functions: `onBookingStateChange`, `scheduledDailyAggregation`
5. Deploy + test counter increments

### Phase 2: Dashboard UI (Week 2)
1. Create DashboardCubit + states
2. Build DashboardScreen with tabs
3. Implement metric cards, heatmap, sport chart
4. Test real-time updates

### Phase 3: Sport Config (Week 3)
1. Create SportConfigCubit + states
2. Add sport dropdown to BookingForm
3. Modify BookingCubit.bookSlot(sport)
4. Display sport badge on cards
5. Test end-to-end

### Phase 4: Polish (Week 4)
1. Add period date range display
2. Implement refresh button
3. Performance testing
4. Sentry integration
5. Final test

---

## Firestore Schema Changes

### New Collections
```firestore
/config/dashboard/realtime/current
  ├─ totalRevenue: 5000.00
  ├─ confirmedCount: 42
  ├─ ... (metrics)

/config/sports
  ├─ sports: ["Futevôlei", "Vôlei"]
  ├─ updatedAt: Timestamp
```

### Modified Collections
```firestore
/bookings/{id}
  ├─ ... (existing)
  ├─ sport: "Futevôlei" (NEW, optional)
```

No breaking changes. Backward compatible.

---

## Known Constraints

### Constraint 1: No Real-Time Aggregation Queries
Firestore aggregation queries don't support real-time listeners.
**Workaround:** Write-time aggregation.

### Constraint 2: Document Write Rate Limit
Can't update single document >1/sec.
**Workaround:** Distributed counters (sharded) for high-traffic. Not needed for Vida Ativa.

### Constraint 3: Heatmap Complex Aggregation
Grouping by hour + day requires multi-level reduction.
**Workaround:** Pre-compute in Cloud Functions, store as nested object.

---

## Sources

- [Firestore Aggregation Queries](https://firebase.google.com/docs/firestore/query-data/aggregation-queries)
- [Write-Time Aggregations](https://firebase.google.com/docs/firestore/solutions/aggregation)
- [Distributed Counters](https://firebase.google.com/docs/firestore/solutions/counters)
- [Cloud Functions Scheduling](https://firebase.google.com/docs/functions/schedule-functions)
- [Schema Evolution & Backward Compatibility](https://medium.com/firebase-developers/cloud-firestore-on-data-constraints-and-evolvability-a8f44b34fde8)
- [Real-Time Stats Monitor in Flutter](https://medium.com/flutter-community/real-time-stats-monitor-with-flutter-and-firebase-576cd554b9ca)
- [BLoC Pattern in Flutter](https://blog.logrocket.com/state-management-flutter-bloc-pattern/)
