// test/integration/rls_stocks_adjustment_admin_test.dart

import 'package:flutter_test/flutter_test.dart';

import '_harness/staging_supabase_client.dart';

void main() {
  test(
    '[DB-TEST] B2.3.2 RLS — admin CAN INSERT stocks_adjustments (STAGING)',
    () async {
      // DB roundtrips can be slow on CI / networks
      final staging =
          await StagingSupabase.create(envPath: 'env/.env.staging');

      // Admin = service role (bypass RLS)
      final client = staging.serviceClient;
      expect(
        client,
        isNotNull,
        reason: 'Service role key required for admin test',
      );

      // ------------------------------------------------------------
      // 1) Arrange: create a real RECEPTION row (self-contained)
      // Reuse the same fixed IDs as the staging minimal seed.
      // ------------------------------------------------------------
      final ids = (
        depotId: '11111111-1111-1111-1111-111111111111',
        produitId: '22222222-2222-2222-2222-222222222222',
        citerneId: '33333333-3333-3333-3333-333333333333',
        tag: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      const volumeAmb = 10.0;
      const volume15c = 10.0;

      // ignore: avoid_print
      print('[DB-TEST] inserting reception...');
      final receptionRow = await client!
          .from('receptions')
          .insert({
            'cours_de_route_id': null,
            'citerne_id': ids.citerneId,
            'produit_id': ids.produitId,
            'partenaire_id': null,
            'index_avant': 0,
            'index_apres': 10,
            'volume_corrige_15c': volume15c,
            'temperature_ambiante_c': 20,
            'densite_a_15': 0.83,
            'proprietaire_type': 'MONALUXE',
            'note': 'ADMIN_TEST ${ids.tag}',
            'volume_ambiant': volumeAmb,
            'statut': 'validee',
            'created_by': null,
            'validated_by': null,
            'date_reception': DateTime.now().toIso8601String(),
            'volume_observe': volumeAmb,
            'volume_15c': null,
          })
          .select('id')
          .single();
      // ignore: avoid_print
      print('[DB-TEST] reception inserted');

      final receptionId = receptionRow['id'] as String?;
      expect(receptionId, isNotNull, reason: 'Reception insert must return an id');

      // Minimal valid payload (must satisfy DB constraints & triggers)
      final payload = {
        'mouvement_type': 'RECEPTION',
        'mouvement_id': receptionId,
        'delta_ambiant': 0,
        'delta_15c': 1,
        'reason': 'ADMIN_TEST',
        'created_by': '2bf68c7c-a907-4504-9aba-89061be487a2', // admin user_id
      };

      // Should succeed (RLS allows admin / service role)
      // ignore: avoid_print
      print('[DB-TEST] inserting stocks_adjustment...');
      final res = await client
          .from('stocks_adjustments')
          .insert(payload)
          .select('id')
          .single();
      // ignore: avoid_print
      print('[DB-TEST] stocks_adjustment inserted');

      expect(res, isA<Map>());
      expect(res['id'], isNotNull);

      // ignore: avoid_print
      print(
        '[DB-TEST] B2.3.2 OK — admin insert allowed '
        '(receptionId=$receptionId, adjustmentId=${res['id']})',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
