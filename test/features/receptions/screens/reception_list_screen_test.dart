// 📌 Module : Réceptions - Tests Widget Liste
// 🧭 Description : Tests widget pour l'écran de liste des réceptions

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/receptions/screens/reception_list_screen.dart';
import 'package:ml_pp_mvp/features/receptions/providers/receptions_table_provider.dart';
import 'package:ml_pp_mvp/features/receptions/models/reception_row_vm.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';

/// Helper pour créer un dataset avec exactement `count` lignes
/// Utilise une factory pour générer chaque ligne avec un index unique
List<ReceptionRowVM> _mockRows({
  required int count,
  required ReceptionRowVM Function(int i) factory,
}) {
  return List.generate(count, factory);
}

/// Factory simple de base pour les lignes "padding" (fournisseur non null)
ReceptionRowVM _baseRow(int i) => ReceptionRowVM(
  id: 'rec-$i',
  dateReception: DateTime(2026, 1, 1).add(Duration(days: i)),
  propriete: 'MONALUXE',
  produitLabel: 'Essence',
  citerneNom: 'Citerne $i',
  vol15: 1000.0 + i,
  volAmb: 1000.0 + i,
  fournisseurNom: 'fourn-$i',
  partenaireNom: null,
);

void main() {
  group('ReceptionListScreen', () {
    testWidgets('Affiche la colonne "Source" au lieu de "Fournisseur"', (
      tester,
    ) async {
      // Arrange - Créer des données mockées avec >= 10 lignes (évite crash PaginatedDataTable)
      final mockReceptions = _mockRows(count: 10, factory: (i) => _baseRow(i));

      // Forcer un layout déterministe (desktop) pour garantir le rendu table
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

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

      // Vérification anti-crash : s'assurer qu'aucune exception n'a été levée pendant le build
      expect(
        tester.takeException(),
        isNull,
        reason: 'Aucune exception ne doit être levée pendant le build',
      );

      // Assert - Vérifier que PaginatedDataTable est présent et que "Source" est affiché
      expect(find.byType(PaginatedDataTable), findsOneWidget);
      // Vérifier la colonne "Source" (peut être dans un Text ou TextRich)
      expect(
        find.descendant(
          of: find.byType(PaginatedDataTable),
          matching: find.textContaining('Source'),
        ),
        findsWidgets,
      );
      expect(find.text('Fournisseur'), findsNothing);
    });

    testWidgets(
      'Affiche le sourceLabel correctement pour une réception avec fournisseur',
      (tester) async {
        // Arrange - Créer des données mockées avec >= 10 lignes
        // La première ligne contient fournisseurNom = 'moccho tst', puis compléter jusqu'à 10 avec _baseRow
        final mockReceptions = _mockRows(
          count: 10,
          factory: (i) {
            if (i == 0) {
              // Première ligne avec fournisseur
              return ReceptionRowVM(
                id: 'rec-1',
                dateReception: DateTime.now(),
                propriete: 'MONALUXE',
                produitLabel: 'Essence',
                citerneNom: 'Citerne A',
                vol15: 1000.0,
                volAmb: 1000.0,
                fournisseurNom: 'moccho tst',
                partenaireNom: null,
              );
            } else {
              // Lignes de padding
              return _baseRow(i);
            }
          },
        );

        // Forcer un layout déterministe (desktop)
        await tester.binding.setSurfaceSize(const Size(1300, 800));
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
        });

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

        // Vérification anti-crash : s'assurer qu'aucune exception n'a été levée pendant le build
        expect(
          tester.takeException(),
          isNull,
          reason: 'Aucune exception ne doit être levée pendant le build',
        );

        // Assert - Vérifier que le nom du fournisseur est affiché (peut être dans un chip ou texte)
        // Utiliser textContaining pour être tolérant au rendu exact
        expect(find.textContaining('moccho'), findsWidgets);
        // Vérifier aussi que les champs principaux sont présents
        expect(find.text('Essence'), findsWidgets);
        expect(find.text('Citerne A'), findsWidgets);
      },
    );

    testWidgets(
      'Affiche le sourceLabel correctement pour une réception avec partenaire',
      (tester) async {
        // Arrange - Créer des données mockées avec >= 10 lignes
        // La première ligne contient partenaireNom = 'falcon test' (et fournisseurNom null), puis compléter jusqu'à 10 avec _baseRow
        final mockReceptions = _mockRows(
          count: 10,
          factory: (i) {
            if (i == 0) {
              // Première ligne avec partenaire
              return ReceptionRowVM(
                id: 'rec-2',
                dateReception: DateTime.now(),
                propriete: 'PARTENAIRE',
                produitLabel: 'Gasoil',
                citerneNom: 'Citerne B',
                vol15: 2000.0,
                volAmb: 2000.0,
                fournisseurNom: null,
                partenaireNom: 'falcon test',
              );
            } else {
              // Lignes de padding
              return _baseRow(i);
            }
          },
        );

        // Forcer un layout déterministe (desktop)
        await tester.binding.setSurfaceSize(const Size(1300, 800));
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
        });

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

        // Vérification anti-crash : s'assurer qu'aucune exception n'a été levée pendant le build
        expect(
          tester.takeException(),
          isNull,
          reason: 'Aucune exception ne doit être levée pendant le build',
        );

        // Assert - Vérifier que le nom du partenaire est affiché (peut être dans un chip ou texte)
        // Utiliser textContaining pour être tolérant au rendu exact
        expect(find.textContaining('falcon'), findsWidgets);
        // Vérifier aussi que les champs principaux sont présents
        expect(find.text('Gasoil'), findsWidgets);
        expect(find.text('Citerne B'), findsWidgets);
      },
    );

    testWidgets('Affiche "—" quand ni fournisseur ni partenaire', (
      tester,
    ) async {
      // Arrange - Créer des données mockées avec >= 10 lignes
      // La première ligne a fournisseurNom=null et partenaireNom=null, puis compléter jusqu'à 10 avec _baseRow
      final mockReceptions = _mockRows(
        count: 10,
        factory: (i) {
          if (i == 0) {
            // Première ligne sans fournisseur ni partenaire
            return ReceptionRowVM(
              id: 'rec-3',
              dateReception: DateTime.now(),
              propriete: 'MONALUXE',
              produitLabel: 'Essence',
              citerneNom: 'Citerne C',
              vol15: 3000.0,
              volAmb: 3000.0,
              fournisseurNom: null,
              partenaireNom: null,
            );
          } else {
            // Lignes de padding
            return _baseRow(i);
          }
        },
      );

      // Forcer un layout déterministe (desktop) pour garantir le rendu table
      // Évite les variations imprévisibles entre mobile (cards) et desktop (table)
      await tester.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() async {
        await tester.binding.setSurfaceSize(null);
      });

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

      // Vérification anti-crash : s'assurer qu'aucune exception n'a été levée pendant le build
      expect(
        tester.takeException(),
        isNull,
        reason: 'Aucune exception ne doit être levée pendant le build',
      );

      // Assert - Vérifier que le placeholder "—" est affiché
      // Essayer d'abord find.text('—') avec findsWidgets (peut y avoir plusieurs occurrences)
      expect(
        find.text('—'),
        findsWidgets,
        reason: 'Le placeholder "—" doit être affiché au moins une fois',
      );

      // Vérifier aussi que les champs principaux sont présents pour confirmer que la ligne est rendue
      expect(find.text('Essence'), findsWidgets);
      expect(find.text('Citerne C'), findsWidgets);
    });

    testWidgets(
      'Réceptions List (PCA) n\'affiche aucun bouton d\'action',
      (tester) async {
        // Arrange - Créer des données mockées avec >= 10 lignes
        final mockReceptions = _mockRows(count: 10, factory: (i) => _baseRow(i));

        // Forcer un layout déterministe (desktop) pour garantir le rendu table
        await tester.binding.setSurfaceSize(const Size(1300, 800));
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
        });

        // Act - Monter l'écran avec le provider override et rôle PCA
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              receptionsTableProvider.overrideWith(
                (ref) => Future.value(mockReceptions),
              ),
              userRoleProvider.overrideWith((ref) => UserRole.pca),
            ],
            child: const MaterialApp(home: ReceptionListScreen()),
          ),
        );

        // Attendre que les données soient chargées
        await tester.pumpAndSettle();

        // Assert - Vérifier que les boutons d'action ne sont pas présents
        expect(
          find.byIcon(Icons.add),
          findsNothing,
          reason: 'Le bouton "+" ne doit pas être affiché pour le rôle PCA',
        );

        expect(
          find.byIcon(Icons.add_rounded),
          findsNothing,
          reason: 'Le bouton "+" (rounded) ne doit pas être affiché pour le rôle PCA',
        );

        expect(
          find.text('Actions'),
          findsNothing,
          reason: 'La colonne "Actions" ne doit pas être affichée pour le rôle PCA',
        );

        expect(
          find.byIcon(Icons.edit),
          findsNothing,
          reason: 'Aucune icône "edit" ne doit être affichée pour le rôle PCA',
        );

        // Vérifier que l'écran se charge correctement malgré tout
        expect(
          find.byType(ReceptionListScreen),
          findsOneWidget,
          reason: 'L\'écran de liste doit être affiché même pour PCA',
        );
      },
    );
  });
}
