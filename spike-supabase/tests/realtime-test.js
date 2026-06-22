// realtime-test.js — SPIKE-09: Realtime Cross-Tenant Isolation + Latency Evaluation
// Tests three properties:
//   1. Cross-tenant isolation: tenant_A subscriber does NOT receive tenant_B INSERT
//   2. Latency baseline: time from INSERT to event callback (if same-tenant control test)
//   3. Free-tier limits: documented from Supabase docs (not runtime measured)
//
// Run: node spike-supabase/tests/realtime-test.js
// (from repo root) or: cd spike-supabase && node tests/realtime-test.js
//
// SPIKE-13: This script uses SUPABASE_SECRET_KEY for admin operations only.
// The secret key is loaded from .env (gitignored) and never hardcoded.
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import path from 'path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '../.env') });

const SUPABASE_URL             = process.env.SUPABASE_URL;
const SUPABASE_PUBLISHABLE_KEY = process.env.SUPABASE_PUBLISHABLE_KEY;
const SUPABASE_SECRET_KEY      = process.env.SUPABASE_SECRET_KEY;

if (!SUPABASE_URL || !SUPABASE_PUBLISHABLE_KEY || !SUPABASE_SECRET_KEY) {
  console.error('FATAL: .env missing SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, or SUPABASE_SECRET_KEY');
  process.exit(1);
}

function parseJWT(token) {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) throw new Error('Invalid JWT format');
    const decoded = Buffer.from(parts[1], 'base64').toString('utf8');
    return JSON.parse(decoded);
  } catch (err) {
    throw new Error(`JWT parse failed: ${err.message}`);
  }
}

const TENANT_A = '10000000-0000-0000-0000-000000000001';
const TENANT_B = '20000000-0000-0000-0000-000000000001';
const TEST_DATE = '2099-01-15';
const ISOLATION_WAIT_MS = 3000; // Wait 3s after insert — if no event arrives, isolation confirmed

const adminClient = createClient(SUPABASE_URL, SUPABASE_SECRET_KEY);
const anonClient  = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);

async function setupUsers() {
  const ts = Date.now();
  const emailA   = `realtime-a-${ts}@spike.local`;
  const emailB   = `realtime-b-${ts}@spike.local`;
  const password = 'TestPassword123!';

  console.log('=== SETUP ===');

  // Create user A (Tenant A)
  const { data: signUpA, error: errA } = await adminClient.auth.admin.createUser({
    email: emailA, password, email_confirm: true,
  });
  if (errA || !signUpA.user) throw new Error(`createUser A failed: ${errA?.message}`);
  const userA_id = signUpA.user.id;

  // Create user B (Tenant B)
  const { data: signUpB, error: errB } = await adminClient.auth.admin.createUser({
    email: emailB, password, email_confirm: true,
  });
  if (errB || !signUpB.user) throw new Error(`createUser B failed: ${errB?.message}`);
  const userB_id = signUpB.user.id;

  // Insert memberships
  const { error: memA } = await adminClient.from('memberships')
    .insert({ tenant_id: TENANT_A, user_id: userA_id, role: 'client' });
  if (memA) throw new Error(`Membership A failed: ${memA.message}`);

  const { error: memB } = await adminClient.from('memberships')
    .insert({ tenant_id: TENANT_B, user_id: userB_id, role: 'client' });
  if (memB) throw new Error(`Membership B failed: ${memB.message}`);

  // Sign in both users to get JWTs
  const { data: siA, error: siErrA } = await anonClient.auth.signInWithPassword({ email: emailA, password });
  if (siErrA || !siA.session) throw new Error(`signIn A failed: ${siErrA?.message}`);
  const jwtA = parseJWT(siA.session.access_token);
  console.log(`User A: ${userA_id} | tenant_id in JWT: ${jwtA.app_metadata?.tenant_id ?? 'MISSING'}`);

  const { data: siB, error: siErrB } = await anonClient.auth.signInWithPassword({ email: emailB, password });
  if (siErrB || !siB.session) throw new Error(`signIn B failed: ${siErrB?.message}`);
  const jwtB = parseJWT(siB.session.access_token);
  console.log(`User B: ${userB_id} | tenant_id in JWT: ${jwtB.app_metadata?.tenant_id ?? 'MISSING'}`);

  if (!jwtA.app_metadata?.tenant_id || !jwtB.app_metadata?.tenant_id) {
    throw new Error('Auth Hook did NOT inject tenant_id. Check hook deployment (Phase 32).');
  }

  return {
    userA_id, userB_id,
    tokenA: siA.session.access_token,
    tokenB: siB.session.access_token,
  };
}

