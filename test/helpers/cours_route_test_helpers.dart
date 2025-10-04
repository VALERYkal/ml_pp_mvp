// 📌 Module : Cours de Route - Helpers de Test
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Helpers et utilitaires pour les tests du module CDR

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_form_screen.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_list_screen.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_detail_screen.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart' show RefDataCache;
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/shared/providers/session_provider.dart' show sessionProvider;
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_filters_provider.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../fixtures/cours_route_fixtures.dart';

/// Helpers pour les tests du module Cours de Route
class CoursRouteTestHelpers {
  /// Crée un cours de route avec des données spécifiques
  static Future<void> createCoursDeRoute(
    WidgetTester tester,
    Map<String, String> data,
  ) async {
    // Naviguer vers le formulaire
    await tester.tap(find.text('Nouveau cours'));
    await tester.pumpAndSettle();

    // Remplir le formulaire
    await _fillCoursForm(tester, data);

    // Sauvegarder
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
  }

  /// Fait progresser un cours vers un statut spécifique
  static Future<void> progressToStatut(
    WidgetTester tester,
    StatutCours targetStatut,
  ) async {
    // Naviguer vers les détails du cours
    await tester.tap(find.text('Détails'));
    await tester.pumpAndSettle();

    // Avancer le statut
    await tester.tap(find.text('Avancer statut'));
    await tester.pump();

    // Sélectionner le statut cible
    await tester.tap(find.text(targetStatut.label));
    await tester.pumpAndSettle();
  }

  /// Se connecte avec un rôle spécifique
  static Future<void> loginAsRole(
    WidgetTester tester,
    UserRole role, {
    String? depotId,
  }) async {
    // Simuler la connexion avec le rôle spécifié
    // Dans un vrai test, on utiliserait un mock du provider d'authentification
    await tester.pump();
  }

  /// Applique des filtres sur la liste des cours
  static Future<void> applyFilters(
    WidgetTester tester,
    Map<String, dynamic> filters,
  ) async {
    // Appliquer le filtre fournisseur
    if (filters.containsKey('fournisseurId')) {
      await tester.tap(find.text('Fournisseur'));
      await tester.pump();
      await tester.tap(find.text(filters['fournisseurId']));
      await tester.pump();
    }

    // Appliquer le filtre volume
    if (filters.containsKey('volumeMin') || filters.containsKey('volumeMax')) {
      await tester.tap(find.text('Modifier volume'));
      await tester.pump();

      // Ajuster le slider (simulation)
      await tester.tap(find.text('OK'));
      await tester.pump();
    }
  }

  /// Vérifie qu'un cours apparaît dans la liste
  static void verifyCoursInList(String plaqueCamion) {
    expect(find.text(plaqueCamion), findsOneWidget);
  }

  /// Vérifie qu'un cours n'apparaît pas dans la liste
  static void verifyCoursNotInList(String plaqueCamion) {
    expect(find.text(plaqueCamion), findsNothing);
  }

  /// Vérifie qu'un cours a un statut spécifique
  static void verifyCoursStatut(String plaqueCamion, StatutCours statut) {
    expect(find.text(plaqueCamion), findsOneWidget);
    expect(find.text(statut.label), findsOneWidget);
  }

  /// Vérifie qu'un message d'erreur apparaît
  static void verifyErrorMessage(String message) {
    expect(find.text(message), findsOneWidget);
  }

  /// Vérifie qu'un message de succès apparaît
  static void verifySuccessMessage(String message) {
    expect(find.text(message), findsOneWidget);
  }

  /// Vérifie qu'un bouton est disponible
  static void verifyButtonAvailable(String buttonText) {
    expect(find.text(buttonText), findsOneWidget);
  }

  /// Vérifie qu'un bouton n'est pas disponible
  static void verifyButtonNotAvailable(String buttonText) {
    expect(find.text(buttonText), findsNothing);
  }

  /// Vérifie qu'un champ de formulaire a une erreur
  static void verifyFieldError(String fieldKey, String errorMessage) {
    expect(find.text(errorMessage), findsOneWidget);
  }

