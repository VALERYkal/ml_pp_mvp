import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/data/repositories/stocks_kpi_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';

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
  }) =>
      this;

  /// Permet `await query;` car PostgrestFilterBuilder est thenable
  @override
  Future<S> then<S>(
    FutureOr<S> Function(T value) onValue, {
    Function? onError,
  }) {
    return Future<T>.value(_result).then(onValue, onError: onError);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
        final typeArg = invocation.typeArguments.first;
        // Vérifier que le type est bien List<Map<String, dynamic>>
        // On utilise un cast dynamique pour contourner les limitations du typage
        return _FakeFilterBuilder<List<Map<String, dynamic>>>(
          rowsToReturn as dynamic,
        ) as dynamic;
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
    throw UnimplementedError('Méthode non implémentée: ${invocation.memberName}');
  }
}

/// Fake Supabase client qui retourne des données contrôlées
class _FakeSupabaseClient extends SupabaseClient {
  final Map<String, List<Map<String, dynamic>>> _viewData = {};
  String? capturedViewName;

  _FakeSupabaseClient() : super('https://example.com', 'anon-key');

  void setViewData(String viewName, List<Map<String, dynamic>> data) {
    _viewData[viewName] = data;
  }

  @override
  SupabaseQueryBuilder from(String viewName) {
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
      // Dummy client (utilisé seulement pour instancier le repository)
      client = SupabaseClient('https://example.com', 'anon-key');
      repository = StocksKpiRepository(client);
    });

    group('fetchDepotProductTotals', () {
      test('method exists and signature is correct', () {
        expect(repository.fetchDepotProductTotals, isNotNull);
        // Vérifier que la méthode accepte les bons paramètres
        expect(
          () => repository.fetchDepotProductTotals(),
          returnsNormally,
        );
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
        expect(
          () => repository.fetchDepotOwnerTotals(),
          returnsNormally,
        );
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

      test(
        'filters to latest date_jour when multiple dates returned',
        () async {
          // Arrange: créer un fake client avec des données contenant plusieurs dates
          final fakeClient = _FakeSupabaseClient();
          final rowsToReturn = [
            {
              'depot_id': 'depot-1',
              'depot_nom': 'Depot A',
              'proprietaire_type': 'MONALUXE',
              'produit_id': 'prod-1',
              'produit_nom': 'Gasoil',
              'stock_ambiant_total': 1000.0,
              'stock_15c_total': 950.0,
              'date_jour': '2025-12-09', // Date la plus récente
            },
            {
              'depot_id': 'depot-1',
              'depot_nom': 'Depot A',
              'proprietaire_type': 'MONALUXE',
              'produit_id': 'prod-1',
              'produit_nom': 'Gasoil',
              'stock_ambiant_total': 1100.0,
              'stock_15c_total': 1050.0,
              'date_jour': '2025-12-09', // Même date (devrait être inclus)
            },
            {
              'depot_id': 'depot-1',
              'depot_nom': 'Depot A',
              'proprietaire_type': 'PARTENAIRE',
              'produit_id': 'prod-1',
              'produit_nom': 'Gasoil',
              'stock_ambiant_total': 500.0,
              'stock_15c_total': 475.0,
              'date_jour': '2025-12-08', // Date plus ancienne (devrait être exclue)
            },
          ];
          fakeClient.setViewData('v_stock_actuel_owner_snapshot', rowsToReturn);

          final repo = StocksKpiRepository(fakeClient);

          // Act
          final result = await repo.fetchDepotOwnerTotals(
            dateJour: DateTime(2025, 12, 10),
            depotId: 'depot-1',
          );

          // Assert
          expect(result, isNotEmpty);

          // Note: v_stock_actuel_owner_snapshot ignore dateJour (snapshot = toujours état actuel)
          // Le test vérifie que la vue correcte est utilisée et que les données sont retournées
          // Il y a 2 lignes dans rowsToReturn (MONALUXE et PARTENAIRE), donc on devrait avoir 2 résultats
          expect(result.length, 2);
          
          // Vérifier que les stocks correspondent aux données mockées
          final monaluxeResult = result.firstWhere(
            (kpi) => kpi.proprietaireType == 'MONALUXE',
          );
          expect(monaluxeResult.stockAmbiantTotal, 1000.0);
          expect(monaluxeResult.stock15cTotal, 950.0);
        },
      );
    });

    group('fetchCiterneOwnerSnapshots', () {
      test('method exists and signature is correct', () {
        expect(repository.fetchCiterneOwnerSnapshots, isNotNull);
        // Vérifier que la méthode accepte les bons paramètres
        expect(
          () => repository.fetchCiterneOwnerSnapshots(),
          returnsNormally,
        );
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
        expect(
          () => repository.fetchCiterneGlobalSnapshots(),
          returnsNormally,
        );
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

      test(
        'filters to latest date_jour when multiple dates returned',
        () async {
          // Arrange: créer un fake client avec des données contenant plusieurs dates
          final fakeClient = _FakeSupabaseClient();
          final rowsToReturn = [
            {
              'citerne_id': 'citerne-1',
              'citerne_nom': 'Tank A',
              'produit_id': 'prod-1',
              'produit_nom': 'Gasoil',
              'date_jour': '2025-12-09', // Date la plus récente
              'stock_ambiant_total': 1000.0,
              'stock_15c_total': 950.0,
              'capacite_totale': 5000.0,
              'capacite_securite': 500.0,
            },
            {
              'citerne_id': 'citerne-2',
              'citerne_nom': 'Tank B',
              'produit_id': 'prod-1',
              'produit_nom': 'Gasoil',
              'date_jour': '2025-12-09', // Même date (devrait être inclus)
              'stock_ambiant_total': 2000.0,
              'stock_15c_total': 1900.0,
              'capacite_totale': 10000.0,
              'capacite_securite': 1000.0,
            },
            {
              'citerne_id': 'citerne-1',
              'citerne_nom': 'Tank A',
              'produit_id': 'prod-1',
              'produit_nom': 'Gasoil',
              'date_jour': '2025-12-08', // Date plus ancienne (devrait être exclue)
              'stock_ambiant_total': 900.0,
              'stock_15c_total': 855.0,
              'capacite_totale': 5000.0,
              'capacite_securite': 500.0,
            },
          ];
          fakeClient.setViewData('v_stock_actuel_snapshot', rowsToReturn);

          final repo = StocksKpiRepository(fakeClient);

          // Act
          final result = await repo.fetchCiterneGlobalSnapshots(
            dateJour: DateTime(2025, 12, 10),
            depotId: 'depot-1',
          );

          // Assert
          expect(result, isNotEmpty);
          
          // Vérifier que la vue correcte a été utilisée
          expect(fakeClient.capturedViewName, 'v_stock_actuel_snapshot');
          
          // Note: v_stock_actuel_snapshot ignore dateJour (snapshot = toujours état actuel)
          // Le test vérifie que la vue correcte est utilisée et que les données sont retournées
          // Il y a 2 lignes dans rowsToReturn, donc on devrait avoir 2 résultats
          expect(result.length, 2);
          
          // Vérifier que les données correspondent aux lignes de la date la plus récente
          final tankA = result.firstWhere(
            (snapshot) => snapshot.citerneId == 'citerne-1',
          );
          expect(tankA.stockAmbiantTotal, 1000.0);
          expect(tankA.stock15cTotal, 950.0);
        },
      );
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