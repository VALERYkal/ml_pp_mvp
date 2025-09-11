import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/repositories.dart';
import '../models/kpi_models.dart';

final camionsASuivreProvider = FutureProvider.family<CamionsASuivreData, CamionsFilter>((ref, filter) async {
  final repo = ref.watch(coursDeRouteRepoProvider);
  final counts = await repo.countsCamionsASuivre(depotId: filter.depotId);
  return CamionsASuivreData(enRoute: counts.enRoute, enAttente: counts.enAttente);
});
