import 'package:flutter_test/flutter_test.dart';

// ✅ Ajuste ces imports selon ton projet
import 'package:ml_pp_mvp/data/repositories/stocks_kpi_repository.dart';
import '../support/fakes/fake_supabase_query.dart';

void main() {
  group('CONTRACT — Stock actuel source', () {
    test('StocksKpiRepository MUST query v_stock_actuel (single source of truth)', () async {
      // Arrange
      final fakeClient = FakeSupabaseClient();

      // Seed minimal dataset to avoid empty behaviors in the fake chain
      fakeClient.setViewData('v_stock_actuel', <Map<String, dynamic>>[
        {
          'depot_id': '00000000-0000-0000-0000-000000000001',
          'citerne_id': '00000000-0000-0000-0000-000000000002',
          'produit_id': '00000000-0000-0000-0000-000000000003',
          'proprietaire_type': 'MONALUXE',
          'stock_ambiant': 1.0,
          'stock_15c': 1.0,
        }
      ]);

      final repo = StocksKpiRepository(fakeClient);

      // Act
      // ✅ fetchStockActuelRows() nécessite depotId (required)
      await repo.fetchStockActuelRows(
        depotId: '00000000-0000-0000-0000-000000000001',
      );

      // Assert — contract guard
      expect(fakeClient.fromCalls, isNotEmpty, reason: 'Repo must query a SQL view');
      expect(
        fakeClient.fromCalls,
        contains('v_stock_actuel'),
        reason:
            'CONTRACT: Stock actuel MUST come from v_stock_actuel only. '
            'If you change the source, update the contract docs & migration strategy first.',
      );

      // Optional: ensure no alternative views are queried
      expect(fakeClient.fromCalls, isNot(contains('stocks_journaliers')));
      expect(fakeClient.fromCalls, isNot(contains('v_stock_actuel_owner_snapshot')));
    });
  });
}
