// SPIKE-08: Flutter mini-app proving Supabase Auth + RLS + book_slot() RPC
// Run: flutter run -d chrome \
//   --dart-define=SUPABASE_URL=https://fasirsbiadcchfgvktzt.supabase.co \
//   --dart-define=SUPABASE_ANON_KEY=<anon_key> \
//   --dart-define=TEST_EMAIL_1=testclient@spike.local \
//   --dart-define=TEST_PASSWORD_1=<password> \
//   --dart-define=TEST_EMAIL_2=testadmin@spike.local \
//   --dart-define=TEST_PASSWORD_2=<password>
//
// SPIKE-13: Only anon key used. No privileged key is present in this file.
// Security audit command is in 34-01-PLAN.md verification section.

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Credentials injected at build time via --dart-define (never hardcoded in git).
// defaultValue contains the staging project URL as a convenience fallback for local
// development. The anon key default is intentionally empty — must be provided via
// --dart-define or the app will print a clear error.
const _supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://fasirsbiadcchfgvktzt.supabase.co',
);
const _supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: '',
);
const _email1 = String.fromEnvironment(
  'TEST_EMAIL_1',
  defaultValue: 'testclient@spike.local',
);
const _password1 = String.fromEnvironment('TEST_PASSWORD_1', defaultValue: '');
const _email2 = String.fromEnvironment(
  'TEST_EMAIL_2',
  defaultValue: 'testadmin@spike.local',
);
const _password2 = String.fromEnvironment('TEST_PASSWORD_2', defaultValue: '');

// Seed fixture UUIDs (from spike-supabase/schema/03_seed.sql)
const _slotA1 = '12000000-0000-0000-0000-000000000001';
const _rpcBookingDate = '2099-12-31';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_supabaseAnonKey.isEmpty) {
    debugPrint('FATAL: SUPABASE_ANON_KEY not set. '
        'Run with --dart-define=SUPABASE_ANON_KEY=<key>');
    runApp(const _FatalErrorApp(
      message: 'SUPABASE_ANON_KEY not set.\n\n'
          'Run with:\n--dart-define=SUPABASE_ANON_KEY=<key>',
    ));
    return;
  }

  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);

  runApp(const SpikeApp());
}

class _FatalErrorApp extends StatelessWidget {
  const _FatalErrorApp({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red.shade900,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class SpikeApp extends StatelessWidget {
  const SpikeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SPIKE-08: Flutter Proof',
      theme: ThemeData(colorSchemeSeed: Colors.deepOrange),
      home: const ProofScreen(),
    );
  }
}

class ProofScreen extends StatefulWidget {
  const ProofScreen({super.key});

  @override
  State<ProofScreen> createState() => _ProofScreenState();
}

class _ProofScreenState extends State<ProofScreen> {
  final List<String> _log = [];
  bool _running = false;
  bool _done = false;

  final _supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _runProof();
  }

  void _append(String msg) {
    debugPrint(msg);
    setState(() => _log.add(msg));
  }

