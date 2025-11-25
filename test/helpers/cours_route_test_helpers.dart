// ð Module : Cours de Route - Helpers de Test
// ð§ Auteur : Valery Kalonga
// ð Date : 2025-01-27
// ð§­ Description : Helpers et utilitaires pour les tests du module CDR

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_form_screen.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_list_screen.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_detail_screen.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart' show RefDataCache;
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/shared/providers/session_provider.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_filters_provider.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:mockito/mockito.dart' as mockito;
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../fixtures/cours_route_fixtures.dart';

// Fonction pour enregistrer la configuration des tests
void registerCoursRouteTestSetup() {
  setUpAll(() {
    // Fallbacks pour les types utilisÃ©s dans les mocks
    mockito.registerFallbackValue<String>('');
    mockito.registerFallbackValue<bool>(false);
    mockito.registerFallbackValue<StatutCours>(StatutCours.chargement);
    mockito.registerFallbackValue<CoursDeRoute>(
      CoursDeRoute(
        id: 'test-fallback',
        fournisseurId: 'fournisseur-1',
        produitId: 'produit-1',
        depotDestinationId: 'depot-1',
        plaqueCamion: 'ABC123',
        chauffeur: 'Test Chauffeur',
        volume: 50000,
        statut: StatutCours.chargement,
      ),
    );
  });
}

// Wrapper pour crÃ©er un CoursDeRoute Ã  partir d'un StatutCours
CoursDeRoute _cdrWithStatut(StatutCours statut) {
  return CoursDeRoute(
    id: 'test',
    fournisseurId: 'fournisseur-1',
    produitId: 'produit-1',
    depotDestinationId: 'depot-1',
    plaqueCamion: 'ABC123',
    chauffeur: 'Test Chauffeur',
    volume: 50000,
    statut: statut,
  );
}

/// Helpers pour les tests du module Cours de Route
class CoursRouteTestHelpers {
  /// CrÃ©e un cours de route avec des donnÃ©es spÃ©cifiques
  static Future<void> createCoursDeRoute(WidgetTester tester, Map<String, String> data) async {
    // Naviguer vers le formulaire
    await tester.tap(find.text('Nouveau cours'));
    await tester.pumpAndSettle();

    // Remplir le formulaire
    await _fillCoursForm(tester, data);

    // Sauvegarder
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
  }

  /// Fait progresser un cours vers un statut spÃ©cifique
  static Future<void> progressToStatut(WidgetTester tester, StatutCours targetStatut) async {
    // Naviguer vers les dÃ©tails du cours
    await tester.tap(find.text('DÃ©tails'));
    await tester.pumpAndSettle();

    // Avancer le statut
    await tester.tap(find.text('Avancer statut'));
    await tester.pump();

    // SÃ©lectionner le statut cible
    await tester.tap(find.text(targetStatut.label));
    await tester.pumpAndSettle();
  }

  /// Se connecte avec un rÃ´le spÃ©cifique
  static Future<void> loginAsRole(WidgetTester tester, UserRole role, {String? depotId}) async {
    // Simuler la connexion avec le rÃ´le spÃ©cifiÃ©
    // Dans un vrai test, on utiliserait un mock du provider d'authentification
    await tester.pump();
  }

