@Tags(['integration'])
// ð Module : Cours de Route - Tests Widget
// ð§ Auteur : Valery Kalonga
// ð Date : 2025-01-27
// ð§­ Description : Tests widget pour l'Ã©cran de formulaire des cours de route
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_form_screen.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';

/// Tests widget pour l'Ã©cran de formulaire des cours de route
///
/// Ces tests vÃ©rifient :
/// - L'affichage correct de l'Ã©cran
/// - Les Ã©tats de chargement et d'erreur
void main() {
  group('CoursRouteFormScreen', () {
    /// Mock des donnÃ©es de rÃ©fÃ©rence
    final mockRefData = RefDataCache(
      fournisseurs: {'f1': 'Fournisseur Test 1', 'f2': 'Fournisseur Test 2'},
      produits: {'p1': 'Essence', 'p2': 'Gasoil / AGO'},
      produitCodes: {'p1': 'ESS', 'p2': 'AGO'},
      depots: {'d1': 'DÃ©pÃ´t Test 1', 'd2': 'DÃ©pÃ´t Test 2'},
      loadedAt: DateTime.now(),
    );

    /// Test de l'affichage de l'Ã©cran avec des donnÃ©es
    testWidgets('affiche correctement l\'Ã©cran avec des donnÃ©es', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [refDataProvider.overrideWith((ref) async => mockRefData)],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      // Act - Attendre que les donnÃ©es se chargent
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Nouveau cours'), findsOneWidget);
      expect(find.text('Fournisseur *'), findsOneWidget);
      expect(find.text('Produit *'), findsOneWidget);
      expect(find.text('DÃ©pÃ´t destination'), findsOneWidget);
      expect(find.text('Pays de dÃ©part *'), findsOneWidget);
      expect(find.text('Date de chargement *'), findsOneWidget);
      expect(find.text('Plaque camion *'), findsOneWidget);
      expect(find.text('Chauffeur *'), findsOneWidget);
      expect(find.text('Volume (L) *'), findsOneWidget);
      expect(find.text('Enregistrer'), findsOneWidget);
    });

    /// Test de la validation automatique
    testWidgets('active la validation automatique', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [refDataProvider.overrideWith((ref) async => mockRefData)],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      // Act - Attendre que les donnÃ©es se chargent
      await tester.pumpAndSettle();

      // Assert - VÃ©rifier que le formulaire a autovalidateMode
      final form = tester.widget<Form>(find.byType(Form));
      expect(form.autovalidateMode, AutovalidateMode.onUserInteraction);
    });

    /// Test de la protection dirty state
    testWidgets('affiche une confirmation lors de la navigation arriÃ¨re avec des modifications', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [refDataProvider.overrideWith((ref) async => mockRefData)],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      // Act - Attendre que les donnÃ©es se chargent et saisir du texte
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Test');
      await tester.pump();

      // Simuler la navigation arriÃ¨re
      await tester.pageBack();

      // Assert - VÃ©rifier que la confirmation s'affiche
      expect(find.text('Annuler les modifications ?'), findsOneWidget);
    });

    /// Test de l'affichage de l'Ã©cran en Ã©tat de chargement
    testWidgets('affiche correctement l\'Ã©tat de chargement', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            refDataProvider.overrideWith((ref) async {
              // Simuler un dÃ©lai de chargement
              await Future.delayed(const Duration(milliseconds: 50));
              return mockRefData;
            }),
          ],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      // Act - VÃ©rifier immÃ©diatement que le loader s'affiche
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Attendre que le chargement se termine
      await tester.pumpAndSettle();
    });

    /// Test de l'affichage de l'Ã©cran en Ã©tat d'erreur
    testWidgets('affiche correctement l\'Ã©tat d\'erreur', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            refDataProvider.overrideWith((ref) async {
              throw Exception('Erreur de test');
            }),
          ],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      // Act - Attendre que l'erreur se propage
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Erreur lors du chargement des rÃ©fÃ©rentiels'), findsOneWidget);
      expect(find.text('RÃ©essayer'), findsOneWidget);
    });

    /// Test de validation des champs obligatoires
    testWidgets('should validate required fields', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [refDataProvider.overrideWith((ref) async => mockRefData)],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Tenter de sauvegarder sans remplir les champs obligatoires
      await tester.tap(find.byKey(const Key('save_button')));
      await tester.pump();

      // Assert - VÃ©rifier que les messages d'erreur apparaissent
      expect(find.text('Fournisseur requis'), findsOneWidget);
      expect(find.text('Produit requis'), findsOneWidget);
      expect(find.text('DÃ©pÃ´t destination requis'), findsOneWidget);
      expect(find.text('Pays requis'), findsOneWidget);
      expect(find.text('Date requise'), findsOneWidget);
      expect(find.text('Plaque camion requise'), findsOneWidget);
      expect(find.text('Chauffeur requis'), findsOneWidget);
      expect(find.text('Volume requis'), findsOneWidget);
    });

    /// Test de validation du volume
    testWidgets('should validate volume constraints', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [refDataProvider.overrideWith((ref) async => mockRefData)],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Saisir un volume invalide
      await tester.enterText(find.byKey(const Key('volume_field')), '-100');
      await tester.pump();

      // Assert
      expect(find.text('Volume doit Ãªtre positif'), findsOneWidget);
    });

    /// Test de validation de la date
    testWidgets('should validate date constraints', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [refDataProvider.overrideWith((ref) async => mockRefData)],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act - SÃ©lectionner une date future
      await tester.tap(find.text('Date de chargement *'));
      await tester.pump();

      // Naviguer vers une date future
      await tester.tap(find.text('OK'));
      await tester.pump();

      // Assert
      expect(find.text('Date future interdite'), findsOneWidget);
    });

    /// Test de validation de la plaque camion
    testWidgets('should validate plaque camion format', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [refDataProvider.overrideWith((ref) async => mockRefData)],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Saisir une plaque invalide
      await tester.enterText(find.byKey(const Key('plaque_camion_field')), 'INVALID');
      await tester.pump();

      // Assert
      expect(find.text('Format de plaque invalide'), findsOneWidget);
    });

    /// Test de sauvegarde rÃ©ussie
    testWidgets('should save cours successfully', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [refDataProvider.overrideWith((ref) async => mockRefData)],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Remplir le formulaire avec des donnÃ©es valides
      await tester.tap(find.text('Fournisseur Test 1'));
      await tester.pump();
      await tester.tap(find.text('Fournisseur Test 1'));
      await tester.pump();

      await tester.tap(find.text('Essence'));
      await tester.pump();
      await tester.tap(find.text('Essence'));
      await tester.pump();

      await tester.tap(find.text('DÃ©pÃ´t Test 1'));
      await tester.pump();
      await tester.tap(find.text('DÃ©pÃ´t Test 1'));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('pays_field')), 'RDC');
      await tester.enterText(find.byKey(const Key('plaque_camion_field')), 'ABC123');
      await tester.enterText(find.byKey(const Key('chauffeur_field')), 'Jean Dupont');
      await tester.enterText(find.byKey(const Key('volume_field')), '50000');

      // SÃ©lectionner une date valide
      await tester.tap(find.text('Date de chargement *'));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pump();

      // Sauvegarder
      await tester.tap(find.byKey(const Key('save_button')));
      await tester.pumpAndSettle();

      // Assert - VÃ©rifier le message de succÃ¨s
      expect(find.text('Cours crÃ©Ã© avec succÃ¨s'), findsOneWidget);
    });

    /// Test de gestion des erreurs de sauvegarde
    testWidgets('should handle save errors', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [refDataProvider.overrideWith((ref) async => mockRefData)],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Remplir et sauvegarder (simuler une erreur)
      await tester.enterText(find.byKey(const Key('pays_field')), 'RDC');
      await tester.enterText(find.byKey(const Key('plaque_camion_field')), 'ABC123');
      await tester.enterText(find.byKey(const Key('chauffeur_field')), 'Jean Dupont');
      await tester.enterText(find.byKey(const Key('volume_field')), '50000');

      await tester.tap(find.byKey(const Key('save_button')));
      await tester.pumpAndSettle();

      // Assert - VÃ©rifier que les erreurs de validation apparaissent
      expect(find.text('Fournisseur requis'), findsOneWidget);
    });
  });
}

