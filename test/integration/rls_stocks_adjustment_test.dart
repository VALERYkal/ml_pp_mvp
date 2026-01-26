// test/integration/rls_stocks_adjustment_test.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:postgrest/postgrest.dart';

import '_harness/staging_supabase_client.dart';
import '_env/staging_env.dart';

void main() {
  // Check both activation modes: env var and dart-define
  final runDbTestsEnv = Platform.environment['RUN_DB_TESTS'] == '1' ||
      Platform.environment['RUN_DB_TESTS'] == 'true';
  final runDbTestsDartDefine =
      const bool.fromEnvironment('RUN_DB_TESTS', defaultValue: false);
  final runDbTests = runDbTestsEnv || runDbTestsDartDefine;

  test(
    '[DB-TEST] B2.3.1 RLS — lecture cannot INSERT stocks_adjustments (STAGING)',
    () async {
    final staging = await StagingSupabase.create(envPath: 'env/.env.staging');

    // IMPORTANT: We must use anonClient (RLS applies). serviceClient would bypass RLS.
    final client = staging.anonClient;

    // 1) Login as NON_ADMIN (lecture)
    final env = await StagingEnv.load(path: 'env/.env.staging');

    var res;
    try {
      res = await client.auth
          .signInWithPassword(
            email: env.nonAdminEmail!,
            password: env.nonAdminPassword!,
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      fail(
        '[DB-TEST] Timeout querying STAGING. Check network/DNS or Supabase status.',
      );
      return;
    }
    expect(res.user, isNotNull);
    final userId = res.user!.id;

    // 2) Attempt forbidden insert
    // Get a real RECEPTION id (use serviceClient to bypass RLS for the lookup)
    final lookupClient = staging.serviceClient ?? staging.anonClient;

    List<dynamic> rows;
    try {
      rows = await lookupClient
          .from('receptions')
          .select('id')
          .order('created_at', ascending: false)
          .limit(1)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      fail(
        '[DB-TEST] Timeout querying STAGING. Check network/DNS or Supabase status.',
      );
      return;
    }

    if (rows is! List || rows.isEmpty) {
      fail('No receptions found in STAGING to build a valid stocks_adjustments payload.');
    }

    final receptionId = (rows.first as Map<String, dynamic>)['id'] as String;

    final payload = {
      'mouvement_type': 'RECEPTION',
      'mouvement_id': receptionId,
      'created_by': userId,
      'delta_ambiant': 1.0,
      'delta_15c': 1.0,
      'reason': '[TEST] RLS must block lecture',
    };

    try {
      await client
          .from('stocks_adjustments')
          .insert(payload)
          .timeout(const Duration(seconds: 10));
      fail('Expected RLS/permission error, but insert succeeded.');
    } on TimeoutException {
      fail(
        '[DB-TEST] Timeout querying STAGING. Check network/DNS or Supabase status.',
      );
      return;
    } on PostgrestException catch (e) {
      final msg = e.message.toLowerCase();
      // Accept typical RLS/permission messages (varies by policy)
      expect(
        msg,
        anyOf(
          contains('rls'),
          contains('permission'),
          contains('not allowed'),
          contains('forbidden'),
          contains('row-level security'),
        ),
      );
    }
    },
    skip: runDbTests
        ? false
        : 'DB tests are opt-in. Set RUN_DB_TESTS=1 or --dart-define=RUN_DB_TESTS=true',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}


