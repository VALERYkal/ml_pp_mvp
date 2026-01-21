// 📌 Module : Cours de Route - Tests d'Intégration Flux Métier Complet
// 🧑 Auteur : Mona (IA Flutter/Supabase/Riverpod)
// 📅 Date : 2025-11-27
// 🧭 Description : Tests d'intégration pour valider le flux métier complet CDR
//
// RÈGLE MÉTIER CDR (Cours de Route) :
// - "Au chargement" = CHARGEMENT uniquement
// - "En route" = TRANSIT + FRONTIERE
// - "Arrivés" = ARRIVE
// - DECHARGE = EXCLU des listes actives et des KPI
// - Les transitions doivent passer par la machine d'état

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';

// ════════════════════════════════════════════════════════════════════════════
// FAKE SERVICE IN-MEMORY
// ════════════════════════════════════════════════════════════════════════════

/// Fake service CDR pour les tests d'intégration de flux
/// Stocke les données en mémoire et valide les transitions via la machine d'état
class FakeCoursDeRouteServiceForFlow implements CoursDeRouteService {
  final List<CoursDeRoute> _data = [];

  FakeCoursDeRouteServiceForFlow({List<CoursDeRoute>? seedData}) {
    if (seedData != null) {
      _data.addAll(seedData);
    }
  }

