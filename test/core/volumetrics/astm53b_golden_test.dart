// test/core/volumetrics/astm53b_golden_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/core/volumetrics/astm53b_engine.dart';
import 'package:ml_pp_mvp/core/volumetrics/astm53b_golden_cases.dart';

@Tags(['astm53b', 'golden'])
void main() {
  group('Astm53bGoldenCases', () {
    test('la liste des cas golden est définie (peut être vide au début)', () {
      // On ne force pas à avoir déjà des cas, mais on vérifie au moins
      // que la constante est bien accessible.
      expect(kAstm53bGoldenCases, isNotNull);
    });
  });

  group('DefaultAstm53bCalculator golden cases', () {
    test(
      'ne s\'exécute pas tant que le moteur ASTM 53B n\'est pas implémenté',
      () {
        const calculator = DefaultAstm53bCalculator();

        for (final goldenCase in kAstm53bGoldenCases) {
          expect(
            () => calculator.compute(goldenCase.input),
            throwsA(isA<UnimplementedError>()),
          );
        }
      },
      skip: kAstm53bGoldenCases.isEmpty
          ? 'Pas encore de cas golden renseignés et moteur non implémenté.'
          : 'Moteur ASTM 53B non implémenté : ces tests seront activés une fois la formule en place.',
    );
  });
}
