import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cdr_etat.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';

// Expects you already have a service provider or factory in your project.
final cdrKpiCountsProvider = FutureProvider<Map<CdrEtat, int>>((ref) async {
  final service = ref.watch(coursDeRouteServiceProvider); // reuse existing provider if present
  return service.countByEtat();
});
