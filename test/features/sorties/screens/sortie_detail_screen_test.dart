import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/sorties/models/sortie_row_vm.dart';
import 'package:ml_pp_mvp/features/sorties/providers/sorties_table_provider.dart';
import 'package:ml_pp_mvp/features/sorties/screens/sortie_detail_screen.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';

void main() {
  group('SortieDetailScreen', () {
    testWidgets('Affiche un loader quand l\'état est en chargement', (
      tester,
    ) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          sortiesTableProvider.overrideWith((ref) async {
            // Simuler un chargement en cours
            await Future.delayed(const Duration(milliseconds: 100));
            return <SortieRowVM>[];
          }),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: SortieDetailScreen(sortieId: 'test-id')),
        ),
      );
      await tester.pump(); // Premier pump pour afficher le loading

      // Assert - Vérifier que le loader est présent pendant le chargement
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Purger le Timer en laissant le temps au Future.delayed de se terminer
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets(
      'Affiche un message d\'erreur quand le provider est en erreur',
      (tester) async {
        // Arrange
        final error = Exception('Erreur de test');
        final container = ProviderContainer(
          overrides: [
            sortiesTableProvider.overrideWith((ref) async {
              throw error;
            }),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(home: SortieDetailScreen(sortieId: 'test-id')),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Erreur lors du chargement'), findsOneWidget);
        expect(find.text('Réessayer'), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      },
    );

    testWidgets('Affiche "Sortie introuvable" quand la sortie n\'existe pas', (
      tester,
    ) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          sortiesTableProvider.overrideWith(
            (ref) async => [
              SortieRowVM(
                id: 'autre-id',
                dateSortie: DateTime.now(),
                propriete: 'MONALUXE',
                produitLabel: 'ESS · Essence',
                citerneNom: 'Citerne 1',
                vol15: 1000.0,
                volAmb: 1000.0,
                statut: 'validee',
              ),
            ],
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: SortieDetailScreen(sortieId: 'test-id')),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Sortie introuvable'), findsOneWidget);
      expect(
        find.text('La sortie demandée n\'existe pas ou a été supprimée.'),
        findsOneWidget,
      );
    });

    testWidgets('Affiche les détails d\'une sortie MONALUXE avec badge', (
      tester,
    ) async {
      // Arrange
      final sortie = SortieRowVM(
        id: 'test-id',
        dateSortie: DateTime(2025, 1, 15),
        propriete: 'MONALUXE',
        produitLabel: 'ESS · Essence',
        citerneNom: 'Citerne 1',
        vol15: 1000.0,
        volAmb: 1000.0,
        beneficiaireNom: 'Client Test',
        statut: 'validee',
      );

      final container = ProviderContainer(
        overrides: [
          sortiesTableProvider.overrideWith((ref) async => [sortie]),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: SortieDetailScreen(sortieId: 'test-id')),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('Détail de la sortie'),
        findsAtLeastNWidgets(1),
      ); // AppBar + contenu
      expect(find.text('MONALUXE'), findsOneWidget);
      expect(find.text('ESS · Essence'), findsOneWidget);
      expect(find.text('Citerne 1'), findsOneWidget);
      expect(find.text('Client Test'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsWidgets); // Badge MONALUXE
    });

    testWidgets('Affiche les détails d\'une sortie PARTENAIRE avec badge', (
      tester,
    ) async {
      // Arrange
      final sortie = SortieRowVM(
        id: 'test-id',
        dateSortie: DateTime(2025, 1, 15),
        propriete: 'PARTENAIRE',
        produitLabel: 'GAS · Gasoil',
        citerneNom: 'Citerne 2',
        vol15: 2000.0,
        volAmb: 2000.0,
        beneficiaireNom: 'Partenaire Test',
        statut: 'validee',
      );

      final container = ProviderContainer(
        overrides: [
          sortiesTableProvider.overrideWith((ref) async => [sortie]),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: SortieDetailScreen(sortieId: 'test-id')),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('PARTENAIRE'), findsOneWidget);
      expect(find.text('GAS · Gasoil'), findsOneWidget);
      expect(find.text('Partenaire Test'), findsOneWidget);
      expect(find.byIcon(Icons.business), findsWidgets); // Badge PARTENAIRE
    });

    testWidgets(
      'Affiche "Bénéficiaire inconnu" quand beneficiaireNom est null',
      (tester) async {
        // Arrange
        final sortie = SortieRowVM(
          id: 'test-id',
          dateSortie: DateTime(2025, 1, 15),
          propriete: 'MONALUXE',
          produitLabel: 'ESS · Essence',
          citerneNom: 'Citerne 1',
          vol15: 1000.0,
          volAmb: 1000.0,
          beneficiaireNom: null,
          statut: 'validee',
        );

        final container = ProviderContainer(
          overrides: [
            sortiesTableProvider.overrideWith((ref) async => [sortie]),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(home: SortieDetailScreen(sortieId: 'test-id')),
          ),
        );
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Bénéficiaire inconnu'), findsOneWidget);
      },
    );

    testWidgets('Affiche les volumes formatés', (tester) async {
      // Arrange
      final sortie = SortieRowVM(
        id: 'test-id',
        dateSortie: DateTime(2025, 1, 15),
        propriete: 'MONALUXE',
        produitLabel: 'ESS · Essence',
        citerneNom: 'Citerne 1',
        vol15: 1234.5,
        volAmb: 1234.5,
        statut: 'validee',
      );

      final container = ProviderContainer(
        overrides: [
          sortiesTableProvider.overrideWith((ref) async => [sortie]),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: SortieDetailScreen(sortieId: 'test-id')),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Volume @15°C'), findsOneWidget);
      expect(find.text('Volume ambiant'), findsOneWidget);
      // Les volumes sont formatés, on vérifie juste que les labels sont présents
    });

    testWidgets('Le bouton Réessayer est présent en cas d\'erreur', (
      tester,
    ) async {
      // Arrange
      final error = Exception('Erreur de test');
      final container = ProviderContainer(
        overrides: [
          sortiesTableProvider.overrideWith((ref) async {
            throw error;
          }),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: SortieDetailScreen(sortieId: 'test-id')),
        ),
      );
      await tester.pumpAndSettle();

      // Trouver le bouton Réessayer
      final retryButton = find.text('Réessayer');
      expect(retryButton, findsOneWidget);

      // Vérifier que le bouton est cliquable
      await tester.tap(retryButton);
      await tester.pump();

      // Assert: Le bouton est présent et cliquable (pas de crash)
    });

    testWidgets(
      'Sortie Detail (Directeur) ne montre pas le bouton Ajustement',
      (tester) async {
        // Arrange
        final sortie = SortieRowVM(
          id: 'test-id',
          dateSortie: DateTime(2025, 1, 15),
          propriete: 'MONALUXE',
          produitLabel: 'ESS · Essence',
          citerneNom: 'Citerne 1',
          vol15: 1000.0,
          volAmb: 1000.0,
          beneficiaireNom: 'Client Test',
          statut: 'validee',
        );

        final container = ProviderContainer(
          overrides: [
            sortiesTableProvider.overrideWith((ref) async => [sortie]),
            userRoleProvider.overrideWith((ref) => UserRole.directeur),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(home: SortieDetailScreen(sortieId: 'test-id')),
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
        final sortie = SortieRowVM(
          id: 'test-id',
          dateSortie: DateTime(2025, 1, 15),
          propriete: 'MONALUXE',
          produitLabel: 'ESS · Essence',
          citerneNom: 'Citerne 1',
          vol15: 1000.0,
          volAmb: 1000.0,
          beneficiaireNom: 'Client Test',
          statut: 'validee',
        );

        final container = ProviderContainer(
          overrides: [
            sortiesTableProvider.overrideWith((ref) async => [sortie]),
            userRoleProvider.overrideWith((ref) => UserRole.admin),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(home: SortieDetailScreen(sortieId: 'test-id')),
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
      'Sortie Detail (Gérant) ne montre pas le bouton Ajustement',
      (tester) async {
        // Arrange
        final sortie = SortieRowVM(
          id: 'test-id',
          dateSortie: DateTime(2025, 1, 15),
          propriete: 'MONALUXE',
          produitLabel: 'ESS · Essence',
          citerneNom: 'Citerne 1',
          vol15: 1000.0,
          volAmb: 1000.0,
          beneficiaireNom: 'Client Test',
          statut: 'validee',
        );

        final container = ProviderContainer(
          overrides: [
            sortiesTableProvider.overrideWith((ref) async => [sortie]),
            userRoleProvider.overrideWith((ref) => UserRole.gerant),
          ],
        );

        // Act
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(home: SortieDetailScreen(sortieId: 'test-id')),
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
