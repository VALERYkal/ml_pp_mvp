import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/governance/domain/integrity_check.dart';

void main() {
  group('IntegrityCheck', () {
    group('fromMap', () {
      test('parse correctly with all fields', () {
        final map = {
          'id': 'a0b1c2d3-e4f5-6789-abcd-ef0123456789',
          'check_code': 'STOCK_NEGATIF',
          'severity': 'CRITICAL',
          'entity_type': 'CITERNE_STOCK',
          'entity_id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
          'message': 'Stock négatif détecté.',
          'payload': {'citerne_id': 'c1', 'stock_ambiant': -10.0},
          'status': 'OPEN',
          'last_detected_at': '2025-02-06T10:00:00.000Z',
        };

        final check = IntegrityCheck.fromMap(map);

        expect(check.id, 'a0b1c2d3-e4f5-6789-abcd-ef0123456789');
        expect(check.checkCode, 'STOCK_NEGATIF');
        expect(check.severity, 'CRITICAL');
        expect(check.entityType, 'CITERNE_STOCK');
        expect(check.entityId, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
        expect(check.message, 'Stock négatif détecté.');
        expect(check.payload, {'citerne_id': 'c1', 'stock_ambiant': -10.0});
        expect(check.status, 'OPEN');
        expect(check.detectedAt, DateTime.utc(2025, 2, 6, 10, 0, 0));
      });

      test('payload null -> empty map', () {
        final map = {
          'id': 'id-1',
          'check_code': 'TEST',
          'severity': 'WARN',
          'entity_type': 'CDR',
          'entity_id': 'id-1',
          'message': 'Test',
          'payload': null,
          'status': 'OPEN',
          'last_detected_at': '2025-02-06T12:00:00Z',
        };

        final check = IntegrityCheck.fromMap(map);

        expect(check.payload, isEmpty);
        expect(check.payload, isA<Map<String, dynamic>>());
      });

      test('last_detected_at parse from string ISO8601', () {
        final map = {
          'id': 'x',
          'check_code': 'TEST',
          'severity': 'INFO',
          'entity_type': 'X',
          'entity_id': '1',
          'message': 'Msg',
          'payload': {},
          'status': 'OPEN',
          'last_detected_at': '2025-01-15T08:30:00.123Z',
        };

        final check = IntegrityCheck.fromMap(map);

        expect(check.detectedAt, DateTime.utc(2025, 1, 15, 8, 30, 0, 123));
      });

      test('severity lower case -> upper', () {
        final map = {
          'id': 'x',
          'check_code': 'T',
          'severity': 'warn',
          'entity_type': 'X',
          'entity_id': '1',
          'message': 'M',
          'payload': {},
          'status': 'OPEN',
          'last_detected_at': '2025-02-06T00:00:00Z',
        };

        final check = IntegrityCheck.fromMap(map);

        expect(check.severity, 'WARN');
        expect(check.isWarn, isTrue);
        expect(check.isCritical, isFalse);
      });

      test('isCritical and isWarn helpers', () {
        expect(
          IntegrityCheck.fromMap({
            'id': 'x',
            'check_code': 'C',
            'severity': 'CRITICAL',
            'entity_type': 'X',
            'entity_id': '1',
            'message': 'M',
            'payload': {},
            'status': 'OPEN',
            'last_detected_at': '2025-02-06T00:00:00Z',
          }).isCritical,
          isTrue,
        );
        expect(
          IntegrityCheck.fromMap({
            'id': 'x',
            'check_code': 'W',
            'severity': 'WARN',
            'entity_type': 'X',
            'entity_id': '1',
            'message': 'M',
            'payload': {},
            'status': 'OPEN',
            'last_detected_at': '2025-02-06T00:00:00Z',
          }).isWarn,
          isTrue,
        );
      });
    });

    group('severityRank', () {
      test('status helpers isOpen, isAck, isResolved', () {
        final open = IntegrityCheck.fromMap({
          'id': 'x',
          'check_code': 'C',
          'severity': 'WARN',
          'entity_type': 'X',
          'entity_id': '1',
          'message': 'M',
          'payload': {},
          'status': 'OPEN',
          'last_detected_at': '2025-02-06T00:00:00Z',
        });
        expect(open.isOpen, isTrue);
        expect(open.canAck, isTrue);
        expect(open.canResolve, isTrue);

        final resolved = IntegrityCheck.fromMap({
          'id': 'x',
          'check_code': 'C',
          'severity': 'WARN',
          'entity_type': 'X',
          'entity_id': '1',
          'message': 'M',
          'payload': {},
          'status': 'RESOLVED',
          'last_detected_at': '2025-02-06T00:00:00Z',
        });
        expect(resolved.isResolved, isTrue);
        expect(resolved.canAck, isFalse);
        expect(resolved.canResolve, isFalse);
      });

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
