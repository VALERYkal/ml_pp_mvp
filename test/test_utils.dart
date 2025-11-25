// ð Module : Utilitaires de Test
// ð§ Auteur : Valery Kalonga
// ð Date : 2025-01-27
// ð§­ Description : Utilitaires de test pour les tests CDR

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';

/// Helper pour pomper un widget avec les providers nÃ©cessaires
///
/// [tester] : Le WidgetTester Ã  utiliser
/// [widget] : Le widget Ã  tester
/// [overrides] : Overrides supplÃ©mentaires pour les providers
/// [routerConfig] : Configuration du routeur (optionnel)
Future<void> pumpWithProviders(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
  GoRouter? routerConfig,
}) async {
  final defaultOverrides = [
    // Providers par dÃ©faut pour les tests CDR
    userRoleProvider.overrideWith((ref) => UserRole.lecture),
    refDataProvider.overrideWith((ref) => FakeRefData() as RefDataCache),
  ];

  final allOverrides = [...defaultOverrides, ...overrides];

  await tester.pumpWidget(
    ProviderScope(
      overrides: allOverrides,
      child: routerConfig != null
          ? MaterialApp.router(routerConfig: routerConfig)
          : MaterialApp(home: widget),
    ),
  );
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
           produits ?? {'produit-1': 'Essence', 'produit-2': 'Diesel', 'produit-3': 'KÃ©rosÃ¨ne'},
       depots = depots ?? {'depot-1': 'DÃ©pÃ´t Central', 'depot-2': 'DÃ©pÃ´t Nord'};
}

/// Builder pour crÃ©er des cours de route de test
///
/// [overrides] : Valeurs Ã  surcharger dans le cours de route
///
/// Retourne :
/// - `CoursDeRoute` : Un cours de route avec des valeurs par dÃ©faut
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

/// Builder pour crÃ©er un cours de route dÃ©chargÃ©
///
/// [overrides] : Valeurs Ã  surcharger dans le cours de route
///
/// Retourne :
/// - `CoursDeRoute` : Un cours de route avec statut dÃ©chargÃ©
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
    statut: StatutCours.decharge, // â Statut dÃ©chargÃ©
    note: note,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

/// Builder pour crÃ©er une liste de cours de route de test
///
/// [count] : Nombre de cours Ã  crÃ©er
/// [statuts] : Liste des statuts Ã  utiliser (rÃ©pÃ©tÃ©s si nÃ©cessaire)
///
/// Retourne :
/// - `List<CoursDeRoute>` : Liste de cours de route
List<CoursDeRoute> fakeCdrList({int count = 4, List<StatutCours>? statuts}) {
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

/// Fake service minimal pour les tests
class FakeCoursDeRouteService implements CoursDeRouteService {
  final List<CoursDeRoute> _cours;
  final CoursDeRoute? _coursById;

  FakeCoursDeRouteService({List<CoursDeRoute>? cours, CoursDeRoute? coursById})
    : _cours = cours ?? fakeCdrList(),
      _coursById = coursById;

  @override
  Future<List<CoursDeRoute>> getAll() async {
    return _cours;
  }

  @override
  Future<List<CoursDeRoute>> getActifs() async {
    return _cours.where((c) => c.statut != StatutCours.decharge).toList();
  }

  @override
  Future<CoursDeRoute?> getById(String id) async {
    return _coursById ??
        _cours.firstWhere((c) => c.id == id, orElse: () => throw StateError('Not found'));
  }

  // MÃ©thodes non utilisÃ©es dans les tests - implÃ©mentation minimale
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
  Future<List<CoursDeRoute>> getByStatut(StatutCours statut) async => throw UnimplementedError();

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

/// Helper pour vÃ©rifier qu'un widget est affichÃ© sans exception
///
/// [tester] : Le WidgetTester Ã  utiliser
/// [widget] : Le widget Ã  tester
/// [overrides] : Overrides supplÃ©mentaires pour les providers
Future<void> expectNoRenderException(
  WidgetTester tester,
  Widget widget, {
  List<Override> overrides = const [],
}) async {
  await pumpWithProviders(tester, widget, overrides: overrides);

  // VÃ©rifier qu'il n'y a pas d'exception de rendu
  expect(tester.takeException(), isNull);

  // Attendre que le widget soit construit
  await tester.pumpAndSettle();

  // VÃ©rifier qu'il n'y a toujours pas d'exception
  expect(tester.takeException(), isNull);
}

/// Helper pour vÃ©rifier qu'un texte est affichÃ©
///
/// [text] : Le texte Ã  chercher
/// [finds] : Le nombre d'occurrences attendues
void expectTextFound(String text, {int finds = 1}) {
  expect(find.text(text), findsNWidgets(finds));
}

/// Helper pour vÃ©rifier qu'un texte n'est pas affichÃ©
///
/// [text] : Le texte Ã  vÃ©rifier qu'il n'est pas prÃ©sent
void expectTextNotFound(String text) {
  expect(find.text(text), findsNothing);
}

/// Helper pour vÃ©rifier qu'un widget est prÃ©sent
///
/// [widget] : Le widget Ã  chercher
/// [finds] : Le nombre d'occurrences attendues
void expectWidgetFound(Widget widget, {int finds = 1}) {
  expect(find.byWidget(widget), findsNWidgets(finds));
}

/// Helper pour vÃ©rifier qu'un widget n'est pas prÃ©sent
///
/// [widget] : Le widget Ã  vÃ©rifier qu'il n'est pas prÃ©sent
void expectWidgetNotFound(Widget widget) {
  expect(find.byWidget(widget), findsNothing);
}

