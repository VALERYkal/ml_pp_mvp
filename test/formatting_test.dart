import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/shared/utils/formatters.dart';

void main() {
  group('Formatters Tests', () {
    test('fmtThousands should format numbers with spaces', () {
      expect(fmtThousands(1000), equals('1\u202F000')); // narrow no-break space
      expect(fmtThousands(10000), equals('10\u202F000'));
      expect(fmtThousands(125000), equals('125\u202F000'));
      expect(fmtThousands(1500), equals('1\u202F500'));
    });

    test('fmtThousands should handle decimals', () {
      expect(fmtThousands(1500.5, decimals: 1), equals('1\u202F500,5'));
      expect(fmtThousands(1500.25, decimals: 2), equals('1\u202F500,25'));
    });

    test('fmtLiters should add L suffix', () {
      expect(fmtLiters(1000), equals('1\u202F000 L'));
      expect(fmtLiters(10000), equals('10\u202F000 L'));
      expect(fmtLiters(125000), equals('125\u202F000 L'));
      expect(fmtLiters(1500), equals('1\u202F500 L'));
    });

    test('fmtLiters should handle decimals', () {
      expect(fmtLiters(1500.5, decimals: 1), equals('1\u202F500,5 L'));
      expect(fmtLiters(1500.25, decimals: 2), equals('1\u202F500,25 L'));
    });

    test('fmtLiters should handle zero', () {
      expect(fmtLiters(0), equals('0 L'));
    });

    test('fmtLiters should handle negative numbers', () {
      expect(fmtLiters(-1000), equals('-1\u202F000 L'));
    });
  });
}
