// 📌 Module : Réceptions - Tests d'Intégration Réception → Stocks journaliers
// 🧑 Auteur : Expert Flutter/Supabase Testing Engineer
// 📅 Date : 2025-11-29
// 🧭 Description : Tests d'intégration pour valider le flux Réception → Stocks journaliers
//
// OBJECTIF :
// Vérifier qu'une réception Monaluxe incrémente (ou crée) la bonne ligne dans
// stocks_journaliers via le trigger DB.

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/receptions/data/reception_service.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;

// ════════════════════════════════════════════════════════════════════════════
// HELPERS POUR TESTS D'INTÉGRATION
// ════════════════════════════════════════════════════════════════════════════

/// Helper pour créer un produit de test dans Supabase
Future<String> _createTestProduit(SupabaseClient client) async {
  final payload = {
    'nom': 'Essence Test Stocks Integration ${DateTime.now().millisecondsSinceEpoch}',
    'code': 'ESS',
    'actif': true,
  };

  final result = await client
      .from('produits')
      .insert(payload)
      .select('id')
      .single() as Map<String, dynamic>;

  return result['id'] as String;
}

/// Helper pour créer un dépôt de test dans Supabase
Future<String> _createTestDepot(SupabaseClient client) async {
  final payload = {
    'nom': 'Dépôt Test Stocks Integration ${DateTime.now().millisecondsSinceEpoch}',
    'adresse': 'Adresse Test',
  };

  final result = await client
      .from('depots')
      .insert(payload)
      .select('id')
      .single() as Map<String, dynamic>;

  return result['id'] as String;
}

/// Helper pour créer une citerne de test dans Supabase
Future<String> _createTestCiterne(
  SupabaseClient client, {
  required String produitId,
  required String depotId,
}) async {
  final payload = {
    'produit_id': produitId,
    'depot_id': depotId,
    'nom': 'Citerne Test Stocks Integration',
    'capacite_totale': 50000.0,
    'capacite_securite': 5000.0,
    'statut': 'active',
  };

  final result = await client
      .from('citernes')
      .insert(payload)
      .select('id')
      .single() as Map<String, dynamic>;

  return result['id'] as String;
}

/// Helper pour nettoyer les données de test
Future<void> _cleanupTestData(
  SupabaseClient client, {
  String? citerneId,
  String? receptionId,
  String? produitId,
  String? depotId,
  DateTime? dateJour,
}) async {
  if (receptionId != null) {
    try {
      await client.from('receptions').delete().eq('id', receptionId);
    } catch (_) {}
  }

  // Nettoyer les stocks journaliers pour la date de test
  if (citerneId != null && produitId != null && dateJour != null) {
    try {
      final dateStr = '${dateJour.year.toString().padLeft(4, '0')}-'
          '${dateJour.month.toString().padLeft(2, '0')}-'
          '${dateJour.day.toString().padLeft(2, '0')}';
      await client
          .from('stocks_journaliers')
          .delete()
          .eq('citerne_id', citerneId)
          .eq('produit_id', produitId)
          .eq('date_jour', dateStr);
    } catch (_) {}
  }

  if (citerneId != null) {
    try {
      await client.from('citernes').delete().eq('id', citerneId);
    } catch (_) {}
  }
  if (produitId != null) {
    try {
      await client.from('produits').delete().eq('id', produitId);
    } catch (_) {}
  }
  if (depotId != null) {
    try {
      await client.from('depots').delete().eq('id', depotId);
    } catch (_) {}
  }
}

/// Helper pour récupérer le stock journalier
Future<Map<String, dynamic>?> _getStockJournalier(
  SupabaseClient client, {
  required String citerneId,
  required String produitId,
  required DateTime dateJour,
}) async {
  final dateStr = '${dateJour.year.toString().padLeft(4, '0')}-'
      '${dateJour.month.toString().padLeft(2, '0')}-'
      '${dateJour.day.toString().padLeft(2, '0')}';

  final result = await client
      .from('stocks_journaliers')
      .select('*')
      .eq('citerne_id', citerneId)
      .eq('produit_id', produitId)
      .eq('date_jour', dateStr)
      .maybeSingle() as Map<String, dynamic>?;

  return result;
}

// ════════════════════════════════════════════════════════════════════════════
// FAKE REFERENTIELS REPO POUR TESTS
// ════════════════════════════════════════════════════════════════════════════

class _FakeRefRepoForStocksIntegration extends refs.ReferentielsRepo {
  final String produitId;
  final String produitCode;

  _FakeRefRepoForStocksIntegration(this.produitId, this.produitCode)
      : super(SupabaseClient('http://localhost', 'anon'));

