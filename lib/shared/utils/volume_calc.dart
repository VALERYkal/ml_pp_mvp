/* ===========================================================
   ML_PP MVP — Utilitaires volume (ambiant & approximation @15 °C)

   ⚠️ DB-FIRST — PAS SOURCE DE VÉRITÉ MÉTIER pour le volume @15 °C
   - Le volume canonique (`volume_15c`) est calculé et persisté par la base
     (triggers / grilles ASTM selon le pipeline produit).
   - `volume_corrige_15c` est un fallback legacy en lecture : toujours préférer
     `volume_15c ?? volume_corrige_15c` côté app pour un scalaire @15 °C.

   Ce fichier fournit uniquement des approximations locales utiles au MVP
   (prévisualisation UI, deltas d’ajustement quand aucun scalaire DB n’est
   disponible). Ne pas les utiliser pour des décisions métier finales.
   =========================================================== */

/// Volume ambiant à partir d’indices (avant/après).
/// - Si une valeur est nulle → 0.
/// - Si le résultat est négatif → clamp à 0 (sécurité UX).
double computeVolumeAmbiant(double? indexAvant, double? indexApres) {
  if (indexAvant == null || indexApres == null) return 0;
  final v = indexApres - indexAvant;
  return v > 0 ? v : 0;
}

/// **Approximation UX non canonique** du volume à 15 °C à partir du volume
/// observé (L), de la température (°C) et d’un scalaire de densité.
///
/// La **base de données** calcule le volume @15 °C officiel (`volume_15c`) ;
/// cette formule linéaire MVP (`beta≈0.00065`) ne remplace pas le moteur DB.
double calcV15({
  required double volumeObserveL,
  required double temperatureC,
  required double densiteA15, // conservé pour évolutivité / cohérence d’API
}) {
  const double beta = 0.00065;
  final correction = 1 - beta * (temperatureC - 15.0);
  final v15 = volumeObserveL * correction;
  return v15.isFinite ? v15 : volumeObserveL;
}

/// **Approximation UX non canonique** (alpha produit ESS / AGO).
///
/// Ne reflète pas le calcul volumétrique réglementaire en base. À n’utiliser
/// que pour indicateurs ou brouillons d’écran, jamais comme vérité stock.
double computeV15({
  required double volumeAmbiant,
  required double? temperatureC,
  required double? densiteA15, // réservé pour évolutions
  required String produitCode, // 'ESS' | 'AGO'
}) {
  if (temperatureC == null) return volumeAmbiant;
  final alpha = (produitCode.toUpperCase() == 'ESS') ? 0.00100 : 0.00085;
  return volumeAmbiant * (1 - alpha * (temperatureC - 15.0));
}

/// Format SQL `date` (yyyy-MM-dd) sans dépendance externe.
String formatSqlDate(DateTime dt) => dt.toIso8601String().split('T').first;
