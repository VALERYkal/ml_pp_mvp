import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/data/repositories/stocks_kpi_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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