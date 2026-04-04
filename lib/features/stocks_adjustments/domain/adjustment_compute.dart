// 📌 Module : Stocks Adjustments - Domain Logic (Pure Functions)
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2026-01-01
// 🧭 Description : Fonctions pures pour calculer les deltas d'ajustement et valider les impacts
//
// DB-first : le scalaire @15 °C lu depuis une ligne = `volume_15c ?? volume_corrige_15c`
// ([MovementData.effectiveVolume15c]). Les appels à [calcV15] ci-dessous ne font qu’approximer
// un état « nouveau » ou combler l’absence de scalaire DB — prévisualisation / module ajustements,
// pas la vérité métier persistée.

import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';

/// Type de correction d'ajustement
enum AdjustmentType {
  volume,
  temperature,
  densite,
  mixte,
}

extension AdjustmentTypeX on AdjustmentType {
  String get label {
    switch (this) {
      case AdjustmentType.volume:
        return 'Volume';
      case AdjustmentType.temperature:
        return 'Température';
      case AdjustmentType.densite:
        return 'Densité';
      case AdjustmentType.mixte:
        return 'Mixte';
    }
  }

  String get prefix {
    switch (this) {
      case AdjustmentType.volume:
        return '[VOLUME]';
      case AdjustmentType.temperature:
        return '[TEMP]';
      case AdjustmentType.densite:
        return '[DENSITE]';
      case AdjustmentType.mixte:
        return '[MIXTE]';
    }
  }
}

/// Données du mouvement (réception ou sortie)
class MovementData {
  final double volumeAmbiant;
  final double? temperatureC;
  final double? densiteA15;
  /// Canonique DB (`volume_15c`), si présent sur la ligne.
  final double? volume15c;
  /// Fallback legacy (`volume_corrige_15c`).
  final double? volumeCorrige15c;

  MovementData({
    required this.volumeAmbiant,
    this.temperatureC,
    this.densiteA15,
    this.volume15c,
    this.volumeCorrige15c,
  });

  /// Lecture unique scalaire @15 °C : aligné contrat app / DB.
  double? get effectiveVolume15c => volume15c ?? volumeCorrige15c;
}

/// Paramètres pour le calcul des deltas
class AdjustmentDeltasParams {
  final AdjustmentType type;
  final MovementData movement;
  final double? correctionAmbiante;
  final double? nouvelleTemperature;
  final double? nouvelleDensite;

  AdjustmentDeltasParams({
    required this.type,
    required this.movement,
    this.correctionAmbiante,
    this.nouvelleTemperature,
    this.nouvelleDensite,
  });
}

/// Résultat du calcul des deltas
class AdjustmentDeltas {
  final double deltaAmbiant;
  final double delta15c;

  const AdjustmentDeltas({
    required this.deltaAmbiant,
    required this.delta15c,
  });
}