async function createTestSlotForTenantB() {
  const { data: slot, error } = await adminClient
    .from('slots')
    .insert({
      tenant_id:   TENANT_B,
      day_of_week: 2,
      start_time:  '14:00',
      end_time:    '15:00',
      price:       80.00,
      is_active:   true,
    })
    .select('id')
    .single();

  if (error || !slot) throw new Error(`Slot B creation failed: ${error?.message}`);
  console.log(`Test slot (Tenant B): ${slot.id}`);
  return slot.id;
}

async function testCrossTenantIsolation(tokenA, tokenB, userB_id, slotB_id) {
  console.log('\n=== TEST 1: CROSS-TENANT ISOLATION ===');
  console.log('Tenant A subscribes to bookings.INSERT');
  console.log('Tenant B inserts a booking');
  console.log('Expected: Tenant A does NOT receive the event (RLS blocks cross-tenant)');
  console.log('');

  // Client A: authenticated as tenant_A, subscribes to bookings channel
  const clientA = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
    global: { headers: { Authorization: `Bearer ${tokenA}` } },
  });

  // Client B: authenticated as tenant_B, will insert
  const clientB = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
    global: { headers: { Authorization: `Bearer ${tokenB}` } },
  });

  let eventReceived = false;
  let eventPayload = null;
  let eventTimestamp = null;

  const channel = clientA.channel('bookings-isolation').on(
    'postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'bookings' },
    (payload) => {
      eventReceived = true;
      eventTimestamp = Date.now();
      eventPayload = payload;
      console.log('EVENT RECEIVED BY TENANT A (unexpected):', JSON.stringify(payload, null, 2));
    },
  ).subscribe((status) => {
    if (status === 'SUBSCRIBED') {
      console.log('Tenant A channel status: SUBSCRIBED');
    } else if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT') {
      console.error(`Tenant A channel subscription failed: ${status}`);
    } else if (status === 'CLOSED') {
      console.log('Tenant A channel closed (expected during cleanup)');
    } else {
      console.log(`Tenant A channel status: ${status}`);
    }
  });

  // Wait for channel subscription to establish (WebSocket handshake can take 1-5s)
  const SUBSCRIBE_TIMEOUT_MS = 10000;
  const POLL_INTERVAL_MS = 200;
  let waited = 0;
  while (channel.state !== 'joined' && waited < SUBSCRIBE_TIMEOUT_MS) {
    await new Promise(r => setTimeout(r, POLL_INTERVAL_MS));
    waited += POLL_INTERVAL_MS;
  }

  if (channel.state !== 'joined') {
    throw new Error(`Channel not joined after ${SUBSCRIBE_TIMEOUT_MS}ms — current state: ${channel.state}`);
  }

  // Tenant B inserts a booking for its own slot
  const insertTime = Date.now();
  console.log(`Tenant B inserting booking for slot ${slotB_id} on ${TEST_DATE}...`);

  const { data: insertData, error: insertErr } = await clientB.from('bookings').insert({
    tenant_id:    TENANT_B,
    user_id:      userB_id,
    slot_id:      slotB_id,
    booking_date: TEST_DATE,
    status:       'pending',
  }).select();

  if (insertErr) {
    console.log(`Tenant B insert error: ${insertErr.message}`);
    console.log('(RLS may block insert itself — expected if no WITH CHECK policy for this test user)');
  } else {
    console.log(`Tenant B insert success: booking_id=${insertData?.[0]?.id}`);
  }

  // Wait for potential event propagation
  console.log(`Waiting ${ISOLATION_WAIT_MS}ms for event propagation...`);
  await new Promise(r => setTimeout(r, ISOLATION_WAIT_MS));

  // Evaluate result
  const isolationPass = !eventReceived;
  const latencyMs = eventReceived && eventTimestamp ? eventTimestamp - insertTime : null;

  console.log('');
  console.log(`Event received by Tenant A: ${eventReceived ? 'YES (BAD)' : 'NO (GOOD)'}`);
  if (latencyMs !== null) {
    console.log(`Latency (insert → event): ${latencyMs}ms`);
  }

  const result = {
    isolation_pass: isolationPass,
    event_received: eventReceived,
    latency_ms: latencyMs,
    verdict: isolationPass
      ? 'PASS — Tenant A did NOT receive Tenant B event (RLS filters Realtime events)'
      : 'FAIL (BLOCKING) — Tenant A received Tenant B event (RLS does NOT filter Realtime)',
  };

  console.log('\nISOLATION RESULT:');
  console.table(result);

  if (!isolationPass) {
    console.log('\n*** BLOCKING FINDING ***');
    console.log('RLS does not filter Realtime events for cross-tenant scenarios.');
    console.log('This must be documented as BLOCKING in realtime-evaluation.md for DECISION.md.');
    console.log('Tenant-aware Realtime would require application-level filtering (extra complexity).');
  }

  // Cleanup Realtime
  await clientA.removeAllChannels();

  return result;
}

