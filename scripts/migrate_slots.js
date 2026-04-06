/**
 * migrate_slots.js
 *
 * Migrates slots from recurring (dayOfWeek-based) to date-specific.
 *
 * What it does:
 *   0. Creates a full backup of slots + bookings to scripts/backup-<project>-<timestamp>.json
 *   1. Reads all existing legacy slots (which have dayOfWeek field, no date field)
 *   2. Calculates how many weeks to generate:
 *        weeksToGenerate = totalLegacySlots / uniqueTemplates
 *      starting from START_DATE (2026-03-28), preserving the same slot density as today
 *   3. For each slot × date pair from bookings → creates a date-specific slot doc
 *   4. For all dates from START_DATE to START_DATE + weeksToGenerate → creates date-specific slots
 *   5. Updates each booking's slotId to reference the new date-specific slot doc
 *   6. Deletes the old recurring slot docs
 *
 * Usage:
 *   node migrate_slots.js --project <firebase-project-id> [--dry-run] [--key <keyfile>]
 *
 * The service account key must be at ./service-account.json or passed via --key.
 *
 * Dry-run mode prints all planned operations without writing to Firestore.
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// ─── Config ──────────────────────────────────────────────────────────────────

const START_DATE = new Date('2026-03-28T00:00:00.000Z');
const END_DATE   = new Date('2026-12-31T00:00:00.000Z');

const DRY_RUN = process.argv.includes('--dry-run');
const projectArg = process.argv.indexOf('--project');
const PROJECT_ID = projectArg !== -1 ? process.argv[projectArg + 1] : null;

if (!PROJECT_ID) {
  console.error('Usage: node migrate_slots.js --project <firebase-project-id> [--dry-run] [--key <keyfile>]');
  process.exit(1);
}

// ─── Init ─────────────────────────────────────────────────────────────────────

const keyArg = process.argv.indexOf('--key');
const keyFile = keyArg !== -1 ? process.argv[keyArg + 1] : 'service-account.json';
const serviceAccountPath = path.join(__dirname, keyFile);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccountPath),
  projectId: PROJECT_ID,
});
const db = admin.firestore();

// ─── Helpers ──────────────────────────────────────────────────────────────────

function toDateString(date) {
  const y = date.getUTCFullYear();
  const m = String(date.getUTCMonth() + 1).padStart(2, '0');
  const d = String(date.getUTCDate()).padStart(2, '0');
  return `${y}-${m}-${d}`;
}

/**
 * Returns all dates from START_DATE up to END_DATE (inclusive)
 * that match a given weekday.
 * weekday: 1=Mon … 7=Sun (Dart/ISO convention).
 */
function generateDates(weekday) {
  const jsDay = weekday === 7 ? 0 : weekday; // convert to JS: Sun=0
  const dates = [];

  // Find first occurrence of jsDay on or after START_DATE
  const cursor = new Date(START_DATE);
  const startDow = cursor.getUTCDay();
  let diff = (jsDay - startDow + 7) % 7;
  cursor.setUTCDate(cursor.getUTCDate() + diff);

  while (cursor <= END_DATE) {
    dates.push(toDateString(cursor));
    cursor.setUTCDate(cursor.getUTCDate() + 7);
  }

  return dates;
}

// ─── Backup ───────────────────────────────────────────────────────────────────

