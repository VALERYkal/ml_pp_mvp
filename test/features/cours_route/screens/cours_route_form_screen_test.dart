// 📌 Module : Cours de Route - Tests Widget
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Tests widget pour l'écran de formulaire des cours de route

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_form_screen.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';

/// Tests widget pour l'écran de formulaire des cours de route
///
/// Ces tests vérifient :
/// - L'affichage correct de l'écran
/// - Les états de chargement et d'erreur
void main() {
  group('CoursRouteFormScreen', () {
    /// Mock des données de référence
    final mockRefData = RefDataCache(
      fournisseurs: {'f1': 'Fournisseur Test 1', 'f2': 'Fournisseur Test 2'},
      produits: {'p1': 'Essence', 'p2': 'Gasoil / AGO'},
      produitCodes: {'p1': 'ESS', 'p2': 'AGO'},
      depots: {'d1': 'Dépôt Test 1', 'd2': 'Dépôt Test 2'},
      loadedAt: DateTime.now(),
    );

    /// Test de l'affichage de l'écran avec des données
    testWidgets('affiche correctement l\'écran avec des données', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [refDataProvider.overrideWith((ref) async => mockRefData)],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      // Act - Attendre que les données se chargent
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Nouveau cours'), findsOneWidget);
      expect(find.text('Fournisseur *'), findsOneWidget);
      expect(find.text('Produit *'), findsOneWidget);
      expect(find.text('Dépôt destination'), findsOneWidget);
      expect(find.text('Pays de départ *'), findsOneWidget);
      expect(find.text('Date de chargement *'), findsOneWidget);
      expect(find.text('Plaque camion *'), findsOneWidget);
      expect(find.text('Chauffeur *'), findsOneWidget);
      expect(find.text('Volume (L) *'), findsOneWidget);
      expect(find.text('Enregistrer'), findsOneWidget);
    });

    /// Test de la validation automatique
    testWidgets('active la validation automatique', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [refDataProvider.overrideWith((ref) async => mockRefData)],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      // Act - Attendre que les données se chargent
      await tester.pumpAndSettle();

      // Assert - Vérifier que le formulaire a autovalidateMode
      final form = tester.widget<Form>(find.byType(Form));
      expect(form.autovalidateMode, AutovalidateMode.onUserInteraction);
    });

    /// Test de la protection dirty state
    testWidgets(
      'affiche une confirmation lors de la navigation arrière avec des modifications',
      (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              refDataProvider.overrideWith((ref) async => mockRefData),
            ],
            child: const MaterialApp(home: CoursRouteFormScreen()),
          ),
        );

        // Act - Attendre que les données se chargent et saisir du texte
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, 'Test');
        await tester.pump();

        // Simuler la navigation arrière
        final dynamic widgetsAppState = tester.state(find.byType(MaterialApp));
        await widgetsAppState.didPopRoute();

        // Assert - Vérifier que la confirmation s'affiche
        expect(find.text('Annuler les modifications ?'), findsOneWidget);
      },
    );

    /// Test de l'affichage de l'écran en état de chargement
    testWidgets('affiche correctement l\'état de chargement', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            refDataProvider.overrideWith((ref) async {
              await Future.delayed(const Duration(milliseconds: 100));
              return mockRefData;
            }),
          ],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      // Assert - Vérifier que le loader s'affiche
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    /// Test de l'affichage de l'écran en état d'erreur
    testWidgets('affiche correctement l\'état d\'erreur', (
      WidgetTester tester,
    ) async {
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
      expect(
        find.text('Erreur lors du chargement des référentiels'),
        findsOneWidget,
      );
      expect(find.text('Réessayer'), findsOneWidget);
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
      await tester.tap(find.text('Enregistrer'));
      await tester.pump();

      // Assert - Vérifier que les messages d'erreur apparaissent
      expect(find.text('Fournisseur requis'), findsOneWidget);
      expect(find.text('Produit requis'), findsOneWidget);
      expect(find.text('Dépôt destination requis'), findsOneWidget);
      expect(find.text('Pays requis'), findsOneWidget);
      expect(find.text('Date requise'), findsOneWidget);
      expect(find.text('Plaque camion requise'), findsOneWidget);
      expect(find.text('Chauffeur requis'), findsOneWidget);
      expect(find.text('Volume requis'), findsOneWidget);
    });

    /// Test de validation du volume
    testWidgets('should validate volume constraints', (
      WidgetTester tester,
    ) async {
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
      expect(find.text('Volume doit être positif'), findsOneWidget);
    });

    /// Test de validation de la date
    testWidgets('should validate date constraints', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [refDataProvider.overrideWith((ref) async => mockRefData)],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Sélectionner une date future
      await tester.tap(find.text('Date de chargement *'));
      await tester.pump();

      // Naviguer vers une date future
      await tester.tap(find.text('OK'));
      await tester.pump();

      // Assert
      expect(find.text('Date future interdite'), findsOneWidget);
    });

    /// Test de validation de la plaque camion
    testWidgets('should validate plaque camion format', (
      WidgetTester tester,
    ) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [refDataProvider.overrideWith((ref) async => mockRefData)],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Saisir une plaque invalide
      await tester.enterText(
        find.byKey(const Key('plaque_camion_field')),
        'INVALID',
      );
      await tester.pump();

      // Assert
      expect(find.text('Format de plaque invalide'), findsOneWidget);
    });

    /// Test de sauvegarde réussie
    testWidgets('should save cours successfully', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        ProviderScope(
          overrides: [refDataProvider.overrideWith((ref) async => mockRefData)],
          child: const MaterialApp(home: CoursRouteFormScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Act - Remplir le formulaire avec des données valides
      await tester.tap(find.text('Fournisseur Test 1'));
      await tester.pump();
      await tester.tap(find.text('Fournisseur Test 1'));
      await tester.pump();

      await tester.tap(find.text('Essence'));
      await tester.pump();
      await tester.tap(find.text('Essence'));
      await tester.pump();

      await tester.tap(find.text('Dépôt Test 1'));
      await tester.pump();
      await tester.tap(find.text('Dépôt Test 1'));
      await tester.pump();

      await tester.enterText(find.byKey(const Key('pays_field')), 'RDC');
      await tester.enterText(
        find.byKey(const Key('plaque_camion_field')),
        'ABC123',
      );
      await tester.enterText(
        find.byKey(const Key('chauffeur_field')),
        'Jean Dupont',
      );
      await tester.enterText(find.byKey(const Key('volume_field')), '50000');

      // Sélectionner une date valide
      await tester.tap(find.text('Date de chargement *'));
      await tester.pump();
      await tester.tap(find.text('OK'));
      await tester.pump();

      // Sauvegarder
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      // Assert - Vérifier le message de succès
      expect(find.text('Cours créé avec succès'), findsOneWidget);
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
      await tester.enterText(
        find.byKey(const Key('plaque_camion_field')),
        'ABC123',
      );
      await tester.enterText(
        find.byKey(const Key('chauffeur_field')),
        'Jean Dupont',
      );
      await tester.enterText(find.byKey(const Key('volume_field')), '50000');

      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      // Assert - Vérifier que les erreurs de validation apparaissent
      expect(find.text('Fournisseur requis'), findsOneWidget);
    });
  });
}