  Future<void> _runProof() async {
    setState(() => _running = true);
    _append('=== SPIKE-08: Flutter Proof ===');
    _append('');

    try {
      // --- TENANT 1 ---
      _append('--- Tenant 1: $_email1 ---');
      final auth1 = await _supabase.auth.signInWithPassword(
        email: _email1,
        password: _password1,
      );
      final user1 = auth1.user!;
      final tenant1Id = user1.appMetadata['tenant_id'] as String? ?? 'MISSING';
      _append('AUTH: user_id=${user1.id}');
      _append('AUTH: tenant_id=$tenant1Id');

      if (tenant1Id == 'MISSING') {
        _append('WARNING: tenant_id missing in JWT — Auth Hook may not be deployed');
      }

      // Read slots — RLS filters by tenant automatically (no .eq() needed)
      final slots1 = await _supabase.from('slots').select();
      final count1 = (slots1 as List).length;
      _append('RLS SLOTS (no .eq): $count1 rows for tenant_1');
      _append('');

      await _supabase.auth.signOut();

      // --- TENANT 2 ---
      _append('--- Tenant 2: $_email2 ---');
      final auth2 = await _supabase.auth.signInWithPassword(
        email: _email2,
        password: _password2,
      );
      final user2 = auth2.user!;
      final tenant2Id = user2.appMetadata['tenant_id'] as String? ?? 'MISSING';
      _append('AUTH: user_id=${user2.id}');
      _append('AUTH: tenant_id=$tenant2Id');

      // Same query — RLS returns different tenant's rows
      final slots2 = await _supabase.from('slots').select();
      final count2 = (slots2 as List).length;
      _append('RLS SLOTS (no .eq): $count2 rows for tenant_2');
      _append('');

      // RLS PROOF: counts should differ between tenants
      _append('=== RLS PROOF (D-04) ===');
      _append('Tenant 1 slots: $count1');
      _append('Tenant 2 slots: $count2');
      if (count1 != count2) {
        _append('RESULT: PASS — different counts prove RLS filters by tenant');
      } else {
        _append('RESULT: WARN — same count; may mean both tenants have equal slots or RLS not filtering');
      }
      _append('');

      await _supabase.auth.signOut();

      // --- RPC PROOF: book_slot() as Tenant 1 ---
      _append('--- RPC: book_slot() as tenant_1 ---');
      final auth1b = await _supabase.auth.signInWithPassword(
        email: _email1,
        password: _password1,
      );
      final user1b = auth1b.user!;
      final tenant1bId = user1b.appMetadata['tenant_id'] as String? ?? 'MISSING';

      final rpcResult = await _supabase.rpc('book_slot', params: {
        'p_slot_id': _slotA1,
        'p_booking_date': _rpcBookingDate,
        'p_user_id': user1b.id,
        'p_tenant_id': tenant1bId,
      });

      if (rpcResult is! List) {
        _append('RPC returned non-list: ${rpcResult.runtimeType}');
        return;
      }
      final rows = rpcResult;
      if (rows.isNotEmpty) {
        final rawRow = rows.first;
        if (rawRow is! Map) {
          _append('RPC row[0] is not a map: ${rawRow.runtimeType}');
          return;
        }
        final row = Map<String, dynamic>.from(rawRow as Map);
        final successRaw = row['success'];
        if (successRaw is! bool) {
          _append('RPC error: success is ${successRaw.runtimeType}, expected bool');
          return;
        }
        final success = successRaw;
        final rawErrorCode = row['error_code'];
        final errorCode = rawErrorCode is String ? rawErrorCode : null;
        final rawBookingId = row['booking_id'];
        final bookingId = rawBookingId is String ? rawBookingId : null;
        _append('RPC book_slot(): success=$success, error_code=$errorCode, booking_id=$bookingId');

        if (success) {
          _append('RESULT: PASS — booking confirmed, booking_id=$bookingId');
        } else if (errorCode == 'SLOT_ALREADY_BOOKED') {
          _append('RESULT: PASS — SLOT_ALREADY_BOOKED (slot was already booked; RPC working correctly)');
        } else {
          _append('RESULT: FAIL — unexpected error_code=$errorCode');
        }
      } else {
        _append('RPC result: empty response');
      }

      await _supabase.auth.signOut();
      _append('');
      _append('=== SPIKE-08 PROOF COMPLETE ===');

    } catch (e, st) {
      _append('ERROR: $e');
      debugPrint('Stack: $st');
    }

    setState(() {
      _running = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SPIKE-08: Flutter Proof'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          if (_running)
            const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _log.length,
              itemBuilder: (_, i) => Text(
                _log[i],
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
              ),
            ),
          ),
          if (_done)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _log.clear();
                    _done = false;
                  });
                  _runProof();
                },
                child: const Text('Re-run Proof'),
              ),
            ),
        ],
      ),
    );
  }
}