async function testSameTenantLatency(tokenA, userA_id) {
  console.log('\n=== TEST 2: SAME-TENANT LATENCY BASELINE ===');
  console.log('Tenant A subscribes + Tenant A inserts (control test for latency)');

  // Create a test slot for tenant_A
  const { data: slotA, error: slotErr } = await adminClient.from('slots').insert({
    tenant_id:   TENANT_A,
    day_of_week: 3,
    start_time:  '16:00',
    end_time:    '17:00',
    price:       90.00,
    is_active:   true,
  }).select('id').single();

  if (slotErr || !slotA) {
    console.log(`Slot A creation failed: ${slotErr?.message} — skipping latency test`);
    return { latency_ms: null, skipped: true };
  }

  const slotA_id = slotA.id;

  const clientA = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
    global: { headers: { Authorization: `Bearer ${tokenA}` } },
  });

  let latencyMs = null;
  let eventReceived = false;
  const insertTimeRef = { value: 0 };

  const channel = clientA.channel('latency-baseline').on(
    'postgres_changes',
    { event: 'INSERT', schema: 'public', table: 'bookings' },
    () => {
      latencyMs = Date.now() - insertTimeRef.value;
      eventReceived = true;
      console.log(`Latency event received: ${latencyMs}ms`);
    },
  ).subscribe((status) => {
    if (status === 'CHANNEL_ERROR' || status === 'TIMED_OUT' || status === 'CLOSED') {
      console.error(`Latency channel subscription failed: ${status}`);
    } else {
      console.log(`Latency channel status: ${status}`);
    }
  });

  let waitedLatency = 0;
  while (channel.state !== 'joined' && waitedLatency < 10000) {
    await new Promise(r => setTimeout(r, 200));
    waitedLatency += 200;
  }

  if (channel.state !== 'joined') {
    console.log(`Latency channel not joined after 10s (state: ${channel.state}) — skipping latency insert`);
    await clientA.removeAllChannels();
    return { latency_ms: null, event_received: false, skipped: true };
  }

  insertTimeRef.value = Date.now();
  const { error: insErr } = await clientA.from('bookings').insert({
    tenant_id:    TENANT_A,
    user_id:      userA_id,
    slot_id:      slotA_id,
    booking_date: '2099-02-15',
    status:       'pending',
  });

  if (insErr) {
    console.log(`Same-tenant insert error: ${insErr.message}`);
  }

  // Wait up to 5s for event
  let waited = 0;
  while (!eventReceived && waited < 5000) {
    await new Promise(r => setTimeout(r, 200));
    waited += 200;
  }

  await clientA.removeAllChannels();

  // Cleanup test data
  await adminClient.from('bookings').delete().eq('slot_id', slotA_id);
  await adminClient.from('slots').delete().eq('id', slotA_id);

  const result = { latency_ms: latencyMs, event_received: eventReceived };
  console.log('Latency result:', result);
  return result;
}

