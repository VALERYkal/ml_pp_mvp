import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/data/repositories/stocks_repository.dart';

void main() {
  group('StocksRepository Tests', () {
    test('StocksTotals should have correct structure', () {
      const totals = StocksTotals(totalAmbiant: 1000.0, total15c: 950.0, lastDay: null);

      expect(totals.totalAmbiant, equals(1000.0));
      expect(totals.total15c, equals(950.0));
      expect(totals.lastDay, isNull);
    });

    test('StocksTotals should handle date correctly', () {
      final date = DateTime(2025, 9, 11);
      final totals = StocksTotals(totalAmbiant: 2000.0, total15c: 1900.0, lastDay: date);

      expect(totals.totalAmbiant, equals(2000.0));
      expect(totals.total15c, equals(1900.0));
      expect(totals.lastDay, equals(date));
    });

    test('StocksTotals should handle zero values', () {
      const totals = StocksTotals(totalAmbiant: 0.0, total15c: 0.0, lastDay: null);

      expect(totals.totalAmbiant, equals(0.0));
      expect(totals.total15c, equals(0.0));
      expect(totals.lastDay, isNull);
    });
  });
}
