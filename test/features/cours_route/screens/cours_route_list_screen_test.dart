@Tags(['integration'])
// 📌 Module : Cours de Route - Tests Widget Liste
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Test widget pour l'écran de liste CDR avec filtres par statut
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_list_screen.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_filters_provider.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';

/// Fake service minimal pour les tests de liste
class FakeCoursDeRouteService implements CoursDeRouteService {
  final List<CoursDeRoute> _cours;

  FakeCoursDeRouteService({List<CoursDeRoute>? cours})
    : _cours = cours ?? _createDefaultCoursList();

  static List<CoursDeRoute> _createDefaultCoursList() {
    return [
      CoursDeRoute(
        id: 'cdr-1',
        fournisseurId: 'fournisseur-1',
        produitId: 'produit-1',
        depotDestinationId: 'depot-1',
        transporteur: 'Transport Express',
        plaqueCamion: 'ABC123',
        chauffeur: 'Jean Dupont',
        volume: 50000.0,
        statut: StatutCours.chargement,
        createdAt: DateTime.parse('2025-01-27T10:00:00Z'),
      ),
      CoursDeRoute(
        id: 'cdr-2',
        fournisseurId: 'fournisseur-2',
        produitId: 'produit-2',
        depotDestinationId: 'depot-1',
        transporteur: 'Transport Rapide',
        plaqueCamion: 'DEF456',
        chauffeur: 'Marie Martin',
        volume: 30000.0,
        statut: StatutCours.transit,
        createdAt: DateTime.parse('2025-01-27T11:00:00Z'),
      ),
      CoursDeRoute(
        id: 'cdr-3',
        fournisseurId: 'fournisseur-1',
        produitId: 'produit-1',
        depotDestinationId: 'depot-2',
        transporteur: 'Transport Express',
        plaqueCamion: 'GHI789',
        chauffeur: 'Pierre Durand',
        volume: 45000.0,
        statut: StatutCours.decharge, // ✅ Cours déchargé pour le test
        createdAt: DateTime.parse('2025-01-27T12:00:00Z'),
      ),
      CoursDeRoute(
        id: 'cdr-4',
        fournisseurId: 'fournisseur-3',
        produitId: 'produit-3',
        depotDestinationId: 'depot-1',
        transporteur: 'Transport Pro',
        plaqueCamion: 'JKL012',
        chauffeur: 'Sophie Bernard',
        volume: 60000.0,
        statut: StatutCours.frontiere,
        createdAt: DateTime.parse('2025-01-27T13:00:00Z'),
      ),
    ];
  }

  @override
  Future<List<CoursDeRoute>> getAll() async {
    return _cours;
  }

  @override
  Future<List<CoursDeRoute>> getActifs() async {
    return _cours.where((c) => c.statut != StatutCours.decharge).toList();
  }

  // Méthodes non utilisées dans ce test - implémentation minimale
  @override
  Future<CoursDeRoute?> getById(String id) async => throw UnimplementedError();

  @override
  Future<void> create(dynamic cours) async => throw UnimplementedError();

  @override
  Future<void> update(dynamic cours) async => throw UnimplementedError();

  @override
  Future<void> delete(String id) async => throw UnimplementedError();

  @override
  Future<void> updateStatut({
    required String id,
    required dynamic to,
    bool fromReception = false,
  }) async => throw UnimplementedError();

  @override
  Future<List<dynamic>> getByStatut(dynamic statut) async => throw UnimplementedError();

  @override
  Future<bool> canTransition({required dynamic from, required dynamic to}) async =>
      throw UnimplementedError();

  @override
  Future<bool> applyTransition({
    required String cdrId,
    required dynamic from,
    required dynamic to,
    String? userId,
  }) async => throw UnimplementedError();

  @override
  Future<Map<String, int>> countByStatut() async => throw UnimplementedError();

  @override
  Future<Map<String, int>> countByCategorie() async => throw UnimplementedError();
}

