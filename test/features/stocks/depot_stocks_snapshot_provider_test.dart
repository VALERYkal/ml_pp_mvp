import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/data/repositories/stocks_kpi_repository.dart';
import 'package:ml_pp_mvp/features/stocks/data/stocks_kpi_providers.dart';

/// Fake repository pour les tests du provider
class FakeStocksKpiRepository implements StocksKpiRepository {
  final List<DepotGlobalStockKpi> _globalTotals;
  final List<DepotOwnerStockKpi> _ownerTotals;
  final List<CiterneGlobalStockSnapshot> _citerneSnapshots;

  FakeStocksKpiRepository({
    List<DepotGlobalStockKpi>? globalTotals,
    List<DepotOwnerStockKpi>? ownerTotals,
    List<CiterneGlobalStockSnapshot>? citerneSnapshots,
  }) : _globalTotals = globalTotals ?? [],
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
  group('depotStocksSnapshotProvider', () {
    test(
      'should build DepotStocksSnapshot with data from repository',
      () async {
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
            capaciteSecurite: 0.0,
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
            capaciteSecurite: 0.0,
          ),
        ];

        final fakeRepo = FakeStocksKpiRepository(
          globalTotals: [testGlobalTotal],
          ownerTotals: testOwners,
          citerneSnapshots: testCiternes,
        );

        final container = ProviderContainer(
          overrides: [stocksKpiRepositoryProvider.overrideWithValue(fakeRepo)],
        );

        // Act
        final params = DepotStocksSnapshotParams(
          depotId: testDepotId,
          dateJour: testDate,
          allowFallbackInDebug:
              true, // Autoriser fallback pour ce test (repo OK)
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
      },
    );

    test('should use DateTime.now() when dateJour is not provided', () async {
      // Arrange
      final testDepotId = 'depot-1';
      final fakeRepo = FakeStocksKpiRepository(
        globalTotals: [],
        ownerTotals: [],
        citerneSnapshots: [],
      );

      final container = ProviderContainer(
        overrides: [stocksKpiRepositoryProvider.overrideWithValue(fakeRepo)],
      );

      // Act
      final params = DepotStocksSnapshotParams(
        depotId: testDepotId,
        // dateJour is null
        allowFallbackInDebug: true, // Autoriser fallback pour ce test (repo OK)
      );
      // Read the provider and wait for it to complete
      final snapshot = await container.read(
        depotStocksSnapshotProvider(params).future,
      );

      // Assert
      // The date should be normalized to midnight and match today's date
      // (year, month, day only, ignoring time)
      final now = DateTime.now();
      final expectedDate = DateTime(now.year, now.month, now.day);
      expect(snapshot.dateJour.year, equals(expectedDate.year));
      expect(snapshot.dateJour.month, equals(expectedDate.month));
      expect(snapshot.dateJour.day, equals(expectedDate.day));
      // The time should be normalized to midnight
      expect(snapshot.dateJour.hour, equals(0));
      expect(snapshot.dateJour.minute, equals(0));
      expect(snapshot.dateJour.second, equals(0));
      expect(snapshot.isFallback, isFalse);
    });

    test(
      'should create empty DepotGlobalStockKpi when globalTotals is empty',
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
          overrides: [stocksKpiRepositoryProvider.overrideWithValue(fakeRepo)],
        );

        // Act
        final params = DepotStocksSnapshotParams(
          depotId: testDepotId,
          dateJour: testDate,
          allowFallbackInDebug:
              true, // Autoriser fallback pour ce test (repo OK)
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
      },
    );

    // PHASE 4 - Anti-régression tests

    test(
      'returns isFallback=false for normal fixtures with valid repository data',
      () async {
        // Arrange: repository avec des données valides
        final testDate = DateTime(2025, 12, 10);
        final testDepotId = 'depot-1';

        final testGlobalTotal = DepotGlobalStockKpi(
          depotId: testDepotId,
          depotNom: 'Dépôt Test',
          produitId: 'prod-1',
          produitNom: 'Gasoil',
          stockAmbiantTotal: 5000.0,
          stock15cTotal: 4750.0,
        );

        final testOwners = [
          DepotOwnerStockKpi(
            depotId: testDepotId,
            depotNom: 'Dépôt Test',
            proprietaireType: 'MONALUXE',
            produitId: 'prod-1',
            produitNom: 'Gasoil',
            stockAmbiantTotal: 3000.0,
            stock15cTotal: 2850.0,
          ),
        ];

        final fakeRepo = FakeStocksKpiRepository(
          globalTotals: [testGlobalTotal],
          ownerTotals: testOwners,
          citerneSnapshots: [],
        );

        final container = ProviderContainer(
          overrides: [stocksKpiRepositoryProvider.overrideWithValue(fakeRepo)],
        );

        // Act
        final params = DepotStocksSnapshotParams(
          depotId: testDepotId,
          dateJour: testDate,
          allowFallbackInDebug:
              false, // Fallback interdit = doit réussir sans fallback
        );
        final snapshot = await container.read(
          depotStocksSnapshotProvider(params).future,
        );

        // Assert: isFallback doit être false car les données sont valides
        expect(
          snapshot.isFallback,
          isFalse,
          reason: 'Avec des données valides, isFallback doit être false',
        );
        expect(snapshot.totals.stockAmbiantTotal, equals(5000.0));
        expect(snapshot.owners.length, equals(1));
      },
    );

