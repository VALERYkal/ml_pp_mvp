import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_provider.dart';
import 'package:ml_pp_mvp/features/stocks/data/stocks_kpi_providers.dart';
import 'package:ml_pp_mvp/features/citernes/providers/citerne_providers.dart';

/// Invalide les providers KPI/Stocks liés au dashboard après un mouvement de stock.
///
/// Cette fonction doit être appelée après une réception ou une sortie validée
/// pour garantir que le dashboard affiche les données à jour.
///
/// - Invalide le snapshot KPI principal (`kpiProviderProvider`)
/// - Invalide le provider agrégé stocks du dashboard (`stocksDashboardKpisProvider`)
/// - Invalide les providers snapshot de stock actuel (depotGlobalStockFromSnapshotProvider, 
///   depotOwnerStockFromSnapshotProvider, citerneStocksSnapshotProvider)
///   si `depotId` est fourni, sinon invalide toute la family
///
/// Paramètres:
/// - [ref]: La référence Riverpod (peut être `Ref` ou `WidgetRef`)
/// - [depotId]: Optionnel, l'ID du dépôt concerné. Si fourni, invalide uniquement
///   l'instance des providers pour ce dépôt. Sinon, invalide toute la family.
void invalidateDashboardKpisAfterStockMovement(WidgetRef ref, {String? depotId}) {
  // 1) Invalider le provider KPI dashboard (snapshot global)
  ref.invalidate(kpiProviderProvider);

  // 2) Invalider le cache stocks du dashboard
  // stocksDashboardKpisProvider est une family -> on invalide l'instance ciblée si possible
  if (depotId != null) {
    ref.invalidate(stocksDashboardKpisProvider(depotId));
  } else {
    // Fallback: invalider toute la family (ok si pas de depotId)
    ref.invalidate(stocksDashboardKpisProvider);
  }

  // 3) Invalider les providers snapshot de stock actuel (nouvelle source de vérité)
  if (depotId != null) {
    try {
      ref.invalidate(depotGlobalStockFromSnapshotProvider(depotId));
    } catch (_) {}
    try {
      ref.invalidate(depotOwnerStockFromSnapshotProvider(depotId));
    } catch (_) {}
    try {
      ref.invalidate(citerneStocksSnapshotProvider);
    } catch (_) {}
  } else {
    // Fallback: invalider toute la family si pas de depotId
    try {
      ref.invalidate(depotGlobalStockFromSnapshotProvider);
    } catch (_) {}
    try {
      ref.invalidate(depotOwnerStockFromSnapshotProvider);
    } catch (_) {}
    try {
      ref.invalidate(citerneStocksSnapshotProvider);
    } catch (_) {}
  }
}