  @override
  Future<List<refs.ProduitRef>> loadProduits() async {
    return [
      refs.ProduitRef(
        id: produitId,
        code: produitCode,
        nom: 'Essence Test',
      ),
    ];
  }

  @override
  Future<List<refs.CiterneRef>> loadCiternesActives() async => [];

  @override
  String? getProduitIdByCodeSync(String code) {
    if (code.toUpperCase() == produitCode.toUpperCase()) {
      return produitId;
    }
    return null;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TESTS D'INTÉGRATION
// ════════════════════════════════════════════════════════════════════════════

import '../../test_utils/supabase_test_bootstrap.dart';

void main() {
  setUpAll(() async {
    // Initialiser Supabase pour éviter les erreurs "Supabase.instance not initialized"
    await ensureSupabaseInitializedForTests();
  });

  group('Réception → Stocks journaliers Integration Flow', () {
    // ⚠️ NOTE : Ces tests nécessitent un SupabaseClient configuré
    // Pour les tests unitaires, utilisez des fakes/mocks
    // Pour les tests d'intégration réels, configurez Supabase.instance.client

    test(
      'INTÉGRATION : Créer une réception MONALUXE met à jour stocks_journaliers via trigger',
      () async {
        // Arrange
        SupabaseClient? testClient;
        try {
          testClient = Supabase.instance.client;
          // Vérifier que le client est fonctionnel
          await testClient.from('stocks_journaliers').select('id').limit(1);
        } catch (e) {
          // ignore: avoid_print
          print('⚠️ SKIP: Supabase client non configuré pour les tests d\'intégration');
          return;
        }

        final client = testClient;

        // Créer les données de test nécessaires
        String? produitId;
        String? depotId;
        final dateReception = DateTime.now();
        String? citerneId;
        String? receptionId;

        try {
          // 1. Créer les référentiels de test
          produitId = await _createTestProduit(client);
          depotId = await _createTestDepot(client);

          // 2. Créer une citerne de test active
          citerneId = await _createTestCiterne(
            client,
            produitId: produitId,
            depotId: depotId,
          );

          // 3. Vérifier l'état initial des stocks (devrait être vide ou 0)
          final stockInitial = await _getStockJournalier(
            client,
            citerneId: citerneId,
            produitId: produitId,
            dateJour: dateReception,
          );

          final stockAmbiantInitial = stockInitial != null
              ? (stockInitial['stock_ambiant'] as num?)?.toDouble() ?? 0.0
              : 0.0;
          final stock15cInitial = stockInitial != null
              ? (stockInitial['stock_15c'] as num?)?.toDouble() ?? 0.0
              : 0.0;

          // 4. Créer le service de réception
          final refRepo = _FakeRefRepoForStocksIntegration(produitId, 'ESS');
          final receptionService = ReceptionService.withClient(
            client,
            refRepo: refRepo,
          );

          // 5. Créer une réception MONALUXE avec volumes connus
          const indexAvant = 1000.0;
          const indexApres = 1100.0; // Volume ambiant = 100L
          const temperatureCAmb = 25.0;
          const densiteA15 = 0.75;

          receptionId = await receptionService.createValidated(
            citerneId: citerneId,
            produitId: produitId,
            indexAvant: indexAvant,
            indexApres: indexApres,
            temperatureCAmb: temperatureCAmb,
            densiteA15: densiteA15,
            proprietaireType: 'MONALUXE',
            dateReception: dateReception,
          );

          // Attendre un peu pour que le trigger s'exécute
          await Future.delayed(const Duration(milliseconds: 500));

          // 6. Assert : Vérifier que la réception existe
          final receptionExists = await client
              .from('receptions')
              .select('volume_ambiant, volume_corrige_15c')
              .eq('id', receptionId)
              .single() as Map<String, dynamic>;
          expect(receptionExists, isNotNull,
              reason: 'La réception devrait avoir été créée');

          final volumeAmbiantReception =
              (receptionExists['volume_ambiant'] as num?)?.toDouble() ?? 0.0;
          final volume15cReception =
              (receptionExists['volume_corrige_15c'] as num?)?.toDouble() ?? 0.0;

          // 7. Assert : Vérifier que stocks_journaliers a été mis à jour
          final stockFinal = await _getStockJournalier(
            client,
            citerneId: citerneId,
            produitId: produitId,
            dateJour: dateReception,
          );

          expect(stockFinal, isNotNull,
              reason: 'La ligne stocks_journaliers devrait exister pour la date de réception');

          final stockAmbiantFinal =
              (stockFinal!['stock_ambiant'] as num?)?.toDouble() ?? 0.0;
          final stock15cFinal =
              (stockFinal['stock_15c'] as num?)?.toDouble() ?? 0.0;

          // Vérifier que les stocks correspondent au volume de réception
          // (ou à l'ancienne valeur + nouvelle, selon le modèle de cumul)
          expect(
            stockAmbiantFinal,
            equals(stockAmbiantInitial + volumeAmbiantReception),
            reason:
                'Le stock ambiant devrait être égal à l\'ancien stock + volume de réception',
          );

          expect(
            stock15cFinal,
            equals(stock15cInitial + volume15cReception),
            reason:
                'Le stock 15°C devrait être égal à l\'ancien stock + volume corrigé de réception',
          );

          // Vérifier que les valeurs sont cohérentes
          expect(stockAmbiantFinal, greaterThan(0),
              reason: 'Le stock ambiant devrait être > 0');
          expect(stock15cFinal, greaterThan(0),
              reason: 'Le stock 15°C devrait être > 0');
        } finally {
          // Nettoyer les données de test
          await _cleanupTestData(
            client,
            citerneId: citerneId,
            receptionId: receptionId,
            produitId: produitId,
            depotId: depotId,
            dateJour: dateReception,
          );
        }
      },
      // Note: Ce test nécessite un SupabaseClient configuré pour l'environnement de test
      // Pour activer, configurez Supabase.instance.client avec des credentials de test
      // ou utilisez un environnement de test dédié
      // skip: true, // Décommenter pour désactiver le test
    );

    test(
      'INTÉGRATION : Plusieurs réceptions cumulent correctement dans stocks_journaliers',
      () async {
        // Arrange
        SupabaseClient? testClient;
        try {
          testClient = Supabase.instance.client;
          await testClient.from('stocks_journaliers').select('id').limit(1);
        } catch (e) {
          // ignore: avoid_print
          print('⚠️ SKIP: Supabase client non configuré');
          return;
        }

        final client = testClient;

        // Créer les données de test nécessaires
        String? produitId;
        String? depotId;
        final dateReception = DateTime.now();
        String? citerneId;
        final List<String> receptionIds = [];

        try {
          // Créer les référentiels de test
          produitId = await _createTestProduit(client);
          depotId = await _createTestDepot(client);

          // Créer une citerne de test
          citerneId = await _createTestCiterne(
            client,
            produitId: produitId,
            depotId: depotId,
          );

          final refRepo = _FakeRefRepoForStocksIntegration(produitId, 'ESS');
          final receptionService = ReceptionService.withClient(
            client,
            refRepo: refRepo,
          );

          // Créer 2 réceptions successives
          final reception1Id = await receptionService.createValidated(
            citerneId: citerneId,
            produitId: produitId,
            indexAvant: 1000.0,
            indexApres: 1100.0, // 100L
            temperatureCAmb: 25.0,
            densiteA15: 0.75,
            proprietaireType: 'MONALUXE',
            dateReception: dateReception,
          );
          receptionIds.add(reception1Id);

          await Future.delayed(const Duration(milliseconds: 500));

          final reception2Id = await receptionService.createValidated(
            citerneId: citerneId,
            produitId: produitId,
            indexAvant: 1100.0,
            indexApres: 1200.0, // 100L
            temperatureCAmb: 25.0,
            densiteA15: 0.75,
            proprietaireType: 'MONALUXE',
            dateReception: dateReception,
          );
          receptionIds.add(reception2Id);

          await Future.delayed(const Duration(milliseconds: 500));

          // Assert : Vérifier que les stocks sont cumulés
          final stockFinal = await _getStockJournalier(
            client,
            citerneId: citerneId,
            produitId: produitId,
            dateJour: dateReception,
          );

          expect(stockFinal, isNotNull);

          final stockAmbiantFinal =
              (stockFinal!['stock_ambiant'] as num?)?.toDouble() ?? 0.0;
          final stock15cFinal =
              (stockFinal['stock_15c'] as num?)?.toDouble() ?? 0.0;

          // Les deux réceptions de 100L chacune devraient donner ~200L au total
          expect(stockAmbiantFinal, greaterThanOrEqualTo(200.0),
              reason: 'Le stock ambiant devrait cumuler les deux réceptions');
          expect(stock15cFinal, greaterThan(0),
              reason: 'Le stock 15°C devrait être > 0');
        } finally {
          for (final id in receptionIds) {
            await _cleanupTestData(
              client,
              citerneId: citerneId,
              receptionId: id,
              produitId: produitId,
              depotId: depotId,
              dateJour: dateReception,
            );
          }
        }
      },
      // Note: Ce test nécessite un SupabaseClient configuré pour l'environnement de test
      // skip: true, // Décommenter pour désactiver le test
    );
  });
}

