import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '_harness/staging_supabase_client.dart';
import '_staging_fixtures.dart';

/// Test d'intégration Réception -> Stocks journaliers (STAGING DB réel).
///
/// 🔎 Objectif :
/// - Insérer une réception via l'API Supabase directe
/// - Vérifier que :
///   - la table `stocks_journaliers` est créditée correctement
///   - `stocks_journaliers.stock_15c >= volume_corrige_15c` de la réception
///
/// 📋 Prérequis :
/// - `env/.env.staging` doit exister avec les vraies clés STAGING
/// - Le seed `staging/sql/seed_staging_minimal_v2.sql` doit avoir été appliqué
///   (contient les IDs fixes : dépôt, produit, citerne)
/// - Une citerne avec l'ID `kStagingCiterneId` doit exister en STAGING
///   (ou être créée dynamiquement dans le test)
void main() {
  // Check both activation modes: env var and dart-define
  final runDbTestsEnv = Platform.environment['RUN_DB_TESTS'] == '1' ||
      Platform.environment['RUN_DB_TESTS'] == 'true';
  final runDbTestsDartDefine =
      const bool.fromEnvironment('RUN_DB_TESTS', defaultValue: false);
  final runDbTests = runDbTestsEnv || runDbTestsDartDefine;

  group('[DB-TEST] Réception -> Stocks journaliers (STAGING)', () {
    test(
      'Insert réception avec volume_corrige_15c met à jour stocks_journaliers',
      () async {
      final staging = await StagingSupabase.create(envPath: 'env/.env.staging');
      final client = staging.serviceClient ?? staging.anonClient;

      // IDs fixes du seed staging (centralisés dans _staging_fixtures.dart)
      final ids = (
        depotId: kStagingDepotId,
        produitId: kStagingProduitId,
        citerneId: kStagingCiterneId,
        tag: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // S'assurer que la citerne existe (création idempotente si nécessaire)
      try {
        await client
            .from('citernes')
            .upsert({
              'id': kStagingCiterneId,
              'depot_id': kStagingDepotId,
              'produit_id': kStagingProduitId,
              'nom': 'TANK TEST',
              'capacite_totale': 50000,
              'capacite_securite': 2000,
              'localisation': 'ZONE TEST',
              'statut': 'active',
            })
            .timeout(const Duration(seconds: 10));
      } on TimeoutException {
        fail(
          '[DB-TEST] Timeout querying STAGING. Check network/DNS or Supabase status.',
        );
        return;
      } catch (e) {
        // Ignore si la citerne existe déjà ou si l'upsert échoue pour une autre raison
        // ignore: avoid_print
        print('[DB-TEST] Note: Citerne may already exist or upsert failed: $e');
      }

      const volumeAmb = 1000.0;
      const volume15c = 995.0;

      Map<String, dynamic> receptionRow;
      try {
        receptionRow = await client
            .from('receptions')
            .insert({
              'cours_de_route_id': null,
              'citerne_id': ids.citerneId,
              'produit_id': ids.produitId,
              'partenaire_id': null,
              'index_avant': 0,
              'index_apres': 1000,
              'volume_corrige_15c': volume15c,
              'temperature_ambiante_c': 20,
              'densite_a_15_kgm3': 830,
              'proprietaire_type': 'MONALUXE',
              'note': 'TEST ${ids.tag}',
              'volume_ambiant': volumeAmb,
              'statut': 'validee', // IMPORTANT: dans tes données c'est en minuscule
              'created_by': null,
              'validated_by': null,
              'date_reception': DateTime.now().toIso8601String(),
              'volume_observe': volumeAmb,
              'volume_15c': null, // explicit (optionnel)
            })
            .select(
                'id, citerne_id, produit_id, volume_ambiant, volume_corrige_15c, statut')
            .single()
            .timeout(const Duration(seconds: 10));
      } on TimeoutException {
        fail(
          '[DB-TEST] Timeout querying STAGING. Check network/DNS or Supabase status.',
        );
        return;
      }

      expect((receptionRow['volume_corrige_15c'] as num).toDouble(), equals(volume15c));
      expect(receptionRow['statut'], equals('validee'));

      // Attendre un peu pour que le trigger s'exécute
      await Future.delayed(const Duration(milliseconds: 500));

      // Assert : Vérifier que stocks_journaliers.stock_15c >= volume_corrige_15c
      final dateReception = DateTime.now();
      final dateStr = '${dateReception.year.toString().padLeft(4, '0')}-'
          '${dateReception.month.toString().padLeft(2, '0')}-'
          '${dateReception.day.toString().padLeft(2, '0')}';

      Map<String, dynamic>? stockRow;
      try {
        stockRow = await client
            .from('stocks_journaliers')
            .select('stock_15c, stock_ambiant')
            .eq('citerne_id', ids.citerneId)
            .eq('produit_id', ids.produitId)
            .eq('date_jour', dateStr)
            .maybeSingle()
            .timeout(const Duration(seconds: 10));
      } on TimeoutException {
        fail(
          '[DB-TEST] Timeout querying STAGING. Check network/DNS or Supabase status.',
        );
        return;
      }

      expect(stockRow, isNotNull, reason: 'La ligne stocks_journaliers devrait exister');

      final stock15c = (stockRow!['stock_15c'] as num?)?.toDouble() ?? 0.0;

      expect(
        stock15c,
        greaterThanOrEqualTo(volume15c),
        reason: 'stocks_journaliers.stock_15c ($stock15c) doit être >= volume_corrige_15c ($volume15c)',
      );

      // ignore: avoid_print
      print('[DB-TEST] Réception insérée avec volume_corrige_15c=$volume15c, stock_15c=$stock15c');
      },
      skip: runDbTests
          ? false
          : 'DB tests are opt-in. Set RUN_DB_TESTS=1 or --dart-define=RUN_DB_TESTS=true',
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}

