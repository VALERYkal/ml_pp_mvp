import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/stocks_adjustments/domain/adjustment_compute.dart';

void main() {
  group('AdjustmentTypeX', () {
    test('label returns correct labels', () {
      expect(AdjustmentType.volume.label, 'Volume');
      expect(AdjustmentType.temperature.label, 'Température');
      expect(AdjustmentType.densite.label, 'Densité');
      expect(AdjustmentType.mixte.label, 'Mixte');
    });

    test('prefix returns correct prefixes', () {
      expect(AdjustmentType.volume.prefix, '[VOLUME]');
      expect(AdjustmentType.temperature.prefix, '[TEMP]');
      expect(AdjustmentType.densite.prefix, '[DENSITE]');
      expect(AdjustmentType.mixte.prefix, '[MIXTE]');
    });
  });

  group('buildPrefixedReason', () {
    test('prefixes reason correctly for each type', () {
      expect(
        buildPrefixedReason(AdjustmentType.volume, 'Correction manuelle'),
        '[VOLUME] Correction manuelle',
      );
      expect(
        buildPrefixedReason(AdjustmentType.temperature, 'Température incorrecte'),
        '[TEMP] Température incorrecte',
      );
      expect(
        buildPrefixedReason(AdjustmentType.densite, 'Densité mesurée'),
        '[DENSITE] Densité mesurée',
      );
      expect(
        buildPrefixedReason(AdjustmentType.mixte, 'Correction multiple'),
        '[MIXTE] Correction multiple',
      );
    });

    test('trims reason before prefixing', () {
      expect(
        buildPrefixedReason(AdjustmentType.volume, '  Espaces  '),
        '[VOLUME] Espaces',
      );
    });
  });

  group('hasNonZeroImpact', () {
    test('returns true when deltaAmbiant is non-zero', () {
      expect(
        hasNonZeroImpact(
          const AdjustmentDeltas(deltaAmbiant: 10.0, delta15c: 0.0),
        ),
        isTrue,
      );
    });

    test('returns true when delta15c is non-zero', () {
      expect(
        hasNonZeroImpact(
          const AdjustmentDeltas(deltaAmbiant: 0.0, delta15c: 5.0),
        ),
        isTrue,
      );
    });

    test('returns true when both deltas are non-zero', () {
      expect(
        hasNonZeroImpact(
          const AdjustmentDeltas(deltaAmbiant: 10.0, delta15c: 5.0),
        ),
        isTrue,
      );
    });

    test('returns false when both deltas are zero', () {
      expect(
        hasNonZeroImpact(
          const AdjustmentDeltas(deltaAmbiant: 0.0, delta15c: 0.0),
        ),
        isFalse,
      );
    });
  });

  group('computeAdjustmentDeltas - VOLUME', () {
    test('calculates deltas correctly for volume adjustment', () {
      final movement = MovementData(
        volumeAmbiant: 1000.0,
        temperatureC: 20.0,
        densiteA15: 0.8,
        volumeCorrige15c: 980.0,
      );

      final params = AdjustmentDeltasParams(
        type: AdjustmentType.volume,
        movement: movement,
        correctionAmbiante: 50.0,
      );

      final result = computeAdjustmentDeltas(params);

      // deltaAmbiant = correction
      expect(result.deltaAmbiant, 50.0);
      // delta15c should be recalculated via calcV15
      expect(result.delta15c, isNot(0.0));
    });

    test('handles zero correction for volume', () {
      final movement = MovementData(
        volumeAmbiant: 1000.0,
        temperatureC: 20.0,
        densiteA15: 0.8,
      );

      final params = AdjustmentDeltasParams(
        type: AdjustmentType.volume,
        movement: movement,
        correctionAmbiante: 0.0,
      );

      final result = computeAdjustmentDeltas(params);

      expect(result.deltaAmbiant, 0.0);
      // delta15c should still be calculated (may be 0 if no change)
      expect(result.delta15c, isA<double>());
    });
  });

  group('computeAdjustmentDeltas - TEMPERATURE', () {
    test('calculates deltas correctly for temperature adjustment', () {
      final movement = MovementData(
        volumeAmbiant: 1000.0,
        temperatureC: 20.0,
        densiteA15: 0.8,
        volumeCorrige15c: 980.0,
      );

      final params = AdjustmentDeltasParams(
        type: AdjustmentType.temperature,
        movement: movement,
        nouvelleTemperature: 25.0,
      );

      final result = computeAdjustmentDeltas(params);

      // deltaAmbiant should be 0 for temperature-only adjustment
      expect(result.deltaAmbiant, 0.0);
      // delta15c should be non-zero (recalculated)
      expect(result.delta15c, isNot(0.0));
    });

    test('returns zero deltas when temperature is null', () {
      final movement = MovementData(
        volumeAmbiant: 1000.0,
        temperatureC: 20.0,
        densiteA15: 0.8,
      );

      final params = AdjustmentDeltasParams(
        type: AdjustmentType.temperature,
        movement: movement,
        nouvelleTemperature: null,
      );

      final result = computeAdjustmentDeltas(params);

      expect(result.deltaAmbiant, 0.0);
      expect(result.delta15c, 0.0);
    });

    test('returns zero deltas when temperature is <= 0', () {
      final movement = MovementData(
        volumeAmbiant: 1000.0,
        temperatureC: 20.0,
        densiteA15: 0.8,
      );

      final params = AdjustmentDeltasParams(
        type: AdjustmentType.temperature,
        movement: movement,
        nouvelleTemperature: -5.0,
      );

      final result = computeAdjustmentDeltas(params);

      expect(result.deltaAmbiant, 0.0);
      expect(result.delta15c, 0.0);
    });
  });

  group('computeAdjustmentDeltas - DENSITE', () {
    test('calculates deltas correctly for density adjustment', () {
      final movement = MovementData(
        volumeAmbiant: 1000.0,
        temperatureC: 20.0,
        densiteA15: 0.8,
        volumeCorrige15c: 980.0,
      );

      final params = AdjustmentDeltasParams(
        type: AdjustmentType.densite,
        movement: movement,
        nouvelleDensite: 0.85,
      );

      final result = computeAdjustmentDeltas(params);

      // deltaAmbiant should be 0 for density-only adjustment
      expect(result.deltaAmbiant, 0.0);
      // delta15c should be non-zero (recalculated)
      expect(result.delta15c, isNot(0.0));
    });

    test('returns zero deltas when density is null', () {
      final movement = MovementData(
        volumeAmbiant: 1000.0,
        temperatureC: 20.0,
        densiteA15: 0.8,
      );

      final params = AdjustmentDeltasParams(
        type: AdjustmentType.densite,
        movement: movement,
        nouvelleDensite: null,
      );

      final result = computeAdjustmentDeltas(params);

      expect(result.deltaAmbiant, 0.0);
      expect(result.delta15c, 0.0);
    });

    test('returns zero deltas when density is <= 0', () {
      final movement = MovementData(
        volumeAmbiant: 1000.0,
        temperatureC: 20.0,
        densiteA15: 0.8,
      );

      final params = AdjustmentDeltasParams(
        type: AdjustmentType.densite,
        movement: movement,
        nouvelleDensite: -0.1,
      );

      final result = computeAdjustmentDeltas(params);

      expect(result.deltaAmbiant, 0.0);
      expect(result.delta15c, 0.0);
    });
  });

  group('computeAdjustmentDeltas - MIXTE', () {
    test('calculates deltas correctly for mixed adjustment', () {
      final movement = MovementData(
        volumeAmbiant: 1000.0,
        temperatureC: 20.0,
        densiteA15: 0.8,
        volumeCorrige15c: 980.0,
      );

      final params = AdjustmentDeltasParams(
        type: AdjustmentType.mixte,
        movement: movement,
        correctionAmbiante: 50.0,
        nouvelleTemperature: 25.0,
        nouvelleDensite: 0.85,
      );

      final result = computeAdjustmentDeltas(params);

      // Both deltas should be non-zero
      expect(result.deltaAmbiant, 50.0);
      expect(result.delta15c, isNot(0.0));
    });

    test('returns zero deltas when temperature is invalid', () {
      final movement = MovementData(
        volumeAmbiant: 1000.0,
        temperatureC: 20.0,
        densiteA15: 0.8,
      );

      final params = AdjustmentDeltasParams(
        type: AdjustmentType.mixte,
        movement: movement,
        correctionAmbiante: 50.0,
        nouvelleTemperature: -5.0, // Invalid
        nouvelleDensite: 0.85,
      );

      final result = computeAdjustmentDeltas(params);

      expect(result.deltaAmbiant, 0.0);
      expect(result.delta15c, 0.0);
    });

    test('returns zero deltas when density is invalid', () {
      final movement = MovementData(
        volumeAmbiant: 1000.0,
        temperatureC: 20.0,
        densiteA15: 0.8,
      );

      final params = AdjustmentDeltasParams(
        type: AdjustmentType.mixte,
        movement: movement,
        correctionAmbiante: 50.0,
        nouvelleTemperature: 25.0,
        nouvelleDensite: -0.1, // Invalid
      );

      final result = computeAdjustmentDeltas(params);

      expect(result.deltaAmbiant, 0.0);
      expect(result.delta15c, 0.0);
    });
  });
}