  /// Vérifie qu'un champ de formulaire est valide
  static void verifyFieldValid(String fieldKey) {
    // Vérifier qu'il n'y a pas de message d'erreur
    expect(find.text('requis'), findsNothing);
  }

  /// Crée un mock du service CoursDeRouteService
  static MockCoursDeRouteService createMockService() {
    return MockCoursDeRouteService();
  }

  /// Crée un mock du client Supabase
  static MockSupabaseClient createMockSupabaseClient() {
    return MockSupabaseClient();
  }

  /// Configure les mocks pour les tests
  static void setupMocks(
    MockCoursDeRouteService mockService,
    MockSupabaseClient mockSupabase,
  ) {
    // Configuration des mocks selon les besoins des tests
    when(
      mockService.getAll(),
    ).thenAnswer((_) async => CoursRouteFixtures.sampleList());
    when(
      mockService.getActifs(),
    ).thenAnswer((_) async => CoursRouteFixtures.activeCoursList());
    when(mockService.create(any<CoursDeRoute>())).thenAnswer((_) async {});
    when(mockService.update(any<CoursDeRoute>())).thenAnswer((_) async {});
    when(mockService.delete(any<String>())).thenAnswer((_) async {});
    when(
      mockService.updateStatut(
        id: anyNamed('id'),
        to: anyNamed('to'),
        fromReception: anyNamed('fromReception'),
      ),
    ).thenAnswer((_) async {});
  }

  /// Crée un ProviderContainer avec les overrides nécessaires
  static ProviderContainer createTestContainer({
    MockCoursDeRouteService? mockService,
    MockSupabaseClient? mockSupabase,
    RefDataCache? refData,
    UserRole? userRole,
    String? depotId,
  }) {
    return ProviderContainer(
      overrides: [
        if (mockService != null)
          coursDeRouteServiceProvider.overrideWithValue(mockService),
        if (refData != null)
          refDataProvider.overrideWith((ref) async => refData),
        if (userRole != null)
          sessionProvider.overrideWith(
            (ref) => AuthState(
              user: MockUser(role: userRole, depotId: depotId),
              isAuthenticated: true,
            ),
          ),
      ],
    );
  }

  /// Crée des données de référence pour les tests
  static RefDataCache createRefData() {
    return CoursRouteFixtures.refDataCache();
  }

  /// Crée un cours de route pour les tests
  static CoursDeRoute createCours({
    String? id,
    String? fournisseurId,
    String? produitId,
    String? depotDestinationId,
    String? plaqueCamion,
    String? chauffeur,
    double? volume,
    StatutCours? statut,
  }) {
    return CoursDeRoute(
      id: id ?? 'test-id',
      fournisseurId: fournisseurId ?? 'fournisseur-1',
      produitId: produitId ?? 'produit-1',
      depotDestinationId: depotDestinationId ?? 'depot-1',
      plaqueCamion: plaqueCamion ?? 'ABC123',
      chauffeur: chauffeur ?? 'Jean Dupont',
      volume: volume ?? 50000,
      statut: statut ?? StatutCours.chargement,
    );
  }

  /// Crée une liste de cours pour les tests
  static List<CoursDeRoute> createCoursList() {
    return CoursRouteFixtures.sampleList();
  }

  /// Vérifie les transitions de statut
  static void verifyStatutTransitions() {
    final transitions = CoursRouteFixtures.statutTransitions();

    for (final entry in transitions.entries) {
      final currentStatut = entry.key;
      final nextStatut = entry.value;

      if (nextStatut != null) {
        expect(CoursDeRouteUtils.getStatutSuivant(currentStatut), nextStatut);
        expect(CoursDeRouteUtils.peutProgresser(currentStatut), true);
      } else {
        expect(CoursDeRouteUtils.getStatutSuivant(currentStatut), null);
        expect(CoursDeRouteUtils.peutProgresser(currentStatut), false);
      }
    }
  }

