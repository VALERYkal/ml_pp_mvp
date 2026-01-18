// 📌 Module : Réceptions - Tests Widget Détail
// 🧭 Description : Tests widget pour l'écran de détail des réceptions

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/receptions/screens/reception_detail_screen.dart';
import 'package:ml_pp_mvp/features/receptions/providers/receptions_table_provider.dart';
import 'package:ml_pp_mvp/features/receptions/models/reception_row_vm.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';

void main() {
  group('ReceptionDetailScreen', () {
    testWidgets(
      'Réception Detail (Directeur) ne montre pas le bouton Ajustement',
      (tester) async {
        // Arrange
        final reception = ReceptionRowVM(
          id: 'test-id',
          dateReception: DateTime(2025, 1, 15),
          propriete: 'MONALUXE',
          produitLabel: 'ESS · Essence',
          citerneNom: 'Citerne 1',
          vol15: 1000.0,
          volAmb: 1000.0,
          fournisseurNom: 'Fournisseur Test',
        );

        final container = ProviderContainer(
          overrides: [
            receptionsTableProvider.overrideWith((ref) async => [reception]),
            userRoleProvider.overrideWith((ref) => UserRole.directeur),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: ReceptionDetailScreen(receptionId: 'test-id'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Corriger (Ajustement)'), findsNothing);
        expect(find.byIcon(Icons.tune), findsNothing);
      },
    );

    testWidgets(
      'Admin voit le bouton Ajustement',
      (tester) async {
        // Arrange
        final reception = ReceptionRowVM(
          id: 'test-id',
          dateReception: DateTime(2025, 1, 15),
          propriete: 'MONALUXE',
          produitLabel: 'ESS · Essence',
          citerneNom: 'Citerne 1',
          vol15: 1000.0,
          volAmb: 1000.0,
          fournisseurNom: 'Fournisseur Test',
        );

        final container = ProviderContainer(
          overrides: [
            receptionsTableProvider.overrideWith((ref) async => [reception]),
            userRoleProvider.overrideWith((ref) => UserRole.admin),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: ReceptionDetailScreen(receptionId: 'test-id'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.byIcon(Icons.tune), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AppBar),
            matching: find.byIcon(Icons.tune),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Réception Detail (Gérant) ne montre pas le bouton Ajustement',
      (tester) async {
        // Arrange
        final reception = ReceptionRowVM(
          id: 'test-id',
          dateReception: DateTime(2025, 1, 15),
          propriete: 'MONALUXE',
          produitLabel: 'ESS · Essence',
          citerneNom: 'Citerne 1',
          vol15: 1000.0,
          volAmb: 1000.0,
          fournisseurNom: 'Fournisseur Test',
        );

        final container = ProviderContainer(
          overrides: [
            receptionsTableProvider.overrideWith((ref) async => [reception]),
            userRoleProvider.overrideWith((ref) => UserRole.gerant),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: ReceptionDetailScreen(receptionId: 'test-id'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Corriger (Ajustement)'), findsNothing);
        expect(find.byIcon(Icons.tune), findsNothing);
      },
    );
  });
}
