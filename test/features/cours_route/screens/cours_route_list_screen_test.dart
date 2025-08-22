// 📌 Module : Cours de Route - Tests Widget
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Tests widget pour l'écran de liste des cours de route (v2.2)

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_list_screen.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';

/// Tests widget pour l'écran de liste des cours de route (v2.2)
/// 
/// Ces tests vérifient :
/// - L'affichage correct de l'écran
/// - Les états de chargement et d'erreur
/// - Le filtrage réactif
/// - Les actions selon les rôles
void main() {
  group('CoursRouteListScreen', () {
    /// Mock des données de référence
    final mockRefData = RefDataCache(
      fournisseurs: {
        'f1': 'Fournisseur Test 1',
        'f2': 'Fournisseur Test 2',
      },
      produits: {
        'p1': 'Essence',
        'p2': 'Gasoil / AGO',
      },
      produitCodes: {
        'p1': 'ESS',
        'p2': 'AGO',
      },
      depots: {
        'd1': 'Dépôt Test 1',
        'd2': 'Dépôt Test 2',
      },
      loadedAt: DateTime.now(),
    );

    /// Mock des cours de route
    final mockCours = [
      CoursDeRoute(
        id: 'c1',
        fournisseurId: 'f1',
        produitId: 'p1',
        depotDestinationId: 'd1',
        plaqueCamion: 'ABC123',
        chauffeur: 'Jean Dupont',
        volume: 1500.0,
        dateChargement: DateTime(2025, 1, 27),
        statut: StatutCours.chargement,
      ),
      CoursDeRoute(
        id: 'c2',
        fournisseurId: 'f2',
        produitId: 'p2',
        depotDestinationId: 'd2',
        plaqueCamion: 'XYZ789',
        chauffeur: 'Marie Martin',
        volume: 2000.0,
        dateChargement: DateTime(2025, 1, 26),
        statut: StatutCours.transit,
      ),
    ];

    /// Test de l'affichage de l'écran avec des données
    testWidgets('affiche correctement l\'écran avec des données', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteListProvider.overrideWith((ref) async => mockCours),
            refDataProvider.overrideWith((ref) async => mockRefData),
            userRoleProvider.overrideWith((ref) => UserRole.admin),
          ],
          child: const MaterialApp(
            home: CoursRouteListScreen(),
          ),
        ),
      );

      // Act - Attendre que les données se chargent
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Cours de Route'), findsOneWidget);
      expect(find.text('Fournisseur Test 1'), findsOneWidget);
      expect(find.text('Fournisseur Test 2'), findsOneWidget);
      expect(find.text('Essence'), findsOneWidget);
      expect(find.text('Gasoil / AGO'), findsOneWidget);
    });

    /// Test de l'affichage de l'écran en état de chargement
    testWidgets('affiche correctement l\'état de chargement', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteListProvider.overrideWith((ref) async {
              await Future.delayed(const Duration(milliseconds: 50));
              return mockCours;
            }),
            userRoleProvider.overrideWith((ref) => UserRole.admin),
          ],
          child: const MaterialApp(
            home: CoursRouteListScreen(),
          ),
        ),
      );

      // Assert - Vérifier que le loader s'affiche
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Attendre que le timer se termine
      await tester.pumpAndSettle();
    });

    /// Test de l'affichage de l'écran en état d'erreur
    testWidgets('affiche correctement l\'état d\'erreur', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteListProvider.overrideWith((ref) async {
              throw Exception('Erreur de test');
            }),
            userRoleProvider.overrideWith((ref) => UserRole.admin),
          ],
          child: const MaterialApp(
            home: CoursRouteListScreen(),
          ),
        ),
      );

      // Act - Attendre que l'erreur se propage
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Erreur'), findsOneWidget);
      expect(find.text('Erreur chargement: Exception: Erreur de test'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
    });

    /// Test de l'affichage de l'écran vide
    testWidgets('affiche correctement l\'état vide', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteListProvider.overrideWith((ref) async => <CoursDeRoute>[]),
            refDataProvider.overrideWith((ref) async => mockRefData),
            userRoleProvider.overrideWith((ref) => UserRole.admin),
          ],
          child: const MaterialApp(
            home: CoursRouteListScreen(),
          ),
        ),
      );

      // Act - Attendre que les données se chargent
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Aucun cours pour le moment'), findsOneWidget);
      expect(find.text('Créer un cours'), findsOneWidget);
    });

    /// Test des filtres
    testWidgets('affiche les filtres correctement', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteListProvider.overrideWith((ref) async => mockCours),
            refDataProvider.overrideWith((ref) async => mockRefData),
            userRoleProvider.overrideWith((ref) => UserRole.admin),
          ],
          child: const MaterialApp(
            home: CoursRouteListScreen(),
          ),
        ),
      );

      // Act - Attendre que les données se chargent
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Tous'), findsAtLeastNWidgets(1));
      expect(find.text('Plaque ou chauffeur…'), findsOneWidget);
    });

    /// Test du bouton d'ajout
    testWidgets('affiche le bouton d\'ajout', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteListProvider.overrideWith((ref) async => mockCours),
            refDataProvider.overrideWith((ref) async => mockRefData),
            userRoleProvider.overrideWith((ref) => UserRole.admin),
          ],
          child: const MaterialApp(
            home: CoursRouteListScreen(),
          ),
        ),
      );

      // Act - Attendre que les données se chargent
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.add), findsNWidgets(2)); // AppBar + FAB
    });

    /// Test du pull-to-refresh
    testWidgets('supporte le pull-to-refresh', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteListProvider.overrideWith((ref) async => mockCours),
            refDataProvider.overrideWith((ref) async => mockRefData),
            userRoleProvider.overrideWith((ref) => UserRole.admin),
          ],
          child: const MaterialApp(
            home: CoursRouteListScreen(),
          ),
        ),
      );

      // Act - Attendre que les données se chargent
      await tester.pumpAndSettle();

      // Assert - Vérifier que RefreshIndicator est présent
      expect(find.byType(RefreshIndicator), findsOneWidget);
    });
  });
}
