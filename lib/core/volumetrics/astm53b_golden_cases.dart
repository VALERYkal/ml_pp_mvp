// lib/core/volumetrics/astm53b_golden_cases.dart

import 'package:ml_pp_mvp/core/volumetrics/astm53b_engine.dart';

/// Représente un cas "golden" pour valider le moteur ASTM 53B.
///
/// L'objectif de ces cas :
/// - reproduire exactement les résultats de l'application terrain ASTM
/// - garantir que ML_PP génère les mêmes densités@15, VCF et volumes@15
/// - servir de base à des tests de non-régression.
///
/// Remarque :
/// - Les valeurs peuvent être issues de réceptions PROD existantes.
/// - Dans un premier temps, ce fichier peut contenir des placeholders.
/// - Les valeurs seront raffinées au fur et à mesure de la calibration.
class Astm53bGoldenCase {
  /// Identifiant technique du cas (peut faire référence à une réception PROD).
  final String id;

  /// Entrée observée (densité, température, volume observé).
  final Astm53bInput input;

  /// Densité à 15 °C attendue (issue de l'app terrain), en kg/m³.
  final double expectedDensity15KgPerM3;

  /// VCF attendu (Volume Correction Factor).
  final double expectedVcf;

  /// Volume corrigé à 15 °C attendu, en litres.
  final double expectedVolume15Liters;

  /// Commentaire optionnel (ex: "Réception SEP 14/02/2026 - camion 1").
  final String? comment;

  const Astm53bGoldenCase({
    required this.id,
    required this.input,
    required this.expectedDensity15KgPerM3,
    required this.expectedVcf,
    required this.expectedVolume15Liters,
    this.comment,
  });
}

/// Liste des cas golden actuellement définis pour ASTM 53B.
///
/// IMPORTANT :
/// - Au début, cette liste peut être partiellement ou totalement vide.
/// - Les valeurs "expected" doivent être remplies uniquement lorsque
///   les résultats terrain sont confirmés.
/// - Ce fichier est versionné comme une référence métier.
const List<Astm53bGoldenCase> kAstm53bGoldenCases = <Astm53bGoldenCase>[
  // Exemple de placeholder à adapter avec de vraies valeurs terrain :
  //
  // Astm53bGoldenCase(
  //   id: 'reception_sep_20260214_camion1',
  //   input: Astm53bInput(
  //     densityObservedKgPerM3: 0.843 * 1000,
  //     temperatureObservedC: 22.4,
  //     volumeObservedLiters: 39291,
  //   ),
  //   expectedDensity15KgPerM3: 845.0, // TODO: valeur réelle
  //   expectedVcf: 0.995,              // TODO: valeur réelle
  //   expectedVolume15Liters: 39102.0, // TODO: valeur réelle
  //   comment: 'Placeholder, à calibrer avec app ASTM terrain.',
  // ),
];
