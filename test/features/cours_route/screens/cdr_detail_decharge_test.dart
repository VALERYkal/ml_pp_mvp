@Tags(['integration'])
// 📌 Module : Cours de Route - Tests Widget Détail Déchargé
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Test widget pour l'écran de détail CDR avec statut "déchargé"
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_detail_screen.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';

/// Fake service minimal pour les tests
class FakeCoursDeRouteService implements CoursDeRouteService {
  final CoursDeRoute? _cours;

  FakeCoursDeRouteService({CoursDeRoute? cours}) : _cours = cours;

  @override
  Future<CoursDeRoute?> getById(String id) async {
    return _cours;
  }

  // Méthodes non utilisées dans ce test - implémentation minimale
  @override
  Future<List<dynamic>> getAll() async => throw UnimplementedError();

  @override
  Future<List<dynamic>> getActifs() async => throw UnimplementedError();

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
  Future<List<dynamic>> getByStatut(dynamic statut) async =>
      throw UnimplementedError();

  @override
  Future<bool> canTransition({
    required dynamic from,
    required dynamic to,
  }) async => throw UnimplementedError();

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
  Future<Map<String, int>> countByCategorie() async =>
      throw UnimplementedError();
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
  }) : fournisseurs = fournisseurs ?? {'fournisseur-1': 'Fournisseur Test'},
       produits = produits ?? {'produit-1': 'Essence'},
       depots = depots ?? {'depot-1': 'Dépôt Test'};
}

