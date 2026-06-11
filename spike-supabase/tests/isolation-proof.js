// isolation-proof.js — SPIKE-06: HTTP Cross-Tenant Isolation Proof
// Cria 2 usuários reais, autentica, executa 3 ataques cross-tenant, cleanup.
// Run: node spike-supabase/tests/isolation-proof.js
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import path from 'path';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.join(__dirname, '../.env') });

const SUPABASE_URL           = process.env.SUPABASE_URL;
const SUPABASE_PUBLISHABLE_KEY = process.env.SUPABASE_PUBLISHABLE_KEY;
const SUPABASE_SECRET_KEY    = process.env.SUPABASE_SECRET_KEY;

if (!SUPABASE_URL || !SUPABASE_PUBLISHABLE_KEY || !SUPABASE_SECRET_KEY) {
  console.error('FATAL: .env missing SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, or SUPABASE_SECRET_KEY');
  process.exit(1);
}

const TENANT_A = '10000000-0000-0000-0000-000000000001';
const TENANT_B = '20000000-0000-0000-0000-000000000001';

const anonClient  = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);
const adminClient = createClient(SUPABASE_URL, SUPABASE_SECRET_KEY);

async function setup() {
  const ts = Date.now();
  const emailA = `test-a-${ts}@example.com`;
  const emailB = `test-b-${ts}@example.com`;
  const password = 'TestPassword123!';

  console.log('=== SETUP ===');

  const { data: signUpA, error: errA } = await adminClient.auth.admin.createUser({ email: emailA, password, email_confirm: true });
  if (errA || !signUpA.user) throw new Error(`createUser A failed: ${errA?.message}`);
  const userA_id = signUpA.user.id;
  console.log(`User A created: ${userA_id} (${emailA})`);

  const { data: signUpB, error: errB } = await adminClient.auth.admin.createUser({ email: emailB, password, email_confirm: true });
  if (errB || !signUpB.user) throw new Error(`createUser B failed: ${errB?.message}`);
  const userB_id = signUpB.user.id;
  console.log(`User B created: ${userB_id} (${emailB})`);

  const { error: memA } = await adminClient.from('memberships')
    .insert({ tenant_id: TENANT_A, user_id: userA_id, role: 'client' });
  if (memA) throw new Error(`Membership A insert failed: ${memA.message}`);
  console.log(`Membership A inserted (tenant: ${TENANT_A})`);

  const { error: memB } = await adminClient.from('memberships')
    .insert({ tenant_id: TENANT_B, user_id: userB_id, role: 'client' });
  if (memB) throw new Error(`Membership B insert failed: ${memB.message}`);
  console.log(`Membership B inserted (tenant: ${TENANT_B})`);

  const { data: siA, error: siErrA } = await anonClient.auth.signInWithPassword({ email: emailA, password });
  if (siErrA || !siA.session) throw new Error(`signIn A failed: ${siErrA?.message}`);
  // Decode JWT to check hook-injected claims (session.user reflects DB, not JWT)
  const jwtA = JSON.parse(Buffer.from(siA.session.access_token.split('.')[1], 'base64').toString('utf8'));
  console.log(`User A signed in. tenant_id in JWT: ${jwtA.app_metadata?.tenant_id ?? 'MISSING!'}`);

  const { data: siB, error: siErrB } = await anonClient.auth.signInWithPassword({ email: emailB, password });
  if (siErrB || !siB.session) throw new Error(`signIn B failed: ${siErrB?.message}`);
  const jwtB = JSON.parse(Buffer.from(siB.session.access_token.split('.')[1], 'base64').toString('utf8'));
  console.log(`User B signed in. tenant_id in JWT: ${jwtB.app_metadata?.tenant_id ?? 'MISSING!'}`);

  if (!jwtA.app_metadata?.tenant_id) {
    throw new Error('Auth Hook did NOT inject tenant_id for User A. Check hook deployment.');
  }
  if (!jwtB.app_metadata?.tenant_id) {
    throw new Error('Auth Hook did NOT inject tenant_id for User B. Check hook deployment.');
  }

  return { userA_id, userB_id, sessionA: siA.session, sessionB: siB.session };
}

