import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/data/repositories/stocks_kpi_repository.dart';
import 'package:ml_pp_mvp/features/stocks/data/stocks_kpi_providers.dart';
import 'package:ml_pp_mvp/features/stocks/domain/depot_stocks_snapshot.dart';

/// Fake repository pour les tests du provider
class FakeStocksKpiRepository implements StocksKpiRepository {
  final List<DepotGlobalStockKpi> _globalTotals;
  final List<DepotOwnerStockKpi> _ownerTotals;
  final List<CiterneGlobalStockSnapshot> _citerneSnapshots;

  FakeStocksKpiRepository({
    List<DepotGlobalStockKpi>? globalTotals,
    List<DepotOwnerStockKpi>? ownerTotals,
    List<CiterneGlobalStockSnapshot>? citerneSnapshots,
  })  : _globalTotals = globalTotals ?? [],
        _ownerTotals = ownerTotals ?? [],
        _citerneSnapshots = citerneSnapshots ?? [];

  @override
  Future<List<DepotGlobalStockKpi>> fetchDepotProductTotals({
    String? depotId,
    String? produitId,
    DateTime? dateJour,
  }) async {
    return _globalTotals;
  }

  @override
  Future<List<DepotOwnerStockKpi>> fetchDepotOwnerTotals({
    String? depotId,
    String? produitId,
    String? proprietaireType,
    DateTime? dateJour,
  }) async {
    return _ownerTotals;
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
    return _citerneSnapshots;
  }
}

void main() {
  group('depotStocksSnapshotProvider', () {
    test('should build DepotStocksSnapshot with data from repository', () async {
      // Arrange
      final testDate = DateTime(2025, 12, 8);
      final testDepotId = 'depot-1';

      final testGlobalTotal = DepotGlobalStockKpi(
        depotId: testDepotId,
        depotNom: 'Dépôt Test',
        produitId: 'produit-1',
        produitNom: 'Gasoil/AGO',
        stockAmbiantTotal: 10000.0,
        stock15cTotal: 9500.0,
      );

      final testOwners = [
        DepotOwnerStockKpi(
          depotId: testDepotId,
          depotNom: 'Dépôt Test',
          proprietaireType: 'MONALUXE',
          produitId: 'produit-1',
          produitNom: 'Gasoil/AGO',
          stockAmbiantTotal: 6000.0,
          stock15cTotal: 5700.0,
        ),
        DepotOwnerStockKpi(
          depotId: testDepotId,
          depotNom: 'Dépôt Test',
          proprietaireType: 'PARTENAIRE',
          produitId: 'produit-1',
          produitNom: 'Gasoil/AGO',
          stockAmbiantTotal: 4000.0,
          stock15cTotal: 3800.0,
        ),
      ];

      final testCiternes = [
        CiterneGlobalStockSnapshot(
          citerneId: 'citerne-1',
          citerneNom: 'TANK1',
          produitId: 'produit-1',
          produitNom: 'Gasoil/AGO',
          dateJour: testDate,
          stockAmbiantTotal: 5000.0,
          stock15cTotal: 4750.0,
          capaciteTotale: 10000.0,
        ),
        CiterneGlobalStockSnapshot(
          citerneId: 'citerne-2',
          citerneNom: 'TANK2',
          produitId: 'produit-1',
          produitNom: 'Gasoil/AGO',
          dateJour: testDate,
          stockAmbiantTotal: 5000.0,
          stock15cTotal: 4750.0,
          capaciteTotale: 10000.0,
        ),
      ];

      final fakeRepo = FakeStocksKpiRepository(
        globalTotals: [testGlobalTotal],
        ownerTotals: testOwners,
        citerneSnapshots: testCiternes,
      );

      final container = ProviderContainer(
        overrides: [
          stocksKpiRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      // Act
      final params = DepotStocksSnapshotParams(
        depotId: testDepotId,
        dateJour: testDate,
      );
      final snapshotAsync = container.read(
        depotStocksSnapshotProvider(params),
      );

      // Read the provider and wait for it to complete
      final snapshot = await container.read(
        depotStocksSnapshotProvider(params).future,
      );

      // Assert
      expect(snapshot.dateJour, equals(testDate));
      expect(snapshot.isFallback, isFalse);
      expect(snapshot.totals, equals(testGlobalTotal));
      expect(snapshot.owners, equals(testOwners));
      expect(snapshot.citerneRows, equals(testCiternes));
    });

    test('should use DateTime.now() when dateJour is not provided', () async {
      // Arrange
      final testDepotId = 'depot-1';
      final fakeRepo = FakeStocksKpiRepository(
        globalTotals: [],
        ownerTotals: [],
        citerneSnapshots: [],
      );

      final container = ProviderContainer(
        overrides: [
          stocksKpiRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      // Act
      final params = DepotStocksSnapshotParams(
        depotId: testDepotId,
        // dateJour is null
      );
      final snapshotAsync = container.read(
        depotStocksSnapshotProvider(params),
      );

      // Read the provider and wait for it to complete
      final snapshot = await container.read(
        depotStocksSnapshotProvider(params).future,
      );

      // Assert
      // The date should be close to now (within 1 second)
      final now = DateTime.now();
      expect(
        snapshot.dateJour.difference(now).inSeconds.abs(),
        lessThan(1),
      );
      expect(snapshot.isFallback, isFalse);
    });

    test('should create empty DepotGlobalStockKpi when globalTotals is empty',
        () async {
      // Arrange
      final testDate = DateTime(2025, 12, 8);
      final testDepotId = 'depot-1';

      final fakeRepo = FakeStocksKpiRepository(
        globalTotals: [], // Empty list
        ownerTotals: [],
        citerneSnapshots: [],
      );

      final container = ProviderContainer(
        overrides: [
          stocksKpiRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );

      // Act
      final params = DepotStocksSnapshotParams(
        depotId: testDepotId,
        dateJour: testDate,
      );
      final snapshotAsync = container.read(
        depotStocksSnapshotProvider(params),
      );

      // Read the provider and wait for it to complete
      final snapshot = await container.read(
        depotStocksSnapshotProvider(params).future,
      );

      // Assert
      expect(snapshot.totals.depotId, equals(testDepotId));
      expect(snapshot.totals.depotNom, isEmpty);
      expect(snapshot.totals.produitId, isEmpty);
      expect(snapshot.totals.produitNom, isEmpty);
      expect(snapshot.totals.stockAmbiantTotal, equals(0.0));
      expect(snapshot.totals.stock15cTotal, equals(0.0));
    });
  });
}

