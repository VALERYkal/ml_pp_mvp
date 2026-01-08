// test/integration/db_smoke_test.dart
import 'package:flutter_test/flutter_test.dart';

import '_harness/staging_supabase_client.dart';

void main() {
  test('[DB-TEST] STAGING smoke: can run a simple query', () async {
    final staging = await StagingSupabase.create(envPath: 'env/.env.staging');

    // Use serviceClient if available (bypasses RLS), otherwise fallback to anonClient
    final client = staging.serviceClient ?? staging.anonClient;

    // Simple, low-risk query: fetch 1 row from a small reference table.
    // Using depots table (should exist after seed_staging_minimal_v2.sql)
    final res = await client
        .from('depots')
        .select('id')
        .limit(1);

    // If the query throws, the test fails automatically.
    // We just assert the type / shape is plausible.
    expect(res, isA<List>());

    // Optional log (visible with -r expanded)
    // ignore: avoid_print
    print('[DB-TEST] Connected to STAGING and queried depots successfully.');
  });
}

