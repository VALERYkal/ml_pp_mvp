import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/shared/utils/formatters.dart';

void main() {
  group('KPI Harmonisation Tests', () {
    test('All KPIs should use the same formatting', () {
      // Test KPI 1 format (Camions à suivre)
      final kpi1EnRoute = fmtLiters(10000);
      final kpi1Attente = fmtLiters(5000);

      // Test KPI 2 format (Réceptions du jour)
      final kpi2Ambiant = fmtLiters(15000);
      final kpi2Corrige = fmtLiters(12000);

      // All should use the same format: "X 000 L"
      expect(kpi1EnRoute, equals('10\u202F000 L'));
      expect(kpi1Attente, equals('5\u202F000 L'));
      expect(kpi2Ambiant, equals('15\u202F000 L'));
      expect(kpi2Corrige, equals('12\u202F000 L'));
    });

    test('Format should be consistent across different values', () {
      final values = [1000, 10000, 125000, 1500];
      final expectedFormats = ['1\u202F000 L', '10\u202F000 L', '125\u202F000 L', '1\u202F500 L'];

      for (int i = 0; i < values.length; i++) {
        expect(fmtLiters(values[i]), equals(expectedFormats[i]));
      }
    });

    test('No more compact format (K/M) should be used', () {
      // These should NOT appear in the output
      final result = fmtLiters(10000);
      expect(result, isNot(contains('K')));
      expect(result, isNot(contains('M')));
      expect(result, isNot(contains('k')));
      expect(result, isNot(contains('m')));
    });

    test('Format should handle zero correctly', () {
      expect(fmtLiters(0), equals('0 L'));
    });

    test('Format should handle negative numbers', () {
      expect(fmtLiters(-1000), equals('-1\u202F000 L'));
    });
  });
}
