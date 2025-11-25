/* ===========================================================
   ML_PP MVP  Utils volumes (ambiant & 15°C)
   Rôle: fonctions pures pour calculer volume ambiant (indices)
   et approx du volume à 15°C (MVP). Aucun effet de bord.
   =========================================================== */
/// Calcule le volume ambiant à partir d'indices (avant/après).
/// - Si une valeur est nulle ? renvoie 0.
/// - Si le résultat est négatif ? clamp à 0 (sécurité UX).
double computeVolumeAmbiant(double? indexAvant, double? indexApres) {
  if (indexAvant == null || indexApres == null) return 0;
  final v = indexApres - indexAvant;
  return v > 0 ? v : 0;
}

/// Calcule le volume corrigé à 15°C à partir du volume observé (L),
/// de la température ambiante (°C) et de la densité à 15°C.
/// MVP: correction linéaire v15 = vObs * (1 - beta * (T - 15)), beta0.00065.
double calcV15({
  required double volumeObserveL,
  required double temperatureC,
  required double densiteA15, // conservé pour évolutivité
}) {
  const double beta = 0.00065;
  final correction = 1 - beta * (temperatureC - 15.0);
  final v15 = volumeObserveL * correction;
  return v15.isFinite ? v15 : volumeObserveL;
}

/// Approximation MVP du volume corrigé à 15°C.
/// produitCode: 'ESS' ou 'AGO' pour choisir un alpha typique.
/// - Si temperatureC est null ? fallback = volumeAmbiant.
double computeV15({
  required double volumeAmbiant,
  required double? temperatureC,
  required double? densiteA15, // réservé pour calculs réglementaires futurs
  required String produitCode, // 'ESS' | 'AGO'
}) {
  if (temperatureC == null) return volumeAmbiant;
  final alpha = (produitCode.toUpperCase() == 'ESS') ? 0.00100 : 0.00085;
  return volumeAmbiant * (1 - alpha * (temperatureC - 15.0));
}

/// Format SQL 'date' (yyyy-MM-dd) sans dépendance externe.
String formatSqlDate(DateTime dt) => dt.toIso8601String().split('T').first;




