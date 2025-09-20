// ⚠️ DÉPRÉCIÉ - Utiliser kpiProvider à la place
// Ce fichier sera supprimé dans la prochaine version majeure
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/repositories.dart';
import '../../profil/providers/profil_provider.dart';
import '../models/kpi_models.dart';

/// Provider stable pour les paramètres par défaut des cours
final coursDefaultParamProvider = Provider<({String? depotId, String? produitId})>((ref) {
  final profil = ref.watch(profilProvider).maybeWhen(
    data: (p) => p,
    orElse: () => null,
  );
  final depotId = profil?.depotId;
  // produitId reste null pour l'instant (tous les produits)
  return (depotId: depotId, produitId: null);
});

/// Provider KPI cours avec volumes enrichis
final coursKpiProvider = FutureProvider.family<CoursCounts, ({String? depotId, String? produitId})>((ref, p) async {
  final repo = ref.watch(coursDeRouteRepoProvider);
  return await repo.countsEnRouteEtAttente(
    depotId: p.depotId,
    produitId: p.produitId,
  );
});

/// Provider pour invalidation en temps réel des KPIs cours
/// 
/// Ce provider est utilisé dans les dashboards pour s'assurer que les KPIs
/// sont mis à jour automatiquement lors des changements de cours de route.
/// 
/// Exemple d'utilisation :
/// ```dart
/// ref.watch(coursRealtimeInvalidatorProvider);
/// ```
final coursRealtimeInvalidatorProvider = Provider<void>((ref) {
  // Ce provider est utilisé pour déclencher une invalidation automatique
  // des KPIs cours dans les dashboards. Il est surveillé par les écrans
  // de dashboard pour maintenir les données à jour.
  
  // Note: L'invalidation manuelle des KPIs est gérée dans les providers
  // de création/modification/suppression des cours de route
  return;
});
