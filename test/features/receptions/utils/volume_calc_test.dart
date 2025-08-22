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
}


