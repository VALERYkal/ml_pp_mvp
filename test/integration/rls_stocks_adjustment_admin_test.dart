// test/integration/rls_stocks_adjustment_admin_test.dart

import 'package:flutter_test/flutter_test.dart';

import '_harness/staging_supabase_client.dart';

void main() {
  test(
    '[DB-TEST] B2.3.2 RLS — admin CAN INSERT stocks_adjustments (STAGING)',
    () async {
      final staging =
          await StagingSupabase.create(envPath: 'env/.env.staging');

      // Admin = service role (bypass RLS)
      final client = staging.serviceClient;
      expect(client, isNotNull, reason: 'Service role key required for admin test');

      // Minimal valid payload (must satisfy DB constraints & triggers)
      final payload = {
        'mouvement_type': 'RECEPTION',
        'mouvement_id': 'ee02a4e8-7029-4dcd-b638-dac6c9f56743', // valid existing id
        'delta_ambiant': 0,
        'delta_15c': 1,
        'reason': 'ADMIN_TEST',
        'created_by': '2bf68c7c-a907-4504-9aba-89061be487a2', // admin user_id
      };

      // Should succeed (RLS allows admin / service role)
      final res = await client!
          .from('stocks_adjustments')
          .insert(payload)
          .select('id')
          .single();

      expect(res, isA<Map>());
      expect(res['id'], isNotNull);

      // ignore: avoid_print
      print('[DB-TEST] B2.3.2 OK — admin insert allowed (id=${res['id']})');
    },
  );
}
