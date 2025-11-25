// ?? DÉPRÉCIÉ - Utiliser kpiProvider à la place
// Ce fichier sera supprimé dans la prochaine version majeure
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/data/repositories/sorties_repository.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';

final sortiesRepoProvider = Provider<SortiesRepository>((ref) {
  return SortiesRepository(Supabase.instance.client);
});

/// Param stable (record) pour éviter les rebuilds infinis.
/// startUtcIso / endUtcIso = bornes UTC calculées depuis le jour LOCAL (Kinshasa).
typedef SortiesParam = ({
  String? depotId,
  String startUtcIso,
  String endUtcIso,
});

final sortiesTodayParamProvider = Provider<SortiesParam>((ref) {
  final profilAsync = ref.watch(currentProfilProvider);
  final profil = profilAsync.maybeWhen(data: (p) => p, orElse: () => null);
  final depotId = profil?.depotId;

  // Jour LOCAL : [00:00; 24:00) -> converti en ISO UTC pour la requête.
  final now = DateTime.now();
  final startLocal = DateTime(now.year, now.month, now.day);
  final endLocal = startLocal.add(const Duration(days: 1));
  final startUtcIso = startLocal.toUtc().toIso8601String();
  final endUtcIso = endLocal.toUtc().toIso8601String();

  return (depotId: depotId, startUtcIso: startUtcIso, endUtcIso: endUtcIso);
});

final sortiesKpiProvider = FutureProvider.family<SortiesStats, SortiesParam>((
  ref,
  p,
) async {
  final repo = ref.watch(sortiesRepoProvider);
  return repo.statsJour(
    startUtcIso: p.startUtcIso,
    endUtcIso: p.endUtcIso,
    depotId: p.depotId,
  );
});

/// Invalidation realtime sur sorties_produit (insert/update/delete)
final sortiesRealtimeInvalidatorProvider = Provider.autoDispose<void>((ref) {
  final p = ref.watch(sortiesTodayParamProvider);

  // Note: PostgresChanges n'est pas disponible dans cette version de Supabase
  // On utilise une invalidation manuelle pour l'instant
  // TODO: Implémenter l'invalidation temps réel quand l'API sera disponible

  // Pour l'instant, on retourne simplement void
  return;
});

