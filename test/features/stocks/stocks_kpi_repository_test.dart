import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/data/repositories/stocks_kpi_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fake filter builder générique qui implémente PostgrestFilterBuilder<T>
///
/// Permet de résoudre le problème de typage générique strict de Supabase.
/// eq(), lte(), order() retournent this (même builder chainable).
/// Permet `await query` car implémente then().
class _FakeFilterBuilder<T> implements PostgrestFilterBuilder<T> {
  _FakeFilterBuilder(this._result);

  final T _result;

  @override
  PostgrestFilterBuilder<T> eq(String column, Object? value) => this;

  @override
  PostgrestFilterBuilder<T> lte(String column, dynamic value) => this;

  @override
  PostgrestFilterBuilder<T> order(
    String column, {
    bool ascending = true,
    bool? nullsFirst,
    String? foreignTable,
  }) => this;

  // Match supabase_flutter/postgrest signature variations in tests.
  @override
  _FakeFilterBuilder<T> in_(String column, List values) {
    return this;
  }

  /// Permet `await query;` car PostgrestFilterBuilder est thenable
  @override
  Future<S> then<S>(
    FutureOr<S> Function(T value) onValue, {
    Function? onError,
  }) {
    return Future<T>.value(_result).then(onValue, onError: onError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Gérer maybeSingle() pour le fallback snapshot
    // Note: Le as dynamic est volontaire pour gérer les variations de types Supabase
    if (invocation.isMethod && invocation.memberName == #maybeSingle) {
      final dynamic v = _result;

      // Cas classique Supabase : le builder a une List<Map> et maybeSingle doit renvoyer
      // - null si vide
      // - le premier élément si non vide
      if (v is List) {
        if (v.isEmpty) {
          return _FakeFilterBuilder<Map<String, dynamic>?>(null) as dynamic;
        }
        return _FakeFilterBuilder<Map<String, dynamic>?>(v.first as Map<String, dynamic>?) as dynamic;
      }

      // Sinon, renvoyer tel quel
      return _FakeFilterBuilder<Map<String, dynamic>?>(v as Map<String, dynamic>?) as dynamic;
    }
    return super.noSuchMethod(invocation);
  }
}

/// Wrapper pour from() qui implémente SupabaseQueryBuilder
class _FakeSupabaseTableBuilder implements SupabaseQueryBuilder {
  _FakeSupabaseTableBuilder(this.rowsToReturn);

  final List<Map<String, dynamic>> rowsToReturn;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Intercepter select<T>() et retourner le filterBuilder typé
    if (invocation.isMethod && invocation.memberName == #select) {
      // Le type générique est dans invocation.typeArguments
      // On vérifie si c'est List<Map<String, dynamic>> et on retourne le builder typé
      if (invocation.typeArguments.isNotEmpty) {
        // Vérifier que le type est bien List<Map<String, dynamic>>
        // On utilise un cast dynamique pour contourner les limitations du typage
        return _FakeFilterBuilder<List<Map<String, dynamic>>>(
              rowsToReturn as dynamic,
            )
            as dynamic;
      }
      // Si pas de type générique, utiliser le type par défaut
      return _FakeFilterBuilder<List<Map<String, dynamic>>>(
        rowsToReturn as dynamic,
      );
    }
    // Pour toutes les autres méthodes/getters, retourner this
    if (invocation.isGetter || invocation.isMethod) {
      return this;
    }
    throw UnimplementedError(
      'Méthode non implémentée: ${invocation.memberName}',
    );
  }
}

/// Fake Supabase client qui retourne des données contrôlées
class _FakeSupabaseClient extends SupabaseClient {
  final Map<String, List<Map<String, dynamic>>> _viewData = {};
  String? capturedViewName;
  final List<String> fromCalls = [];

  _FakeSupabaseClient() : super('https://example.com', 'anon-key');

  void setViewData(String viewName, List<Map<String, dynamic>> data) {
    _viewData[viewName] = data;
  }

  @override
  SupabaseQueryBuilder from(String viewName) {
    fromCalls.add(viewName);
    capturedViewName = viewName;
    final rows = _viewData[viewName] ?? [];
    // Retourner un objet qui implémente SupabaseQueryBuilder
    return _FakeSupabaseTableBuilder(rows);
  }
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
      final fakeClient = _FakeSupabaseClient();
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
        final fakeClient = _FakeSupabaseClient();
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
        final fakeClient = _FakeSupabaseClient();
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

    group('fetchCiterneGlobalSnapshots', () {
      test('method exists and signature is correct', () {
        expect(repository.fetchCiterneGlobalSnapshots, isNotNull);
        // Vérifier que la méthode accepte les bons paramètres
        expect(() => repository.fetchCiterneGlobalSnapshots(), returnsNormally);
        expect(
          () => repository.fetchCiterneGlobalSnapshots(
            depotId: 'depot-1',
            citerneId: 'citerne-1',
            produitId: 'prod-1',
            dateJour: DateTime.now(),
          ),
          returnsNormally,
        );
      });

      test('method uses dateJour parameter (not dateDernierMouvement)', () {
        // Ce test vérifie à la compilation que la méthode utilise dateJour
        // (pas dateDernierMouvement comme l'ancien repository)
        final date = DateTime(2025, 12, 9);
        expect(
          () => repository.fetchCiterneGlobalSnapshots(dateJour: date),
          returnsNormally,
        );
      });

      test('aggregates by citerne_id from v_stock_actuel (all owners combined)', () async {
        // Arrange: créer un fake client avec des données v_stock_actuel (format granulaire)
        // Test non-régression: 2 lignes v_stock_actuel même citerne_id (MONALUXE + PARTENAIRE)
        final fakeClient = _FakeSupabaseClient();
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
        final result = await repo.fetchCiterneGlobalSnapshots(
          dateJour: DateTime(2025, 12, 10), // Ignored: v_stock_actuel = toujours état actuel
          depotId: 'depot-1',
        );

        // Assert
        expect(result, isNotEmpty);

        // Vérifier que la vue correcte a été utilisée
        expect(fakeClient.fromCalls, contains('v_stock_actuel'));

        // Note: v_stock_actuel ignore dateJour (toujours état actuel)
        // Le test vérifie que la vue correcte est utilisée et que les données sont agrégées

        // Vérifier que citerne-1 agrège correctement MONALUXE + PARTENAIRE
        // Total: 600 + 400 = 1000 (ambiant), 590 + 360 = 950 (15c)
        final tankA = result.firstWhere(
          (snapshot) => snapshot.citerneId == 'citerne-1',
          orElse: () =>
              throw StateError('Citerne-1 non trouvée dans les résultats'),
        );
        expect(tankA.stockAmbiantTotal, 1000.0);
        expect(tankA.stock15cTotal, 950.0);

        // Vérifier que citerne-2 a ses valeurs (MONALUXE uniquement)
        final tankB = result.firstWhere(
          (snapshot) => snapshot.citerneId == 'citerne-2',
          orElse: () =>
              throw StateError('Citerne-2 non trouvée dans les résultats'),
        );
        expect(tankB.stockAmbiantTotal, 2000.0);
        expect(tankB.stock15cTotal, 1900.0);
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
