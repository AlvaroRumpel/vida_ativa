// concurrency-test.js — SPIKE-07: Anti-Double-Booking Concurrency Proof
// 50 simultaneous book_slot() calls → exactly 1 CONFIRMED, 49 SLOT_ALREADY_BOOKED.
// Run: node spike-supabase/tests/concurrency-test.js
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import path from 'path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '../.env') });

const SUPABASE_URL            = process.env.SUPABASE_URL;
const SUPABASE_PUBLISHABLE_KEY = process.env.SUPABASE_PUBLISHABLE_KEY;
const SUPABASE_SECRET_KEY     = process.env.SUPABASE_SECRET_KEY;

if (!SUPABASE_URL || !SUPABASE_PUBLISHABLE_KEY || !SUPABASE_SECRET_KEY) {
  console.error('FATAL: .env missing SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, or SUPABASE_SECRET_KEY');
  process.exit(1);
}

const TENANT_A            = '10000000-0000-0000-0000-000000000001';
const TEST_DATE           = '2099-12-31';
const CONCURRENT_REQUESTS = 50;

const adminClient = createClient(SUPABASE_URL, SUPABASE_SECRET_KEY);

async function setupUser() {
  const ts = Date.now();
  const email    = `conctest-${ts}@example.com`;
  const password = 'TestPassword123!';

  const { data: signUpData, error: signUpErr } = await adminClient.auth.admin.createUser({ email, password, email_confirm: true });
  if (signUpErr || !signUpData.user) throw new Error(`createUser failed: ${signUpErr?.message}`);
  const userId = signUpData.user.id;

  const { error: memErr } = await adminClient.from('memberships')
    .insert({ tenant_id: TENANT_A, user_id: userId, role: 'client' });
  if (memErr) throw new Error(`Membership insert failed: ${memErr.message}`);

  const anonClient = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);
  const { data: signInData, error: signInErr } = await anonClient.auth.signInWithPassword({ email, password });
  if (signInErr || !signInData.session) throw new Error(`signIn failed: ${signInErr?.message}`);

  const jwt = JSON.parse(Buffer.from(signInData.session.access_token.split('.')[1], 'base64').toString('utf8'));
  console.log(`Test user created: ${userId}`);
  console.log(`tenant_id in JWT: ${jwt.app_metadata?.tenant_id ?? 'MISSING!'}`);

  if (!jwt.app_metadata?.tenant_id) {
    throw new Error('Auth Hook did NOT inject tenant_id. Check hook deployment.');
  }

  return { userId, session: signInData.session };
}

async function createTestSlot() {
  const { data: slot, error } = await adminClient
    .from('slots')
    .insert({
      tenant_id:   TENANT_A,
      day_of_week: 1,
      start_time:  '10:00',
      end_time:    '11:00',
      price:       100.00,
      is_active:   true
    })
    .select('id')
    .single();

  if (error || !slot) throw new Error(`Slot creation failed: ${error?.message}`);
  console.log(`Test slot created: ${slot.id}`);
  return slot.id;
}

async function runConcurrencyTest(userClient, slotId, userId) {
  console.log(`\n=== CONCURRENCY TEST ===`);
  console.log(`Firing ${CONCURRENT_REQUESTS} simultaneous book_slot() calls...`);
  console.log(`slot_id: ${slotId}`);
  console.log(`booking_date: ${TEST_DATE}`);

  const calls = Array.from({ length: CONCURRENT_REQUESTS }, () =>
    userClient.rpc('book_slot', {
      p_slot_id:      slotId,
      p_booking_date: TEST_DATE,
      p_user_id:      userId,
      p_tenant_id:    TENANT_A,
    })
  );

  const results = await Promise.allSettled(calls);

  const summary = results.reduce((acc, r) => {
    if (r.status === 'rejected') { acc.networkErrors++; return acc; }
    const row = r.value.data?.[0];
    if (!row) { acc.nullResults++; return acc; }
    if (row.success === true) {
      acc.confirmed++;
      acc.bookingId = row.booking_id;
    } else {
      acc[row.error_code] = (acc[row.error_code] ?? 0) + 1;
    }
    return acc;
  }, { confirmed: 0, SLOT_ALREADY_BOOKED: 0, SLOT_LOCKED_RETRY: 0, USER_NOT_IN_TENANT: 0, networkErrors: 0, nullResults: 0, bookingId: null });

  console.log('\n=== RESULTS ===');
  console.table({
    'CONFIRMED (success=true)': summary.confirmed,
    'SLOT_ALREADY_BOOKED':      summary.SLOT_ALREADY_BOOKED,
    'SLOT_LOCKED_RETRY':        summary.SLOT_LOCKED_RETRY,
    'USER_NOT_IN_TENANT':       summary.USER_NOT_IN_TENANT,
    'Network errors':           summary.networkErrors,
    'Null results':             summary.nullResults,
  });

  if (summary.bookingId) console.log(`Booking ID confirmed: ${summary.bookingId}`);

  const totalResolved = summary.confirmed + summary.SLOT_ALREADY_BOOKED + summary.SLOT_LOCKED_RETRY;
  const pass = summary.confirmed === 1 && totalResolved === CONCURRENT_REQUESTS && summary.networkErrors === 0;

  console.log(`\nExpected: confirmed=1, SLOT_ALREADY_BOOKED=${CONCURRENT_REQUESTS - 1}`);
  console.log(`Got:      confirmed=${summary.confirmed}, SLOT_ALREADY_BOOKED=${summary.SLOT_ALREADY_BOOKED}, SLOT_LOCKED_RETRY=${summary.SLOT_LOCKED_RETRY}`);
  console.log(`\nRESULT: ${pass ? 'PASS' : 'FAIL'}`);

  return { pass, summary, slotId };
}

async function cleanup(slotId, userId) {
  console.log('\n=== CLEANUP ===');
  const { error: bErr } = await adminClient.from('bookings').delete().eq('slot_id', slotId).eq('booking_date', TEST_DATE);
  console.log(`Booking deleted: ${bErr ? 'ERROR: ' + bErr.message : 'OK'}`);
  const { error: sErr } = await adminClient.from('slots').delete().eq('id', slotId);
  console.log(`Slot deleted: ${sErr ? 'ERROR: ' + sErr.message : 'OK'}`);
  const { error: uErr } = await adminClient.auth.admin.deleteUser(userId);
  console.log(`User deleted: ${uErr ? 'ERROR: ' + uErr.message : 'OK'}`);
}

async function main() {
  console.log('=== SETUP ===');
  const { userId, session } = await setupUser();
  const slotId = await createTestSlot();

  const userClient = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
    global: { headers: { Authorization: `Bearer ${session.access_token}` } }
  });

  try {
    await runConcurrencyTest(userClient, slotId, userId);
  } finally {
    await cleanup(slotId, userId);
  }
}

main().catch(err => {
  console.error('Script error:', err.message);
  process.exit(1);
});
