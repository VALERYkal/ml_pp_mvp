// 📌 Module : Réceptions - Providers KPI
// 🧭 Description : Providers Riverpod pour les KPI des réceptions

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/data/repositories/repositories.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/features/receptions/kpi/receptions_kpi_repository.dart';

/// Provider pour le repository KPI Réceptions
final receptionsKpiRepositoryProvider = Provider<ReceptionsKpiRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return ReceptionsKpiRepository(client);
});

/// Provider pour les KPI des réceptions du jour
/// 
/// Retourne un KpiNumberVolume avec :
/// - count : nombre de réceptions validées du jour
/// - volume15c : somme des volumes corrigés à 15°C
/// - volumeAmbient : somme des volumes ambiants
/// 
/// Supporte le filtrage par dépôt via le profil utilisateur
final receptionsKpiTodayProvider = FutureProvider.autoDispose<KpiNumberVolume>((ref) async {
  final repo = ref.watch(receptionsKpiRepositoryProvider);
  final profil = await ref.watch(profilProvider.future);
  final depotId = profil?.depotId;
  final now = DateTime.now();
  return repo.getReceptionsKpiForDay(now, depotId: depotId);
});

