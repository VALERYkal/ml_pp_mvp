import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/governance/domain/integrity_check.dart';
import 'package:ml_pp_mvp/features/governance/providers/integrity_providers.dart';

void main() {
  group('IntegrityProviders', () {
    test('invalidate triggers provider rebuild', () async {
      var fetchCount = 0;
      final container = ProviderContainer(
        overrides: [
          integrityAlertsProvider.overrideWith((ref) async {
            fetchCount++;
            return [
              IntegrityCheck(
                id: 'alert-1',
                checkCode: 'TEST',
                severity: 'WARN',
                entityType: 'CDR',
                entityId: 'id-1',
                message: 'Test',
                payload: {},
                status: 'OPEN',
                detectedAt: DateTime(2025, 2, 6, 10, 0, 0),
              ),
            ];
          }),
        ],
      );
      addTearDown(container.dispose);

      final list1 = await container.read(integrityAlertsProvider.future);
      expect(list1.length, 1);
      expect(fetchCount, 1);

      container.invalidate(integrityAlertsProvider);
      final list2 = await container.read(integrityAlertsProvider.future);
      expect(list2.length, 1);
      expect(fetchCount, 2);
    });
  });
}