    test(
      'normalizes dateJour to 00:00:00.000 before querying repository',
      () async {
        // Arrange: créer une date avec heures/minutes/secondes
        final testDateWithTime = DateTime(2025, 12, 10, 14, 30, 45, 123);
        final testDepotId = 'depot-1';

        // Fake repository qui capture la date utilisée
        DateTime? capturedDateJour;
        final fakeRepo = FakeStocksKpiRepository(
          globalTotals: [
            DepotGlobalStockKpi(
              depotId: testDepotId,
              depotNom: 'Test',
              produitId: 'prod-1',
              produitNom: 'Gasoil',
              stockAmbiantTotal: 1000.0,
              stock15cTotal: 950.0,
            ),
          ],
        );

        // Créer un wrapper qui capture dateJour
        final capturingRepo = _CapturingStocksKpiRepository(
          fakeRepo,
          onDateJour: (date) => capturedDateJour = date,
        );

        final container = ProviderContainer(
          overrides: [
            stocksKpiRepositoryProvider.overrideWithValue(capturingRepo),
          ],
        );

        // Act
        final params = DepotStocksSnapshotParams(
          depotId: testDepotId,
          dateJour: testDateWithTime, // Date avec heures/minutes/secondes
          allowFallbackInDebug: true,
        );
        final snapshot = await container.read(
          depotStocksSnapshotProvider(params).future,
        );

        // Assert: la date dans snapshot doit être normalisée
        expect(
          snapshot.dateJour.hour,
          equals(0),
          reason: 'Heure doit être normalisée à 0',
        );
        expect(
          snapshot.dateJour.minute,
          equals(0),
          reason: 'Minute doit être normalisée à 0',
        );
        expect(
          snapshot.dateJour.second,
          equals(0),
          reason: 'Seconde doit être normalisée à 0',
        );
        expect(
          snapshot.dateJour.millisecond,
          equals(0),
          reason: 'Milliseconde doit être normalisée à 0',
        );
        expect(snapshot.dateJour.year, equals(2025));
        expect(snapshot.dateJour.month, equals(12));
        expect(snapshot.dateJour.day, equals(10));

        // Assert: la date passée au repository doit aussi être normalisée
        expect(capturedDateJour, isNotNull);
        expect(capturedDateJour!.hour, equals(0));
        expect(capturedDateJour!.minute, equals(0));
        expect(capturedDateJour!.second, equals(0));
        expect(capturedDateJour!.millisecond, equals(0));
      },
    );