async function runAttacks(sessionA, sessionB, userA_id) {
  console.log('\n=== ATTACKS ===');

  const clientA = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
    global: { headers: { Authorization: `Bearer ${sessionA.access_token}` } }
  });

  let allPass = true;

  // Attack 1: Cross-tenant SELECT em bookings
  const { data: sel, error: selErr } = await clientA
    .from('bookings')
    .select('*')
    .eq('tenant_id', TENANT_B);

  const pass1 = sel !== null && sel.length === 0 && selErr === null;
  if (!pass1) allPass = false;
  console.log(`\nAttack 1 (SELECT cross-tenant bookings):`);
  console.log(`  rows returned: ${sel?.length ?? 'null'}`);
  console.log(`  error: ${selErr?.message ?? 'none'}`);
  console.log(`  RESULT: ${pass1 ? 'PASS' : 'FAIL'} — expected 0 rows`);

  // Attack 2: Cross-tenant INSERT em bookings
  const { data: slotB } = await adminClient
    .from('slots')
    .select('id')
    .eq('tenant_id', TENANT_B)
    .limit(1)
    .single();

  const slotB_id = slotB?.id ?? '22000000-0000-0000-0000-000000000001';

  const { data: ins, error: insErr } = await clientA
    .from('bookings')
    .insert({
      tenant_id:    TENANT_B,
      user_id:      userA_id,
      slot_id:      slotB_id,
      booking_date: '2099-06-01',
      status:       'pending'
    })
    .select();

  const pass2 = insErr !== null;
  if (!pass2) allPass = false;
  console.log(`\nAttack 2 (INSERT cross-tenant bookings):`);
  console.log(`  inserted rows: ${ins?.length ?? 0}`);
  console.log(`  error: ${insErr?.message ?? 'NO ERROR — FAIL'}`);
  console.log(`  RESULT: ${pass2 ? 'PASS' : 'FAIL'} — expected RLS error`);

  // Attack 3: Cross-tenant UPDATE em bookings
  const { data: upd, error: updErr } = await clientA
    .from('bookings')
    .update({ status: 'cancelled' })
    .eq('tenant_id', TENANT_B)
    .select();

  const pass3 = (upd !== null && upd.length === 0) || updErr !== null;
  if (!pass3) allPass = false;
  console.log(`\nAttack 3 (UPDATE cross-tenant bookings):`);
  console.log(`  rows affected: ${upd?.length ?? 0}`);
  console.log(`  error: ${updErr?.message ?? 'none'}`);
  console.log(`  RESULT: ${pass3 ? 'PASS' : 'FAIL'} — expected 0 rows affected`);

  console.log(`\n=== SUMMARY ===`);
  console.log(`Attack 1 (SELECT): ${pass1 ? 'PASS' : 'FAIL'}`);
  console.log(`Attack 2 (INSERT): ${pass2 ? 'PASS' : 'FAIL'}`);
  console.log(`Attack 3 (UPDATE): ${pass3 ? 'PASS' : 'FAIL'}`);
  console.log(`\nOVERALL RESULT: ${allPass ? 'PASS — RLS blocks all cross-tenant attacks' : 'FAIL — one or more attacks succeeded'}`);

  return allPass;
}

async function cleanup(userA_id, userB_id) {
  console.log('\n=== CLEANUP ===');
  const { error: delA } = await adminClient.auth.admin.deleteUser(userA_id);
  console.log(`User A deleted: ${delA ? 'ERROR: ' + delA.message : 'OK'}`);
  const { error: delB } = await adminClient.auth.admin.deleteUser(userB_id);
  console.log(`User B deleted: ${delB ? 'ERROR: ' + delB.message : 'OK'}`);
}

async function main() {
  const { userA_id, userB_id, sessionA, sessionB } = await setup();
  try {
    await runAttacks(sessionA, sessionB, userA_id);
  } finally {
    await cleanup(userA_id, userB_id);
  }
}

main().catch(err => {
  console.error('Script error:', err.message);
  process.exit(1);
});
