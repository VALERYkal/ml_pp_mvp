import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';

void main() {
  group('KPI Provider - Volume Mapping Tests', () {
    test('should map volume_corrige_15c correctly when null', () {
      // Test avec volume_corrige_15c = null
      final row = {'volume_corrige_15c': null, 'volume_ambiant': 10000.0};

      final v15Raw = row['volume_corrige_15c'];
      final vaRaw = row['volume_ambiant'];

      final v15 = (v15Raw is num) ? (v15Raw as num).toDouble() : 0.0;
      final va = (vaRaw is num) ? (vaRaw as num).toDouble() : 0.0;

      // VÃ©rifier que volume_corrige_15c = 0.0 et non 10000.0
      expect(v15, equals(0.0));
      expect(va, equals(10000.0));
      expect(v15, isNot(equals(va))); // Ne doit pas Ãªtre Ã©gal Ã  l'ambiant
    });

    test('should map volume_corrige_15c correctly when valid', () {
      // Test avec volume_corrige_15c = 9954.5
      final row = {'volume_corrige_15c': 9954.5, 'volume_ambiant': 10000.0};

      final v15Raw = row['volume_corrige_15c'];
      final vaRaw = row['volume_ambiant'];

      final v15 = (v15Raw is num) ? (v15Raw as num).toDouble() : 0.0;
      final va = (vaRaw is num) ? (vaRaw as num).toDouble() : 0.0;

      // VÃ©rifier que les valeurs sont correctes
      expect(v15, equals(9954.5));
      expect(va, equals(10000.0));
      expect(v15, isNot(equals(va))); // Doit Ãªtre diffÃ©rent de l'ambiant
    });

    test('should map volume_corrige_15c correctly when int', () {
      // Test avec volume_corrige_15c = 9954 (int)
      final row = {'volume_corrige_15c': 9954, 'volume_ambiant': 10000};

      final v15Raw = row['volume_corrige_15c'];
      final vaRaw = row['volume_ambiant'];

      final v15 = (v15Raw is num) ? (v15Raw as num).toDouble() : 0.0;
      final va = (vaRaw is num) ? (vaRaw as num).toDouble() : 0.0;

      // VÃ©rifier que les valeurs sont correctes
      expect(v15, equals(9954.0));
      expect(va, equals(10000.0));
      expect(v15, isNot(equals(va))); // Doit Ãªtre diffÃ©rent de l'ambiant
    });

    test('should map volume_corrige_15c correctly when string', () {
      // Test avec volume_corrige_15c = "9954.5" (string)
      final row = {
        'volume_corrige_15c': "9954.5", // String, pas num
        'volume_ambiant': 10000.0,
      };

      final v15Raw = row['volume_corrige_15c'];
      final vaRaw = row['volume_ambiant'];

      final v15 = (v15Raw is num) ? (v15Raw as num).toDouble() : 0.0;
      final va = (vaRaw is num) ? (vaRaw as num).toDouble() : 0.0;

      // VÃ©rifier que volume_corrige_15c = 0.0 car ce n'est pas un num
      expect(v15, equals(0.0));
      expect(va, equals(10000.0));
      expect(v15, isNot(equals(va))); // Ne doit pas Ãªtre Ã©gal Ã  l'ambiant
    });

    test('KpiNumberVolume.fromNullable should handle null values correctly', () {
      // Test du constructeur factory
      final kpi = KpiNumberVolume.fromNullable(count: 1, volume15c: null, volumeAmbient: 10000.0);

      // VÃ©rifier que volume15c = 0.0 et non 10000.0
      expect(kpi.count, equals(1));
      expect(kpi.volume15c, equals(0.0));
      expect(kpi.volumeAmbient, equals(10000.0));
      expect(kpi.volume15c, isNot(equals(kpi.volumeAmbient)));
    });

    test('KpiNumberVolume.fromNullable should handle valid values correctly', () {
      // Test du constructeur factory avec valeurs valides
      final kpi = KpiNumberVolume.fromNullable(count: 1, volume15c: 9954.5, volumeAmbient: 10000.0);

      // VÃ©rifier que les valeurs sont correctes
      expect(kpi.count, equals(1));
      expect(kpi.volume15c, equals(9954.5));
      expect(kpi.volumeAmbient, equals(10000.0));
      expect(kpi.volume15c, isNot(equals(kpi.volumeAmbient)));
    });

    test('KpiStocks.fromNullable should handle null values correctly', () {
      // Test du constructeur factory pour les stocks
      final stocks = KpiStocks.fromNullable(
        totalAmbient: 10000.0,
        total15c: null,
        capacityTotal: 50000.0,
      );

      // VÃ©rifier que total15c = 0.0 et non 10000.0
      expect(stocks.totalAmbient, equals(10000.0));
      expect(stocks.total15c, equals(0.0));
      expect(stocks.capacityTotal, equals(50000.0));
      expect(stocks.total15c, isNot(equals(stocks.totalAmbient)));
    });

    test('KpiStocks.fromNullable should handle valid values correctly', () {
      // Test du constructeur factory pour les stocks avec valeurs valides
      final stocks = KpiStocks.fromNullable(
        totalAmbient: 10000.0,
        total15c: 9954.5,
        capacityTotal: 50000.0,
      );

      // VÃ©rifier que les valeurs sont correctes
      expect(stocks.totalAmbient, equals(10000.0));
      expect(stocks.total15c, equals(9954.5));
      expect(stocks.capacityTotal, equals(50000.0));
      expect(stocks.total15c, isNot(equals(stocks.totalAmbient)));
    });
  });
}

