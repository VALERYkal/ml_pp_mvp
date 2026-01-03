import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/data/repositories/stocks_kpi_repository.dart';
import 'package:ml_pp_mvp/features/stocks/data/stocks_kpi_providers.dart';
import 'package:ml_pp_mvp/shared/refresh/refresh_helpers.dart';

/// Fake repository qui compte les appels à fetchStockActuelRows
class _FakeStocksKpiRepository extends StocksKpiRepository {
  int fetchCallCount = 0;
  final List<Map<String, dynamic>> fakeRows;

  _FakeStocksKpiRepository(this.fakeRows) : super(_FakeSupabaseClient());

  @override
  Future<List<Map<String, dynamic>>> fetchStockActuelRows({
    required String depotId,
    String? produitId,
  }) async {
    fetchCallCount++;
    return fakeRows;
  }
}

/// Fake SupabaseClient minimal pour le repository
class _FakeSupabaseClient extends SupabaseClient {
  _FakeSupabaseClient() : super('http://localhost', 'anon-key');
}

void main() {
  group('Provider invalidation after stock adjustment', () {
    testWidgets(
      'invalidates depotGlobalStockFromSnapshotProvider after adjustment',
      (WidgetTester tester) async {
        // Arrange: Créer un fake repository avec compteur
        final fakeRows = [
          {
            'depot_id': 'depot-1',
            'depot_nom': 'Depot A',
            'citerne_id': 'citerne-1',
            'citerne_nom': 'Tank A',
            'produit_id': 'prod-1',
            'produit_nom': 'Gasoil',
            'proprietaire_type': 'MONALUXE',
            'stock_ambiant': 1000.0,
            'stock_15c': 980.0,
            'updated_at': DateTime.now().toIso8601String(),
          },
        ];

        final fakeRepo = _FakeStocksKpiRepository(fakeRows);
        int initialCallCount = 0;

        // Widget de test qui lit le provider
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              stocksKpiRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  // Lire le provider une première fois
                  final asyncValue = ref.watch(
                    depotGlobalStockFromSnapshotProvider('depot-1'),
                  );

                  // Capturer le compteur après la première lecture
                  if (initialCallCount == 0) {
                    initialCallCount = fakeRepo.fetchCallCount;
                  }

                  return Scaffold(
                    body: Column(
                      children: [
                        Text('Call count: ${fakeRepo.fetchCallCount}'),
                        if (asyncValue.hasValue)
                          Text('Stock ambiant: ${asyncValue.value?.amb ?? 0.0}'),
                        ElevatedButton(
                          key: const Key('invalidate_button'),
                          onPressed: () {
                            // Simuler l'invalidation après création d'ajustement
                            invalidateDashboardKpisAfterStockMovement(
                              ref,
                              depotId: 'depot-1',
                            );
                          },
                          child: const Text('Simulate Adjustment'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Attendre que le widget soit construit et le provider lu
        await tester.pumpAndSettle();

        // Vérifier que le repository a été appelé une première fois
        expect(fakeRepo.fetchCallCount, greaterThan(0));
        final callCountBeforeInvalidation = fakeRepo.fetchCallCount;

        // Act: Simuler l'invalidation (comme après création d'ajustement)
        await tester.tap(find.byKey(const Key('invalidate_button')));
        await tester.pumpAndSettle();

        // Assert: Le repository doit être rappelé (invalidation effective)
        expect(
          fakeRepo.fetchCallCount,
          greaterThan(callCountBeforeInvalidation),
          reason: 'Le provider doit être invalidé et rappelé après ajustement',
        );
      },
    );

    testWidgets(
      'invalidates depotOwnerStockFromSnapshotProvider after adjustment',
      (WidgetTester tester) async {
        // Arrange: Créer un fake repository avec compteur
        final fakeRows = [
          {
            'depot_id': 'depot-1',
            'depot_nom': 'Depot A',
            'citerne_id': 'citerne-1',
            'citerne_nom': 'Tank A',
            'produit_id': 'prod-1',
            'produit_nom': 'Gasoil',
            'proprietaire_type': 'MONALUXE',
            'stock_ambiant': 1000.0,
            'stock_15c': 980.0,
            'updated_at': DateTime.now().toIso8601String(),
          },
        ];

        final fakeRepo = _FakeStocksKpiRepository(fakeRows);

        // Widget de test qui lit le provider
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              stocksKpiRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  // Lire le provider une première fois
                  final asyncValue = ref.watch(
                    depotOwnerStockFromSnapshotProvider('depot-1'),
                  );

                  return Scaffold(
                    body: Column(
                      children: [
                        Text('Call count: ${fakeRepo.fetchCallCount}'),
                        if (asyncValue.hasValue)
                          Text('Stock count: ${asyncValue.value?.length ?? 0}'),
                        ElevatedButton(
                          key: const Key('invalidate_button'),
                          onPressed: () {
                            // Simuler l'invalidation après création d'ajustement
                            invalidateDashboardKpisAfterStockMovement(
                              ref,
                              depotId: 'depot-1',
                            );
                          },
                          child: const Text('Simulate Adjustment'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Attendre que le widget soit construit et le provider lu
        await tester.pumpAndSettle();

        // Vérifier que le repository a été appelé une première fois
        expect(fakeRepo.fetchCallCount, greaterThan(0));
        final callCountBeforeInvalidation = fakeRepo.fetchCallCount;

        // Act: Simuler l'invalidation
        await tester.tap(find.byKey(const Key('invalidate_button')));
        await tester.pumpAndSettle();

        // Assert: Le repository doit être rappelé
        expect(
          fakeRepo.fetchCallCount,
          greaterThan(callCountBeforeInvalidation),
          reason: 'Le provider doit être invalidé et rappelé après ajustement',
        );
      },
    );
  });
}

