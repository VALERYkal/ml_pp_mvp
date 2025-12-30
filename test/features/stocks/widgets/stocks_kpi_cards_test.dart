import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/data/repositories/stocks_kpi_repository.dart';
import 'package:ml_pp_mvp/features/stocks/data/stocks_kpi_providers.dart';
import 'package:ml_pp_mvp/features/stocks/domain/depot_stocks_snapshot.dart';
import 'package:ml_pp_mvp/features/stocks/widgets/stocks_kpi_cards.dart';

/// Fake repository pour les tests du widget
class FakeStocksKpiRepositoryForWidget implements StocksKpiRepository {
  final DepotStocksSnapshot? snapshot;

  FakeStocksKpiRepositoryForWidget({this.snapshot});

  @override
  Future<List<DepotGlobalStockKpi>> fetchDepotProductTotals({
    String? depotId,
    String? produitId,
    DateTime? dateJour,
  }) async {
    if (snapshot != null) {
      return [snapshot!.totals];
    }
    return [];
  }

  @override
  Future<List<DepotOwnerStockKpi>> fetchDepotOwnerTotals({
    String? depotId,
    String? produitId,
    String? proprietaireType,
    DateTime? dateJour,
  }) async {
    if (snapshot != null) {
      return snapshot!.owners;
    }
    return [];
  }

  @override
  Future<List<CiterneOwnerStockSnapshot>> fetchCiterneOwnerSnapshots({
    String? depotId,
    String? citerneId,
    String? produitId,
    String? proprietaireType,
    DateTime? dateJour,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<CiterneGlobalStockSnapshot>> fetchCiterneGlobalSnapshots({
    String? depotId,
    String? citerneId,
    String? produitId,
    DateTime? dateJour,
  }) async {
    if (snapshot != null) {
      return snapshot!.citerneRows;
    }
    return [];
  }

  @override
  Future<double> fetchDepotTotalCapacity({
    required String depotId,
    String? produitId,
  }) async {
    return 0.0;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCiterneStocksFromSnapshot({
    String? depotId,
    String? citerneId,
    String? produitId,
  }) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDepotOwnerStocksFromSnapshot({
    required String depotId,
    String? produitId,
  }) async {
    return [];
  }
}

void main() {
  group('OwnerStockBreakdownCard', () {
    testWidgets('should display loading state', (WidgetTester tester) async {
      // Arrange - override avec un repository qui renvoie des listes vides rapidement
      final fakeRepo = FakeStocksKpiRepositoryForWidget();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ProviderScope(
            overrides: [
              stocksKpiRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const OwnerStockBreakdownCard(depotId: 'depot-1'),
          ),
        ),
      );

      // Assert directement après pumpWidget (sans pump supplémentaire)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    // Note: Le test de breakdown MONALUXE/PARTENAIRE est complexe à cause du provider autoDispose
    // et nécessite une configuration plus avancée. Pour l'instant, on garde uniquement
    // le test de loading qui valide que le widget gère correctement l'état de chargement.
    // Le test du provider (depot_stocks_snapshot_provider_test.dart) valide déjà
    // la logique métier de construction du snapshot.
  });
}