/// Calcule les deltas selon le type de correction
///
/// Cette fonction est pure et peut être testée sans dépendance à l'UI.
/// [delta15c] s’appuie sur [calcV15] pour les états recalculés : **approximation non canonique**.
AdjustmentDeltas computeAdjustmentDeltas(AdjustmentDeltasParams params) {
  final movement = params.movement;

  switch (params.type) {
    case AdjustmentType.volume:
      // Volume : correction ambiante obligatoire ; @15 °C « après » = approx UX (calcV15).
      final correctionAmbiante = params.correctionAmbiante ?? 0.0;
      final nouvelleTemp = movement.temperatureC ?? 15.0;
      final nouvelleDens = movement.densiteA15 ?? 0.8;
      final nouveauVolumeAmbiant = movement.volumeAmbiant + correctionAmbiante;
      final nouveauVolume15cApprox = calcV15(
        volumeObserveL: nouveauVolumeAmbiant,
        temperatureC: nouvelleTemp,
        densiteA15: nouvelleDens,
      );
      final ancienVolume15c = movement.effectiveVolume15c ??
          calcV15(
            volumeObserveL: movement.volumeAmbiant,
            temperatureC: nouvelleTemp,
            densiteA15: nouvelleDens,
          );
      return AdjustmentDeltas(
        deltaAmbiant: correctionAmbiante,
        delta15c: nouveauVolume15cApprox - ancienVolume15c,
      );

    case AdjustmentType.temperature:
      // Température : nouvelle température obligatoire ; effet @15 °C = approx UX (calcV15).
      final nouvelleTemp = params.nouvelleTemperature;
      if (nouvelleTemp == null || nouvelleTemp <= 0) {
        return const AdjustmentDeltas(deltaAmbiant: 0.0, delta15c: 0.0);
      }
      final nouvelleDens = movement.densiteA15 ?? 0.8;
      final nouveauVolume15cApprox = calcV15(
        volumeObserveL: movement.volumeAmbiant,
        temperatureC: nouvelleTemp,
        densiteA15: nouvelleDens,
      );
      final ancienVolume15c = movement.effectiveVolume15c ??
          calcV15(
            volumeObserveL: movement.volumeAmbiant,
            temperatureC: movement.temperatureC ?? 15.0,
            densiteA15: nouvelleDens,
          );
      return AdjustmentDeltas(
        deltaAmbiant: 0.0,
        delta15c: nouveauVolume15cApprox - ancienVolume15c,
      );

    case AdjustmentType.densite:
      // Densité : nouvelle densité obligatoire ; effet @15 °C = approx UX (calcV15).
      final nouvelleDens = params.nouvelleDensite;
      if (nouvelleDens == null || nouvelleDens <= 0) {
        return const AdjustmentDeltas(deltaAmbiant: 0.0, delta15c: 0.0);
      }
      final nouvelleTemp = movement.temperatureC ?? 15.0;
      final nouveauVolume15cApprox = calcV15(
        volumeObserveL: movement.volumeAmbiant,
        temperatureC: nouvelleTemp,
        densiteA15: nouvelleDens,
      );
      final ancienVolume15c = movement.effectiveVolume15c ??
          calcV15(
            volumeObserveL: movement.volumeAmbiant,
            temperatureC: nouvelleTemp,
            densiteA15: movement.densiteA15 ?? 0.8,
          );
      return AdjustmentDeltas(
        deltaAmbiant: 0.0,
        delta15c: nouveauVolume15cApprox - ancienVolume15c,
      );

    case AdjustmentType.mixte:
      // Mixte : correction ambiante + nouvelle température + nouvelle densité ; @15 °C = approx UX.
      final correctionAmbiante = params.correctionAmbiante ?? 0.0;
      final nouvelleTemp = params.nouvelleTemperature;
      final nouvelleDens = params.nouvelleDensite;
      if (nouvelleTemp == null ||
          nouvelleTemp <= 0 ||
          nouvelleDens == null ||
          nouvelleDens <= 0) {
        return const AdjustmentDeltas(deltaAmbiant: 0.0, delta15c: 0.0);
      }
      final nouveauVolumeAmbiant = movement.volumeAmbiant + correctionAmbiante;
      final nouveauVolume15cApprox = calcV15(
        volumeObserveL: nouveauVolumeAmbiant,
        temperatureC: nouvelleTemp,
        densiteA15: nouvelleDens,
      );
      final ancienVolume15c = movement.effectiveVolume15c ??
          calcV15(
            volumeObserveL: movement.volumeAmbiant,
            temperatureC: movement.temperatureC ?? 15.0,
            densiteA15: movement.densiteA15 ?? 0.8,
          );
      return AdjustmentDeltas(
        deltaAmbiant: correctionAmbiante,
        delta15c: nouveauVolume15cApprox - ancienVolume15c,
      );
  }
}

/// Construit la raison préfixée selon le type
String buildPrefixedReason(AdjustmentType type, String reason) {
  final trimmed = reason.trim();
  return '${type.prefix} $trimmed';
}

/// Vérifie si l'impact est non nul
bool hasNonZeroImpact(AdjustmentDeltas deltas) {
  return deltas.deltaAmbiant != 0.0 || deltas.delta15c != 0.0;
}
