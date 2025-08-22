import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modèle pour les KPIs du directeur
class DirecteurKpiData {
  final int receptionsJour;
  final int sortiesJour;
  final int citernesSousSeuil;
  final int totalCiternes;
  final double ratioUtilisation;

  const DirecteurKpiData({
    required this.receptionsJour,
    required this.sortiesJour,
    required this.citernesSousSeuil,
    required this.totalCiternes,
    required this.ratioUtilisation,
  });
}

/// Provider pour les KPIs du directeur
final directeurKpiProvider = FutureProvider<DirecteurKpiData>((ref) async {
  // Simuler un délai de chargement
  await Future.delayed(const Duration(milliseconds: 600));
  
  // Simuler des données spécifiques au directeur
  return DirecteurKpiData(
    receptionsJour: 15 + (DateTime.now().millisecond % 8),
    sortiesJour: 12 + (DateTime.now().millisecond % 6),
    citernesSousSeuil: 2 + (DateTime.now().millisecond % 4),
    totalCiternes: 24,
    ratioUtilisation: 0.75 + (DateTime.now().millisecond % 20) / 100,
  );
});