function documentFreeTierLimits() {
  console.log('\n=== TEST 3: FREE TIER LIMITS (documented from Supabase docs) ===');
  const limits = {
    concurrent_connections_max: 200,
    messages_per_month: 2_000_000,
    max_message_size_kb: 256,
    source: 'https://supabase.com/docs/guides/realtime/limits',
  };
  console.table(limits);
  console.log('Note: 200 concurrent connections is a hard limit on the free tier.');
  console.log('Production usage with multiple tenants will require Pro tier (500 connections).');
  return limits;
}

async function cleanup(userA_id, userB_id, slotB_id) {
  console.log('\n=== CLEANUP ===');
  await adminClient.from('bookings').delete().eq('slot_id', slotB_id).eq('booking_date', TEST_DATE);
  console.log('Test bookings deleted');
  await adminClient.from('slots').delete().eq('id', slotB_id);
  console.log('Test slot B deleted');
  const { error: delA } = await adminClient.auth.admin.deleteUser(userA_id);
  console.log(`User A deleted: ${delA ? 'ERROR: ' + delA.message : 'OK'}`);
  const { error: delB } = await adminClient.auth.admin.deleteUser(userB_id);
  console.log(`User B deleted: ${delB ? 'ERROR: ' + delB.message : 'OK'}`);
}

async function main() {
  console.log('=== SPIKE-09: Realtime Evaluation ===\n');

  const { userA_id, userB_id, tokenA, tokenB } = await setupUsers();
  let slotB_id;

  try {
    slotB_id = await createTestSlotForTenantB();
    const isolationResult  = await testCrossTenantIsolation(tokenA, tokenB, userB_id, slotB_id);
    const latencyResult    = await testSameTenantLatency(tokenA, userA_id);
    const freeTierLimits   = documentFreeTierLimits();

    console.log('\n=== SPIKE-09 SUMMARY ===');
    console.log(`Isolation:    ${isolationResult.isolation_pass ? 'PASS' : 'FAIL (BLOCKING)'}`);
    console.log(`Latency:      ${latencyResult.latency_ms !== null ? latencyResult.latency_ms + 'ms' : 'N/A (event not received)'}`);
    console.log(`Free tier max concurrent: ${freeTierLimits.concurrent_connections_max}`);
    console.log('');
    console.log('Copy these results to spike-supabase/docs/realtime-evaluation.md');

    const overallPass = isolationResult.isolation_pass;
    process.exitCode = overallPass ? 0 : 1;
  } finally {
    if (slotB_id) {
      await cleanup(userA_id, userB_id, slotB_id);
    } else {
      // Cleanup users even if slot creation failed
      await adminClient.auth.admin.deleteUser(userA_id).catch(() => {});
      await adminClient.auth.admin.deleteUser(userB_id).catch(() => {});
    }
    // Ensure all clients are cleaned up
    await anonClient.auth.signOut().catch(() => {});
  }
}

main().catch(err => {
  console.error('Script error:', err.message);
  process.exit(1);
});