async function backup() {
  console.log('\nCreating backup...');
  const [slotsSnap, bookingsSnap] = await Promise.all([
    db.collection('slots').get(),
    db.collection('bookings').get(),
  ]);

  const data = {
    createdAt: new Date().toISOString(),
    project: PROJECT_ID,
    slots: slotsSnap.docs.map(d => ({ id: d.id, ...d.data() })),
    bookings: bookingsSnap.docs.map(d => ({ id: d.id, ...d.data() })),
  };

  const ts = new Date().toISOString().replace(/[:.]/g, '-').slice(0, 19);
  const backupFile = path.join(__dirname, `backup-${PROJECT_ID}-${ts}.json`);
  fs.writeFileSync(backupFile, JSON.stringify(data, null, 2), 'utf8');
  console.log(`Backup saved to: ${backupFile}`);
  console.log(`  Slots: ${data.slots.length}, Bookings: ${data.bookings.length}\n`);

  return data;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function migrate() {
  console.log(`\nMigrating slots for project: ${PROJECT_ID}`);
  console.log(`Start date: ${toDateString(START_DATE)}`);
  if (DRY_RUN) console.log('DRY-RUN mode — no writes will happen\n');

  // 0. Backup (skip on dry-run to avoid unnecessary reads billed)
  if (!DRY_RUN) {
    await backup();
  }

  // 1. Read all existing slots
  const slotsSnap = await db.collection('slots').get();
  const oldSlots = slotsSnap.docs.map(d => ({ id: d.id, ...d.data() }));
  console.log(`Found ${oldSlots.length} existing slot(s)`);

  // Only process slots that still use dayOfWeek (not yet migrated)
  const legacySlots = oldSlots.filter(s => s.dayOfWeek !== undefined && s.date === undefined);
  const alreadyMigrated = oldSlots.length - legacySlots.length;
  if (alreadyMigrated > 0) console.log(`  ${alreadyMigrated} already migrated (skipped)`);
  if (legacySlots.length === 0) {
    console.log('Nothing to migrate.');
    return;
  }
  console.log(`  ${legacySlots.length} legacy (dayOfWeek-based) slot(s) to migrate`);

  console.log(`  Generating slots from ${toDateString(START_DATE)} to ${toDateString(END_DATE)}\n`);

  // 2. Read all non-cancelled bookings
  const bookingsSnap = await db.collection('bookings')
    .where('status', 'in', ['pending', 'confirmed'])
    .get();
  const bookings = bookingsSnap.docs.map(d => ({ id: d.id, ...d.data() }));
  console.log(`Found ${bookings.length} active booking(s)\n`);

  // 3. Build migration map: oldSlotId → Map<date, newSlotId>
  const migrationMap = {}; // { [oldSlotId]: { [date]: newSlotId } }
  const newSlotDocs = []; // { ref, data } to create
  const bookingUpdates = []; // { bookingId, newSlotId }

  const dayNames = ['', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  for (const slot of legacySlots) {
    migrationMap[slot.id] = {};

    // Dates found in existing bookings for this slot (may be before START_DATE)
    const bookedDates = bookings
      .filter(b => b.slotId === slot.id)
      .map(b => b.date)
      .filter(Boolean);

    // All dates from START_DATE to END_DATE for this weekday
    const generatedDates = generateDates(slot.dayOfWeek);

    // Union: booked dates (for data integrity) + generated dates
    const allDates = [...new Set([...bookedDates, ...generatedDates])].sort();

    for (const date of allDates) {
      const newSlotRef = db.collection('slots').doc();
      migrationMap[slot.id][date] = newSlotRef.id;
      newSlotDocs.push({
        ref: newSlotRef,
        data: {
          date,
          startTime: slot.startTime,
          price: slot.price,
          isActive: slot.isActive,
        },
      });
    }

    const dayName = dayNames[slot.dayOfWeek] || `day${slot.dayOfWeek}`;
    console.log(`Slot ${slot.id} (${dayName} ${slot.startTime}) → ${allDates.length} date-specific slot(s)`);
  }

  // 4. Map booking updates
  for (const booking of bookings) {
    const dateMap = migrationMap[booking.slotId];
    if (!dateMap) continue;
    const newSlotId = dateMap[booking.date];
    if (!newSlotId) {
      console.warn(`  WARNING: no new slot for booking ${booking.id} (slotId=${booking.slotId}, date=${booking.date})`);
      continue;
    }
    bookingUpdates.push({ bookingId: booking.id, newSlotId });
  }

  // ─── Summary ───────────────────────────────────────────────────────────────
  console.log(`\nPlan:`);
  console.log(`  Create ${newSlotDocs.length} new date-specific slot(s)`);
  console.log(`  Update ${bookingUpdates.length} booking(s)`);
  console.log(`  Delete ${legacySlots.length} old recurring slot(s)`);

  if (DRY_RUN) {
    console.log('\nDRY-RUN complete. Re-run without --dry-run to apply.');
    return;
  }

  // ─── Apply in batches (Firestore batch limit: 500 ops) ─────────────────────
  const OPS_PER_BATCH = 400;
  let batch = db.batch();
  let opCount = 0;

  const flush = async () => {
    await batch.commit();
    batch = db.batch();
    opCount = 0;
  };

  const addOp = async (fn) => {
    fn(batch);
    opCount++;
    if (opCount >= OPS_PER_BATCH) await flush();
  };

  // Create new slots
  for (const { ref, data } of newSlotDocs) {
    await addOp(b => b.set(ref, data));
  }

  // Update bookings
  for (const { bookingId, newSlotId } of bookingUpdates) {
    await addOp(b => b.update(db.collection('bookings').doc(bookingId), { slotId: newSlotId }));
  }

  // Delete old slots
  for (const slot of legacySlots) {
    await addOp(b => b.delete(db.collection('slots').doc(slot.id)));
  }

  if (opCount > 0) await flush();

  console.log('\nMigration complete.');
  console.log(`  Created: ${newSlotDocs.length} slots`);
  console.log(`  Updated: ${bookingUpdates.length} bookings`);
  console.log(`  Deleted: ${legacySlots.length} old slots`);
}

migrate().catch(err => {
  console.error('Migration failed:', err);
  process.exit(1);
});
