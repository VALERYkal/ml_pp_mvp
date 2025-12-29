@Skip('Supabase integration tests are disabled in flutter test environment')
library;

// 📌 Module : Réceptions - Tests d'Intégration CDR → Réception → CDR.DECHARGE
// 🧑 Auteur : Expert Flutter/Supabase Testing Engineer
// 📅 Date : 2025-11-29
// 🧭 Description : Tests d'intégration pour valider le flux CDR → Réception → Trigger CDR.DECHARGE
//
// OBJECTIF :
// Vérifier qu'une réception liée à un CDR déclenche bien la transition de statut
// du CDR (ARRIVE → DECHARGE) via le trigger DB.

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/receptions/data/reception_service.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;

// ════════════════════════════════════════════════════════════════════════════
// HELPERS POUR TESTS D'INTÉGRATION
// ════════════════════════════════════════════════════════════════════════════

/// Helper pour créer un fournisseur de test dans Supabase
Future<String> _createTestFournisseur(SupabaseClient client) async {
  final payload = {
    'nom': 'Fournisseur Test Integration ${DateTime.now().millisecondsSinceEpoch}',
    'pays': 'RDC',
  };

  final result = await client
      .from('fournisseurs')
      .insert(payload)
      .select('id')
      .single() as Map<String, dynamic>;

  return result['id'] as String;
}

/// Helper pour créer un produit de test dans Supabase
Future<String> _createTestProduit(SupabaseClient client) async {
  final payload = {
    'nom': 'Essence Test Integration',
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
    'nom': 'Dépôt Test Integration ${DateTime.now().millisecondsSinceEpoch}',
    'adresse': 'Adresse Test',
  };

  final result = await client
      .from('depots')
      .insert(payload)
      .select('id')
      .single() as Map<String, dynamic>;

  return result['id'] as String;
}

