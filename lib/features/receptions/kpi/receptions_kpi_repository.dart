// 📌 Module : Réceptions - Repository KPI
// 🧭 Description : Repository pour les KPI des réceptions (agrégations Supabase)

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';

class ReceptionsKpiRepository {
  final SupabaseClient client;

  ReceptionsKpiRepository(this.client);

  /// 🚨 PROD-LOCK: Structure KPI Réceptions du jour - DO NOT MODIFY
  /// Retourne les KPI "réceptions du jour" sous forme de KpiNumberVolume
  ///
  /// Filtre par :
  /// - date_reception == jour (format YYYY-MM-DD)
  /// - statut == 'validee' (OBLIGATOIRE - ne pas accepter 'brouillon')
  /// - depotId (optionnel) : filtre par dépôt via citernes
  ///
  /// Agrège :
  /// - count : nombre de réceptions
  /// - volume15c : somme de volume_15c avec fallback volume_corrige_15c (legacy)
  /// - volumeAmbient : somme de volume_ambiant
  ///
  /// Si cette structure est modifiée, mettre à jour:
  /// - Tests KPI (receptions_kpi_repository_test.dart, receptions_kpi_provider_test.dart)
  /// - Dashboard (affichage KPI)
  /// - Documentation KPI
  Future<KpiNumberVolume> getReceptionsKpiForDay(
    DateTime day, {
    String? depotId,
  }) async {
    // 1. Calculer la date du jour (sans l'heure) au format YYYY-MM-DD
    final dateStr =
        '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';

    try {
      // 2. Requête Supabase avec filtres
      List result;

      if (depotId != null && depotId.isNotEmpty) {
        // Filtrage par dépôt via citernes (inner join)
        result = await client
            .from('receptions')
            .select(
              'volume_corrige_15c, volume_ambiant, citernes!inner(depot_id)',
            )
            .eq('date_reception', dateStr)
            .eq('statut', 'validee')
            .eq('citernes.depot_id', depotId);
      } else {
        // Global - récupérer toutes les réceptions validées du jour
        result = await client
            .from('receptions')
            .select('volume_15c, volume_corrige_15c, volume_ambiant')
            .eq('date_reception', dateStr)
            .eq('statut', 'validee');
      }

      final response = result;

      // 3. Agrégation côté Dart
      int count = 0;
      double volume15c = 0.0;
      double volumeAmbient = 0.0;

      final rows = response as List<Map<String, dynamic>>;

      for (final row in rows) {
        count += 1;

        // Casting sécurisé : priorité volume_15c, fallback legacy volume_corrige_15c
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
      // - Tests KPI (receptions_kpi_repository_test.dart, receptions_kpi_provider_test.dart)
      // - Dashboard (affichage KPI)
      // - Documentation KPI

      debugPrint(
        '[ReceptionsKpiRepository] Erreur lors de la récupération des KPI: $e',
      );
      return KpiNumberVolume.zero;
    }
  }
}