  @override
  Future<List<CoursDeRoute>> getAll() async {
    final sorted = List<CoursDeRoute>.from(_data);
    sorted.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(1970);
      final bDate = b.createdAt ?? DateTime(1970);
      return bDate.compareTo(aDate); // Décroissant
    });
    return sorted;
  }

  @override
  Future<List<CoursDeRoute>> getActifs() async {
    final all = await getAll();
    return all.where((cdr) => cdr.statut != StatutCours.decharge).toList();
  }

  @override
  Future<CoursDeRoute?> getById(String id) async {
    try {
      return _data.firstWhere((cdr) => cdr.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<CoursDeRoute>> getByStatut(StatutCours statut) async {
    final all = await getAll();
    return all.where((cdr) => cdr.statut == statut).toList();
  }

  @override
  Future<void> create(CoursDeRoute cours) async {
    if (cours.fournisseurId.isEmpty ||
        cours.depotDestinationId.isEmpty ||
        cours.produitId.isEmpty) {
      throw ArgumentError(
        'fournisseur, dépôt destination et produit sont requis.',
      );
    }
    if (cours.volume != null && cours.volume! <= 0) {
      throw ArgumentError('volume must be > 0');
    }
    _data.add(cours);
  }

  @override
  Future<void> update(CoursDeRoute cours) async {
    if (cours.volume != null && cours.volume! <= 0) {
      throw ArgumentError('volume must be > 0');
    }
    final index = _data.indexWhere((c) => c.id == cours.id);
    if (index == -1) {
      throw StateError('Cours de route non trouvé: ${cours.id}');
    }
    _data[index] = cours;
  }

  @override
  Future<void> delete(String id) async {
    _data.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> updateStatut({
    required String id,
    required StatutCours to,
    bool fromReception = false,
  }) async {
    final index = _data.indexWhere((c) => c.id == id);
    if (index == -1) {
      throw StateError('Cours de route non trouvé: $id');
    }

    final current = _data[index];
    final from = current.statut;

    // ✅ VALIDATION MACHINE D'ÉTAT
    if (!CoursDeRouteStateMachine.canTransition(
      from,
      to,
      fromReception: fromReception,
    )) {
      throw StateError(
        'Transition non autorisée: ${from.db} -> ${to.db} (fromReception: $fromReception)',
      );
    }

    // Appliquer la transition
    _data[index] = current.copyWith(statut: to);
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
    for (final cdr in _data) {
      final key = cdr.statut.db;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  @override
  Future<Map<String, int>> countByCategorie() async {
    final counts = <String, int>{'en_route': 0, 'en_attente': 0, 'termines': 0};
    for (final cdr in _data) {
      switch (cdr.statut) {
        case StatutCours.chargement:
        case StatutCours.transit:
        case StatutCours.frontiere:
          counts['en_route'] = (counts['en_route'] ?? 0) + 1;
          break;
        case StatutCours.arrive:
          counts['en_attente'] = (counts['en_attente'] ?? 0) + 1;
          break;
        case StatutCours.decharge:
          counts['termines'] = (counts['termines'] ?? 0) + 1;
          break;
      }
    }
    return counts;
  }

  @override
  Future<bool> canTransition({
    required dynamic from,
    required dynamic to,
  }) async {
    throw UnimplementedError(
      'Utiliser CoursDeRouteStateMachine.canTransition() directement',
    );
  }

  @override
  Future<bool> applyTransition({
    required String cdrId,
    required dynamic from,
    required dynamic to,
    String? userId,
  }) async {
    throw UnimplementedError(
      'Utiliser updateStatut() pour les transitions de statut',
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ════════════════════════════════════════════════════════════════════════════

/// Calcule les KPI CDR selon la logique métier
///
/// RÈGLE MÉTIER :
/// - Au chargement = CHARGEMENT uniquement
/// - En route = TRANSIT + FRONTIERE
/// - Arrivés = ARRIVE
/// - DECHARGE = EXCLU
class CdrKpiMetrics {
  final int auChargement;
  final int enRoute;
  final int arrives;
  final int totalActifs;

  const CdrKpiMetrics({
    required this.auChargement,
    required this.enRoute,
    required this.arrives,
    required this.totalActifs,
  });

  /// Calcule les KPI à partir d'une liste de CDR
  static CdrKpiMetrics fromList(List<CoursDeRoute> cdrList) {
    int auChargement = 0;
    int enRoute = 0;
    int arrives = 0;

    for (final cdr in cdrList) {
      switch (cdr.statut) {
        case StatutCours.chargement:
          auChargement++;
          break;
        case StatutCours.transit:
        case StatutCours.frontiere:
          enRoute++;
          break;
        case StatutCours.arrive:
          arrives++;
          break;
        case StatutCours.decharge:
          // EXCLU des KPI
          break;
      }
    }

    return CdrKpiMetrics(
      auChargement: auChargement,
      enRoute: enRoute,
      arrives: arrives,
      totalActifs: auChargement + enRoute + arrives,
    );
  }
}

/// Crée un ProviderContainer avec le fake service
ProviderContainer createFlowTestContainer({
  required FakeCoursDeRouteServiceForFlow fakeService,
}) {
  return ProviderContainer(
    overrides: [coursDeRouteServiceProvider.overrideWithValue(fakeService)],
  );
}

// ════════════════════════════════════════════════════════════════════════════
// TESTS D'INTÉGRATION FLUX MÉTIER
// ════════════════════════════════════════════════════════════════════════════

void main() {
  // Constantes pour le scénario
  const depotId = '11111111-1111-1111-1111-111111111111';
  const fournisseurId = '22222222-2222-2222-2222-222222222222';
  const produitId = '33333333-3333-3333-3333-333333333333';
  const cdrId = 'cdr-flow-test-001';
  const volume = 20000.0;

  group('CDR Flow Integration', () {
    test(
      'CDR Flow Integration - Statut CHARGEMENT correctement reflété dans les listes et KPI',
      () async {
        // Arrange
        final cdrInitial = CoursDeRoute(
          id: cdrId,
          fournisseurId: fournisseurId,
          produitId: produitId,
          depotDestinationId: depotId,
          plaqueCamion: 'FLOW-001',
          transporteur: 'Transport Express',
          volume: volume,
          statut: StatutCours.chargement,
          createdAt: DateTime(2025, 11, 27),
        );

        final fakeService = FakeCoursDeRouteServiceForFlow(
          seedData: [cdrInitial],
        );
        final container = createFlowTestContainer(fakeService: fakeService);

        // Act
        final all = await container.read(coursDeRouteListProvider.future);
        final actifs = await container.read(coursDeRouteActifsProvider.future);
        final chargement = await container.read(
          coursDeRouteByStatutProvider(StatutCours.chargement).future,
        );
        final kpi = CdrKpiMetrics.fromList(all);

        // Assert - Listes
        expect(all, hasLength(1));
        expect(all.first.id, equals(cdrId));
        expect(all.first.statut, equals(StatutCours.chargement));

        expect(actifs, hasLength(1));
        expect(actifs.first.id, equals(cdrId));

        expect(chargement, hasLength(1));
        expect(chargement.first.id, equals(cdrId));

        // Assert - KPI
        expect(kpi.auChargement, equals(1));
        expect(kpi.enRoute, equals(0));
        expect(kpi.arrives, equals(0));
        expect(kpi.totalActifs, equals(1));
      },
    );

    test(
      'CDR Flow Integration - Transition CHARGEMENT -> TRANSIT met à jour les KPI et listes',
      () async {
        // Arrange
        final cdrInitial = CoursDeRoute(
          id: cdrId,
          fournisseurId: fournisseurId,
          produitId: produitId,
          depotDestinationId: depotId,
          plaqueCamion: 'FLOW-001',
          transporteur: 'Transport Express',
          volume: volume,
          statut: StatutCours.chargement,
          createdAt: DateTime(2025, 11, 27),
        );

        final fakeService = FakeCoursDeRouteServiceForFlow(
          seedData: [cdrInitial],
        );
        final container = createFlowTestContainer(fakeService: fakeService);

        // Vérifier l'état initial
        var all = await container.read(coursDeRouteListProvider.future);
        var kpi = CdrKpiMetrics.fromList(all);
        expect(kpi.auChargement, equals(1));
        expect(kpi.enRoute, equals(0));

        // Act - Transition CHARGEMENT -> TRANSIT
        await fakeService.updateStatut(
          id: cdrId,
          to: StatutCours.transit,
          fromReception: false,
        );

        // Invalider les providers pour forcer le recalcul
        container.invalidate(coursDeRouteListProvider);
        container.invalidate(coursDeRouteActifsProvider);

        // Vérifier l'état après transition
        all = await container.read(coursDeRouteListProvider.future);
        final actifs = await container.read(coursDeRouteActifsProvider.future);
        final transit = await container.read(
          coursDeRouteByStatutProvider(StatutCours.transit).future,
        );
        final chargement = await container.read(
          coursDeRouteByStatutProvider(StatutCours.chargement).future,
        );
        kpi = CdrKpiMetrics.fromList(all);

        // Assert - Listes
        expect(all.first.statut, equals(StatutCours.transit));
        expect(actifs, hasLength(1)); // Toujours actif
        expect(transit, hasLength(1));
        expect(chargement, isEmpty); // Plus dans chargement

        // Assert - KPI
        expect(kpi.auChargement, equals(0)); // ✅ Passé de 1 à 0
        expect(kpi.enRoute, equals(1)); // ✅ Passé de 0 à 1
        expect(kpi.arrives, equals(0));
        expect(kpi.totalActifs, equals(1));
      },
    );

    test(
      'CDR Flow Integration - Transition TRANSIT -> FRONTIERE garde le CDR dans "En route"',
      () async {
        // Arrange
        final cdrInitial = CoursDeRoute(
          id: cdrId,
          fournisseurId: fournisseurId,
          produitId: produitId,
          depotDestinationId: depotId,
          plaqueCamion: 'FLOW-001',
          transporteur: 'Transport Express',
          volume: volume,
          statut: StatutCours.transit,
          createdAt: DateTime(2025, 11, 27),
        );

        final fakeService = FakeCoursDeRouteServiceForFlow(
          seedData: [cdrInitial],
        );
        final container = createFlowTestContainer(fakeService: fakeService);

        // Vérifier l'état initial
        var all = await container.read(coursDeRouteListProvider.future);
        var kpi = CdrKpiMetrics.fromList(all);
        expect(kpi.enRoute, equals(1)); // TRANSIT compte dans "En route"

        // Act - Transition TRANSIT -> FRONTIERE
        await fakeService.updateStatut(
          id: cdrId,
          to: StatutCours.frontiere,
          fromReception: false,
        );

        container.invalidate(coursDeRouteListProvider);
        container.invalidate(coursDeRouteActifsProvider);

        // Vérifier l'état après transition
        all = await container.read(coursDeRouteListProvider.future);
        final frontiere = await container.read(
          coursDeRouteByStatutProvider(StatutCours.frontiere).future,
        );
        final transit = await container.read(
          coursDeRouteByStatutProvider(StatutCours.transit).future,
        );
        kpi = CdrKpiMetrics.fromList(all);

        // Assert - Listes
        expect(all.first.statut, equals(StatutCours.frontiere));
        expect(frontiere, hasLength(1));
        expect(transit, isEmpty);

        // Assert - KPI : FRONTIERE reste dans "En route"
        expect(kpi.auChargement, equals(0));
        expect(
          kpi.enRoute,
          equals(1),
        ); // ✅ Toujours dans "En route" (TRANSIT+FRONTIERE)
        expect(kpi.arrives, equals(0));
        expect(kpi.totalActifs, equals(1));
      },
    );

    test(
      'CDR Flow Integration - Transition FRONTIERE -> ARRIVE met à jour "Arrivés"',
      () async {
        // Arrange
        final cdrInitial = CoursDeRoute(
          id: cdrId,
          fournisseurId: fournisseurId,
          produitId: produitId,
          depotDestinationId: depotId,
          plaqueCamion: 'FLOW-001',
          transporteur: 'Transport Express',
          volume: volume,
          statut: StatutCours.frontiere,
          createdAt: DateTime(2025, 11, 27),
        );

        final fakeService = FakeCoursDeRouteServiceForFlow(
          seedData: [cdrInitial],
        );
        final container = createFlowTestContainer(fakeService: fakeService);

        // Vérifier l'état initial
        var all = await container.read(coursDeRouteListProvider.future);
        var kpi = CdrKpiMetrics.fromList(all);
        expect(kpi.enRoute, equals(1));
        expect(kpi.arrives, equals(0));

        // Act - Transition FRONTIERE -> ARRIVE
        await fakeService.updateStatut(
          id: cdrId,
          to: StatutCours.arrive,
          fromReception: false,
        );

        container.invalidate(coursDeRouteListProvider);
        container.invalidate(coursDeRouteActifsProvider);

        // Vérifier l'état après transition
        all = await container.read(coursDeRouteListProvider.future);
        final arrive = await container.read(
          coursDeRouteByStatutProvider(StatutCours.arrive).future,
        );
        final frontiere = await container.read(
          coursDeRouteByStatutProvider(StatutCours.frontiere).future,
        );
        kpi = CdrKpiMetrics.fromList(all);

        // Assert - Listes
        expect(all.first.statut, equals(StatutCours.arrive));
        expect(arrive, hasLength(1));
        expect(frontiere, isEmpty);

        // Assert - KPI
        expect(kpi.auChargement, equals(0));
        expect(kpi.enRoute, equals(0)); // ✅ Passé de 1 à 0
        expect(kpi.arrives, equals(1)); // ✅ Passé de 0 à 1
        expect(kpi.totalActifs, equals(1));
      },
    );

    test(
      'CDR Flow Integration - Transition ARRIVE -> DECHARGE retire le CDR des CDR actifs',
      () async {
        // Arrange
        final cdrInitial = CoursDeRoute(
          id: cdrId,
          fournisseurId: fournisseurId,
          produitId: produitId,
          depotDestinationId: depotId,
          plaqueCamion: 'FLOW-001',
          transporteur: 'Transport Express',
          volume: volume,
          statut: StatutCours.arrive,
          createdAt: DateTime(2025, 11, 27),
        );

        final fakeService = FakeCoursDeRouteServiceForFlow(
          seedData: [cdrInitial],
        );
        final container = createFlowTestContainer(fakeService: fakeService);

        // Vérifier l'état initial
        var all = await container.read(coursDeRouteListProvider.future);
        var actifs = await container.read(coursDeRouteActifsProvider.future);
        var kpi = CdrKpiMetrics.fromList(all);
        expect(actifs, hasLength(1));
        expect(kpi.arrives, equals(1));

        // Act - Transition ARRIVE -> DECHARGE (avec fromReception)
        await fakeService.updateStatut(
          id: cdrId,
          to: StatutCours.decharge,
          fromReception: true, // ✅ Requis pour ARRIVE -> DECHARGE
        );

        container.invalidate(coursDeRouteListProvider);
        container.invalidate(coursDeRouteActifsProvider);

        // Vérifier l'état après transition
        all = await container.read(coursDeRouteListProvider.future);
        actifs = await container.read(coursDeRouteActifsProvider.future);
        final decharge = await container.read(
          coursDeRouteByStatutProvider(StatutCours.decharge).future,
        );
        final arrive = await container.read(
          coursDeRouteByStatutProvider(StatutCours.arrive).future,
        );
        kpi = CdrKpiMetrics.fromList(all);

        // Assert - Listes
        expect(all.first.statut, equals(StatutCours.decharge));
        expect(actifs, isEmpty); // ✅ Retiré des actifs
        expect(decharge, hasLength(1));
        expect(arrive, isEmpty);

        // Assert - KPI : DECHARGE est exclu
        expect(kpi.auChargement, equals(0));
        expect(kpi.enRoute, equals(0));
        expect(kpi.arrives, equals(0)); // ✅ Retiré de "Arrivés"
        expect(kpi.totalActifs, equals(0)); // ✅ Plus aucun actif
      },
    );

    test(
      'CDR Flow Integration - Séquence complète CHARGEMENT -> TRANSIT -> FRONTIERE -> ARRIVE -> DECHARGE',
      () async {
        // Arrange
        final cdrInitial = CoursDeRoute(
          id: cdrId,
          fournisseurId: fournisseurId,
          produitId: produitId,
          depotDestinationId: depotId,
          plaqueCamion: 'FLOW-001',
          transporteur: 'Transport Express',
          volume: volume,
          statut: StatutCours.chargement,
          createdAt: DateTime(2025, 11, 27),
        );

        final fakeService = FakeCoursDeRouteServiceForFlow(
          seedData: [cdrInitial],
        );
        final container = createFlowTestContainer(fakeService: fakeService);

        // Étape 1 : CHARGEMENT
        var all = await container.read(coursDeRouteListProvider.future);
        var kpi = CdrKpiMetrics.fromList(all);
        expect(kpi.auChargement, equals(1));
        expect(kpi.enRoute, equals(0));
        expect(kpi.arrives, equals(0));

        // Étape 2 : TRANSIT
        await fakeService.updateStatut(id: cdrId, to: StatutCours.transit);
        container.invalidate(coursDeRouteListProvider);
        all = await container.read(coursDeRouteListProvider.future);
        kpi = CdrKpiMetrics.fromList(all);
        expect(kpi.auChargement, equals(0));
        expect(kpi.enRoute, equals(1));
        expect(kpi.arrives, equals(0));

        // Étape 3 : FRONTIERE
        await fakeService.updateStatut(id: cdrId, to: StatutCours.frontiere);
        container.invalidate(coursDeRouteListProvider);
        all = await container.read(coursDeRouteListProvider.future);
        kpi = CdrKpiMetrics.fromList(all);
        expect(kpi.auChargement, equals(0));
        expect(kpi.enRoute, equals(1)); // Toujours dans "En route"
        expect(kpi.arrives, equals(0));

        // Étape 4 : ARRIVE
        await fakeService.updateStatut(id: cdrId, to: StatutCours.arrive);
        container.invalidate(coursDeRouteListProvider);
        all = await container.read(coursDeRouteListProvider.future);
        kpi = CdrKpiMetrics.fromList(all);
        expect(kpi.auChargement, equals(0));
        expect(kpi.enRoute, equals(0));
        expect(kpi.arrives, equals(1));

        // Étape 5 : DECHARGE
        await fakeService.updateStatut(
          id: cdrId,
          to: StatutCours.decharge,
          fromReception: true,
        );
        container.invalidate(coursDeRouteListProvider);
        container.invalidate(coursDeRouteActifsProvider);
        all = await container.read(coursDeRouteListProvider.future);
        final actifs = await container.read(coursDeRouteActifsProvider.future);
        kpi = CdrKpiMetrics.fromList(all);
        expect(actifs, isEmpty); // Plus dans les actifs
        expect(kpi.auChargement, equals(0));
        expect(kpi.enRoute, equals(0));
        expect(kpi.arrives, equals(0));
        expect(kpi.totalActifs, equals(0));
      },
    );
  });
}
