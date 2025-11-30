import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';

void main() {
  group('calcV15', () {
    test('T=15 => v15==vObs', () {
      expect(calcV15(volumeObserveL: 1000, temperatureC: 15, densiteA15: 0.83), closeTo(1000, 0.0001));
    });
    test('T>15 => v15 < vObs', () {
      final v15 = calcV15(volumeObserveL: 1000, temperatureC: 30, densiteA15: 0.83);
      expect(v15, lessThan(1000));
    });
    test('T<15 => v15 > vObs', () {
      final v15 = calcV15(volumeObserveL: 1000, temperatureC: 5, densiteA15: 0.83);
      expect(v15, greaterThan(1000));
    });
  });
  
  group('computeV15 - Gestion null', () {
    test('calcule volume_15c si température et densité présents', () {
      final v15 = computeV15(
        volumeAmbiant: 1000,
        temperatureC: 25.0,
        densiteA15: 0.83,
        produitCode: 'ESS',
      );
      expect(v15, isA<double>());
      expect(v15, isNot(equals(1000.0))); // Différent de volume_ambiant
    });
    
    test('retourne volume_ambiant si température null (convention)', () {
      final v15 = computeV15(
        volumeAmbiant: 1000,
        temperatureC: null, // null
        densiteA15: 0.83,
        produitCode: 'ESS',
      );
      // Convention : si température null, retourne volume_ambiant
      expect(v15, equals(1000.0));
    });
    
    test('calcule même si densité null (seule température compte)', () {
      final v15 = computeV15(
        volumeAmbiant: 1000,
        temperatureC: 25.0,
        densiteA15: null, // null - mais la fonction calcule quand même
        produitCode: 'ESS',
      );
      // La fonction calcule avec la température même si densité est null
      // Résultat différent de volume_ambiant car T != 15
      expect(v15, isNot(equals(1000.0)));
      expect(v15, lessThan(1000.0)); // T > 15, donc v15 < vAmb
    });
    
    test('retourne volume_ambiant si température et densité null (convention)', () {
      final v15 = computeV15(
        volumeAmbiant: 1000,
        temperatureC: null,
        densiteA15: null,
        produitCode: 'ESS',
      );
      // Convention : si les deux null, retourne volume_ambiant
      expect(v15, equals(1000.0));
    });
    
    test('ne lance pas d\'exception si température null', () {
      expect(
        () => computeV15(
          volumeAmbiant: 1000,
          temperatureC: null,
          densiteA15: 0.83,
          produitCode: 'ESS',
        ),
        returnsNormally,
      );
    });
    
    test('ne lance pas d\'exception si densité null', () {
      expect(
        () => computeV15(
          volumeAmbiant: 1000,
          temperatureC: 25.0,
          densiteA15: null,
          produitCode: 'ESS',
        ),
        returnsNormally,
      );
    });
  });
}


