// test/core/volumetrics/astm53b_engine_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/core/volumetrics/astm53b_engine.dart';

@Tags(['astm53b'])
void main() {
  group('DefaultAstm53bCalculator', () {
    test(
      'throw UnimplementedError tant que le moteur ASTM 53B n\'est pas implémenté',
      () {
        const calculator = DefaultAstm53bCalculator();
        const input = Astm53bInput(
          densityObservedKgPerM3: 0.843 * 1000, // exemple GASOIL
          temperatureObservedC: 22.4,
          volumeObservedLiters: 39291,
        );

        expect(
          () => calculator.compute(input),
          throwsA(isA<UnimplementedError>()),
        );
      },
      skip:
          'ASTM 53B engine not implemented yet. This test acts as a reminder / guardrail.',
    );
  });

  group('Astm53bInput', () {
    test('copyWith retourne une nouvelle instance avec les champs modifiés', () {
      const input = Astm53bInput(
        densityObservedKgPerM3: 840,
        temperatureObservedC: 20,
        volumeObservedLiters: 1000,
      );

      final updated = input.copyWith(
        temperatureObservedC: 25,
      );

      expect(updated.temperatureObservedC, 25);
      expect(updated.densityObservedKgPerM3, input.densityObservedKgPerM3);
      expect(updated.volumeObservedLiters, input.volumeObservedLiters);
    });
  });
}
