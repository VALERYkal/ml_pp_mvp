// 📌 Module : Stocks - Utilitaires de refresh
// 🧭 Description : Fonction utilitaire pour rafraîchir les providers de stocks après un mouvement (sortie/réception)

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../kpi/providers/kpi_provider.dart';
import '../data/stocks_kpi_providers.dart';

/// Normalise une date à minuit (00:00:00)
DateTime _normalizeDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// Invalide tous les providers liés aux stocks après un mouvement (sortie/réception).
/// 
/// À appeler après création réussie d'une sortie ou réception pour rafraîchir :
/// - Dashboard KPIs (kpiProviderProvider)
/// - Snapshots de stocks par dépôt (depotStocksSnapshotProvider)
/// - Capacité totale du dépôt (depotTotalCapacityProvider)
/// - KPIs dashboard stocks (stocksDashboardKpisProvider)
/// 
/// Paramètres :
/// - [ref] : Riverpod WidgetRef (depuis ConsumerWidget/ConsumerStatefulWidget)
/// - [depotId] : ID du dépôt concerné (obligatoire)
/// - [dateJour] : Date du mouvement (optionnel, défaut = aujourd'hui)
void refreshAfterStockMovement(
  WidgetRef ref, {
  required String depotId,
  DateTime? dateJour,
}) {
  final day = _normalizeDay(dateJour ?? DateTime.now());

  // Dashboard KPIs snapshot (principal)
  ref.invalidate(kpiProviderProvider);

  // Snapshot agrégé dépôt/date (cartes stocks/citernes)
  ref.invalidate(
    depotStocksSnapshotProvider(
      DepotStocksSnapshotParams(depotId: depotId, dateJour: day),
    ),
  );

  // Capacité dépôt (si affichée dans certaines cartes)
  ref.invalidate(depotTotalCapacityProvider(depotId));

  // Dashboard stocks service (si certaines UI le watch directement)
  ref.invalidate(stocksDashboardKpisProvider(depotId));
}