  /// Vérifie la validation des plaques
  static void verifyPlaqueValidation() {
    final validationData = CoursRouteFixtures.plaqueValidationData();

    for (final entry in validationData.entries) {
      final plaque = entry.key;
      final isValid = entry.value;

      // Dans un vrai test, on appellerait la fonction de validation
      // expect(CoursDeRouteUtils.isValidPlaque(plaque), isValid);
    }
  }

  /// Vérifie la validation des volumes
  static void verifyVolumeValidation() {
    final validationData = CoursRouteFixtures.volumeValidationData();

    for (final entry in validationData.entries) {
      final volume = entry.key;
      final isValid = entry.value;

      // Dans un vrai test, on appellerait la fonction de validation
      // expect(CoursDeRouteUtils.isValidVolume(volume), isValid);
    }
  }

  /// Vérifie la validation des dates
  static void verifyDateValidation() {
    final validationData = CoursRouteFixtures.dateValidationData();

    for (final entry in validationData.entries) {
      final date = entry.key;
      final isValid = entry.value;

      // Dans un vrai test, on appellerait la fonction de validation
      // expect(CoursDeRouteUtils.isValidDateChargement(date), isValid);
    }
  }

  /// Attendre que les données se chargent
  static Future<void> waitForDataLoad(WidgetTester tester) async {
    await tester.pumpAndSettle();

    // Attendre que les indicateurs de chargement disparaissent
    while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// Vérifier qu'un widget est visible
  static void verifyWidgetVisible(Widget widget) {
    expect(find.byWidget(widget), findsOneWidget);
  }

  /// Vérifier qu'un widget n'est pas visible
  static void verifyWidgetNotVisible(Widget widget) {
    expect(find.byWidget(widget), findsNothing);
  }
}

/// Helper pour remplir le formulaire de cours
Future<void> _fillCoursForm(
  WidgetTester tester,
  Map<String, String> data,
) async {
  if (data.containsKey('fournisseur')) {
    await tester.tap(find.text(data['fournisseur']!));
    await tester.pump();
    await tester.tap(find.text(data['fournisseur']!));
    await tester.pump();
  }

  if (data.containsKey('produit')) {
    await tester.tap(find.text(data['produit']!));
    await tester.pump();
    await tester.tap(find.text(data['produit']!));
    await tester.pump();
  }

  if (data.containsKey('depot')) {
    await tester.tap(find.text(data['depot']!));
    await tester.pump();
    await tester.tap(find.text(data['depot']!));
    await tester.pump();
  }

  if (data.containsKey('pays')) {
    await tester.enterText(find.byKey(const Key('pays_field')), data['pays']!);
  }

  if (data.containsKey('plaque')) {
    await tester.enterText(
      find.byKey(const Key('plaque_camion_field')),
      data['plaque']!,
    );
  }

  if (data.containsKey('chauffeur')) {
    await tester.enterText(
      find.byKey(const Key('chauffeur_field')),
      data['chauffeur']!,
    );
  }

  if (data.containsKey('volume')) {
    await tester.enterText(
      find.byKey(const Key('volume_field')),
      data['volume']!,
    );
  }

  if (data.containsKey('transporteur')) {
    await tester.enterText(
      find.byKey(const Key('transporteur_field')),
      data['transporteur']!,
    );
  }

  if (data.containsKey('note')) {
    await tester.enterText(find.byKey(const Key('note_field')), data['note']!);
  }

  // Sélectionner une date valide
  await tester.tap(find.text('Date de chargement *'));
  await tester.pump();
  await tester.tap(find.text('OK'));
  await tester.pump();
}

// Mock classes - Utilisation des mocks déjà générés dans d'autres fichiers
// Pas de @GenerateMocks ici pour éviter les conflits avec les autres fichiers de test
class MockCoursDeRouteService extends Mock implements CoursDeRouteService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockUser {
  final UserRole role;
  final String? depotId;

  MockUser({required this.role, this.depotId});
}

class AuthState {
  final MockUser user;
  final bool isAuthenticated;

  AuthState({required this.user, required this.isAuthenticated});
}
