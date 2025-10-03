import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';

/// Provider pour les comptages par statut (détail)
final cdrKpiCountsByStatutProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final service = ref.watch(coursDeRouteServiceProvider);
  return service.countByStatut();
});

/// Provider pour les comptages par catégorie métier (vue d'ensemble)
final cdrKpiCountsByCategorieProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  final service = ref.watch(coursDeRouteServiceProvider);
  return service.countByCategorie();
});
