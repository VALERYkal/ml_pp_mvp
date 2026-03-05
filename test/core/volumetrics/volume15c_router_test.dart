import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/core/feature_flags/feature_flags.dart';
import 'package:ml_pp_mvp/core/volumetrics/volume15c_router.dart';

void main() {
  test('OFF -> retourne volumeAmbient (legacy)', () {
    final result = computeVolume15c(
      flags: const FeatureFlags(useAstm53b15c: false),
      volumeAmbient: 1000.0,
      temperatureC: 30.0,
      densityObservedKgPerM3: 850.0,
    );

    expect(result, 1000.0);
  });

  test('ON -> utilise ASTM 53B (volume corrigé < volume ambiant à 30°C)', () {
    final result = computeVolume15c(
      flags: const FeatureFlags(useAstm53b15c: true),
      volumeAmbient: 1000.0,
      temperatureC: 30.0,
      densityObservedKgPerM3: 850.0,
    );

    expect(result, lessThan(1000.0));
  });
}
