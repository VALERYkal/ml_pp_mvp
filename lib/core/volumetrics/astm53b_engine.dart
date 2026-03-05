// lib/core/volumetrics/astm53b_engine.dart

import 'dart:math' as math;

import 'package:meta/meta.dart';

/// Moteur de calcul volumétrique selon ASTM 53B / API MPMS 11.1.
///
/// Ce module est conçu pour :
/// - rester indépendant de Flutter, Supabase, Riverpod, etc. (Dart pur)
/// - être entièrement testable par des tests unitaires / golden tests
/// - servir de référence unique pour tous les calculs de volume à 15 °C
///
/// Contexte métier ML_PP :
/// - On reçoit du GASOIL avec une densité observée (à température ambiante)
/// - Le terrain utilise ASTM 53B pour convertir en densité 15 °C et VCF
/// - ML_PP doit produire les mêmes résultats (densité@15, VCF, volume@15)
///
/// Implémentation Table 54B (produits raffinés, base 15°C).
class Astm53bInput {
  /// Densité observée (à la température observée), en kg/m³.
  ///
  /// Exemple typique GASOIL : ~830–860 kg/m³.
  final double densityObservedKgPerM3;

  /// Température observée du produit, en °C (ambiante).
  ///
  /// Exemple typique : 15–35 °C.
  final double temperatureObservedC;

  /// Volume observé à la température ambiante, en litres.
  ///
  /// C'est le volume tel que lu sur les index (citerne / compteur).
  final double volumeObservedLiters;

  const Astm53bInput({
    required this.densityObservedKgPerM3,
    required this.temperatureObservedC,
    required this.volumeObservedLiters,
  });

  Astm53bInput copyWith({
    double? densityObservedKgPerM3,
    double? temperatureObservedC,
    double? volumeObservedLiters,
  }) {
    return Astm53bInput(
      densityObservedKgPerM3:
          densityObservedKgPerM3 ?? this.densityObservedKgPerM3,
      temperatureObservedC:
          temperatureObservedC ?? this.temperatureObservedC,
      volumeObservedLiters:
          volumeObservedLiters ?? this.volumeObservedLiters,
    );
  }
}

/// Résultat du calcul ASTM 53B.
///
/// Toutes les valeurs sont exprimées en unités physiques "classiques" :
/// - densité à 15 °C en kg/m³
/// - VCF (Volume Correction Factor) en facteur multiplicatif sans unité
/// - volume corrigé à 15 °C en litres
class Astm53bResult {
  /// Densité à 15 °C, en kg/m³.
  final double density15KgPerM3;

  /// Volume Correction Factor (VCF = V15 / Vobservé).
  final double vcf;

  /// Volume corrigé à 15 °C, en litres.
  final double volume15Liters;

  const Astm53bResult({
    required this.density15KgPerM3,
    required this.vcf,
    required this.volume15Liters,
  });
}

/// Interface du calculateur ASTM 53B.
///
/// L'objectif est de pouvoir :
/// - mocker / stubber le moteur dans les tests applicatifs
/// - éventuellement introduire plusieurs stratégies (table, approximation contrôlée, etc.)
abstract class Astm53bCalculator {
  /// Calcule la densité à 15 °C, le VCF et le volume corrigé à 15 °C.
  ///
  /// Contrat métier (invariants à respecter dans l'implémentation réelle) :
  /// - densityObservedKgPerM3 > 0
  /// - volumeObservedLiters >= 0
  /// - température observée dans un domaine raisonnable (ex: -20 °C à +60 °C)
  /// - vcf > 0
  /// - volume15Liters = volumeObservedLiters * vcf (à un epsilon numérique près)
  ///
  Astm53bResult compute(Astm53bInput input);
}

/// Implémentation ASTM 53B / API MPMS 11.1 pour produits raffinés (GASOIL).
///
/// Formules Table 54B : VCF = exp(-α × dT × (1 + 0.8 × α × dT))
/// avec α = (K0 + K1 × ρ15) / ρ15²
/// Densité à 15°C : ρ15 = ρ_obs / VCF (itératif car α dépend de ρ15)
class DefaultAstm53bCalculator implements Astm53bCalculator {
  const DefaultAstm53bCalculator();

  /// Constantes Table 54B pour produits raffinés, densité ≥ 839 kg/m³ @ 15°C.
  /// Source: ASTM D1250 / API MPMS 11.1 (1980).
  static const double _k0 = 186.9696;
  static const double _k1 = 0.48618;

  @override
  Astm53bResult compute(Astm53bInput input) {
    if (input.volumeObservedLiters < 0) {
      throw ArgumentError('volumeObservedLiters must be >= 0');
    }
    if (input.densityObservedKgPerM3 <= 0) {
      throw ArgumentError('densityObservedKgPerM3 must be > 0');
    }
    if (input.temperatureObservedC < -50 || input.temperatureObservedC > 100) {
      throw ArgumentError('temperatureObservedC out of supported range');
    }
    final density15 = _densityAt15FromObservedB(
      input.densityObservedKgPerM3,
      input.temperatureObservedC,
    );
    final vcf = _vcfTo15B(density15, input.temperatureObservedC);
    final volume15 = input.volumeObservedLiters * vcf;
    return Astm53bResult(
      density15KgPerM3: density15,
      vcf: vcf,
      volume15Liters: volume15,
    );
  }

  @visibleForTesting
  double vcfFromDensity15(double density15KgPerM3, double temperatureObservedC) {
    return _vcfTo15B(density15KgPerM3, temperatureObservedC);
  }

  /// Densité à 15°C à partir de la densité observée (Table 53B/54B).
  /// Itération : ρ15 = ρ_obs / VCF, avec VCF dépendant de ρ15.
  double _densityAt15FromObservedB(double densityObs, double tempC) {
    double density15 = densityObs;
    for (var i = 0; i < 10; i++) {
      final vcf = _vcfTo15B(density15, tempC);
      final density15New = densityObs / vcf;
      if ((density15New - density15).abs() < 0.0001) {
        return density15New;
      }
      density15 = density15New;
    }
    return density15;
  }

  double _alpha54B(double den15) {
    if (den15 >= 839.0) {
      // Zone 1
      return (_k0 + _k1 * den15) / (den15 * den15);
    }
    if (den15 >= 778.0) {
      // Zone 2
      const k0 = 594.5418;
      return k0 / (den15 * den15);
    }
    if (den15 >= 770.0) {
      // Transition zone
      const A = -0.0033612;
      const B = 2680.32;
      return A + (B / (den15 * den15));
    }
    throw ArgumentError('Density@15 out of Table 54B domain: $den15');
  }

  /// VCF vers 15°C (Table 54B) : VCF = exp(-α × dT × (1 + 0.8 × α × dT)).
  double _vcfTo15B(double densityAt15KgM3, double tempC) {
    final dT = tempC - 15.0;
    final alpha = _alpha54B(densityAt15KgM3);
    return _exp(-alpha * dT * (1 + 0.8 * alpha * dT));
  }

  /// Arrondi à [decimals] décimales.
  double _round(double value, int decimals) {
    if (decimals == 0) {
      return value.roundToDouble();
    }
    final factor = _pow(10.0, decimals);
    return (value * factor).round() / factor;
  }

  double _exp(double x) => math.exp(x);
  double _pow(double x, int n) => math.pow(x, n).toDouble();
}
