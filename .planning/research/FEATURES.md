# Feature Landscape: Admin Analytics Dashboard & Sport Field Selection

**Project:** Vida Ativa (PWA court booking for beach volleyball/futevôlei)
**Milestone:** v5.0 - Dashboard & Esportes
**Researched:** 2026-05-19
**Confidence:** HIGH (patterns validated; Firestore schema verified)

---

## Table Stakes: Admin Analytics Dashboard

Features facility operators expect. Missing = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|-----------|-------|
| **Occupancy Rate %** | Core metric for facility utilization; benchmark across sports venues | Low | Formula: (Confirmed bookings ÷ Available slots) × 100 |
| **Total Revenue** | Essential KPI; sum of confirmed payments | Low | Aggregate PaymentRecord.amount by status=confirmed |
| **Average Ticket Price** | Shows pricing effectiveness | Low | totalRevenue ÷ confirmedCount |
| **Bookings by Status** | Visibility into workflow (pending, confirmed, cancelled, expired) | Low | Pie chart; max 4 segments |
| **Time-Window Filtering** | Essential for trends; week/month/year comparison | Medium | Toggle UI for period selection |
| **Revenue Split: Pix vs On-Arrival** | Visibility into payment method distribution | Medium | Stacked bar; critical for cash flow |

---

## Differentiators: Advanced Visualizations

Features that go beyond table stakes.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|-----------|-------|
| **Heatmap: Hour × Day Occupancy** | Identify peak times for pricing/staffing optimization | Medium | 2D grid (7 days × ~15-24 hours) colored by occupancy % |
| **Revenue Trend Line Chart** | Visualize weekly/monthly momentum | Low | Time-series aggregation by week/month |
| **Top Clients by Frequency** | VIP identification for retention focus | Low | Sort by booking count; display top 5 |
| **New vs Returning Clients** | Segment acquisition vs retention health | Medium | Pie chart: new, returning, unique total |
| **Return Rate %** | Client stickiness metric | Medium | (Clients with 2+ bookings ÷ total) × 100 |
| **Sport Distribution Chart** | Understand demand by sport type | Low | Group by sport field; bar/pie chart |
| **Most Booked Days & Hours** | Optimize promotions and staffing | Low | Sort by occupancy; display top 3-5 |
| **No-Show Rate %** | Revenue leakage indicator | Medium | (Confirmed with no attendance ÷ total confirmed) × 100 |

---

## Sport Field Selection: Optional Booking Metadata

New optional field on BookingModel. Backward-compatible schema evolution.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|-----------|-------|
| **Sport Dropdown on Booking Form** | Clients indicate sport when reserving (Vôlei, Beach Tênis, Futevôlei) | Low | UI: dropdown for >5 options; optional field |
| **Admin-Configurable Sport List** | Admin can add/remove sports without code changes | Low | Stored in `/config/sports` collection |
| **Sport Display on Schedules** | Show booked sport on calendar + admin schedule | Low | Display as badge/label; null → "Não informado" |
| **Sport Filter in Bookings View** | Admin can filter bookings by sport type | Low | Add filter chips/dropdown to list; optional feature |

---

## Anti-Features: Explicitly NOT Building in v5.0

| Feature | Why Avoid | What to Do Instead |
|---------|-----------|-------------------|
| **Predictive/ML Forecasting** | Premature; complex | Start with trend charts; identify patterns manually |
| **Custom Report Builder** | Over-engineer for single admin | Fixed dashboard layouts |
| **Drill-Down / Pivot Tables** | Low ROI; enterprise-only | Time-window filters sufficient |
| **Per-Sport Pricing Tiers** | Variant complexity overkill | Enforce uniform slot price |
| **Sport-Specific Booking Rules** | Scope creep; governance complexity | Document in instructions; admin enforces manually |
| **Real-Time Dashboard Notifications** | Low ROI; refresh manually | Manual refresh or 5-min polling if needed |
| **Dynamic/AI-Driven Pricing** | Single venue lacks leverage | Static pricing; manual admin adjustments |

---

## Feature Dependencies

**Critical path:**

```
BookingModel schema extension (sport: String?)
  └─ Backward compatible with existing bookings (null = no sport)

Analytics Dashboard depends on:
  ├─ Occupancy % ← bookings + slots
  ├─ Revenue metrics ← PaymentRecord
  ├─ Time-window toggle ← filter state
  ├─ Heatmap ← group by (dayOfWeek, hour)
  ├─ Client retention ← count(bookings) per user
  └─ No-show rate ← attendance flag or admin log

Sport Selection depends on:
  ├─ BookingModel.sport field
  ├─ /config/sports populated by admin
  └─ Booking form UI with sport dropdown
```

---

## MVP Recommendation

**Phase 1 (Weeks 1-2): Core Dashboard + Sport Field**

Prioritize (user-visible, high-value):
1. ✓ Occupancy Rate % (time-window toggle)
2. ✓ Total Revenue (Pix + on_arrival split)
3. ✓ Average Ticket Price
4. ✓ Bookings by Status (pie chart)
5. ✓ Sport Dropdown on booking form + admin config
6. ✓ Time-window toggle (week/month/year)

**Estimated effort:** 1.5-2 weeks

**Phase 2 (Weeks 3-4): Advanced Metrics (defer if time-constrained)**

Nice-to-have:
- Heatmap (hour × day occupancy)
- Client retention metrics
- Revenue trend line chart
- Sport distribution chart
- No-show rate

**Estimated effort if included:** +1.5 weeks

---

## Backward Compatibility: Sport Field Addition

**Existing bookings (v1-v4):** sport field missing/null
**New bookings (v5.0+):** sport is String or null

**Safe handling:**
1. Dart model: Use `booking.sport ?? 'Não informado'` for display
2. Firestore rules: No validation required for optional field
3. Queries: Filtering by sport automatically returns only new bookings
4. UI displays: Show gracefully for null values
5. Admin views: Display bookings without sport as valid (no "incomplete" marking)

**Migration strategy:** No forced backfill. Old bookings remain null forever (acceptable).

---

## Quality Gate Checklist

- ✓ Table stakes vs differentiators clear
- ✓ Complexity noted per feature (Low/Med/High)
- ✓ Dependencies identified
- ✓ Backward compatibility addressed
- ✓ Data sources specified
- ✓ MVP scope defined
- ✓ Firestore schema extensions minimal/non-breaking

---

## Sources

- [Firebase Firestore Data Model](https://firebase.google.com/docs/firestore/data-model)
- [Cloud Firestore on Data Constraints & Evolvability](https://medium.com/firebase-developers/cloud-firestore-on-data-constraints-and-evolvability-a8f44b34fde8)
- [EZFacility: Sports Facility Management Metrics](https://www.ezfacility.com/blog/sports-facility-management-metrics/)
- [Firestore Query Best Practices](https://firebase.google.com/docs/firestore/best-practices)
