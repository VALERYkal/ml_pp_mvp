// test/integration/rls_stocks_adjustment_admin_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '_harness/staging_supabase_client.dart';

void main() {
  // Flags pour activer les tests DB (opt-in)
  final runDbTests = Platform.environment['RUN_DB_TESTS'] == '1';
  final hasEnvFile = File('env/.env.staging').existsSync();

  // Calculer le message de skip dynamiquement
  final skipReason = !runDbTests
      ? 'DB tests disabled (set RUN_DB_TESTS=1)'
      : (!hasEnvFile ? 'Missing env/.env.staging' : null);

  test(
    '[DB-TEST] B2.3.2 RLS — admin CAN INSERT stocks_adjustments (STAGING)',
    () async {
      final staging = await StagingSupabase.create(envPath: 'env/.env.staging');

      // Admin = service role (bypass RLS)
      final client = staging.serviceClient;
      expect(
        client,
        isNotNull,
        reason: 'Service role key required for admin test',
      );

      // 1) Find an existing mouvement to attach the adjustment to (avoid hardcoded UUID flakiness)
      String? mouvementType;
      String? mouvementId;

      // Try receptions first
      final recRows = await client!
          .from('receptions')
          .select('id, created_at')
          .order('created_at', ascending: false)
          .limit(1);

      if (recRows is List && recRows.isNotEmpty) {
        mouvementType = 'RECEPTION';
        mouvementId = (recRows.first as Map)['id'] as String?;
      } else {
        // Fallback: try sorties_produit (preferred in this project)
        dynamic sortieRows;
        try {
          sortieRows = await client!
              .from('sorties_produit')
              .select('id, created_at')
              .order('created_at', ascending: false)
              .limit(1);
        } catch (_) {
          // Fallback name if project uses another table name
          sortieRows = await client!
              .from('sorties')
              .select('id, created_at')
              .order('created_at', ascending: false)
              .limit(1);
        }

        if (sortieRows is List && sortieRows.isNotEmpty) {
          mouvementType = 'SORTIE';
          mouvementId = (sortieRows.first as Map)['id'] as String?;
        }
      }

      if (mouvementType == null || mouvementId == null) {
        fail(
          '[DB-TEST] Seed missing: no receptions/sorties found in STAGING; cannot test stocks_adjustments insert',
        );
      }

      // 2) Find a stable created_by user_id (prefer admin profil)
      String? createdBy;
      final adminRows = await client!
          .from('profils')
          .select('user_id, role')
          .eq('role', 'admin')
          .limit(1);

      if (adminRows is List && adminRows.isNotEmpty) {
        createdBy = (adminRows.first as Map)['user_id'] as String?;
      } else {
        final anyProfilRows = await client!
            .from('profils')
            .select('user_id')
            .limit(1);
        if (anyProfilRows is List && anyProfilRows.isNotEmpty) {
          createdBy = (anyProfilRows.first as Map)['user_id'] as String?;
        }
      }

      // Fallback to previous hardcoded value if needed (still better than null)
      createdBy ??= '2bf68c7c-a907-4504-9aba-89061be487a2';

      // Minimal valid payload (must satisfy DB constraints & triggers)
      final payload = {
        'mouvement_type': mouvementType,
        'mouvement_id': mouvementId,
        'delta_ambiant': 0.0,
        'delta_15c': 1.0,
        'reason': 'ADMIN_TEST',
        'created_by': createdBy,
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
    skip: skipReason,
  );
}
