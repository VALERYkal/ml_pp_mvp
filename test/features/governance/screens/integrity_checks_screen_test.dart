import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/features/governance/domain/integrity_check.dart';
import 'package:ml_pp_mvp/features/governance/providers/integrity_providers.dart';
import 'package:ml_pp_mvp/features/governance/screens/integrity_checks_screen.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';

IntegrityCheck _createCheck({
  required String checkCode,
  required String severity,
  String id = 'test-id-1',
  String status = 'OPEN',
  String entityType = 'CDR',
  String entityId = 'id-1',
  String message = 'Test message',
  Map<String, dynamic>? payload,
}) {
  return IntegrityCheck(
    id: id,
    checkCode: checkCode,
    severity: severity,
    entityType: entityType,
    entityId: entityId,
    message: message,
    payload: payload ?? {},
    status: status,
    detectedAt: DateTime(2025, 2, 6, 10, 0, 0),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IntegrityChecksScreen', () {
    testWidgets('affiche "Aucun check détecté." quand liste vide', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            integrityAlertsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: IntegrityChecksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aucun check détecté.'), findsOneWidget);
      expect(find.text('Integrity Checks'), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('affiche counts CRITICAL et WARN + items listés', (
      tester,
    ) async {
      final warnCheck = _createCheck(
        checkCode: 'CDR_ARRIVE_STALE',
        severity: 'WARN',
        entityType: 'CDR',
        message: 'CDR en ARRIVE > 2 jours.',
      );
      final criticalCheck = _createCheck(
        checkCode: 'STOCK_NEGATIF',
        severity: 'CRITICAL',
        entityType: 'CITERNE_STOCK',
        message: 'Stock négatif détecté.',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            integrityAlertsProvider.overrideWith((ref) async => [
                  criticalCheck,
                  warnCheck,
                ]),
          ],
          child: const MaterialApp(
            home: IntegrityChecksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CRITICAL'), findsWidgets);
      expect(find.text('WARN'), findsWidgets);
      expect(find.text('STOCK_NEGATIF • CITERNE_STOCK'), findsOneWidget);
      expect(find.text('CDR_ARRIVE_STALE • CDR'), findsOneWidget);
      expect(find.text('Stock négatif détecté.'), findsOneWidget);
      expect(find.text('CDR en ARRIVE > 2 jours.'), findsOneWidget);
    });

    testWidgets('bouton refresh invalide le provider', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            integrityAlertsProvider.overrideWith((ref) async => []),
          ],
          child: const MaterialApp(
            home: IntegrityChecksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aucun check détecté.'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh));
      await tester.pumpAndSettle();

      expect(find.text('Aucun check détecté.'), findsOneWidget);
    });

    testWidgets('filtre severity CRITICAL affiche seulement CRITICAL + compteurs cohérents',
        (tester) async {
      final warnCheck = _createCheck(
        checkCode: 'CDR_ARRIVE_STALE',
        severity: 'WARN',
        entityType: 'CDR',
        message: 'CDR stale',
      );
      final criticalCheck = _createCheck(
        checkCode: 'STOCK_NEGATIF',
        severity: 'CRITICAL',
        entityType: 'CITERNE_STOCK',
        message: 'Stock négatif',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            integrityAlertsProvider.overrideWith((ref) async => [
                  criticalCheck,
                  warnCheck,
                ]),
          ],
          child: const MaterialApp(
            home: IntegrityChecksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('STOCK_NEGATIF • CITERNE_STOCK'), findsOneWidget);
      expect(find.text('CDR_ARRIVE_STALE • CDR'), findsOneWidget);

      await tester.tap(find.descendant(
        of: find.byType(SegmentedButton<String?>),
        matching: find.text('CRITICAL'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('STOCK_NEGATIF • CITERNE_STOCK'), findsOneWidget);
      expect(find.text('CDR_ARRIVE_STALE • CDR'), findsNothing);
      expect(find.text('sur 2 checks chargés'), findsOneWidget);
    });

    testWidgets('filtre entity_type CDR affiche seulement CDR', (tester) async {
      final cdrCheck = _createCheck(
        checkCode: 'CDR_ARRIVE_STALE',
        severity: 'WARN',
        entityType: 'CDR',
        message: 'CDR stale',
      );
      final stockCheck = _createCheck(
        checkCode: 'STOCK_NEGATIF',
        severity: 'CRITICAL',
        entityType: 'CITERNE_STOCK',
        message: 'Stock négatif',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            integrityAlertsProvider.overrideWith((ref) async => [
                  cdrCheck,
                  stockCheck,
                ]),
          ],
          child: const MaterialApp(
            home: IntegrityChecksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButton<String?>));
      await tester.pumpAndSettle();

      await tester.tap(find.text('CDR').last);
      await tester.pumpAndSettle();

      expect(find.text('CDR_ARRIVE_STALE • CDR'), findsOneWidget);
      expect(find.text('STOCK_NEGATIF • CITERNE_STOCK'), findsNothing);
    });

    testWidgets('bouton Copier affiche SnackBar Copié', (tester) async {
      final check = _createCheck(
        checkCode: 'TEST',
        severity: 'WARN',
        entityType: 'CDR',
        payload: {'key': 'value'},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            integrityAlertsProvider.overrideWith((ref) async => [check]),
          ],
          child: const MaterialApp(
            home: IntegrityChecksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('TEST • CDR'));
      await tester.pumpAndSettle();

      expect(find.text('Copier'), findsOneWidget);
      await tester.tap(find.text('Copier'));
      await tester.pumpAndSettle();

      expect(find.text('Copié'), findsOneWidget);
    });

    testWidgets('ACK bouton visible pour admin', (tester) async {
      final check = _createCheck(
        checkCode: 'TEST',
        severity: 'WARN',
        status: 'OPEN',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            integrityAlertsProvider.overrideWith((ref) async => [check]),
            userRoleProvider.overrideWith((ref) => UserRole.admin),
          ],
          child: const MaterialApp(
            home: IntegrityChecksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ACK'), findsOneWidget);
      expect(find.text('RESOLVE'), findsOneWidget);
    });

    testWidgets('ACK bouton visible pour directeur', (tester) async {
      final check = _createCheck(
        checkCode: 'TEST',
        severity: 'WARN',
        status: 'OPEN',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            integrityAlertsProvider.overrideWith((ref) async => [check]),
            userRoleProvider.overrideWith((ref) => UserRole.directeur),
          ],
          child: const MaterialApp(
            home: IntegrityChecksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ACK'), findsOneWidget);
      expect(find.text('RESOLVE'), findsOneWidget);
    });

    testWidgets('Pas de boutons ACK/RESOLVE pour PCA', (tester) async {
      final check = _createCheck(
        checkCode: 'TEST',
        severity: 'WARN',
        status: 'OPEN',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            integrityAlertsProvider.overrideWith((ref) async => [check]),
            userRoleProvider.overrideWith((ref) => UserRole.pca),
          ],
          child: const MaterialApp(
            home: IntegrityChecksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ACK'), findsNothing);
      expect(find.text('RESOLVE'), findsNothing);
    });
  });
}
