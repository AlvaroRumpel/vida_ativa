/**
 * Seed script — populates /config/dashboard/periods/{week,month,year}
 * in the vida-ativa-staging Firebase project with realistic test data,
 * including trend arrays for KPI sparklines (ADMN-30).
 *
 * Usage:
 *   node scripts/seed_dashboard_staging.js
 *
 * The staging service account key is read from the same directory.
 */

const admin = require('firebase-admin');
const path = require('path');

const KEY_FILE = path.join(__dirname, 'vida-ativa-staging-firebase-adminsdk-fbsvc-07010ee1af.json');

admin.initializeApp({
  credential: admin.credential.cert(KEY_FILE),
  projectId: 'vida-ativa-staging',
});

const db = admin.firestore();

// ── Seed data ──────────────────────────────────────────────────────────────────

const now = admin.firestore.Timestamp.now();

const week = {
  period: 'week',
  startDate: '2026-06-01',
  endDate: '2026-06-07',
  updatedAt: now,
  // Counters
  totalBookings: 38,
  confirmedBookings: 28,
  cancelledBookings: 4,
  pendingBookings: 6,
  totalSlotsBooked: 28,
  totalRevenue: 4820,
  pixRevenue: 3120,
  onArrivalRevenue: 1700,
  // Calculated
  totalSlotsAvailable: 49,
  occupancyRate: 0.571,
  avgTicket: 172.14,
  conversionRate: 0.737,
  noShowRate: 0.105,
  uniqueClients: 22,
  newClients: 8,
  returnRate: 0.636,
  // Sparkline trends (7 daily values — ADMN-30)
  occupancyTrend: [0.40, 0.42, 0.38, 0.55, 0.60, 0.58, 0.64],
  revenueTrend: [600, 520, 700, 680, 820, 720, 780],
  avgTicketTrend: [110, 115, 118, 120, 124, 126, 128],
  conversionTrend: [0.72, 0.70, 0.71, 0.69, 0.68, 0.67, 0.68],
  noShowTrend: [0.09, 0.085, 0.08, 0.074, 0.07, 0.069, 0.068],
  // Sport breakdown
  topClients: [
    { userId: 'user-seed-01', displayName: 'Carlos Mendes', bookingCount: 6 },
    { userId: 'user-seed-02', displayName: 'Ana Paula',     bookingCount: 4 },
    { userId: 'user-seed-03', displayName: 'João Ferreira', bookingCount: 3 },
  ],
  revenueBySport: [
    { sport: 'Beach Tennis', revenue: 2180 },
    { sport: 'Futevôlei',    revenue: 1340 },
    { sport: 'Vôlei',        revenue:  820 },
    { sport: 'Beach Soccer', revenue:  480 },
  ],
};

const month = {
  ...week,
  period: 'month',
  startDate: '2026-06-01',
  endDate: '2026-06-30',
  totalBookings: 142,
  confirmedBookings: 105,
  cancelledBookings: 18,
  pendingBookings: 19,
  totalSlotsBooked: 105,
  totalRevenue: 18340,
  pixRevenue: 11900,
  onArrivalRevenue: 6440,
  totalSlotsAvailable: 196,
  occupancyRate: 0.536,
  avgTicket: 174.67,
  conversionRate: 0.739,
  noShowRate: 0.127,
  uniqueClients: 58,
  newClients: 21,
  returnRate: 0.638,
  occupancyTrend: [0.42, 0.48, 0.51, 0.49, 0.55, 0.57, 0.54],
  revenueTrend: [2100, 2400, 2800, 2600, 3200, 2900, 2340],
  avgTicketTrend: [168, 170, 172, 171, 175, 176, 174],
  conversionTrend: [0.71, 0.73, 0.74, 0.72, 0.75, 0.74, 0.74],
  noShowTrend: [0.14, 0.13, 0.12, 0.13, 0.11, 0.12, 0.13],
  revenueBySport: [
    { sport: 'Beach Tennis', revenue: 8240 },
    { sport: 'Futevôlei',    revenue: 5100 },
    { sport: 'Vôlei',        revenue: 3200 },
    { sport: 'Beach Soccer', revenue: 1800 },
  ],
};

const year = {
  ...week,
  period: 'year',
  startDate: '2026-01-01',
  endDate: '2026-12-31',
  totalBookings: 1480,
  confirmedBookings: 1094,
  cancelledBookings: 189,
  pendingBookings: 197,
  totalSlotsBooked: 1094,
  totalRevenue: 191200,
  pixRevenue: 124100,
  onArrivalRevenue: 67100,
  totalSlotsAvailable: 2156,
  occupancyRate: 0.507,
  avgTicket: 174.86,
  conversionRate: 0.739,
  noShowRate: 0.128,
  uniqueClients: 182,
  newClients: 67,
  returnRate: 0.632,
  occupancyTrend: [0.38, 0.41, 0.45, 0.49, 0.50, 0.52, 0.51],
  revenueTrend: [18200, 19400, 22100, 24600, 26300, 27800, 28900],
  avgTicketTrend: [162, 165, 168, 170, 172, 174, 175],
  conversionTrend: [0.69, 0.71, 0.72, 0.73, 0.74, 0.74, 0.74],
  noShowTrend: [0.16, 0.15, 0.14, 0.13, 0.13, 0.12, 0.13],
  revenueBySport: [
    { sport: 'Beach Tennis', revenue: 85920 },
    { sport: 'Futevôlei',    revenue: 53200 },
    { sport: 'Vôlei',        revenue: 33440 },
    { sport: 'Beach Soccer', revenue: 18640 },
  ],
};

// ── Write ──────────────────────────────────────────────────────────────────────

async function seed() {
  const periodsRef = db.collection('config').doc('dashboard').collection('periods');

  const batch = db.batch();
  batch.set(periodsRef.doc('week'),  week);
  batch.set(periodsRef.doc('month'), month);
  batch.set(periodsRef.doc('year'),  year);

  await batch.commit();
  console.log('✓ Seeded config/dashboard/periods/{week,month,year} in vida-ativa-staging');
  process.exit(0);
}

seed().catch(err => {
  console.error('✗ Seed failed:', err.message);
  process.exit(1);
});
