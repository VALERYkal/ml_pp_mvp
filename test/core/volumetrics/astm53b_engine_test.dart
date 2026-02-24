// test/core/volumetrics/astm53b_engine_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/core/volumetrics/astm53b_engine.dart';

@Tags(['astm53b'])
void main() {
  group('DefaultAstm53bCalculator', () {
    test('compute retourne density@15, VCF et volume@15 cohérents', () {
      const calculator = DefaultAstm53bCalculator();
      const input = Astm53bInput(
        densityObservedKgPerM3: 843, // exemple GASOIL
        temperatureObservedC: 22.4,
        volumeObservedLiters: 39291,
      );

      final result = calculator.compute(input);

      expect(result.density15KgPerM3, greaterThan(0));
      expect(result.vcf, greaterThan(0));
      expect(result.vcf, lessThanOrEqualTo(1.1));
      expect(result.volume15Liters, greaterThanOrEqualTo(0));
      expect(
        result.volume15Liters,
        closeTo(input.volumeObservedLiters * result.vcf, 1),
      );
    });
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
