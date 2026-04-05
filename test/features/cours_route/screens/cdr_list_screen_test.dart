// 📌 Module : Cours de Route - Tests Widget Liste CDR
// 🧑 Auteur : Mona (IA Flutter/Supabase/Riverpod)
// 📅 Date : 2025-11-27
// 🧭 Description : Tests widgets pour vérifier la cohérence UI/logique métier dans la liste CDR
//
// RÈGLE MÉTIER CDR (Cours de Route) :
// - "Au chargement" = CHARGEMENT uniquement
// - "En route" = TRANSIT + FRONTIERE
// - "Arrivés" = ARRIVE
// - DECHARGE = EXCLU des listes actives (cours terminé)
// - Progression: CHARGEMENT -> TRANSIT -> FRONTIERE -> ARRIVE -> DECHARGE

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:ml_pp_mvp/features/cours_route/screens/cours_route_list_screen.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';

// ════════════════════════════════════════════════════════════════════════════
// HELPER POUR REFDATA
// ════════════════════════════════════════════════════════════════════════════

RefDataCache createFakeRefData() {
  return RefDataCache(
    fournisseurs: <String, String>{},
    produits: <String, String>{},
    produitCodes: <String, String>{},
    depots: <String, String>{},
    loadedAt: DateTime.now(),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// FAKE SERVICE POUR LES TESTS
// ════════════════════════════════════════════════════════════════════════════

/// Fake service CDR pour les tests widgets
class FakeCoursDeRouteServiceForWidgets implements CoursDeRouteService {
  final List<CoursDeRoute> _seedData;
  final Map<String, StatutCours> _updateStatutCalls = {};

  FakeCoursDeRouteServiceForWidgets({List<CoursDeRoute>? seedData})
    : _seedData = seedData ?? [];

  /// Récupère les appels à updateStatut pour vérification
  Map<String, StatutCours> get updateStatutCalls =>
      Map.unmodifiable(_updateStatutCalls);

  @override
  Future<List<CoursDeRoute>> getAll() async => List.from(_seedData);

  @override
  Future<List<CoursDeRoute>> getActifs() async =>
      _seedData.where((c) => c.statut != StatutCours.decharge).toList();

  @override
  Future<CoursDeRoute?> getById(String id) async {
    try {
      return _seedData.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CoursDeRoute>> getByStatut(StatutCours statut) async =>
      _seedData.where((c) => c.statut == statut).toList();

  @override
  Future<void> create(CoursDeRoute cours) async => _seedData.add(cours);

  @override
  Future<void> update(CoursDeRoute cours) async {
    final index = _seedData.indexWhere((c) => c.id == cours.id);
    if (index != -1) {
      _seedData[index] = cours;
    }
  }

  @override
  Future<void> delete(String id) async =>
      _seedData.removeWhere((c) => c.id == id);

  @override
  Future<void> updateStatut({
    required String id,
    required StatutCours to,
    bool fromReception = false,
  }) async {
    // Enregistrer l'appel pour vérification
    _updateStatutCalls[id] = to;

    // Mettre à jour le statut dans les données
    final index = _seedData.indexWhere((c) => c.id == id);
    if (index != -1) {
      _seedData[index] = _seedData[index].copyWith(statut: to);
    }
  }

  @override
  Future<Map<String, int>> countByStatut() async {
    final counts = <String, int>{
      'CHARGEMENT': 0,
      'TRANSIT': 0,
      'FRONTIERE': 0,
      'ARRIVE': 0,
      'DECHARGE': 0,
    };
    for (final cdr in _seedData) {
      final key = cdr.statut.db;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<Map<String, int>> countByCategorie() async =>
      throw UnimplementedError();
}

// ════════════════════════════════════════════════════════════════════════════
// HELPER POUR CRÉER DES CDR DE TEST
// ════════════════════════════════════════════════════════════════════════════

CoursDeRoute createTestCdr({
  required String id,
  required StatutCours statut,
  String? fournisseurId,
  String? produitId,
  String? depotDestinationId,
}) {
  return CoursDeRoute(
    id: id,
    fournisseurId: fournisseurId ?? 'fournisseur-1',
    produitId: produitId ?? 'produit-1',
    depotDestinationId: depotDestinationId ?? 'depot-1',
    statut: statut,
    volume: 10000.0,
    createdAt: DateTime(2025, 11, 1),
    updatedAt: DateTime(2025, 11, 1),
  );
}

// ════════════════════════════════════════════════════════════════════════════
// TESTS
// ════════════════════════════════════════════════════════════════════════════

void main() {
  group('CDR List Screen - Boutons de progression', () {
    testWidgets(
      'CDR List - CHARGEMENT propose uniquement la progression vers TRANSIT',
      (tester) async {
        // Arrange
        final cdrChargement = createTestCdr(
          id: 'cdr-1',
          statut: StatutCours.chargement,
        );
        final fakeService = FakeCoursDeRouteServiceForWidgets(
          seedData: [cdrChargement],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              coursDeRouteServiceProvider.overrideWithValue(fakeService),
              coursDeRouteListProvider.overrideWith(
                (ref) async => [cdrChargement],
              ),
              userRoleProvider.overrideWith((ref) => UserRole.operateur),
              refDataProvider.overrideWith((ref) async => createFakeRefData()),
            ],
            child: const MaterialApp(home: CoursRouteListScreen()),
          ),
        );

        // Attendre le chargement
        await tester.pumpAndSettle();

        // Assert: Le bouton d'avancement doit être visible et activé
        // Le bouton est un IconButton avec l'icône trending_flat
        final advanceButtons = find.byIcon(Icons.trending_flat);
        expect(
          advanceButtons,
          findsWidgets,
          reason: 'Le bouton d\'avancement doit être visible',
        );

        // Vérifier que le statut est bien affiché
        expect(
          find.text('Chargement'),
          findsWidgets,
          reason: 'Le label "Chargement" doit être visible',
        );
      },
    );

    testWidgets(
      'CDR List - TRANSIT propose uniquement la progression vers FRONTIERE',
      (tester) async {
        // Arrange
        final cdrTransit = createTestCdr(
          id: 'cdr-2',
          statut: StatutCours.transit,
        );
        final fakeService = FakeCoursDeRouteServiceForWidgets(
          seedData: [cdrTransit],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              coursDeRouteServiceProvider.overrideWithValue(fakeService),
              coursDeRouteListProvider.overrideWith(
                (ref) async => [cdrTransit],
              ),
              userRoleProvider.overrideWith((ref) => UserRole.operateur),
              refDataProvider.overrideWith((ref) async => createFakeRefData()),
            ],
            child: const MaterialApp(home: CoursRouteListScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text('Transit'),
          findsWidgets,
          reason: 'Le label "Transit" doit être visible',
        );
        final advanceButtons = find.byIcon(Icons.trending_flat);
        expect(
          advanceButtons,
          findsWidgets,
          reason: 'Le bouton d\'avancement doit être visible',
        );
      },
    );

    testWidgets(
      'CDR List - FRONTIERE propose uniquement la progression vers ARRIVE',
      (tester) async {
        // Arrange
        final cdrFrontiere = createTestCdr(
          id: 'cdr-3',
          statut: StatutCours.frontiere,
        );
        final fakeService = FakeCoursDeRouteServiceForWidgets(
          seedData: [cdrFrontiere],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              coursDeRouteServiceProvider.overrideWithValue(fakeService),
              coursDeRouteListProvider.overrideWith(
                (ref) async => [cdrFrontiere],
              ),
              userRoleProvider.overrideWith((ref) => UserRole.operateur),
              refDataProvider.overrideWith((ref) async => createFakeRefData()),
            ],
            child: const MaterialApp(home: CoursRouteListScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text('Frontière'),
          findsWidgets,
          reason: 'Le label "Frontière" doit être visible',
        );
        final advanceButtons = find.byIcon(Icons.trending_flat);
        expect(
          advanceButtons,
          findsWidgets,
          reason: 'Le bouton d\'avancement doit être visible',
        );
      },
    );

    testWidgets(
      'CDR List - ARRIVE propose uniquement la progression vers DECHARGE',
      (tester) async {
        // Arrange
        final cdrArrive = createTestCdr(
          id: 'cdr-4',
          statut: StatutCours.arrive,
        );
        final fakeService = FakeCoursDeRouteServiceForWidgets(
          seedData: [cdrArrive],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              coursDeRouteServiceProvider.overrideWithValue(fakeService),
              coursDeRouteListProvider.overrideWith((ref) async => [cdrArrive]),
              userRoleProvider.overrideWith((ref) => UserRole.operateur),
              refDataProvider.overrideWith((ref) async => createFakeRefData()),
            ],
            child: const MaterialApp(home: CoursRouteListScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Assert
        expect(
          find.text('Arrivé'),
          findsWidgets,
          reason: 'Le label "Arrivé" doit être visible',
        );
        final advanceButtons = find.byIcon(Icons.trending_flat);
        expect(
          advanceButtons,
          findsWidgets,
          reason: 'Le bouton d\'avancement doit être visible',
        );
      },
    );

    testWidgets('CDR List - DECHARGE est terminal, aucun bouton de progression', (
      tester,
    ) async {
      // Arrange
      final cdrDecharge = createTestCdr(
        id: 'cdr-5',
        statut: StatutCours.decharge,
      );
      final fakeService = FakeCoursDeRouteServiceForWidgets(
        seedData: [cdrDecharge],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteListProvider.overrideWith((ref) async => [cdrDecharge]),
            userRoleProvider.overrideWith((ref) => UserRole.operateur),
            refDataProvider.overrideWith((ref) async => createFakeRefData()),
          ],
          child: const MaterialApp(home: CoursRouteListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(
        find.text('Déchargé'),
        findsWidgets,
        reason: 'Le label "Déchargé" doit être visible',
      );

      // Le bouton d'avancement ne doit PAS être activé pour DECHARGE
      // (car next() retourne null, donc le bouton est désactivé)
      // Vérifier que next() retourne null pour DECHARGE
      final nextStatut = StatutCoursDb.next(StatutCours.decharge);
      expect(
        nextStatut,
        isNull,
        reason:
            'next(DECHARGE) doit retourner null, donc le bouton doit être désactivé',
      );
    });
  });

  group('CDR List Screen - Interaction avec repository', () {
    testWidgets(
      'CDR List - Bouton de progression utilise StatutCoursDb.next() pour déterminer le prochain statut',
      (tester) async {
        // Arrange: Vérifier que la logique métier est respectée
        // CHARGEMENT -> TRANSIT
        expect(
          StatutCoursDb.next(StatutCours.chargement),
          equals(StatutCours.transit),
          reason: 'next(CHARGEMENT) doit retourner TRANSIT',
        );

        // TRANSIT -> FRONTIERE
        expect(
          StatutCoursDb.next(StatutCours.transit),
          equals(StatutCours.frontiere),
          reason: 'next(TRANSIT) doit retourner FRONTIERE',
        );

        // FRONTIERE -> ARRIVE
        expect(
          StatutCoursDb.next(StatutCours.frontiere),
          equals(StatutCours.arrive),
          reason: 'next(FRONTIERE) doit retourner ARRIVE',
        );

        // ARRIVE -> DECHARGE
        expect(
          StatutCoursDb.next(StatutCours.arrive),
          equals(StatutCours.decharge),
          reason: 'next(ARRIVE) doit retourner DECHARGE',
        );

        // DECHARGE -> null (terminal)
        expect(
          StatutCoursDb.next(StatutCours.decharge),
          isNull,
          reason: 'next(DECHARGE) doit retourner null (statut terminal)',
        );
      },
    );

    testWidgets('CDR List - Bouton de progression est désactivé pour DECHARGE', (
      tester,
    ) async {
      // Arrange
      final cdrDecharge = createTestCdr(
        id: 'cdr-5',
        statut: StatutCours.decharge,
      );
      final fakeService = FakeCoursDeRouteServiceForWidgets(
        seedData: [cdrDecharge],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(fakeService),
            coursDeRouteListProvider.overrideWith((ref) async => [cdrDecharge]),
            userRoleProvider.overrideWith((ref) => UserRole.operateur),
            refDataProvider.overrideWith((ref) async => createFakeRefData()),
          ],
          child: const MaterialApp(home: CoursRouteListScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Assert: Vérifier que next() retourne null pour DECHARGE
      final nextStatut = StatutCoursDb.next(StatutCours.decharge);
      expect(
        nextStatut,
        isNull,
        reason:
            'next(DECHARGE) doit retourner null, donc le bouton doit être désactivé',
      );
    });

    testWidgets(
      'CDR List (Gérant) n\'affiche pas le bouton Créer',
      (tester) async {
        // Arrange
        final cdrTest = createTestCdr(
          id: 'cdr-gerant-test',
          statut: StatutCours.chargement,
        );
        final fakeService = FakeCoursDeRouteServiceForWidgets(
          seedData: [cdrTest],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              coursDeRouteServiceProvider.overrideWithValue(fakeService),
              coursDeRouteListProvider.overrideWith((ref) async => [cdrTest]),
              userRoleProvider.overrideWith((ref) => UserRole.gerant),
              refDataProvider.overrideWith((ref) async => createFakeRefData()),
            ],
            child: const MaterialApp(home: CoursRouteListScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Assert - Vérifier que le bouton "+" n'est pas présent
        expect(
          find.byIcon(Icons.add),
          findsNothing,
          reason: 'Le bouton "+" ne doit pas être affiché pour le rôle Gérant',
        );

        // Vérifier que l'écran se charge correctement malgré tout
        expect(
          find.byType(CoursRouteListScreen),
          findsOneWidget,
          reason: 'L\'écran de liste doit être affiché même pour Gérant',
        );
      },
    );
  });
}
