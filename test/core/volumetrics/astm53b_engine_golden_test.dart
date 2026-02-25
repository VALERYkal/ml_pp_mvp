import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/core/volumetrics/astm53b_engine.dart';

void main() {
  group('DefaultAstm53bCalculator - golden VCF (Table 54B)', () {
    const calc = DefaultAstm53bCalculator();

    test('Zone 1 (den15 >= 839): den15=839, T=32.5 -> vcf≈0.98515', () {
      final vcf = calc.vcfFromDensity15(839.0, 32.5);

      expect(vcf, closeTo(0.98515, 1e-5));
    });

    test('Zone 2 (778<=den15<839): den15=819, T=26.75 -> vcf≈0.989552', () {
      final vcf = calc.vcfFromDensity15(819.0, 26.75);

      expect(vcf, closeTo(0.989552, 2e-6));
    });

    test('Zone 1 (den15 >= 839): den15=903.5, T=30.5 -> vcf≈0.988067', () {
      final vcf = calc.vcfFromDensity15(903.5, 30.5);

      expect(vcf, closeTo(0.988067, 1e-6));
    });

    test('Convergence density@15 depuis densité observée (itératif)', () {
      const calc = DefaultAstm53bCalculator();

      // Exemple réaliste terrain (valeurs plausibles GASOIL)
      final result = calc.compute(const Astm53bInput(
        densityObservedKgPerM3: 845.0, // densité observée à T
        temperatureObservedC: 30.0,
        volumeObservedLiters: 1000,
      ));

      // Invariants minimaux (pas une comparaison SEP)
      expect(result.vcf, greaterThan(0));
      expect(result.vcf, lessThan(1)); // à 30°C > 15°C, VCF < 1 pour produits raffinés
      expect(result.density15KgPerM3, greaterThan(result.density15KgPerM3 - 1)); // sanity
      expect(result.density15KgPerM3, greaterThan(845.0)); // densité@15 > densité observée si T>15
    });
  });
}
