// test/core/volumetrics/astm53b_golden_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/core/volumetrics/astm53b_engine.dart';
import 'package:ml_pp_mvp/core/volumetrics/astm53b_golden_cases.dart';

@Tags(['astm53b', 'golden'])
void main() {
  group('Astm53bGoldenCases', () {
    test('la liste des cas golden est définie et non vide', () {
      expect(kAstm53bGoldenCases, isNotNull);
      expect(kAstm53bGoldenCases.length, 8);
    });

    test('chaque cas golden a des valeurs expected cohérentes (volume ≈ round(volObs × vcf))',
        () {
      for (final goldenCase in kAstm53bGoldenCases) {
        final computedVolume =
            (goldenCase.input.volumeObservedLiters * goldenCase.expectedVcf)
                .round();
        expect(
          goldenCase.expectedVolume15Liters,
          closeTo(computedVolume.toDouble(), 1),
          reason: '${goldenCase.id}: expectedVolume15Liters should match '
              'round(volumeObserved × vcf) within ±1 L',
        );
      }
    });
  });

  group('DefaultAstm53bCalculator golden cases', () {
    test(
      'calcule density@15, VCF et volume@15 dans les tolérances pour chaque cas golden',
      () {
        const calculator = DefaultAstm53bCalculator();

        for (final goldenCase in kAstm53bGoldenCases) {
          final result = calculator.compute(goldenCase.input);

          // Tolérances : formule standard ASTM 53B (1980) vs app terrain SEP.
          // Si besoin de matcher strictement l'app : calibration Étape C.
          expect(
            result.density15KgPerM3,
            closeTo(goldenCase.expectedDensity15KgPerM3, 1.2),
            reason: '${goldenCase.id}: densityAt15KgM3',
          );
          expect(
            result.vcf,
            closeTo(goldenCase.expectedVcf, 0.01),
            reason: '${goldenCase.id}: vcfTo15',
          );
          expect(
            result.volume15Liters,
            closeTo(goldenCase.expectedVolume15Liters, 250),
            reason: '${goldenCase.id}: volumeAt15L (après arrondi au litre)',
          );
        }
      },
    );
  });
}
