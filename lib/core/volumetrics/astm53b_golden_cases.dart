// lib/core/volumetrics/astm53b_golden_cases.dart
//
// Source: valeurs terrain app SEP (ASTM 53B / API MPMS 11.1)
// Unités: Volume=L, Densité=kg/m³, base=15°C

import 'package:ml_pp_mvp/core/volumetrics/astm53b_engine.dart';

/// Représente un cas "golden" pour valider le moteur ASTM 53B.
///
/// L'objectif de ces cas :
/// - reproduire exactement les résultats de l'application terrain ASTM
/// - garantir que ML_PP génère les mêmes densités@15, VCF et volumes@15
/// - servir de base à des tests de non-régression.
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

/// Liste des cas golden PROD pour ASTM 53B (8 réceptions GASOIL).
const List<Astm53bGoldenCase> kAstm53bGoldenCases = <Astm53bGoldenCase>[
  Astm53bGoldenCase(
    id: 'GASOIL_PROD_01',
    input: Astm53bInput(
      volumeObservedLiters: 39296,
      temperatureObservedC: 29.7,
      densityObservedKgPerM3: 837.3,
    ),
    expectedDensity15KgPerM3: 847.6,
    expectedVcf: 0.9937,
    expectedVolume15Liters: 39048,
  ),
  Astm53bGoldenCase(
    id: 'GASOIL_PROD_02',
    input: Astm53bInput(
      volumeObservedLiters: 39391,
      temperatureObservedC: 23.5,
      densityObservedKgPerM3: 837.5,
    ),
    expectedDensity15KgPerM3: 843.4,
    expectedVcf: 0.9937,
    expectedVolume15Liters: 39143,
  ),
  Astm53bGoldenCase(
    id: 'GASOIL_PROD_03',
    input: Astm53bInput(
      volumeObservedLiters: 39291,
      temperatureObservedC: 23.2,
      densityObservedKgPerM3: 837.6,
    ),
    expectedDensity15KgPerM3: 843.2,
    expectedVcf: 0.9931,
    expectedVolume15Liters: 39020,
  ),
  Astm53bGoldenCase(
    id: 'GASOIL_PROD_04',
    input: Astm53bInput(
      volumeObservedLiters: 36971,
      temperatureObservedC: 19.0,
      densityObservedKgPerM3: 837.0,
    ),
    expectedDensity15KgPerM3: 839.8,
    expectedVcf: 0.9966,
    expectedVolume15Liters: 36845,
  ),
  Astm53bGoldenCase(
    id: 'GASOIL_PROD_05',
    input: Astm53bInput(
      volumeObservedLiters: 38312,
      temperatureObservedC: 20.0,
      densityObservedKgPerM3: 836.0,
    ),
    expectedDensity15KgPerM3: 839.4,
    expectedVcf: 0.9958,
    expectedVolume15Liters: 38151,
  ),
  Astm53bGoldenCase(
    id: 'GASOIL_PROD_06',
    input: Astm53bInput(
      volumeObservedLiters: 39330,
      temperatureObservedC: 20.0,
      densityObservedKgPerM3: 837.0,
    ),
    expectedDensity15KgPerM3: 840.4,
    expectedVcf: 0.9958,
    expectedVolume15Liters: 39165,
  ),
  Astm53bGoldenCase(
    id: 'GASOIL_PROD_07',
    input: Astm53bInput(
      volumeObservedLiters: 37384,
      temperatureObservedC: 20.0,
      densityObservedKgPerM3: 836.0,
    ),
    expectedDensity15KgPerM3: 839.4,
    expectedVcf: 0.9958,
    expectedVolume15Liters: 37227,
  ),
  Astm53bGoldenCase(
    id: 'GASOIL_PROD_08',
    input: Astm53bInput(
      volumeObservedLiters: 33445,
      temperatureObservedC: 21.0,
      densityObservedKgPerM3: 837.0,
    ),
    expectedDensity15KgPerM3: 840.1,
    expectedVcf: 0.9949,
    expectedVolume15Liters: 33274,
  ),
];