/// Helper pour créer un CDR de test dans Supabase
Future<String> _createTestCdr(
  SupabaseClient client, {
  required String fournisseurId,
  required String produitId,
  required String depotDestinationId,
  String statut = 'ARRIVE',
}) async {
  final payload = {
    'fournisseur_id': fournisseurId,
    'produit_id': produitId,
    'depot_destination_id': depotDestinationId,
    'plaque_camion': 'TEST-INTEGRATION-${DateTime.now().millisecondsSinceEpoch}',
    'chauffeur_nom': 'Chauffeur Test',
    'transporteur': 'Transport Test',
    'depart_pays': 'RDC',
    'volume': 20000.0,
    'statut': statut,
    'date_chargement': DateTime.now().toIso8601String().substring(0, 10),
  };

  final result = await client
      .from('cours_de_route')
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
    'nom': 'Citerne Test Integration',
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
  String? cdrId,
  String? citerneId,
  String? receptionId,
  String? fournisseurId,
  String? produitId,
  String? depotId,
}) async {
  if (receptionId != null) {
    try {
      await client.from('receptions').delete().eq('id', receptionId);
    } catch (_) {}
  }
  if (cdrId != null) {
    try {
      await client.from('cours_de_route').delete().eq('id', cdrId);
    } catch (_) {}
  }
  if (citerneId != null) {
    try {
      await client.from('citernes').delete().eq('id', citerneId);
    } catch (_) {}
  }
  if (fournisseurId != null) {
    try {
      await client.from('fournisseurs').delete().eq('id', fournisseurId);
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

/// Helper pour récupérer le statut d'un CDR
Future<String?> _getCdrStatut(SupabaseClient client, String cdrId) async {
  final result = await client
      .from('cours_de_route')
      .select('statut')
      .eq('id', cdrId)
      .maybeSingle() as Map<String, dynamic>?;

  return result?['statut'] as String?;
}

// ════════════════════════════════════════════════════════════════════════════
// FAKE REFERENTIELS REPO POUR TESTS
// ════════════════════════════════════════════════════════════════════════════

class _FakeRefRepoForIntegration extends refs.ReferentielsRepo {
  final String produitId;
  final String produitCode;

  _FakeRefRepoForIntegration(this.produitId, this.produitCode)
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

void main() {

  group('CDR → Réception → CDR.DECHARGE Integration Flow', () {
    // ⚠️ NOTE : Ces tests nécessitent un SupabaseClient configuré
    // Pour les tests unitaires, utilisez des fakes/mocks
    // Pour les tests d'intégration réels, configurez Supabase.instance.client

    test(
      'INTÉGRATION : Créer une réception liée à un CDR ARRIVE déclenche DECHARGE via trigger',
      () async {
        // ⚠️ SKIP si pas de client Supabase configuré (tests unitaires)
        // Pour activer ce test, configurez Supabase.instance.client avec des credentials de test
        // ou utilisez un environnement de test dédié

        // Arrange
        // Utiliser un client de test si disponible, sinon skip
        SupabaseClient? testClient;
        try {
          // Tenter d'utiliser Supabase.instance.client si disponible
          testClient = Supabase.instance.client;
          // Vérifier que le client est fonctionnel en faisant une requête simple
          await testClient.from('cours_de_route').select('id').limit(1);
        } catch (e) {
          // Si pas de client configuré, skip le test
          // ignore: avoid_print
          print('⚠️ SKIP: Supabase client non configuré pour les tests d\'intégration');
          return;
        }

        final client = testClient;

        // Créer les données de test nécessaires
        String? fournisseurId;
        String? produitId;
        String? depotId;
        String? cdrId;
        String? citerneId;
        String? receptionId;

        try {
          // 1. Créer les référentiels de test
          fournisseurId = await _createTestFournisseur(client);
          produitId = await _createTestProduit(client);
          depotId = await _createTestDepot(client);

          // 2. Créer un CDR de test avec statut ARRIVE
          cdrId = await _createTestCdr(
            client,
            fournisseurId: fournisseurId,
            produitId: produitId,
            depotDestinationId: depotId,
            statut: 'ARRIVE',
          );

          // Vérifier l'état initial
          final statutInitial = await _getCdrStatut(client, cdrId);
          expect(statutInitial, equals('ARRIVE'));

          // 3. Créer une citerne de test active
          citerneId = await _createTestCiterne(
            client,
            produitId: produitId,
            depotId: depotId,
          );

          // 4. Créer le service de réception
          final refRepo = _FakeRefRepoForIntegration(produitId, 'ESS');
          final receptionService = ReceptionService.withClient(
            client,
            refRepo: refRepo,
          );

          // 5. Créer une réception liée au CDR
          receptionId = await receptionService.createValidated(
            coursDeRouteId: cdrId,
            citerneId: citerneId,
            produitId: produitId,
            indexAvant: 1000.0,
            indexApres: 1100.0, // Volume ambiant = 100L
            temperatureCAmb: 25.0,
            densiteA15: 0.75,
            proprietaireType: 'MONALUXE',
            dateReception: DateTime.now(),
          );

          // Attendre un peu pour que le trigger s'exécute
          await Future.delayed(const Duration(milliseconds: 500));

          // 6. Assert : Vérifier que le CDR est passé à DECHARGE
          final statutFinal = await _getCdrStatut(client, cdrId);
          expect(statutFinal, equals('DECHARGE'),
              reason: 'Le trigger DB devrait avoir mis à jour le statut du CDR de ARRIVE à DECHARGE');

          // 7. Assert : Vérifier que la réception existe
          final receptionExists = await client
              .from('receptions')
              .select('id')
              .eq('id', receptionId)
              .maybeSingle();
          expect(receptionExists, isNotNull,
              reason: 'La réception devrait avoir été créée');

          // 8. Assert : Vérifier que la réception est liée au CDR
          final receptionData = await client
              .from('receptions')
              .select('cours_de_route_id, statut')
              .eq('id', receptionId)
              .single() as Map<String, dynamic>;
          expect(receptionData['cours_de_route_id'], equals(cdrId));
          expect(receptionData['statut'], equals('validee'));
        } finally {
          // Nettoyer les données de test
          await _cleanupTestData(
            client,
            cdrId: cdrId,
            citerneId: citerneId,
            receptionId: receptionId,
            fournisseurId: fournisseurId,
            produitId: produitId,
            depotId: depotId,
          );
        }
      },
      // Note: Ce test nécessite un SupabaseClient configuré pour l'environnement de test
      // Pour activer, configurez Supabase.instance.client avec des credentials de test
      // ou utilisez un environnement de test dédié
      // skip: true, // Décommenter pour désactiver le test
    );

    test(
      'INTÉGRATION : Réception sans CDR ne modifie pas de CDR',
      () async {
        // Arrange
        SupabaseClient? testClient;
        try {
          testClient = Supabase.instance.client;
          await testClient.from('cours_de_route').select('id').limit(1);
        } catch (e) {
          // ignore: avoid_print
          print('⚠️ SKIP: Supabase client non configuré');
          return;
        }

        final client = testClient;

        // Créer les données de test nécessaires
        String? produitId;
        String? depotId;
        String? citerneId;
        String? receptionId;

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

          // Créer le service
          final refRepo = _FakeRefRepoForIntegration(produitId, 'ESS');
          final receptionService = ReceptionService.withClient(
            client,
            refRepo: refRepo,
          );

          // Créer une réception SANS CDR
          receptionId = await receptionService.createValidated(
            citerneId: citerneId,
            produitId: produitId,
            indexAvant: 1000.0,
            indexApres: 1100.0,
            temperatureCAmb: 25.0,
            densiteA15: 0.75,
            proprietaireType: 'MONALUXE',
            dateReception: DateTime.now(),
          );

          // Assert : La réception devrait être créée sans erreur
          final receptionExists = await client
              .from('receptions')
              .select('id, cours_de_route_id')
              .eq('id', receptionId)
              .single() as Map<String, dynamic>;
          expect(receptionExists['cours_de_route_id'], isNull);
        } finally {
          await _cleanupTestData(
            client,
            citerneId: citerneId,
            receptionId: receptionId,
            produitId: produitId,
            depotId: depotId,
          );
        }
      },
      // Note: Ce test nécessite un SupabaseClient configuré pour l'environnement de test
      // skip: true, // Décommenter pour désactiver le test
    );
  });
}