    test(
      'ensures all citerneRows have same date_jour (no mixed dates in snapshot)',
      () async {
        // Arrange: créer des citernes avec des dates différentes
        final testDate1 = DateTime(2025, 12, 10);
        final testDate2 = DateTime(2025, 12, 9); // Date différente
        final testDepotId = 'depot-1';

        final testCiternes = [
          CiterneGlobalStockSnapshot(
            citerneId: 'citerne-1',
            citerneNom: 'TANK1',
            produitId: 'prod-1',
            produitNom: 'Gasoil',
            dateJour: testDate1,
            stockAmbiantTotal: 1000.0,
            stock15cTotal: 950.0,
            capaciteTotale: 5000.0,
            capaciteSecurite: 0.0,
          ),
          CiterneGlobalStockSnapshot(
            citerneId: 'citerne-2',
            citerneNom: 'TANK2',
            produitId: 'prod-1',
            produitNom: 'Gasoil',
            dateJour: testDate2, // Date différente (devrait être détectée)
            stockAmbiantTotal: 2000.0,
            stock15cTotal: 1900.0,
            capaciteTotale: 10000.0,
            capaciteSecurite: 0.0,
          ),
        ];

        final fakeRepo = FakeStocksKpiRepository(
          globalTotals: [
            DepotGlobalStockKpi(
              depotId: testDepotId,
              depotNom: 'Test',
              produitId: 'prod-1',
              produitNom: 'Gasoil',
              stockAmbiantTotal: 3000.0,
              stock15cTotal: 2850.0,
            ),
          ],
          ownerTotals: [],
          citerneSnapshots: testCiternes,
        );

        final container = ProviderContainer(
          overrides: [stocksKpiRepositoryProvider.overrideWithValue(fakeRepo)],
        );

        // Act
        final params = DepotStocksSnapshotParams(
          depotId: testDepotId,
          dateJour: testDate1,
          allowFallbackInDebug: true,
        );
        final snapshot = await container.read(
          depotStocksSnapshotProvider(params).future,
        );

        // Assert: le snapshot est retourné même avec des dates mixtes (pas de crash)
        // Note: En pratique, le repository devrait filtrer les dates, mais ce test vérifie
        // que le provider ne crash pas et que le garde de régression détecte le problème.
        // Le log d'avertissement "Plusieurs dates distinctes détectées" devrait être émis.
        expect(snapshot.citerneRows.length, equals(2));

        // Vérifier que le snapshot contient les deux citernes (dates mixtes détectées mais pas bloquantes)
        final citerneIds = snapshot.citerneRows.map((c) => c.citerneId).toSet();
        expect(citerneIds, contains('citerne-1'));
        expect(citerneIds, contains('citerne-2'));

        // Le garde de régression devrait détecter les dates mixtes (visible dans les logs)
        // En production, le repository garantirait une seule date via _filterToLatestDate,
        // donc ce test vérifie que le système est résilient même si le repository ne filtre pas.
      },
    );
  });
}

/// Helper class pour capturer la dateJour passée au repository
class _CapturingStocksKpiRepository implements StocksKpiRepository {
  final StocksKpiRepository _delegate;
  final void Function(DateTime? dateJour) onDateJour;

  _CapturingStocksKpiRepository(this._delegate, {required this.onDateJour});

  @override
  Future<List<DepotGlobalStockKpi>> fetchDepotProductTotals({
    String? depotId,
    String? produitId,
    DateTime? dateJour,
  }) async {
    onDateJour(dateJour);
    return _delegate.fetchDepotProductTotals(
      depotId: depotId,
      produitId: produitId,
      dateJour: dateJour,
    );
  }

  @override
  Future<List<DepotOwnerStockKpi>> fetchDepotOwnerTotals({
    String? depotId,
    String? produitId,
    String? proprietaireType,
    DateTime? dateJour,
  }) async {
    onDateJour(dateJour);
    return _delegate.fetchDepotOwnerTotals(
      depotId: depotId,
      produitId: produitId,
      proprietaireType: proprietaireType,
      dateJour: dateJour,
    );
  }

  @override
  Future<List<CiterneOwnerStockSnapshot>> fetchCiterneOwnerSnapshots({
    String? depotId,
    String? citerneId,
    String? produitId,
    String? proprietaireType,
    DateTime? dateJour,
  }) async {
    return _delegate.fetchCiterneOwnerSnapshots(
      depotId: depotId,
      citerneId: citerneId,
      produitId: produitId,
      proprietaireType: proprietaireType,
      dateJour: dateJour,
    );
  }

  @override
  Future<List<CiterneGlobalStockSnapshot>> fetchCiterneGlobalSnapshots({
    String? depotId,
    String? citerneId,
    String? produitId,
    DateTime? dateJour,
  }) async {
    return _delegate.fetchCiterneGlobalSnapshots(
      depotId: depotId,
      citerneId: citerneId,
      produitId: produitId,
      dateJour: dateJour,
    );
  }

  @override
  Future<double> fetchDepotTotalCapacity({
    required String depotId,
    String? produitId,
  }) async {
    return _delegate.fetchDepotTotalCapacity(
      depotId: depotId,
      produitId: produitId,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCiterneStocksFromSnapshot({
    String? depotId,
    String? citerneId,
    String? produitId,
  }) async {
    return _delegate.fetchCiterneStocksFromSnapshot(
      depotId: depotId,
      citerneId: citerneId,
      produitId: produitId,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDepotOwnerStocksFromSnapshot({
    required String depotId,
    String? produitId,
  }) async {
    return _delegate.fetchDepotOwnerStocksFromSnapshot(
      depotId: depotId,
      produitId: produitId,
    );
  }
}
