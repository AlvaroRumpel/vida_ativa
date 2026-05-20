# Domain Pitfalls: Dashboard & Sport Field Integration

**Domain:** Flutter Web PWA + Firebase — Court Booking with Analytics & Sport Selection
**Researched:** 2026-05-19
**Confidence:** HIGH (Firestore aggregation patterns documented; write-time aggregation standard)

---

## Critical Pitfalls

Mistakes that cause rewrites or data integrity failures.

### Pitfall 1: Real-Time Listeners on Aggregation Queries (Dashboard Stalls)

**What goes wrong:** Trying to use `.snapshots()` on Firestore aggregation queries (`count()`, `sum()`) to get real-time dashboard updates. Aggregation queries do NOT support real-time listeners — you get a single read result, then the listener completes and never emits again. Dashboard shows stale data and admin doesn't notice.

**Why it happens:** Developer assumes aggregation queries work like normal Firestore queries with streams. Training data or documentation skimming suggests real-time is always possible.

**Consequences:** Dashboard appears to load but metrics are frozen. Admin makes decisions on old data. Revenue and occupancy numbers don't update when new bookings arrive.

**Prevention:**
Use **write-time aggregation** instead: update counter documents in Cloud Functions whenever a booking state changes, not on read. Counter documents are normal Firestore documents — they support real-time listeners.

```dart
// WRONG — aggregation queries don't support snapshots()
_firestore
    .collection('bookings')
    .count()
    .snapshots()  // ← FAILS: count() returns Future, not Stream
    .listen((snapshot) { ... });

// RIGHT — listen to pre-computed counter document
_firestore
    .collection('config')
    .doc('dashboard')
    .collection('realtime')
    .doc('current')
    .snapshots()  // ← Works: counter doc is real document
    .listen((snapshot) { ... });
```

**Detection:**
- Code tries to call `.snapshots()` on aggregation query result
- Dashboard updates only on manual refresh, not when new bookings arrive
- No Cloud Functions trigger updating counter documents