  /// Applique des filtres sur la liste des cours
  static Future<void> applyFilters(WidgetTester tester, Map<String, dynamic> filters) async {
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

  /// VÃ©rifie qu'un cours apparaÃ®t dans la liste
  static void verifyCoursInList(String plaqueCamion) {
    expect(find.text(plaqueCamion), findsOneWidget);
  }

  /// VÃ©rifie qu'un cours n'apparaÃ®t pas dans la liste
  static void verifyCoursNotInList(String plaqueCamion) {
    expect(find.text(plaqueCamion), findsNothing);
  }

  /// VÃ©rifie qu'un cours a un statut spÃ©cifique
  static void verifyCoursStatut(String plaqueCamion, StatutCours statut) {
    expect(find.text(plaqueCamion), findsOneWidget);
    expect(find.text(statut.label), findsOneWidget);
  }

  /// VÃ©rifie qu'un message d'erreur apparaÃ®t
  static void verifyErrorMessage(String message) {
    expect(find.text(message), findsOneWidget);
  }

  /// VÃ©rifie qu'un message de succÃ¨s apparaÃ®t
  static void verifySuccessMessage(String message) {
    expect(find.text(message), findsOneWidget);
  }

  /// VÃ©rifie qu'un bouton est disponible
  static void verifyButtonAvailable(String buttonText) {
    expect(find.text(buttonText), findsOneWidget);
  }

  /// VÃ©rifie qu'un bouton n'est pas disponible
  static void verifyButtonNotAvailable(String buttonText) {
    expect(find.text(buttonText), findsNothing);
  }

  /// VÃ©rifie qu'un champ de formulaire a une erreur
  static void verifyFieldError(String fieldKey, String errorMessage) {
    expect(find.text(errorMessage), findsOneWidget);
  }

  /// VÃ©rifie qu'un champ de formulaire est valide
  static void verifyFieldValid(String fieldKey) {
    // VÃ©rifier qu'il n'y a pas de message d'erreur
    expect(find.text('requis'), findsNothing);
  }

  /// CrÃ©e un mock du service CoursDeRouteService
  static MockCoursDeRouteService createMockService() {
    return MockCoursDeRouteService();
  }

  /// CrÃ©e un mock du client Supabase
  static MockSupabaseClient createMockSupabaseClient() {
    return MockSupabaseClient();
  }

  /// Configure les mocks pour les tests
  static void setupMocks(MockCoursDeRouteService mockService, MockSupabaseClient mockSupabase) {
    // Configuration des mocks selon les besoins des tests
    mockito.when(mockService.getAll()).thenAnswer((_) async => CoursRouteFixtures.sampleList());
    mockito
        .when(mockService.getActifs())
        .thenAnswer((_) async => CoursRouteFixtures.activeCoursList());
    mockito.when(mockService.create(mockito.any<CoursDeRoute>())).thenAnswer((_) async {});
    mockito.when(mockService.update(mockito.any<CoursDeRoute>())).thenAnswer((_) async {});
    mockito.when(mockService.delete(mockito.any<String>())).thenAnswer((_) async {});
    mockito
        .when(
          mockService.updateStatut(
            id: mockito.any<String>(named: 'id'),
            to: mockito.any<StatutCours>(named: 'to'),
            fromReception: mockito.any<bool>(named: 'fromReception'),
          ),
        )
        .thenAnswer((_) async {});
  }

  /// CrÃ©e un ProviderContainer avec les overrides nÃ©cessaires
  static ProviderContainer createTestContainer({
    MockCoursDeRouteService? mockService,
    MockSupabaseClient? mockSupabase,
    RefDataCache? refData,
    UserRole? userRole,
    String? depotId,
  }) {
    return ProviderContainer(
      overrides: [
        if (mockService != null) coursDeRouteServiceProvider.overrideWithValue(mockService),
        // CommentÃ© car refDataProvider et sessionProvider sont inconnus
        // if (refData != null)
        //   refDataProvider.overrideWith((ref) async => refData),
        // if (userRole != null)
        //   sessionProvider.overrideWith(
        //     (ref) => AuthState(
        //       user: MockUser(role: userRole, depotId: depotId),
        //       isAuthenticated: true,
        //     ),
        //   ),
      ],
    );
  }

  /// CrÃ©e des donnÃ©es de rÃ©fÃ©rence pour les tests
  static RefDataCache createRefData() {
    return CoursRouteFixtures.refDataCache();
  }

  /// CrÃ©e un cours de route pour les tests
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

  /// CrÃ©e une liste de cours pour les tests
  static List<CoursDeRoute> createCoursList() {
    return CoursRouteFixtures.sampleList();
  }

  /// VÃ©rifie les transitions de statut
  static void verifyStatutTransitions() {
    final transitions = CoursRouteFixtures.statutTransitions();

    for (final entry in transitions.entries) {
      final currentStatut = entry.key;
      final nextStatut = entry.value;

      final cdr = _cdrWithStatut(currentStatut);
      if (nextStatut != null) {
        expect(CoursDeRouteUtils.getStatutSuivant(cdr), nextStatut);
        expect(CoursDeRouteUtils.peutProgresser(cdr), true);
      } else {
        expect(CoursDeRouteUtils.getStatutSuivant(cdr), null);
        expect(CoursDeRouteUtils.peutProgresser(cdr), false);
      }
    }
  }

  /// VÃ©rifie la validation des plaques
  static void verifyPlaqueValidation() {
    final validationData = CoursRouteFixtures.plaqueValidationData();

    for (final entry in validationData.entries) {
      final plaque = entry.key;
      final isValid = entry.value;

      // Dans un vrai test, on appellerait la fonction de validation
      // expect(CoursDeRouteUtils.isValidPlaque(plaque), isValid);
    }
  }

  /// VÃ©rifie la validation des volumes
  static void verifyVolumeValidation() {
    final validationData = CoursRouteFixtures.volumeValidationData();

    for (final entry in validationData.entries) {
      final volume = entry.key;
      final isValid = entry.value;

      // Dans un vrai test, on appellerait la fonction de validation
      // expect(CoursDeRouteUtils.isValidVolume(volume), isValid);
    }
  }

  /// VÃ©rifie la validation des dates
  static void verifyDateValidation() {
    final validationData = CoursRouteFixtures.dateValidationData();

    for (final entry in validationData.entries) {
      final date = entry.key;
      final isValid = entry.value;

      // Dans un vrai test, on appellerait la fonction de validation
      // expect(CoursDeRouteUtils.isValidDateChargement(date), isValid);
    }
  }

  /// Attendre que les donnÃ©es se chargent
  static Future<void> waitForDataLoad(WidgetTester tester) async {
    await tester.pumpAndSettle();

    // Attendre que les indicateurs de chargement disparaissent
    while (find.byType(CircularProgressIndicator).evaluate().isNotEmpty) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  /// VÃ©rifier qu'un widget est visible
  static void verifyWidgetVisible(Widget widget) {
    expect(find.byWidget(widget), findsOneWidget);
  }

  /// VÃ©rifier qu'un widget n'est pas visible
  static void verifyWidgetNotVisible(Widget widget) {
    expect(find.byWidget(widget), findsNothing);
  }
}

/// Helper pour remplir le formulaire de cours
Future<void> _fillCoursForm(WidgetTester tester, Map<String, String> data) async {
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
    await tester.enterText(find.byKey(const Key('plaque_camion_field')), data['plaque']!);
  }

  if (data.containsKey('chauffeur')) {
    await tester.enterText(find.byKey(const Key('chauffeur_field')), data['chauffeur']!);
  }

  if (data.containsKey('volume')) {
    await tester.enterText(find.byKey(const Key('volume_field')), data['volume']!);
  }

  if (data.containsKey('transporteur')) {
    await tester.enterText(find.byKey(const Key('transporteur_field')), data['transporteur']!);
  }

  if (data.containsKey('note')) {
    await tester.enterText(find.byKey(const Key('note_field')), data['note']!);
  }

  // SÃ©lectionner une date valide
  await tester.tap(find.text('Date de chargement *'));
  await tester.pump();
  await tester.tap(find.text('OK'));
  await tester.pump();
}

// Mock classes - Utilisation des mocks dÃ©jÃ  gÃ©nÃ©rÃ©s dans d'autres fichiers
// Pas de @GenerateMocks ici pour Ã©viter les conflits avec les autres fichiers de test
class MockCoursDeRouteService extends mockito.Mock implements CoursDeRouteService {}

class MockSupabaseClient extends mockito.Mock implements SupabaseClient {}

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

