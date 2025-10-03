// ⚠️ DÉPRÉCIÉ - Utiliser kpiProvider à la place
// Ce fichier sera supprimé dans la prochaine version majeure
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:ml_pp_mvp/features/kpi/providers/receptions_kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/providers/sorties_kpi_provider.dart';

class BalanceStats {
  final double deltaAmbiant;
  final double delta15c;
  const BalanceStats({required this.deltaAmbiant, required this.delta15c});
}

final balanceTodayProvider = riverpod.FutureProvider<BalanceStats>((ref) async {
  // On réutilise les paramètres stables des KPI 2 & 4 (déjà filtrés par dépôt si nécessaire)
  final recP = ref.watch(receptionsTodayParamProvider);
  final soP = ref.watch(sortiesTodayParamProvider);

  final recF = ref.watch(receptionsKpiProvider(recP).future);
  final soF = ref.watch(sortiesKpiProvider(soP).future);

  final rec = await recF;
  final so = await soF;

  return BalanceStats(
    deltaAmbiant: rec.volAmbiant - so.volAmbiant,
    delta15c: rec.vol15c - so.vol15c,
  );
});
