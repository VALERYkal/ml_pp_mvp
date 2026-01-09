// 📌 Module : Stocks Adjustments - Providers
// 🧭 Description : Providers pour détecter la présence d'ajustements récents
// B4.2 - Badge "STOCK CORRIGÉ"

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/repositories/repositories.dart' show supabaseClientProvider;

/// Provider qui vérifie si un dépôt a des ajustements récents (30 derniers jours)
///
/// B4.2 - Basé sur la présence d'ajustements récents dans stock_adjustments.
/// Lecture seule depuis la table existante (pas de nouvelle requête DB complexe).
///
/// Retourne `true` si le dépôt a au moins un ajustement dans les 30 derniers jours,
/// `false` sinon.
final hasDepotAdjustmentsProvider = FutureProvider.family<bool, String>((
  ref,
  depotId,
) async {
  if (depotId.isEmpty) return false;

  try {
    final client = ref.watch(supabaseClientProvider);
    
    // Date limite : 30 jours avant aujourd'hui
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    
    // Vérifier s'il existe au moins un ajustement pour ce dépôt dans les 30 derniers jours
    final response = await client
        .from('stock_adjustments')
        .select('id')
        .eq('depot_id', depotId)
        .gte('created_at', cutoffDate.toIso8601String())
        .limit(1)
        .maybeSingle();
    
    return response != null;
  } catch (e) {
    // En cas d'erreur, retourner false (pas de badge affiché)
    return false;
  }
});

/// Provider qui vérifie si une citerne a des ajustements récents (30 derniers jours)
///
/// B4.2 - Basé sur la présence d'ajustements récents dans stock_adjustments.
/// Lecture seule depuis la table existante (pas de nouvelle requête DB complexe).
///
/// Retourne `true` si la citerne a au moins un ajustement dans les 30 derniers jours,
/// `false` sinon.
final hasCiterneAdjustmentsProvider = FutureProvider.family<bool, String>((
  ref,
  citerneId,
) async {
  if (citerneId.isEmpty) return false;

  try {
    final client = ref.watch(supabaseClientProvider);
    
    // Date limite : 30 jours avant aujourd'hui
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    
    // Vérifier s'il existe au moins un ajustement pour cette citerne dans les 30 derniers jours
    final response = await client
        .from('stock_adjustments')
        .select('id')
        .eq('citerne_id', citerneId)
        .gte('created_at', cutoffDate.toIso8601String())
        .limit(1)
        .maybeSingle();
    
    return response != null;
  } catch (e) {
    // En cas d'erreur, retourner false (pas de badge affiché)
    return false;
  }
});
