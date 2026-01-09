// 📌 Module : Stocks Adjustments - Utilitaires de refresh
// 🧭 Description : Fonction utilitaire pour rafraîchir les providers après création d'un ajustement de stock
// B4.1 - Propagation visuelle immédiate après ajustement

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../kpi/providers/kpi_provider.dart';
import '../../stocks/data/stocks_kpi_providers.dart';
import '../../dashboard/providers/citernes_sous_seuil_provider.dart';
import '../../citernes/providers/citerne_providers.dart'
    show citernesWithStockProvider, citerneStocksSnapshotProvider;
import '../../sorties/providers/sortie_providers.dart'
    show citernesByProduitWithStockProvider;
import '../../../shared/refresh/refresh_helpers.dart';

/// Invalide tous les providers dépendants de v_stock_actuel après création d'un ajustement.
///
/// B4.1 - Propagation visuelle immédiate :
/// Après création d'un ajustement, force le rafraîchissement de :
/// - Stock par citerne (citernesWithStockProvider, citernesByProduitWithStockProvider)
/// - Stock journalier (depotGlobalStockFromSnapshotProvider, depotOwnerStockFromSnapshotProvider, depotStocksSnapshotProvider)
/// - KPI dashboard (kpiProviderProvider, stocksDashboardKpisProvider, citernesSousSeuilProvider)
/// - Tous les providers utilisant v_stock_actuel
///
/// Paramètres :
/// - [ref] : Riverpod WidgetRef
/// - [depotId] : ID du dépôt concerné (optionnel). Si fourni, invalide uniquement les providers pour ce dépôt.
///   Si null, invalide tous les providers (moins performant mais garantit la cohérence).
void refreshAfterStockAdjustment(
  WidgetRef ref, {
  String? depotId,
}) {
  // B4.1 - Invalidation ciblée si depotId fourni, sinon invalidation globale
  
  // 1) Dashboard KPIs (snapshot global)
  ref.invalidate(kpiProviderProvider);
  
  // 2) Providers stocks dashboard (family)
  if (depotId != null) {
    ref.invalidate(stocksDashboardKpisProvider(depotId));
    ref.invalidate(depotGlobalStockFromSnapshotProvider(depotId));
    ref.invalidate(depotOwnerStockFromSnapshotProvider(depotId));
    ref.invalidate(kpiGlobalStockByDepotProvider(depotId));
  } else {
    // Invalider toute la family si pas de depotId
    ref.invalidate(stocksDashboardKpisProvider);
    ref.invalidate(depotGlobalStockFromSnapshotProvider);
    ref.invalidate(depotOwnerStockFromSnapshotProvider);
    ref.invalidate(kpiGlobalStockByDepotProvider);
  }
  
  // 3) Providers citernes (stock par citerne)
  // citernesWithStockProvider n'est pas une family, on l'invalide globalement
  try {
    ref.invalidate(citernesWithStockProvider);
  } catch (_) {
    // Ignorer si provider n'existe pas
  }
  
  // citernesByProduitWithStockProvider est une family - on invalide toute la family
  try {
    ref.invalidate(citernesByProduitWithStockProvider);
  } catch (_) {
    // Ignorer si provider n'existe pas
  }
  
  // 4) Provider citernes sous seuil
  try {
    ref.invalidate(citernesSousSeuilProvider);
  } catch (_) {
    // Ignorer si provider n'existe pas
  }
  
  // 5) Provider snapshots citerne (si existant)
  try {
    ref.invalidate(citerneStocksSnapshotProvider);
  } catch (_) {
    // Ignorer si provider n'existe pas
  }
  
  // 6) Utiliser la fonction helper existante pour les autres providers
  invalidateDashboardKpisAfterStockMovement(ref, depotId: depotId);
  
  // Note : depotStocksSnapshotProvider nécessite des params (DepotStocksSnapshotParams)
  // Il sera invalidé lors du prochain watch avec les mêmes params
  // Si on veut l'invalider explicitement, il faudrait connaître depotId + dateJour
}
