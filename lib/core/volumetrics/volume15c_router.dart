import 'package:ml_pp_mvp/core/feature_flags/feature_flags.dart';
import 'package:ml_pp_mvp/core/volumetrics/astm53b_engine.dart';

/// Routeur central pour le calcul du volume à 15°C.
/// OFF par défaut (legacy).
/// ON => utilise ASTM 53B (15°C) via DefaultAstm53bCalculator.
///
/// ⚠️ Aucune intégration métier ici.
double computeVolume15c({
  required FeatureFlags flags,
  required double volumeAmbient,
  required double temperatureC,
  required double densityAt15,
}) {
  if (!flags.useAstm53b15c) {
    // Legacy: tant que l'intégration n'est pas branchée dans Réception,
    // on n'altère pas le comportement.
    return volumeAmbient;
  }

  const calculator = DefaultAstm53bCalculator();
  final result = calculator.compute(
    Astm53bInput(
      densityObservedKgPerM3: densityAt15,
      temperatureObservedC: temperatureC,
      volumeObservedLiters: volumeAmbient,
    ),
  );

  return result.volume15Liters;
}
