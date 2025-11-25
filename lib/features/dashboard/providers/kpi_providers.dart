import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modèle simple pour les KPIs
class KpiData {
  final int receptionsJour;
  final int sortiesJour;
  final int citernesSousSeuil;
  final int stockTotal;

  const KpiData({
    required this.receptionsJour,
    required this.sortiesJour,
    required this.citernesSousSeuil,
    required this.stockTotal,
  });
}

/// Provider pour simuler les données KPI
final kpiProvider = FutureProvider<KpiData>((ref) async {
  // Simuler un délai de chargement
  await Future.delayed(const Duration(milliseconds: 800));

  // Simuler des données aléatoires
  return KpiData(
    receptionsJour: 12 + (DateTime.now().millisecond % 10),
    sortiesJour: 8 + (DateTime.now().millisecond % 8),
    citernesSousSeuil: 3 + (DateTime.now().millisecond % 5),
    stockTotal: 45000 + (DateTime.now().millisecond % 10000),
  );
});

/// Provider pour les KPIs par rôle (pour l'instant, même données pour tous)
final kpiProviderForRole = FutureProvider<KpiData>((ref) async {
  return ref.watch(kpiProvider.future);
});

