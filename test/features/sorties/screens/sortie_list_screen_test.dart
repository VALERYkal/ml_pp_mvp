// 📌 Module : Sorties - Tests Widget Liste
// 🧭 Description : Tests widget pour l'écran de liste des sorties

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/sorties/screens/sortie_list_screen.dart';
import 'package:ml_pp_mvp/features/sorties/providers/sorties_table_provider.dart';
import 'package:ml_pp_mvp/features/sorties/models/sortie_row_vm.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';

/// Helper pour créer un dataset avec exactement `count` lignes
List<SortieRowVM> _mockRows({
  required int count,
  required SortieRowVM Function(int i) factory,
}) {
  return List.generate(count, factory);
}

/// Factory simple de base pour les lignes
SortieRowVM _baseRow(int i) => SortieRowVM(
      id: 'sortie-$i',
      dateSortie: DateTime(2026, 1, 1).add(Duration(days: i)),
      propriete: 'MONALUXE',
      produitLabel: 'Essence',
      citerneNom: 'Citerne $i',
      vol15: 1000.0 + i,
      volAmb: 1000.0 + i,
      beneficiaireNom: 'Client $i',
      statut: 'validee',
    );

void main() {
  group('SortieListScreen', () {
    testWidgets(
      'Sorties List (PCA) n\'affiche aucun bouton d\'action',
      (tester) async {
        // Arrange - Créer des données mockées avec >= 10 lignes
        final mockSorties = _mockRows(count: 10, factory: (i) => _baseRow(i));

        // Forcer un layout déterministe (desktop) pour garantir le rendu table
        await tester.binding.setSurfaceSize(const Size(1300, 800));
        addTearDown(() async {
          await tester.binding.setSurfaceSize(null);
        });

        // Act - Monter l'écran avec le provider override et rôle PCA
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sortiesTableProvider.overrideWith(
                (ref) => Future.value(mockSorties),
              ),
              userRoleProvider.overrideWith((ref) => UserRole.pca),
            ],
            child: const MaterialApp(home: SortieListScreen()),
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
          find.byType(SortieListScreen),
          findsOneWidget,
          reason: 'L\'écran de liste doit être affiché même pour PCA',
        );
      },
    );
  });
}
