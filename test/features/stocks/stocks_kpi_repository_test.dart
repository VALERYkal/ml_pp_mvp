import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/data/repositories/stocks_kpi_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../support/fakes/fake_supabase_query.dart';

/// Helper pour convertir proprement toute valeur numérique en double.
double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  throw ArgumentError('Value $value (${value.runtimeType}) is not numeric');
}

/// Tests pour StocksKpiRepository (repository canonique).
///
/// Note: Ce repository n'a pas de mécanisme de loader injectable.
/// Les tests d'intégration vérifieront le comportement réel avec Supabase.
/// Ces tests vérifient principalement que les méthodes existent et ont les bonnes signatures.
void main() {
  group('StocksKpiRepository', () {
    late StocksKpiRepository repository;
    late SupabaseClient client;

    setUp(() {
      // Fake client: interdit tout accès réseau en tests
      final fakeClient = FakeSupabaseClient();
      client = fakeClient;
      repository = StocksKpiRepository(client);
    });

    group('fetchDepotProductTotals', () {
      test('method exists and signature is correct', () {
        expect(repository.fetchDepotProductTotals, isNotNull);
        // Vérifier que la méthode accepte les bons paramètres
        expect(() => repository.fetchDepotProductTotals(), returnsNormally);
        expect(
          () => repository.fetchDepotProductTotals(
            depotId: 'depot-1',
            produitId: 'prod-1',
            dateJour: DateTime.now(),
          ),
          returnsNormally,
        );
      });
    });

    group('fetchDepotOwnerTotals', () {
      test('method exists and signature is correct', () {
        expect(repository.fetchDepotOwnerTotals, isNotNull);
        // Vérifier que la méthode accepte les bons paramètres
        expect(() => repository.fetchDepotOwnerTotals(), returnsNormally);
        expect(
          () => repository.fetchDepotOwnerTotals(
            depotId: 'depot-1',
            produitId: 'prod-1',
            proprietaireType: 'MONALUXE',
            dateJour: DateTime.now(),
          ),
          returnsNormally,
        );
      });

      test('reads from v_stock_actuel and aggregates by proprietaire_type', () async {
        // Arrange: créer un fake client avec des données v_stock_actuel (format granulaire)
        final fakeClient = FakeSupabaseClient();
        final rowsToReturn = [
          {
            'depot_id': 'depot-1',
            'depot_nom': 'Depot A',
            'citerne_id': 'citerne-1',
            'citerne_nom': 'Tank A',
            'produit_id': 'prod-1',
            'produit_nom': 'Gasoil',
            'proprietaire_type': 'MONALUXE',
            'stock_ambiant': 600.0,
            'stock_15c': 590.0,
            'updated_at': '2025-12-10T10:00:00Z',
          },
          {
            'depot_id': 'depot-1',
            'depot_nom': 'Depot A',
            'citerne_id': 'citerne-1',
            'citerne_nom': 'Tank A',
            'produit_id': 'prod-1',
            'produit_nom': 'Gasoil',
            'proprietaire_type': 'PARTENAIRE',
            'stock_ambiant': 300.0,
            'stock_15c': 290.0,
            'updated_at': '2025-12-10T10:00:00Z',
          },
          {
            'depot_id': 'depot-1',
            'depot_nom': 'Depot A',
            'citerne_id': 'citerne-2',
            'citerne_nom': 'Tank B',
            'produit_id': 'prod-1',
            'produit_nom': 'Gasoil',
            'proprietaire_type': 'MONALUXE',
            'stock_ambiant': 410.0,
            'stock_15c': 410.0,
            'updated_at': '2025-12-10T10:00:00Z',
          },
          {
            'depot_id': 'depot-1',
            'depot_nom': 'Depot A',
            'citerne_id': 'citerne-2',
            'citerne_nom': 'Tank B',
            'produit_id': 'prod-1',
            'produit_nom': 'Gasoil',
            'proprietaire_type': 'PARTENAIRE',
            'stock_ambiant': 200.0,
            'stock_15c': 185.0,
            'updated_at': '2025-12-10T10:00:00Z',
          },
        ];
        fakeClient.setViewData('v_stock_actuel', rowsToReturn);

        final repo = StocksKpiRepository(fakeClient);

        // Act
        final result = await repo.fetchDepotOwnerTotals(
          dateJour: DateTime(2025, 12, 10), // Ignored: v_stock_actuel = toujours état actuel
          depotId: 'depot-1',
        );

        // Assert
        expect(result, isNotEmpty);

        // Vérifier que la vue correcte a été utilisée (critique : on teste la bonne source SQL)
        expect(fakeClient.fromCalls, contains('v_stock_actuel'));

        // Note: v_stock_actuel ignore dateJour (toujours état actuel)
        // Le test vérifie que la vue correcte est utilisée et que les données sont agrégées
        expect(result.length, 2);

        // Vérifier que les stocks sont agrégés correctement par propriétaire
        // MONALUXE: 600 + 410 = 1010 (ambiant), 590 + 410 = 1000 (15c)
        final monaluxeResult = result.firstWhere(
          (kpi) => kpi.proprietaireType == 'MONALUXE',
        );
        expect(monaluxeResult.stockAmbiantTotal, 1010.0);
        expect(monaluxeResult.stock15cTotal, 1000.0);

        // PARTENAIRE: 300 + 200 = 500 (ambiant), 290 + 185 = 475 (15c)
        final partenaireResult = result.firstWhere(
          (kpi) => kpi.proprietaireType == 'PARTENAIRE',
        );
        expect(partenaireResult.stockAmbiantTotal, 500.0);
        expect(partenaireResult.stock15cTotal, 475.0);
      });

      test('non-regression: aggregates correctly with multiple citernes per owner', () async {
        // Test non-régression: 2 lignes v_stock_actuel même propriétaire mais citernes différentes
        // Vérifie que fetchDepotOwnerTotals agrège correctement par propriétaire
        final fakeClient = FakeSupabaseClient();
        final rowsToReturn = [
          {
            'depot_id': 'depot-1',
            'depot_nom': 'Depot A',
            'citerne_id': 'citerne-1',
            'citerne_nom': 'Tank A',
            'produit_id': 'prod-1',
            'produit_nom': 'Gasoil',
            'proprietaire_type': 'MONALUXE',
            'stock_ambiant': 600.0,
            'stock_15c': 590.0,
            'updated_at': '2025-12-10T10:00:00Z',
          },
          {
            'depot_id': 'depot-1',
            'depot_nom': 'Depot A',
            'citerne_id': 'citerne-2',
            'citerne_nom': 'Tank B',
            'produit_id': 'prod-1',
            'produit_nom': 'Gasoil',
            'proprietaire_type': 'MONALUXE',
            'stock_ambiant': 410.0,
            'stock_15c': 410.0,
            'updated_at': '2025-12-10T10:00:00Z',
          },
          {
            'depot_id': 'depot-1',
            'depot_nom': 'Depot A',
            'citerne_id': 'citerne-1',
            'citerne_nom': 'Tank A',
            'produit_id': 'prod-1',
            'produit_nom': 'Gasoil',
            'proprietaire_type': 'PARTENAIRE',
            'stock_ambiant': 300.0,
            'stock_15c': 290.0,
            'updated_at': '2025-12-10T10:00:00Z',
          },
          {
            'depot_id': 'depot-1',
            'depot_nom': 'Depot A',
            'citerne_id': 'citerne-2',
            'citerne_nom': 'Tank B',
            'produit_id': 'prod-1',
            'produit_nom': 'Gasoil',
            'proprietaire_type': 'PARTENAIRE',
            'stock_ambiant': 200.0,
            'stock_15c': 185.0,
            'updated_at': '2025-12-10T10:00:00Z',
          },
        ];
        fakeClient.setViewData('v_stock_actuel', rowsToReturn);

        final repo = StocksKpiRepository(fakeClient);

        // Act
        final result = await repo.fetchDepotOwnerTotals(
          depotId: 'depot-1',
        );

        // Assert
        expect(result.length, 2);

        // Vérifier que MONALUXE agrège correctement toutes les citernes
        // Total: 600 + 410 = 1010 (ambiant), 590 + 410 = 1000 (15c)
        final monaluxeResult = result.firstWhere(
          (kpi) => kpi.proprietaireType == 'MONALUXE',
        );
        expect(monaluxeResult.stockAmbiantTotal, 1010.0);
        expect(monaluxeResult.stock15cTotal, 1000.0);

        // Vérifier que PARTENAIRE agrège correctement toutes les citernes
        // Total: 300 + 200 = 500 (ambiant), 290 + 185 = 475 (15c)
        final partenaireResult = result.firstWhere(
          (kpi) => kpi.proprietaireType == 'PARTENAIRE',
        );
        expect(partenaireResult.stockAmbiantTotal, 500.0);
        expect(partenaireResult.stock15cTotal, 475.0);
      });
    });

    group('fetchCiterneOwnerSnapshots', () {
      test('method exists and signature is correct', () {
        expect(repository.fetchCiterneOwnerSnapshots, isNotNull);
        // Vérifier que la méthode accepte les bons paramètres
        expect(() => repository.fetchCiterneOwnerSnapshots(), returnsNormally);
        expect(
          () => repository.fetchCiterneOwnerSnapshots(
            depotId: 'depot-1',
            citerneId: 'citerne-1',
            produitId: 'prod-1',
            dateJour: DateTime.now(),
          ),
          returnsNormally,
        );
      });
    });

    group('fetchCiterneStocksFromSnapshot', () {
      test('method exists and signature is correct', () {
        expect(repository.fetchCiterneStocksFromSnapshot, isNotNull);
        // Vérifier que la méthode accepte les bons paramètres
        expect(() => repository.fetchCiterneStocksFromSnapshot(), returnsNormally);
        expect(
          () => repository.fetchCiterneStocksFromSnapshot(
            depotId: 'depot-1',
            citerneId: 'citerne-1',
            produitId: 'prod-1',
          ),
          returnsNormally,
        );
      });

      test('aggregates by citerne_id from v_stock_actuel (all owners combined)', () async {
        // Arrange: créer un fake client avec des données v_stock_actuel (format granulaire)
        // Test non-régression: 2 lignes v_stock_actuel même citerne_id (MONALUXE + PARTENAIRE)
        final fakeClient = FakeSupabaseClient();
        final rowsToReturn = [
          {
            'depot_id': 'depot-1',
            'depot_nom': 'Depot A',
            'citerne_id': 'citerne-1',
            'citerne_nom': 'Tank A',
            'produit_id': 'prod-1',
            'produit_nom': 'Gasoil',
            'proprietaire_type': 'MONALUXE',
            'stock_ambiant': 600.0,
            'stock_15c': 590.0,
            'updated_at': '2025-12-09T10:00:00Z',
          },
          {
            'depot_id': 'depot-1',
            'depot_nom': 'Depot A',
            'citerne_id': 'citerne-1',
            'citerne_nom': 'Tank A',
            'produit_id': 'prod-1',
            'produit_nom': 'Gasoil',
            'proprietaire_type': 'PARTENAIRE',
            'stock_ambiant': 400.0,
            'stock_15c': 360.0,
            'updated_at': '2025-12-09T10:00:00Z',
          },
          {
            'depot_id': 'depot-1',
            'depot_nom': 'Depot A',
            'citerne_id': 'citerne-2',
            'citerne_nom': 'Tank B',
            'produit_id': 'prod-1',
            'produit_nom': 'Gasoil',
            'proprietaire_type': 'MONALUXE',
            'stock_ambiant': 2000.0,
            'stock_15c': 1900.0,
            'updated_at': '2025-12-09T10:00:00Z',
          },
        ];
        fakeClient.setViewData('v_stock_actuel', rowsToReturn);
        // Mock pour les capacités des citernes
        fakeClient.setViewData('citernes', [
          {
            'id': 'citerne-1',
            'nom': 'Tank A',
            'capacite_totale': 5000.0,
            'capacite_securite': 500.0,
            'produit_id': 'prod-1',
          },
          {
            'id': 'citerne-2',
            'nom': 'Tank B',
            'capacite_totale': 10000.0,
            'capacite_securite': 1000.0,
            'produit_id': 'prod-1',
          },
        ]);
        fakeClient.setViewData('produits', [
          {'id': 'prod-1', 'nom': 'Gasoil'},
        ]);

        final repo = StocksKpiRepository(fakeClient);

        // Act
        final result = await repo.fetchCiterneStocksFromSnapshot(
          depotId: 'depot-1',
        );

        // Assert
        expect(result, isNotEmpty);

        // Vérifier que la vue correcte a été utilisée
        expect(fakeClient.fromCalls, contains('v_stock_actuel'));

        // Note: v_stock_actuel = toujours état actuel
        // Le test vérifie que la vue correcte est utilisée et que les données sont agrégées

        // Vérifier que citerne-1 agrège correctement MONALUXE + PARTENAIRE
        // Total: 600 + 400 = 1000 (ambiant), 590 + 360 = 950 (15c)
        final tankA = result.firstWhere(
          (snapshot) => snapshot['citerne_id'] == 'citerne-1',
          orElse: () =>
              throw StateError('Citerne-1 non trouvée dans les résultats'),
        );
        expect(_toDouble(tankA['stock_ambiant_total']), 1000.0);
        expect(_toDouble(tankA['stock_15c_total']), 950.0);

        // Vérifier que citerne-2 a ses valeurs (MONALUXE uniquement)
        final tankB = result.firstWhere(
          (snapshot) => snapshot['citerne_id'] == 'citerne-2',
          orElse: () =>
              throw StateError('Citerne-2 non trouvée dans les résultats'),
        );
        expect(_toDouble(tankB['stock_ambiant_total']), 2000.0);
        expect(_toDouble(tankB['stock_15c_total']), 1900.0);
      });
    });

    group('fetchDepotTotalCapacity', () {
      test('method exists and signature is correct', () {
        expect(repository.fetchDepotTotalCapacity, isNotNull);
        expect(
          () => repository.fetchDepotTotalCapacity(depotId: 'depot-1'),
          returnsNormally,
        );
        expect(
          () => repository.fetchDepotTotalCapacity(
            depotId: 'depot-1',
            produitId: 'prod-1',
          ),
          returnsNormally,
        );
      });
    });
  });
}
