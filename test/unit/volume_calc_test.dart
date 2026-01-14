/* ===========================================================
   Tests unitaires — volume_calc
   =========================================================== */
import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';

void main() {
  test('computeVolumeAmbiant', () {
    expect(computeVolumeAmbiant(1000, 1060), closeTo(60, 0.001));
    expect(computeVolumeAmbiant(500, 500), closeTo(0, 0.001));
    expect(computeVolumeAmbiant(null, 123), closeTo(0, 0.001));
  });

  test('computeV15 ESS', () {
    final v = computeV15(
      volumeAmbiant: 1000,
      temperatureC: 25,
      densiteA15: null,
      produitCode: 'ESS',
    );
    expect(v, closeTo(990, 0.6));
  });

  test('computeV15 AGO', () {
    final v = computeV15(
      volumeAmbiant: 1000,
      temperatureC: 25,
      densiteA15: null,
      produitCode: 'AGO',
    );
    expect(v, closeTo(991.5, 0.6));
  });
}
