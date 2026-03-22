// 📌 Module : Sorties - Repository KPI
// 🧭 Description : Repository pour les KPI des sorties (agrégations Supabase)

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';

class SortiesKpiRepository {
  final SupabaseClient client;

  SortiesKpiRepository(this.client);

  /// 🚨 PROD-LOCK: Structure KPI Sorties du jour - DO NOT MODIFY
  /// Retourne les KPI "sorties du jour" sous forme de KpiNumberVolume
  ///
  /// Filtre par :
  /// - date_sortie dans le jour donné (format TIMESTAMPTZ, comparaison >= jour 00:00 et < jour+1 00:00)
  /// - statut == 'validee' (OBLIGATOIRE - ne pas accepter 'brouillon')
  /// - depotId (optionnel) : filtre par dépôt via citernes
  ///
  /// Agrège :
  /// - count : nombre de sorties
  /// - volume15c : somme de volume_15c avec fallback volume_corrige_15c (legacy)
  /// - volumeAmbient : somme de volume_ambiant
  ///
  /// Si cette structure est modifiée, mettre à jour:
  /// - Tests KPI (sorties_kpi_repository_test.dart, sorties_kpi_provider_test.dart)
  /// - Dashboard (affichage KPI)
  /// - Documentation KPI
  Future<KpiNumberVolume> getSortiesKpiForDay(
    DateTime day, {
    String? depotId,
  }) async {
    // 1. Calculer les bornes du jour (00:00:00 UTC du jour et 00:00:00 UTC du jour suivant)
    final dayStart = DateTime.utc(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final dayStartIso = dayStart.toIso8601String();
    final dayEndIso = dayEnd.toIso8601String();

    try {
      // 2. Requête Supabase avec filtres
      List result;

      if (depotId != null && depotId.isNotEmpty) {
        // Filtrage par dépôt via citernes (inner join)
        result = await client
            .from('sorties_produit')
            .select(
              'volume_15c, volume_corrige_15c, volume_ambiant, citernes!inner(depot_id)',
            )
            .eq('statut', 'validee')
            .gte('date_sortie', dayStartIso)
            .lt('date_sortie', dayEndIso)
            .eq('citernes.depot_id', depotId);
      } else {
        // Global - récupérer toutes les sorties validées du jour
        result = await client
            .from('sorties_produit')
            .select('volume_15c, volume_corrige_15c, volume_ambiant')
            .eq('statut', 'validee')
            .gte('date_sortie', dayStartIso)
            .lt('date_sortie', dayEndIso);
      }

      final response = result;

      // 🚨 PROD-LOCK: KPI aggregation logic, update tests if modified.
      // 3. Agrégation côté Dart
      int count = 0;
      double volume15c = 0.0;
      double volumeAmbient = 0.0;

      final rows = response as List<Map<String, dynamic>>;

      for (final row in rows) {
        count += 1;

        // Priorité volume_15c, fallback legacy volume_corrige_15c
        final v15 = (row['volume_15c'] as num?)?.toDouble() ??
            (row['volume_corrige_15c'] as num?)?.toDouble() ??
            0.0;
        final vAmb = (row['volume_ambiant'] as num?)?.toDouble() ?? 0.0;

        volume15c += v15;
        volumeAmbient += vAmb;
      }

      return KpiNumberVolume(
        count: count,
        volume15c: volume15c,
        volumeAmbient: volumeAmbient,
      );
    } catch (e) {
      // 🚨 PROD-LOCK: Structure KpiNumberVolume - DO NOT MODIFY
      // En cas d'erreur, loguer et retourner des valeurs zéro
      // Structure KPI: count + volume15c + volumeAmbient (toujours présents)
      // Si cette structure est modifiée, mettre à jour:
      // - Tests KPI (sorties_kpi_repository_test.dart, sorties_kpi_provider_test.dart)
      // - Dashboard (affichage KPI)
      // - Documentation KPI

      debugPrint(
        '[SortiesKpiRepository] Erreur lors de la récupération des KPI: $e',
      );
      return KpiNumberVolume.zero;
    }
  }
}
