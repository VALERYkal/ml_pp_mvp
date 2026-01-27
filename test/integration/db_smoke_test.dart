// test/integration/db_smoke_test.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '_harness/staging_supabase_client.dart';

void main() {
  // Check both activation modes: env var and dart-define
  final runDbTestsEnv = Platform.environment['RUN_DB_TESTS'] == '1' ||
      Platform.environment['RUN_DB_TESTS'] == 'true';
  final runDbTestsDartDefine =
      const bool.fromEnvironment('RUN_DB_TESTS', defaultValue: false);
  final runDbTests = runDbTestsEnv || runDbTestsDartDefine;

  test(
    '[DB-TEST] STAGING smoke: can run a simple query',
    () async {
      final staging = await StagingSupabase.create(envPath: 'env/.env.staging');

      // Use serviceClient if available (bypasses RLS), otherwise fallback to anonClient
      final client = staging.serviceClient ?? staging.anonClient;

      // Simple, low-risk query: fetch 1 row from a small reference table.
      // Using depots table (should exist after seed_staging_minimal_v2.sql)
      // Wrap with timeout for fail-fast behavior
      List<dynamic> res;
      try {
        res = await client
            .from('depots')
            .select('id')
            .limit(1)
            .timeout(const Duration(seconds: 10));
      } on TimeoutException {
        fail(
          '[DB-TEST] Timeout querying STAGING. Check network/DNS or Supabase status.',
        );
        return; // Unreachable, but satisfies analyzer
      }

      // If the query throws, the test fails automatically.
      // We just assert the type / shape is plausible.
      expect(res, isA<List>());

      // Optional log (visible with -r expanded)
      // ignore: avoid_print
      print('[DB-TEST] Connected to STAGING and queried depots successfully.');
    },
    skip: runDbTests
        ? false
        : 'DB tests are opt-in. Set RUN_DB_TESTS=1 or --dart-define=RUN_DB_TESTS=true',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

