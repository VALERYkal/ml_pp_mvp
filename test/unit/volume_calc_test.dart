/* ===========================================================
   Tests unitaires â volume_calc
   =========================================================== */
import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/shared/utils/volume_calc.dart';

void main() {
  test('computeVolumeAmbiant', () {
    expect(computeVolumeAmbiant(1000, 1060), 60);
    expect(computeVolumeAmbiant(500, 500), 0);
    expect(computeVolumeAmbiant(null, 123), 0);
  });

  test('computeV15 ESS', () {
    final v = computeV15(
      volumeAmbiant: 1000,
      temperatureC: 25,
      densiteA15: null,
      produitCode: 'ESS',
    );
    expect((v - 990).abs() < 0.6, true);
  });

  test('computeV15 AGO', () {
    final v = computeV15(
      volumeAmbiant: 1000,
      temperatureC: 25,
      densiteA15: null,
      produitCode: 'AGO',
    );
    expect((v - 991.5).abs() < 0.6, true);
  });
}

