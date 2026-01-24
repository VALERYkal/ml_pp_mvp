// 📌 Module : Réceptions - Providers KPI
// 🧭 Description : Providers Riverpod pour les KPI des réceptions

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/data/repositories/repositories.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';
import 'package:ml_pp_mvp/features/receptions/kpi/receptions_kpi_repository.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_provider.dart'
    show receptionsRawTodayProvider, computeKpiReceptions;

/// Provider pour le repository KPI Réceptions
///
/// ⚠️ DÉPRÉCIÉ : Utiliser receptionsRawTodayProvider + computeKpiReceptions à la place
/// Ce provider est conservé pour compatibilité ascendante mais sera supprimé dans une future version.
final receptionsKpiRepositoryProvider = Provider<ReceptionsKpiRepository>((
  ref,
) {
  final client = ref.watch(supabaseClientProvider);
  return ReceptionsKpiRepository(client);
});

/// Provider pour les KPI des réceptions du jour
///
/// 🎯 ARCHITECTURE PROD-READY :
/// - Utilise receptionsRawTodayProvider (provider brut overridable)
/// - Utilise computeKpiReceptions (fonction pure testable)
/// - Retourne KpiReceptions (modèle enrichi avec countMonaluxe/countPartenaire)
///
/// Supporte le filtrage par dépôt via le profil utilisateur (via receptionsRawTodayProvider)
///
/// Pour les tests : override receptionsRawTodayProvider avec des données mockées.
final receptionsKpiTodayProvider = FutureProvider.autoDispose<KpiReceptions>((
  ref,
) async {
  final rows = await ref.watch(receptionsRawTodayProvider.future);
  final kpi = computeKpiReceptions(rows);

  // Logs optionnels pour debug (peut être retiré en production)
  // debugPrint(
  //   '📊 KPI Réceptions: count=${kpi.count}, '
  //   'volumeAmbiant=${kpi.volumeAmbient}, '
  //   'volume15c=${kpi.volume15c}, '
  //   'monaluxe=${kpi.countMonaluxe}, '
  //   'partenaire=${kpi.countPartenaire}',
  // );

  return kpi;
});
