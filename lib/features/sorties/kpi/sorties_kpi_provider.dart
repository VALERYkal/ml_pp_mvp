// 📌 Module : Sorties - Providers KPI
// 🧭 Description : Providers Riverpod pour les KPI des sorties

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/data/repositories/repositories.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';
import 'package:ml_pp_mvp/features/sorties/kpi/sorties_kpi_repository.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_provider.dart'
    show sortiesRawTodayProvider, computeKpiSorties;

/// Provider pour le repository KPI Sorties
///
/// ⚠️ DÉPRÉCIÉ : Utiliser sortiesRawTodayProvider + computeKpiSorties à la place
/// Ce provider est conservé pour compatibilité ascendante mais sera supprimé dans une future version.
final sortiesKpiRepositoryProvider = Provider<SortiesKpiRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SortiesKpiRepository(client);
});

/// Provider pour les KPI des sorties du jour
///
/// 🎯 ARCHITECTURE PROD-READY :
/// - Utilise sortiesRawTodayProvider (provider brut overridable)
/// - Utilise computeKpiSorties (fonction pure testable)
/// - Retourne KpiSorties (modèle enrichi avec countMonaluxe/countPartenaire)
///
/// Supporte le filtrage par dépôt via le profil utilisateur (via sortiesRawTodayProvider)
///
/// Pour les tests : override sortiesRawTodayProvider avec des données mockées.
final sortiesKpiTodayProvider = FutureProvider.autoDispose<KpiSorties>((
  ref,
) async {
  final rows = await ref.watch(sortiesRawTodayProvider.future);
  final kpi = computeKpiSorties(rows);

  // Logs optionnels pour debug (peut être retiré en production)
  // debugPrint(
  //   '📊 KPI Sorties: count=${kpi.count}, '
  //   'volumeAmbiant=${kpi.volumeAmbient}, '
  //   'volume15c=${kpi.volume15c}, '
  //   'monaluxe=${kpi.countMonaluxe}, '
  //   'partenaire=${kpi.countPartenaire}',
  // );

  return kpi;
});
