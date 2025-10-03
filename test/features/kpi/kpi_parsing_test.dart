import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';

double _toD(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v.trim().replaceAll(',', '.')) ?? 0.0;
  return 0.0;
}

void main() {
  group('KPI Parsing Tests', () {
    test('parse numeric or string to double safely', () {
      expect(_toD(10), 10.0);
      expect(_toD(10.5), 10.5);
      expect(_toD('9954.5'), 9954.5);
      expect(_toD('9,954.5'.replaceAll(',', '')), 9954.5); // au cas où
      expect(_toD(null), 0.0);
      expect(_toD('bad'), 0.0);
    });

    test('no fallback 15C -> ambient', () {
      final receptions = KpiNumberVolume.fromNullable(
        count: 1,
        volume15c: _toD(null), // 0
        volumeAmbient: _toD(10000), // 10k
      );
      expect(receptions.volume15c, 0.0); // ✅ pas 10k
      expect(receptions.volumeAmbient, 10000.0);
    });

    test('correct 15C values are preserved', () {
      final receptions = KpiNumberVolume.fromNullable(
        count: 1,
        volume15c: _toD(9954.5), // 9954.5
        volumeAmbient: _toD(10000), // 10k
      );
      expect(receptions.volume15c, 9954.5);
      expect(receptions.volumeAmbient, 10000.0);
      expect(receptions.volume15c, isNot(equals(receptions.volumeAmbient)));
    });

    test('stocks parsing works correctly', () {
      final stocks = KpiStocks.fromNullable(
        totalAmbient: _toD(10000.0),
        total15c: _toD(9954.5),
        capacityTotal: _toD(50000.0),
      );
      expect(stocks.totalAmbient, 10000.0);
      expect(stocks.total15c, 9954.5);
      expect(stocks.capacityTotal, 50000.0);
      expect(stocks.total15c, isNot(equals(stocks.totalAmbient)));
    });

    test('stocks with null 15C should not fallback to ambient', () {
      final stocks = KpiStocks.fromNullable(
        totalAmbient: _toD(10000.0),
        total15c: _toD(null), // 0
        capacityTotal: _toD(50000.0),
      );
      expect(stocks.totalAmbient, 10000.0);
      expect(stocks.total15c, 0.0); // ✅ pas 10k
      expect(stocks.capacityTotal, 50000.0);
    });

    test('string parsing with commas and dots', () {
      expect(_toD('9,954.5'), 9954.5);
      expect(_toD('9.954,5'), 9954.5);
      expect(_toD(' 9954.5 '), 9954.5);
      expect(_toD(''), 0.0);
    });
  });
}
