# Technology Stack: Dashboard & Sport Field Integration

**Project:** Vida Ativa
**Researched:** 2026-05-19
**Scope:** v5.0 (Dashboard aggregation + Sport field feature)

---

## Recommended Stack

### Core Framework
| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Flutter | 3.22+ | UI framework for PWA | Already in use; BLoC/Cubit pattern established |
| flutter_bloc | 8.1.6+ | State management | Used throughout project; familiar pattern for team |
| cloud_firestore | 4.x+ | Real-time database | Already integrated; supports streams for dashboard |
| cloud_functions | 4.x+ | Serverless aggregations | Deploy scheduled functions + triggers for counters |
| firebase_auth | 4.x+ | Authentication | Already in use |
| sentry_flutter | 7.x+ | Error monitoring | Already integrated; log aggregation errors |

### Dashboard Libraries
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| fl_chart | 0.60.0+ | Charts (line, bar, heatmap) | Admin sees revenue trends, occupancy grid |
| intl | 0.19.0+ | Date/number formatting | Display metrics by period (week/month/year) |
| equatable | 2.0.5+ | Value equality | DashboardMetricsModel, SportConfigModel |

### Cloud Functions (Node.js)
| Library | Version | Purpose | Why |
|---------|---------|---------|-----|
| firebase-admin | 12.0.0+ | Admin SDK for CF | Write aggregations to Firestore atomically |
| firebase-functions | 5.0.0+ | CF runtime | Already used; deploy triggers + scheduled |

### Development & Testing
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter_test | stable | Unit tests for models | Test DashboardMetricsModel, SportConfigModel |
| bloc_test | 9.1.0+ | BLoC testing | Test DashboardCubit, SportConfigCubit state transitions |
| mocktail | 1.0.0+ | Mocking Firestore | Mock CF, database reads in unit tests |

---

## Installation

```bash
# Core (already present)
flutter pub add flutter_bloc
flutter pub add cloud_firestore
flutter pub add cloud_functions
flutter pub add firebase_auth
flutter pub add sentry_flutter

# New dependencies for v5.0
flutter pub add fl_chart              # Charts
flutter pub add intl                  # Date/number formatting

# Dev dependencies (already present)
flutter pub add -d flutter_test
flutter pub add -d bloc_test
flutter pub add -d mocktail
```

### Cloud Functions Setup

```bash
cd functions
npm install firebase-admin@12
npm install firebase-functions@5
npm install --save-dev @types/node typescript

# Deploy aggregations
firebase deploy --only functions
```

---

## Alternatives Considered

| Category | Recommended | Alternative | Why Not |
|----------|-------------|-------------|---------|
| Dashboard Charts | fl_chart | charts_flutter, syncfusion | fl_chart is lightweight, no licensing; syncfusion = premium |
| Real-Time Aggregation | Write-time (Cloud Functions trigger) | Read-time (aggregation query) + Redis cache | Aggregation queries don't support real-time listeners; Redis adds infrastructure |
| Scheduled Functions | Firebase pubsub.schedule() | Cloud Scheduler + HTTP | pubsub is integrated, no extra setup |
| Sport List Storage | /config/sports (Firestore) | In-app hardcoded enum | Firestore allows admin edit without redeploy |
| Sport Dropdown | Built-in Dropdown widget | dropdown_button2 | Built-in sufficient; dropdown_button2 adds no value for simple list |

---

## Configuration

### Firestore Indexes (Required)
The dashboard batch job queries bookings by date range + status:

```bash
# Create indexes in Firebase console or deploy via rules
firestore/indexes.json:
{
  "indexes": [
    {
      "collectionGroup": "bookings",
      "queryScope": "Collection",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "ASCENDING" }
      ]
    }
  ]
}
```

Deploy: `firebase deploy --only firestore:indexes`

### Environment Variables (Cloud Functions)
No new env vars needed. Existing `/config/mercadopago`, `/config/booking` are read by CF.

---

## Sources

- [Flutter BLoC Library](https://bloclibrary.dev/)
- [Cloud Firestore Documentation](https://firebase.google.com/docs/firestore)
- [Cloud Functions Scheduling](https://firebase.google.com/docs/functions/schedule-functions)
- [fl_chart Package](https://pub.dev/packages/fl_chart)
- [Firebase Admin SDK](https://firebase.google.com/docs/admin/setup)
