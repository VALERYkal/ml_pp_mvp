// test/integration/rls_stocks_adjustment_read_test.dart
import 'package:flutter_test/flutter_test.dart';

import '_harness/staging_supabase_client.dart';
import '_env/staging_env.dart';

void main() {
  test('[DB-TEST] B2.3.3 RLS — lecture CAN SELECT stocks_adjustments (STAGING)',
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
    await staging.anonClient.auth.signInWithPassword(
      email: env.testUserEmail!,
      password: env.testUserPassword!,
    );

    // Attempt SELECT under RLS
    final res = await staging.anonClient
        .from('stocks_adjustments')
        .select('id, created_at')
        .limit(1);

    expect(res, isA<List>());

    // ignore: avoid_print
    print('[DB-TEST] SELECT OK — rows=${(res as List).length}');
  });
}


