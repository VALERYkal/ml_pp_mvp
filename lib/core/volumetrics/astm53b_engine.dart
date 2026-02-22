// lib/core/volumetrics/astm53b_engine.dart

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
/// Cette première version ne contient PAS encore la formule ASTM 53B.
/// On pose uniquement :
/// - les types d'entrée/sortie
/// - le contrat métier
/// - les invariants
/// L'implémentation réelle sera ajoutée dans une étape ultérieure.
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
  /// Pour l'instant, cette méthode n'est PAS implémentée et lèvera une erreur.
  Astm53bResult compute(Astm53bInput input);
}

/// Implémentation par défaut (placeholder) du calculateur ASTM 53B.
///
/// ATTENTION : cette implémentation ne fait encore aucun calcul.
/// Elle existe uniquement pour brancher le code applicatif et les tests.
/// L'implémentation réelle sera ajoutée dans un commit ultérieur, une fois
/// les cas "golden" et les tolérances définis.
class DefaultAstm53bCalculator implements Astm53bCalculator {
  const DefaultAstm53bCalculator();

  @override
  Astm53bResult compute(Astm53bInput input) {
    // TODO(astm53b): implémenter la formule ASTM 53B / API MPMS 11.1.
    // Pour le moment, on bloque explicitement pour éviter tout usage
    // "approximatif" en PROD.
    throw UnimplementedError(
      'ASTM 53B engine not implemented yet. See BLOC 2 roadmap.',
    );
  }
}