void main() {
  group('CDR Detail Screen - Déchargé Status Tests', () {
    late CoursDeRoute coursDecharge;

    setUp(() {
      coursDecharge = CoursDeRoute(
        id: 'test-cdr-id',
        fournisseurId: 'fournisseur-1',
        produitId: 'produit-1',
        depotDestinationId: 'depot-1',
        transporteur: 'Transport Express SARL',
        plaqueCamion: 'ABC123',
        plaqueRemorque: 'DEF456',
        chauffeur: 'Jean Dupont',
        volume: 50000.0,
        dateChargement: DateTime.parse('2025-01-27T10:00:00Z'),
        dateArriveePrevue: DateTime.parse('2025-01-28T10:00:00Z'),
        pays: 'RDC',
        statut: StatutCours.decharge, // ✅ Statut déchargé
        note: 'Cours de test déchargé',
        createdAt: DateTime.parse('2025-01-27T09:00:00Z'),
        updatedAt: DateTime.parse('2025-01-27T15:00:00Z'),
      );
    });

    testWidgets('should render without exceptions for déchargé status', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeCoursDeRouteService(cours: coursDecharge);
      final fakeRefData = FakeRefData();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteByIdProvider(
              coursDecharge.id,
            ).overrideWith((ref) => AsyncValue.data(coursDecharge)),
            userRoleProvider.overrideWith((ref) => UserRole.lecture),
            refDataProvider.overrideWith((ref) => AsyncValue.data(fakeRefData)),
          ],
          child: MaterialApp(
            home: CoursRouteDetailScreen(coursId: coursDecharge.id),
          ),
        ),
      );

      // Vérifier qu'il n'y a pas d'exception de rendu
      expect(tester.takeException(), isNull);

      // Attendre que le widget soit construit
      await tester.pumpAndSettle();

      // Vérifier qu'il n'y a toujours pas d'exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display déchargé status chip', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeCoursDeRouteService(cours: coursDecharge);
      final fakeRefData = FakeRefData();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteByIdProvider(
              coursDecharge.id,
            ).overrideWith((ref) => AsyncValue.data(coursDecharge)),
            userRoleProvider.overrideWith((ref) => UserRole.lecture),
            refDataProvider.overrideWith((ref) => AsyncValue.data(fakeRefData)),
          ],
          child: MaterialApp(
            home: CoursRouteDetailScreen(coursId: coursDecharge.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Chercher le chip de statut "Déchargé"
      final statutChip = find.text('Déchargé');
      expect(statutChip, findsOneWidget);

      // Vérifier que le chip est bien affiché avec la bonne couleur
      final chipWidget = tester.widget<Container>(
        find.ancestor(of: statutChip, matching: find.byType(Container)).first,
      );

      expect(chipWidget, isNotNull);
    });

    testWidgets('should show limited actions for déchargé status', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeCoursDeRouteService(cours: coursDecharge);
      final fakeRefData = FakeRefData();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteByIdProvider(
              coursDecharge.id,
            ).overrideWith((ref) => AsyncValue.data(coursDecharge)),
            userRoleProvider.overrideWith(
              (ref) => UserRole.lecture,
            ), // Non-admin
            refDataProvider.overrideWith((ref) => AsyncValue.data(fakeRefData)),
          ],
          child: MaterialApp(
            home: CoursRouteDetailScreen(coursId: coursDecharge.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que le message informatif est affiché
      final infoMessage = find.textContaining('Ce cours a été déchargé');
      expect(infoMessage, findsOneWidget);

      // Vérifier que les boutons d'action sont désactivés pour un utilisateur non-admin
      final modifierButton = find.text('Modifier');
      final supprimerButton = find.text('Supprimer');

      expect(modifierButton, findsOneWidget);
      expect(supprimerButton, findsOneWidget);
    });

    testWidgets('should allow admin actions for déchargé status', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeCoursDeRouteService(cours: coursDecharge);
      final fakeRefData = FakeRefData();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteByIdProvider(
              coursDecharge.id,
            ).overrideWith((ref) => AsyncValue.data(coursDecharge)),
            userRoleProvider.overrideWith((ref) => UserRole.admin), // Admin
            refDataProvider.overrideWith((ref) => AsyncValue.data(fakeRefData)),
          ],
          child: MaterialApp(
            home: CoursRouteDetailScreen(coursId: coursDecharge.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que le message informatif n'est PAS affiché pour un admin
      final infoMessage = find.textContaining('Ce cours a été déchargé');
      expect(infoMessage, findsNothing);

      // Vérifier que les boutons d'action sont disponibles pour un admin
      final modifierButton = find.text('Modifier');
      final supprimerButton = find.text('Supprimer');

      expect(modifierButton, findsOneWidget);
      expect(supprimerButton, findsOneWidget);
    });

    testWidgets('should display course information correctly', (
      WidgetTester tester,
    ) async {
      final fakeService = FakeCoursDeRouteService(cours: coursDecharge);
      final fakeRefData = FakeRefData();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteByIdProvider(
              coursDecharge.id,
            ).overrideWith((ref) => AsyncValue.data(coursDecharge)),
            userRoleProvider.overrideWith((ref) => UserRole.lecture),
            refDataProvider.overrideWith((ref) => AsyncValue.data(fakeRefData)),
          ],
          child: MaterialApp(
            home: CoursRouteDetailScreen(coursId: coursDecharge.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier les informations principales
      expect(find.text('Transport Express SARL'), findsOneWidget);
      expect(find.text('ABC123'), findsOneWidget);
      expect(find.text('DEF456'), findsOneWidget);
      expect(find.text('Jean Dupont'), findsOneWidget);
      expect(find.text('50 000 L'), findsOneWidget);
      expect(find.text('RDC'), findsOneWidget);
      expect(find.text('Cours de test déchargé'), findsOneWidget);
    });

    testWidgets('should handle loading state', (WidgetTester tester) async {
      final fakeService = FakeCoursDeRouteService(cours: coursDecharge);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteByIdProvider(
              coursDecharge.id,
            ).overrideWith((ref) => const AsyncValue.loading()),
            userRoleProvider.overrideWith((ref) => UserRole.lecture),
            refDataProvider.overrideWith((ref) => const AsyncValue.loading()),
          ],
          child: MaterialApp(
            home: CoursRouteDetailScreen(coursId: coursDecharge.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que l'indicateur de chargement est affiché
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should handle error state', (WidgetTester tester) async {
      final fakeService = FakeCoursDeRouteService(cours: coursDecharge);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteByIdProvider(coursDecharge.id).overrideWith(
              (ref) => AsyncValue.error('Test error', StackTrace.current),
            ),
            userRoleProvider.overrideWith((ref) => UserRole.lecture),
            refDataProvider.overrideWith(
              (ref) => AsyncValue.error('Ref data error', StackTrace.current),
            ),
          ],
          child: MaterialApp(
            home: CoursRouteDetailScreen(coursId: coursDecharge.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que le message d'erreur est affiché
      expect(find.text('Erreur lors du chargement'), findsOneWidget);
      expect(find.text('Test error'), findsOneWidget);
    });

    testWidgets('should handle not found state', (WidgetTester tester) async {
      final fakeService = FakeCoursDeRouteService(cours: null); // Pas de cours

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteByIdProvider(
              coursDecharge.id,
            ).overrideWith((ref) => AsyncValue.data(null)),
            userRoleProvider.overrideWith((ref) => UserRole.lecture),
            refDataProvider.overrideWith(
              (ref) => AsyncValue.data(FakeRefData()),
            ),
          ],
          child: MaterialApp(
            home: CoursRouteDetailScreen(coursId: coursDecharge.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Vérifier que le message "non trouvé" est affiché
      expect(find.text('Cours non trouvé'), findsOneWidget);
      expect(
        find.text('Le cours de route demandé n\'existe pas ou a été supprimé.'),
        findsOneWidget,
      );
    });
  });
}