/// Fake ref data pour les tests
class FakeRefData {
  final Map<String, String> fournisseurs;
  final Map<String, String> produits;
  final Map<String, String> depots;

  FakeRefData({
    Map<String, String>? fournisseurs,
    Map<String, String>? produits,
    Map<String, String>? depots,
  }) : fournisseurs =
           fournisseurs ??
           {
             'fournisseur-1': 'Fournisseur Test 1',
             'fournisseur-2': 'Fournisseur Test 2',
             'fournisseur-3': 'Fournisseur Test 3',
           },
       produits =
           produits ?? {'produit-1': 'Essence', 'produit-2': 'Diesel', 'produit-3': 'Kérosène'},
       depots = depots ?? {'depot-1': 'Dépôt Central', 'depot-2': 'Dépôt Nord'};
}

void main() {
  group('CDR List Screen Tests', () {
    late FakeCoursDeRouteService fakeService;
    late FakeRefData fakeRefData;

    setUp(() {
      fakeService = FakeCoursDeRouteService();
      fakeRefData = FakeRefData();
    });

    testWidgets('should render list screen without exceptions', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteListProvider.overrideWith((ref) => AsyncValue.data(fakeService._cours)),
            userRoleProvider.overrideWith((ref) => UserRole.lecture),
            refDataProvider.overrideWith((ref) => AsyncValue.data(fakeRefData)),
          ],
          child: MaterialApp(home: const CoursRouteListScreen()),
        ),
      );

      // Vérifier qu'il n'y a pas d'exception de rendu
      expect(tester.takeException(), isNull);

      // Attendre que le widget soit construit
      await tester.pumpAndSettle();

      // Vérifier qu'il n'y a toujours pas d'exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display all courses by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteListProvider.overrideWith((ref) => AsyncValue.data(fakeService._cours)),
            userRoleProvider.overrideWith((ref) => UserRole.lecture),
            refDataProvider.overrideWith((ref) => AsyncValue.data(fakeRefData)),
          ],
          child: MaterialApp(home: const CoursRouteListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que tous les cours sont affichés
      expect(find.text('ABC123'), findsOneWidget); // cdr-1
      expect(find.text('DEF456'), findsOneWidget); // cdr-2
      expect(find.text('GHI789'), findsOneWidget); // cdr-3 (déchargé)
      expect(find.text('JKL012'), findsOneWidget); // cdr-4
    });

    testWidgets('should filter by déchargé status', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteListProvider.overrideWith((ref) => AsyncValue.data(fakeService._cours)),
            userRoleProvider.overrideWith((ref) => UserRole.lecture),
            refDataProvider.overrideWith((ref) => AsyncValue.data(fakeRefData)),
            // Override du filtre pour ne montrer que les cours déchargés
            coursFiltersProvider.overrideWith((ref) => CoursFilters(statut: StatutCours.decharge)),
          ],
          child: MaterialApp(home: const CoursRouteListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que seul le cours déchargé est affiché
      expect(find.text('GHI789'), findsOneWidget); // cdr-3 (déchargé)

      // Vérifier que les autres cours ne sont pas affichés
      expect(find.text('ABC123'), findsNothing); // cdr-1
      expect(find.text('DEF456'), findsNothing); // cdr-2
      expect(find.text('JKL012'), findsNothing); // cdr-4
    });

    testWidgets('should display status chips correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteListProvider.overrideWith((ref) => AsyncValue.data(fakeService._cours)),
            userRoleProvider.overrideWith((ref) => UserRole.lecture),
            refDataProvider.overrideWith((ref) => AsyncValue.data(fakeRefData)),
          ],
          child: MaterialApp(home: const CoursRouteListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que les chips de statut sont affichés
      expect(find.text('Chargement'), findsOneWidget);
      expect(find.text('Transit'), findsOneWidget);
      expect(find.text('Déchargé'), findsOneWidget);
      expect(find.text('Frontière'), findsOneWidget);
    });

    testWidgets('should handle empty list', (WidgetTester tester) async {
      final emptyService = FakeCoursDeRouteService(cours: []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(emptyService),
            coursDeRouteListProvider.overrideWith((ref) => AsyncValue.data([])),
            userRoleProvider.overrideWith((ref) => UserRole.lecture),
            refDataProvider.overrideWith((ref) => AsyncValue.data(fakeRefData)),
          ],
          child: MaterialApp(home: const CoursRouteListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier qu'un message approprié est affiché pour la liste vide
      expect(find.textContaining('Aucun cours'), findsOneWidget);
    });

    testWidgets('should handle loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteListProvider.overrideWith((ref) => const AsyncValue.loading()),
            userRoleProvider.overrideWith((ref) => UserRole.lecture),
            refDataProvider.overrideWith((ref) => const AsyncValue.loading()),
          ],
          child: MaterialApp(home: const CoursRouteListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que l'indicateur de chargement est affiché
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle error state', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteListProvider.overrideWith(
              (ref) => AsyncValue.error('Test error', StackTrace.current),
            ),
            userRoleProvider.overrideWith((ref) => UserRole.lecture),
            refDataProvider.overrideWith(
              (ref) => AsyncValue.error('Ref data error', StackTrace.current),
            ),
          ],
          child: MaterialApp(home: const CoursRouteListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que le message d'erreur est affiché
      expect(find.textContaining('Erreur'), findsOneWidget);
      expect(find.text('Test error'), findsOneWidget);
    });

    testWidgets('should show create button for authenticated users', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteListProvider.overrideWith((ref) => AsyncValue.data(fakeService._cours)),
            userRoleProvider.overrideWith((ref) => UserRole.lecture),
            refDataProvider.overrideWith((ref) => AsyncValue.data(fakeRefData)),
          ],
          child: MaterialApp(home: const CoursRouteListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que le bouton de création est présent
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should display course information correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteListProvider.overrideWith((ref) => AsyncValue.data(fakeService._cours)),
            userRoleProvider.overrideWith((ref) => UserRole.lecture),
            refDataProvider.overrideWith((ref) => AsyncValue.data(fakeRefData)),
          ],
          child: MaterialApp(home: const CoursRouteListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier les informations des cours
      expect(find.text('Transport Express'), findsNWidgets(2)); // cdr-1 et cdr-3
      expect(find.text('Transport Rapide'), findsOneWidget); // cdr-2
      expect(find.text('Transport Pro'), findsOneWidget); // cdr-4

      expect(find.text('Jean Dupont'), findsOneWidget);
      expect(find.text('Marie Martin'), findsOneWidget);
      expect(find.text('Pierre Durand'), findsOneWidget);
      expect(find.text('Sophie Bernard'), findsOneWidget);
    });

    testWidgets('should filter by multiple statuses', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteListProvider.overrideWith((ref) => AsyncValue.data(fakeService._cours)),
            userRoleProvider.overrideWith((ref) => UserRole.lecture),
            refDataProvider.overrideWith((ref) => AsyncValue.data(fakeRefData)),
            // Override du filtre pour montrer chargement et transit
            coursFiltersProvider.overrideWith(
              (ref) => CoursFilters(statuts: {StatutCours.chargement, StatutCours.transit}),
            ),
          ],
          child: MaterialApp(home: const CoursRouteListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que seuls les cours en chargement et transit sont affichés
      expect(find.text('ABC123'), findsOneWidget); // cdr-1 (chargement)
      expect(find.text('DEF456'), findsOneWidget); // cdr-2 (transit)

      // Vérifier que les autres cours ne sont pas affichés
      expect(find.text('GHI789'), findsNothing); // cdr-3 (déchargé)
      expect(find.text('JKL012'), findsNothing); // cdr-4 (frontière)
    });
  });
}
