// test/integration/rls_stocks_adjustment_read_test.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

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
    '[DB-TEST] B2.3.3 RLS — lecture CAN SELECT stocks_adjustments (STAGING)',
    () async {
    final staging = await StagingSupabase.create(envPath: 'env/.env.staging');
    final env = await StagingEnv.load(path: 'env/.env.staging');

    if (env.testUserEmail == null || env.testUserEmail!.isEmpty) {
      throw StateError('[DB-TEST] TEST_USER_EMAIL missing in env/.env.staging');
    }
    if (env.testUserPassword == null || env.testUserPassword!.isEmpty) {
      throw StateError('[DB-TEST] TEST_USER_PASSWORD missing in env/.env.staging');
    }

    // Login as lecture (authenticated)
    try {
      await staging.anonClient.auth
          .signInWithPassword(
            email: env.testUserEmail!,
            password: env.testUserPassword!,
          )
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      fail(
        '[DB-TEST] Timeout querying STAGING. Check network/DNS or Supabase status.',
      );
      return;
    }

    // Attempt SELECT under RLS
    List<dynamic> res;
    try {
      res = await staging.anonClient
          .from('stocks_adjustments')
          .select('id, created_at')
          .limit(1)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      fail(
        '[DB-TEST] Timeout querying STAGING. Check network/DNS or Supabase status.',
      );
      return;
    }

    expect(res, isA<List>());

    // ignore: avoid_print
    print('[DB-TEST] SELECT OK — rows=${(res as List).length}');
    },
    skip: runDbTests
        ? false
        : 'DB tests are opt-in. Set RUN_DB_TESTS=1 or --dart-define=RUN_DB_TESTS=true',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}


