import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/governance/domain/integrity_check.dart';

void main() {
  group('IntegrityCheck', () {
    group('fromMap', () {
      test('parse correctly with all fields', () {
        final map = {
          'check_code': 'STOCK_NEGATIF',
          'severity': 'CRITICAL',
          'entity_type': 'CITERNE_STOCK',
          'entity_id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          'message': 'Stock négatif détecté.',
          'payload': {'citerne_id': 'c1', 'stock_ambiant': -10.0},
          'detected_at': '2025-02-06T10:00:00.000Z',
        };

        final check = IntegrityCheck.fromMap(map);

        expect(check.checkCode, 'STOCK_NEGATIF');
        expect(check.severity, 'CRITICAL');
        expect(check.entityType, 'CITERNE_STOCK');
        expect(check.entityId, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
        expect(check.message, 'Stock négatif détecté.');
        expect(check.payload, {'citerne_id': 'c1', 'stock_ambiant': -10.0});
        expect(check.detectedAt, DateTime.utc(2025, 2, 6, 10, 0, 0));
      });

      test('payload null -> empty map', () {
        final map = {
          'check_code': 'TEST',
          'severity': 'WARN',
          'entity_type': 'CDR',
          'entity_id': 'id-1',
          'message': 'Test',
          'payload': null,
          'detected_at': '2025-02-06T12:00:00Z',
        };

        final check = IntegrityCheck.fromMap(map);

        expect(check.payload, isEmpty);
        expect(check.payload, isA<Map<String, dynamic>>());
      });

      test('detected_at parse from string ISO8601', () {
        final map = {
          'check_code': 'TEST',
          'severity': 'INFO',
          'entity_type': 'X',
          'entity_id': '1',
          'message': 'Msg',
          'payload': {},
          'detected_at': '2025-01-15T08:30:00.123Z',
        };

        final check = IntegrityCheck.fromMap(map);

        expect(check.detectedAt, DateTime.utc(2025, 1, 15, 8, 30, 0, 123));
      });

      test('severity lower case -> upper', () {
        final map = {
          'check_code': 'T',
          'severity': 'warn',
          'entity_type': 'X',
          'entity_id': '1',
          'message': 'M',
          'payload': {},
          'detected_at': '2025-02-06T00:00:00Z',
        };

        final check = IntegrityCheck.fromMap(map);

        expect(check.severity, 'WARN');
        expect(check.isWarn, isTrue);
        expect(check.isCritical, isFalse);
      });

      test('isCritical and isWarn helpers', () {
        expect(
          IntegrityCheck.fromMap({
            'check_code': 'C',
            'severity': 'CRITICAL',
            'entity_type': 'X',
            'entity_id': '1',
            'message': 'M',
            'payload': {},
            'detected_at': '2025-02-06T00:00:00Z',
          }).isCritical,
          isTrue,
        );
        expect(
          IntegrityCheck.fromMap({
            'check_code': 'W',
            'severity': 'WARN',
            'entity_type': 'X',
            'entity_id': '1',
            'message': 'M',
            'payload': {},
            'detected_at': '2025-02-06T00:00:00Z',
          }).isWarn,
          isTrue,
        );
      });
    });

    group('severityRank', () {
      test('CRITICAL=1, WARN=2, other=3', () {
        expect(IntegrityCheck.severityRank('CRITICAL'), 1);
        expect(IntegrityCheck.severityRank('critical'), 1);
        expect(IntegrityCheck.severityRank('WARN'), 2);
        expect(IntegrityCheck.severityRank('warn'), 2);
        expect(IntegrityCheck.severityRank('INFO'), 3);
        expect(IntegrityCheck.severityRank(''), 3);
        expect(IntegrityCheck.severityRank('OTHER'), 3);
      });

      test('ordering: CRITICAL before WARN before other', () {
        final critical = IntegrityCheck.severityRank('CRITICAL');
        final warn = IntegrityCheck.severityRank('WARN');
        final info = IntegrityCheck.severityRank('INFO');

        expect(critical, lessThan(warn));
        expect(warn, lessThan(info));
      });
    });
  });
}
