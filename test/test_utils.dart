// 📌 Module : Utilitaires de Test
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Utilitaires de test pour les tests CDR

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';

/// Helper pour pomper un widget avec les providers nécessaires
/// 
/// [tester] : Le WidgetTester Flutter
/// [child] : Le widget à tester
/// [overrides] : Overrides supplémentaires pour les providers
/// [router] : Configuration du routeur (optionnel)
Future<void> pumpWithProviders(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
  GoRouter? router,
}) async {
  final defaultOverrides = <Override>[
    userRoleProvider.overrideWith((ref) => UserRole.lecture),

    // IMPORTANT: refDataProvider doit retourner RefDataCache (pas AsyncValue)
    refDataProvider.overrideWith((ref) async => RefDataCache(
          fournisseurs: const {
            'fournisseur-1': 'Fournisseur Test 1',
            'fournisseur-2': 'Fournisseur Test 2',
            'fournisseur-3': 'Fournisseur Test 3',
          },
          produits: const {
            'produit-1': 'Essence',
            'produit-2': 'Diesel',
            'produit-3': 'Kérosène',
          },
          produitCodes: const {
            'produit-1': 'ESS',
            'produit-2': 'GO',
            'produit-3': 'KER',
          },
          depots: const {
            'depot-1': 'Dépôt Central',
            'depot-2': 'Dépôt Nord',
          },
          loadedAt: DateTime(2025, 1, 27),
        )),
  ];

  final allOverrides = <Override>[...defaultOverrides, ...overrides];

  await tester.pumpWidget(
    ProviderScope(
      overrides: allOverrides,
      child: router == null
          ? MaterialApp(home: child)
          : MaterialApp.router(
              routerDelegate: router.routerDelegate,
              routeInformationParser: router.routeInformationParser,
              routeInformationProvider: router.routeInformationProvider,
            ),
    ),
  );

  await tester.pump();
}

/// Helper pour créer un RefDataCache de test
RefDataCache createFakeRefDataCache({
  Map<String, String>? fournisseurs,
  Map<String, String>? produits,
  Map<String, String>? produitCodes,
  Map<String, String>? depots,
  DateTime? loadedAt,
}) {
  return RefDataCache(
    fournisseurs: fournisseurs ?? {
      'fournisseur-1': 'Fournisseur Test 1',
      'fournisseur-2': 'Fournisseur Test 2',
      'fournisseur-3': 'Fournisseur Test 3',
    },
    produits: produits ?? {
      'produit-1': 'Essence',
      'produit-2': 'Diesel',
      'produit-3': 'Kérosène',
    },
    produitCodes: produitCodes ?? {
      'produit-1': 'ESS',
      'produit-2': 'GO',
      'produit-3': 'KER',
    },
    depots: depots ?? {
      'depot-1': 'Dépôt Central',
      'depot-2': 'Dépôt Nord',
    },
    loadedAt: loadedAt ?? DateTime.now(),
  );
}

