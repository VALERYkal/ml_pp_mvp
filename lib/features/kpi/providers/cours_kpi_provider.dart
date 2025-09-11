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

/// Provider pour invalidation en temps réel (optionnel)
final coursRealtimeInvalidatorProvider = Provider<void>((ref) {
  // Ici on pourrait ajouter une logique d'invalidation en temps réel
  // Par exemple, écouter les changements de statut des cours
  return;
});