**Phase to address:** Dashboard implementation (Phase 1-2 of v5.0). Confidence: HIGH (Firestore docs explicit that agg queries don't support real-time).

---

### Pitfall 2: Counter Document Contention at High Write Volume

**What goes wrong:** A single `/config/dashboard/realtime/current` document is updated by every booking state change. At >1 write/sec, Firestore throttles to serialize writes to the same document. Dashboard updates slow down or fail with `RESOURCE_EXHAUSTED` error.

**Why it happens:** Naive implementation updates one central counter. At low volume (Vida Ativa ~0.2 bookings/sec peak), this is fine. But scaling assumption is wrong.

**Consequences:** Dashboard becomes unreliable during peak hours. Update failures are silently logged to Sentry, but metrics diverge from truth.

**Prevention:**
**Use distributed counters** for high-volume scenarios:
- Split counter across N shards: `/config/dashboard/realtime/shard_0`, `shard_1`, etc.
- Randomly select a shard on each write
- Sum shards on read (aggregate query works for this)
- For Vida Ativa (current: ~0.2 bookings/sec), single counter is fine. Flag for Phase review if volume grows >5 bookings/min.

```javascript
// Single counter (current app, OK)
await admin.firestore()
  .collection('config')
  .doc('dashboard')
  .collection('realtime')
  .doc('current')
  .update({ totalRevenue: FieldValue.increment(price) });

// Distributed shards (if needed at scale)
const shardCount = 10;
const shardId = Math.floor(Math.random() * shardCount);
await admin.firestore()
  .collection('config')
  .doc('dashboard')
  .collection('realtime')
  .doc(`shard_${shardId}`)
  .update({ totalRevenue: FieldValue.increment(price) });
```

**Detection:**
- `RESOURCE_EXHAUSTED` errors in Sentry during peak hours
- Cloud Functions trigger retries frequently
- Dashboard update latency >5 seconds during busy periods

**Phase to address:** Dashboard implementation. Monitor during Phase 2 testing. Current app volume doesn't require shards, but design for it.

---

### Pitfall 3: Computing Heatmap Grid on Every Dashboard Load

**What goes wrong:** Dashboard loads and runs a Firestore query to group bookings by `(hour, dayOfWeek)`, computing the heatmap grid live. With 5,000+ bookings in the database, this query is slow (seconds) and expensive (thousands of read units per load).

**Why it happens:** Simplicity — compute on read instead of pre-computing. Works fine with 100 bookings, breaks at 1,000+.

**Consequences:** Dashboard load time >10 seconds. Heatmap is expensive to update. Admin gets frustrated and stops using the tool.

**Prevention:**
Pre-compute heatmap grid in the scheduled Cloud Function (`scheduledDailyAggregation`). Store `hourlyGrid` as a nested object in the counter document. On read, it's already computed.

```javascript
// Cloud Function: compute heatmap once per day
const hourlyGrid: { [key: string]: { [day: string]: number } } = {};
snapshots.forEach((doc) => {
  const hour = doc.data().startTime; // "08:00"
  const dayName = getDayName(doc.data().date);
  if (!hourlyGrid[hour]) hourlyGrid[hour] = {};
  hourlyGrid[hour][dayName] = (hourlyGrid[hour][dayName] || 0) + 1;
});

// Store pre-computed grid
await db.collection('config').doc('dashboard')
  .collection('day').doc('current').set({
    hourlyGrid,
    lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
```

Then in Dart, read the pre-computed grid:

```dart
final metrics = await _firestore
    .collection('config').doc('dashboard')
    .collection('day').doc('current').get();
final hourlyGrid = metrics.data()?['hourlyGrid'];
// Render immediately, no computation needed
```

**Detection:**
- Dashboard load time increases with database size
- Heatmap query is slow; profiler shows complex grouping
- Heatmap is computed in Flutter, not pre-stored

**Phase to address:** Dashboard implementation (Phase 1-2). Confidence: HIGH (pre-computation is standard pattern).

---

### Pitfall 4: Sport Dropdown Shows Admin List Before It's Loaded

**What goes wrong:** BookingForm renders with an empty sport dropdown while `SportConfigCubit` is still loading `/config/sports`. User taps the dropdown, sees "loading..." or blank, and assumes the feature is broken or that no sports are configured.

**Why it happens:** Cubit streams load asynchronously; UI doesn't gate the dropdown on `SportConfigLoaded` state.

**Consequences:** Confusing UX; users skip the sport field thinking it's broken.

**Prevention:**
Gate the dropdown render on `SportConfigLoaded` state:

```dart
BlocBuilder<SportConfigCubit, SportConfigState>(
  builder: (context, state) {
    if (state is SportConfigLoaded) {
      return Dropdown(
        items: [
          DropdownMenuItem(child: Text('Nenhum')),
          ...state.sports.map((s) => DropdownMenuItem(child: Text(s))),
        ],
      );
    } else if (state is SportConfigError) {
      return Text('Erro ao carregar esportes');
    }
    // SportConfigInitial: don't render dropdown yet
    return SizedBox();
  },
)
```

Load SportConfigCubit in `main.dart` before any booking screen, so it's ready when needed.

**Detection:**
- Sport dropdown appears empty on booking form
- Test: restart app, navigate to booking form immediately → blank dropdown
- SportConfigLoaded state is never reached

**Phase to address:** Sport field implementation (Phase 1-2 of v5.0). Confidence: HIGH (standard BLoC pattern).

---

## Moderate Pitfalls

### Pitfall 5: Forgetting to Handle Null Sport Field in Queries & Display

**What goes wrong:** Filter query: `bookings.where('sport', '==', 'Futevôlei')` excludes all old bookings with `sport: null`. Sport distribution chart shows fewer bookings than actual total. Admin thinks the feature isn't working.

**Why it happens:** Firestore `where` clauses exclude `null` by default. Developer forgets that old bookings have no sport field.

**Consequences:** Metrics are inconsistent. Sport distribution chart doesn't add up to total bookings.

**Prevention:**
1. Explicitly handle null in queries (if needed):
```dart
// Get bookings for a sport OR null
final query = _firestore.collection('bookings')
    .where(Filter.or(
      Filter('sport', '==', 'Futevôlei'),
      Filter('sport', '==', null),
    ));
```

2. More commonly: in aggregations, treat null as "unspecified" sport:
```javascript
const sport = booking.sport || 'unspecified';
sportBreakdown[sport] = (sportBreakdown[sport] || 0) + 1;
```

3. In display, show null gracefully:
```dart
Text(booking.sport ?? 'Esporte não informado')
```

**Detection:**
- Sport distribution chart shows 20 bookings, but total confirmed is 50
- Queries for "all Futevôlei bookings" miss results

**Phase to address:** Dashboard + Sport field implementation. Confidence: HIGH.

---

### Pitfall 6: Cloud Functions Timeout or Fail Silently

**What goes wrong:** Scheduled batch aggregation function (`scheduledDailyAggregation`) times out or hits a quota error, but there's no alert. Admin checks dashboard next day and sees outdated metrics.

**Why it happens:** No error handling, no monitoring, no retry policy.

**Consequences:** Dashboard metrics become unreliable over time. Admin loses trust in the tool.

**Prevention:**
1. Add Sentry logging to Cloud Functions:
```javascript
import * as Sentry from "@sentry/node";

Sentry.init({ dsn: process.env.SENTRY_DSN });

export const scheduledDailyAggregation = functions
  .pubsub
  .schedule('0 1 * * *')
  .onRun(async (context) => {
    try {
      // ... aggregation logic ...
    } catch (error) {
      Sentry.captureException(error);
      throw error; // Let Cloud Functions retry
    }
  });
```

2. Set function timeout appropriately (max 540s for gen 2):
```bash
firebase deploy --only functions --memory 512MB
```

3. Monitor Cloud Functions logs in Firebase Console → Cloud Functions → Logs

**Detection:**
- Cloud Functions logs show `INTERNAL`, `TIMEOUT`, or unhandled errors
- No Sentry alert configured for CF errors
- Dashboard metrics suddenly stop updating

**Phase to address:** Dashboard implementation. Confidence: HIGH.

---

## Minor Pitfalls

### Pitfall 7: Denormalizing Sport to Every BookingModel (Causes Inconsistency)

**What goes wrong:** Instead of storing sport in `/config/sports` list, sport values are hardcoded or duplicated across booking documents. Admin changes "Futevôlei" to "Futsal", but old bookings still say "Futevôlei".

**Why it happens:** Lazy implementation; denormalization seems simpler initially.

**Consequences:** Inconsistent sport names across the database; reports don't group correctly.

**Prevention:**
Store sport as a STRING value (not an object). Admin manages the allowed list in `/config/sports`. Bookings reference the string, not the config. This is already the pattern in the architecture doc.

**Detection:**
- Multiple variations of same sport name ("Futevôlei", "futevolei", "FUTEVOLEI")
- Sport name changes require backfill query

**Phase to address:** Sport field implementation. Confidence: HIGH.

---

### Pitfall 8: Dashboard DashboardCubit Not Closed on Dispose

**What goes wrong:** DashboardCubit stream subscription is never cancelled when the dashboard screen is closed. After opening/closing the dashboard multiple times, many streams are still active, consuming memory and CPU.

**Why it happens:** Forgot to override `close()` method and cancel the subscription.

**Consequences:** Memory leak; app becomes sluggish after repeated dashboard navigation.

**Prevention:**
Always cancel streams in Cubit `close()`:

```dart
class DashboardCubit extends Cubit<DashboardState> {
  StreamSubscription<DocumentSnapshot>? _sub;

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
```

**Detection:**
- App slows down after opening dashboard many times
- Profiler shows many active Firestore listeners
- Memory usage grows over time

**Phase to address:** Dashboard implementation. Confidence: HIGH (standard BLoC pattern).

---

## Phase-Specific Warnings

| Phase | Likely Pitfall | Mitigation |
|-------|---------------|------------|
| Dashboard Cubit | Real-time agg queries fail | Use write-time aggregation (counter doc) not aggregation queries |
| Dashboard Cubit | Heatmap load is slow | Pre-compute hourly grid in scheduled CF |
| Cloud Functions | Counter document contention | Monitor write latency; use shards if >5 bookings/min |
| Sport Config Cubit | Dropdown empty on first load | Gate dropdown render on SportConfigLoaded state |
| Queries + Aggregation | Null sport field excluded | Handle null as "unspecified"; treat in grouping |
| Cloud Functions | Batch job fails silently | Log to Sentry; set appropriate timeout; monitor logs |
| BookingModel migration | Sport inconsistency | Store as string, not object; admin manages /config/sports list |

---

## Sources

- [Firestore Aggregation Queries Documentation](https://firebase.google.com/docs/firestore/query-data/aggregation-queries)
- [Write-Time Aggregations Solution](https://firebase.google.com/docs/firestore/solutions/aggregation)
- [Distributed Counters Pattern](https://firebase.google.com/docs/firestore/solutions/counters)
- [Cloud Functions Timeout Configuration](https://firebase.google.com/docs/functions/manage-functions)
- [BLoC Library Close Method](https://bloclibrary.dev/)