/// Builder pour créer des cours de route de test
/// 
/// [overrides] : Valeurs à surcharger dans le cours de route
/// 
/// Retourne :
/// - `CoursDeRoute` : Un cours de route avec des valeurs par défaut
CoursDeRoute fakeCdr({
  String? id,
  String? fournisseurId,
  String? produitId,
  String? depotDestinationId,
  String? transporteur,
  String? plaqueCamion,
  String? plaqueRemorque,
  String? chauffeur,
  double? volume,
  DateTime? dateChargement,
  DateTime? dateArriveePrevue,
  String? pays,
  StatutCours? statut,
  String? note,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return CoursDeRoute(
    id: id ?? 'test-cdr-id',
    fournisseurId: fournisseurId ?? 'fournisseur-1',
    produitId: produitId ?? 'produit-1',
    depotDestinationId: depotDestinationId ?? 'depot-1',
    transporteur: transporteur ?? 'Transport Express SARL',
    plaqueCamion: plaqueCamion ?? 'ABC123',
    plaqueRemorque: plaqueRemorque ?? 'DEF456',
    chauffeur: chauffeur ?? 'Jean Dupont',
    volume: volume ?? 50000.0,
    dateChargement: dateChargement ?? DateTime.parse('2025-01-27T10:00:00Z'),
    dateArriveePrevue: dateArriveePrevue ?? DateTime.parse('2025-01-28T10:00:00Z'),
    pays: pays ?? 'RDC',
    statut: statut ?? StatutCours.chargement,
    note: note ?? 'Cours de test',
    createdAt: createdAt ?? DateTime.parse('2025-01-27T09:00:00Z'),
    updatedAt: updatedAt ?? DateTime.parse('2025-01-27T15:00:00Z'),
  );
}

/// Builder pour créer un cours de route déchargé
/// 
/// [overrides] : Valeurs à surcharger dans le cours de route
/// 
/// Retourne :
/// - `CoursDeRoute` : Un cours de route avec statut déchargé
CoursDeRoute fakeCdrDecharge({
  String? id,
  String? fournisseurId,
  String? produitId,
  String? depotDestinationId,
  String? transporteur,
  String? plaqueCamion,
  String? plaqueRemorque,
  String? chauffeur,
  double? volume,
  DateTime? dateChargement,
  DateTime? dateArriveePrevue,
  String? pays,
  String? note,
  DateTime? createdAt,
  DateTime? updatedAt,
}) {
  return fakeCdr(
    id: id,
    fournisseurId: fournisseurId,
    produitId: produitId,
    depotDestinationId: depotDestinationId,
    transporteur: transporteur,
    plaqueCamion: plaqueCamion,
    plaqueRemorque: plaqueRemorque,
    chauffeur: chauffeur,
    volume: volume,
    dateChargement: dateChargement,
    dateArriveePrevue: dateArriveePrevue,
    pays: pays,
    statut: StatutCours.decharge, // ✅ Statut déchargé
    note: note,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// Builder pour créer une liste de cours de route de test
/// 
/// [count] : Nombre de cours à créer
/// [statuts] : Liste des statuts à utiliser (répétés si nécessaire)
/// 
/// Retourne :
/// - `List<CoursDeRoute>` : Liste de cours de route
List<CoursDeRoute> fakeCdrList({
  int count = 4,
  List<StatutCours>? statuts,
}) {
  final defaultStatuts = [
    StatutCours.chargement,
    StatutCours.transit,
    StatutCours.frontiere,
    StatutCours.arrive,
    StatutCours.decharge,
  ];
  
  final effectiveStatuts = statuts ?? defaultStatuts;
  
  return List.generate(count, (index) {
    final statutIndex = index % effectiveStatuts.length;
    return fakeCdr(
      id: 'cdr-${index + 1}',
      fournisseurId: 'fournisseur-${(index % 3) + 1}',
      produitId: 'produit-${(index % 3) + 1}',
      depotDestinationId: 'depot-${(index % 2) + 1}',
      transporteur: 'Transport ${index + 1}',
      plaqueCamion: 'ABC${(index + 1).toString().padLeft(3, '0')}',
      chauffeur: 'Chauffeur ${index + 1}',
      volume: 30000.0 + (index * 10000),
      statut: effectiveStatuts[statutIndex],
      note: 'Note ${index + 1}',
    );
  });
}

/// Mock service pour les tests (utilise Mockito)
class MockCoursDeRouteService extends Mock implements CoursDeRouteService {}

/// Helper pour vérifier qu'un widget est affiché sans exception
/// 
/// [tester] : Le WidgetTester Flutter
/// [widget] : Le widget à tester
/// [overrides] : Overrides supplémentaires pour les providers
Future<void> expectNoRenderException(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
}) async {
  await pumpWithProviders(tester, widget, overrides: overrides);
  
  // Vérifier qu'il n'y a pas d'exception de rendu
  expect(tester.takeException(), isNull);
  
  // Attendre que le widget soit construit
  await tester.pumpAndSettle();
  
  // Vérifier qu'il n'y a toujours pas d'exception
  expect(tester.takeException(), isNull);
}

/// Helper pour vérifier qu'un texte est affiché
/// 
/// [text] : Le texte à chercher
/// [finds] : Le nombre d'occurrences attendues
void expectTextFound(String text, {int finds = 1}) {
  expect(find.text(text), findsNWidgets(finds));
}

/// Helper pour vérifier qu'un texte n'est pas affiché
/// 
/// [text] : Le texte à vérifier qu'il n'est pas présent
void expectTextNotFound(String text) {
  expect(find.text(text), findsNothing);
}

/// Helper pour vérifier qu'un widget est présent
/// 
/// [widget] : Le widget à chercher
/// [finds] : Le nombre d'occurrences attendues
void expectWidgetFound(Widget widget, {int finds = 1}) {
  expect(find.byWidget(widget), findsNWidgets(finds));
}

/// Helper pour vérifier qu'un widget n'est pas présent
/// 
/// [widget] : Le widget à vérifier qu'il n'est pas présent
void expectWidgetNotFound(Widget widget) {
  expect(find.byWidget(widget), findsNothing);
}
