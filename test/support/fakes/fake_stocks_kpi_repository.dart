import 'package:ml_pp_mvp/data/repositories/stocks_kpi_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fake repo 100% in-memory pour éviter Supabase.instance en tests.
class FakeStocksKpiRepository extends StocksKpiRepository {
  FakeStocksKpiRepository()
      : super(SupabaseClient('http://localhost', 'anon')); // jamais utilisé

  // Données injectables depuis les tests
  List<DepotGlobalStockKpi> globalTotals = const [];
  List<DepotOwnerStockKpi> ownerTotals = const [];
  List<CiterneGlobalStockSnapshot> citerneSnapshots = const [];

  @override
  Future<List<DepotGlobalStockKpi>> fetchDepotProductTotals({
    String? depotId,
    String? produitId,
    DateTime? dateJour,
  }) async {
    return globalTotals;
  }

  @override
  Future<List<DepotOwnerStockKpi>> fetchDepotOwnerTotals({
    DateTime? dateJour,
    String? depotId,
    String? produitId,
    String? proprietaireType,
  }) async {
    return ownerTotals;
  }

  @override
  Future<List<CiterneGlobalStockSnapshot>> fetchCiterneGlobalSnapshots({
    String? depotId,
    String? citerneId,
    String? produitId,
    DateTime? dateJour,
  }) async {
    return citerneSnapshots;
  }
}

