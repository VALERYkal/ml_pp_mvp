// ⚠️ DÉPRÉCIÉ - Utiliser kpiProvider à la place
// Ce fichier sera supprimé dans la prochaine version majeure
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/data/repositories/stocks_repository.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';

final stocksRepoProvider = riverpod.Provider<StocksRepository>((ref) {
  return StocksRepository(Supabase.instance.client);
});

typedef StocksParam = ({String? depotId, String? produitId});

/// Param par défaut (filtre dépôt pour directeur/gerant, global pour admin si pas de depotId)
final stocksDefaultParamProvider = riverpod.Provider<StocksParam>((ref) {
  final profil = ref.watch(currentProfilProvider).valueOrNull;
  return (depotId: profil?.depotId, produitId: null);
});

/// Totaux actuels (ambiant & 15°C) — réutilisable (family)
final stocksTotalsProvider =
    riverpod.FutureProvider.family<StocksTotals, StocksParam>((ref, p) async {
  final repo = ref.watch(stocksRepoProvider);
  return repo.totauxActuels(depotId: p.depotId, produitId: p.produitId);
});

/// Realtime invalidation (stocks_journaliers -> la vue se mettra à jour)
final stocksRealtimeInvalidatorProvider = riverpod.Provider.autoDispose<void>((ref) {
  final p = ref.watch(stocksDefaultParamProvider);

  // Note: PostgresChanges n'est pas disponible dans cette version de Supabase
  // On utilise une invalidation manuelle pour l'instant
  // TODO: Implémenter l'invalidation temps réel quand l'API sera disponible
  
  // Pour l'instant, on retourne simplement void
  return;
});
