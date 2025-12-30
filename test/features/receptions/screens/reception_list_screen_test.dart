// 📌 Module : Réceptions - Tests Widget Liste
// 🧭 Description : Tests widget pour l'écran de liste des réceptions

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/receptions/screens/reception_list_screen.dart';
import 'package:ml_pp_mvp/features/receptions/providers/receptions_table_provider.dart';
import 'package:ml_pp_mvp/features/receptions/models/reception_row_vm.dart';

void main() {
  group('ReceptionListScreen', () {
    testWidgets('Affiche la colonne "Source" au lieu de "Fournisseur"', (
      tester,
    ) async {
      // Arrange - Créer des données mockées
      final mockReceptions = [
        ReceptionRowVM(
          id: 'rec-1',
          dateReception: DateTime.now(),
          propriete: 'MONALUXE',
          produitLabel: 'Essence',
          citerneNom: 'Citerne A',
          vol15: 1000.0,
          volAmb: 1000.0,
          fournisseurNom: 'moccho tst',
          partenaireNom: null,
        ),
      ];

      // Act - Monter l'écran avec le provider override
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            receptionsTableProvider.overrideWith(
              (ref) => Future.value(mockReceptions),
            ),
          ],
          child: const MaterialApp(home: ReceptionListScreen()),
        ),
      );

      // Attendre que les données soient chargées
      await tester.pumpAndSettle();

      // Assert - Vérifier que "Source" est affiché et "Fournisseur" ne l'est pas
      expect(find.text('Source'), findsOneWidget);
      expect(find.text('Fournisseur'), findsNothing);
    });

    testWidgets(
      'Affiche le sourceLabel correctement pour une réception avec fournisseur',
      (tester) async {
        // Arrange
        final mockReceptions = [
          ReceptionRowVM(
            id: 'rec-1',
            dateReception: DateTime.now(),
            propriete: 'MONALUXE',
            produitLabel: 'Essence',
            citerneNom: 'Citerne A',
            vol15: 1000.0,
            volAmb: 1000.0,
            fournisseurNom: 'moccho tst',
            partenaireNom: null,
          ),
        ];

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              receptionsTableProvider.overrideWith(
                (ref) => Future.value(mockReceptions),
              ),
            ],
            child: const MaterialApp(home: ReceptionListScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Assert - Vérifier que le nom du fournisseur est affiché
        expect(find.text('moccho tst'), findsOneWidget);
      },
    );

    testWidgets(
      'Affiche le sourceLabel correctement pour une réception avec partenaire',
      (tester) async {
        // Arrange
        final mockReceptions = [
          ReceptionRowVM(
            id: 'rec-2',
            dateReception: DateTime.now(),
            propriete: 'PARTENAIRE',
            produitLabel: 'Gasoil',
            citerneNom: 'Citerne B',
            vol15: 2000.0,
            volAmb: 2000.0,
            fournisseurNom: null,
            partenaireNom: 'falcon test',
          ),
        ];

        // Act
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              receptionsTableProvider.overrideWith(
                (ref) => Future.value(mockReceptions),
              ),
            ],
            child: const MaterialApp(home: ReceptionListScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Assert - Vérifier que le nom du partenaire est affiché
        expect(find.text('falcon test'), findsOneWidget);
      },
    );

    testWidgets('Affiche "—" quand ni fournisseur ni partenaire', (
      tester,
    ) async {
      // Arrange
      final mockReceptions = [
        ReceptionRowVM(
          id: 'rec-3',
          dateReception: DateTime.now(),
          propriete: 'MONALUXE',
          produitLabel: 'Essence',
          citerneNom: 'Citerne C',
          vol15: 3000.0,
          volAmb: 3000.0,
          fournisseurNom: null,
          partenaireNom: null,
        ),
      ];

      // Act
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            receptionsTableProvider.overrideWith(
              (ref) => Future.value(mockReceptions),
            ),
          ],
          child: const MaterialApp(home: ReceptionListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert - Vérifier que "—" est affiché (il peut y avoir plusieurs "—" dans le tableau)
      expect(find.text('—'), findsWidgets);
    });
  });
}
