// 📌 Module : Cours de Route - Tests Provider Liste CDR
// 🧑 Auteur : Mona (IA Flutter/Supabase/Riverpod)
// 📅 Date : 2025-11-27
// 🧭 Description : Tests unitaires pour les providers de liste Cours de Route
//
// RÈGLE MÉTIER CDR (Cours de Route) :
// - "Au chargement" = CHARGEMENT uniquement
// - "En route" = TRANSIT + FRONTIERE
// - "Arrivés" = ARRIVE
// - DECHARGE = EXCLU des listes actives (cours terminé)
// - "Actifs" = CHARGEMENT + TRANSIT + FRONTIERE + ARRIVE (tout sauf DECHARGE)

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cdr_etat.dart';

// ════════════════════════════════════════════════════════════════════════════
// FAKE SERVICE POUR LES TESTS
// ════════════════════════════════════════════════════════════════════════════

/// Fake service CDR pour les tests unitaires
/// Stocke les données en mémoire sans dépendance Supabase
class FakeCoursDeRouteService implements CoursDeRouteService {
  final List<CoursDeRoute> _seedData;

  FakeCoursDeRouteService({List<CoursDeRoute>? seedData})
    : _seedData = seedData ?? [];

  @override
  Future<List<CoursDeRoute>> getAll() async {
    // Tri par createdAt décroissant (plus récent en premier)
    final sorted = List<CoursDeRoute>.from(_seedData);
    sorted.sort((a, b) {
      final aDate = a.createdAt ?? DateTime(1970);
      final bDate = b.createdAt ?? DateTime(1970);
      return bDate.compareTo(aDate); // Décroissant
    });
    return sorted;
  }

  @override
  Future<List<CoursDeRoute>> getActifs() async {
    // Retourne uniquement les CDR non déchargés
    final all = await getAll();
    return all.where((cdr) => cdr.statut != StatutCours.decharge).toList();
  }

  @override
  Future<CoursDeRoute?> getById(String id) async {
    try {
      return _seedData.firstWhere((cdr) => cdr.id == id);
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
    _seedData.add(cours);
  }

  @override
  Future<void> update(CoursDeRoute cours) async {
    final index = _seedData.indexWhere((c) => c.id == cours.id);
    if (index != -1) {
      _seedData[index] = cours;
    }
  }

  @override
  Future<void> delete(String id) async {
    _seedData.removeWhere((c) => c.id == id);
  }

  @override
  Future<void> updateStatut({
    required String id,
    required StatutCours to,
    bool fromReception = false,
  }) async {
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
  Future<Map<String, int>> countByCategorie() async {
    final counts = <String, int>{'en_route': 0, 'en_attente': 0, 'termines': 0};
    for (final cdr in _seedData) {
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
    if (from is CdrEtat && to is CdrEtat) {
      return from.canTransitionTo(to);
    }
    return false;
  }

  @override
  Future<bool> applyTransition({
    required String cdrId,
    required dynamic from,
    required dynamic to,
    String? userId,
  }) async {
    return true; // Simplifié pour les tests
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ════════════════════════════════════════════════════════════════════════════

/// Crée un ProviderContainer configuré avec le FakeService
ProviderContainer createTestContainer({required List<CoursDeRoute> seedData}) {
  final fakeService = FakeCoursDeRouteService(seedData: seedData);
  return ProviderContainer(
    overrides: [coursDeRouteServiceProvider.overrideWithValue(fakeService)],
  );
}

// ════════════════════════════════════════════════════════════════════════════
// JEU DE DONNÉES DE TEST
// ════════════════════════════════════════════════════════════════════════════

/// IDs de dépôts pour les tests
const depotPrincipalId = '11111111-1111-1111-1111-111111111111';
const depotSecondaireId = '22222222-2222-2222-2222-222222222222';

/// IDs fournisseur et produit génériques pour les tests
const fournisseurId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const produitId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

/// Crée un CDR de test avec les paramètres spécifiés
CoursDeRoute createTestCdr({
  required String id,
  required StatutCours statut,
  String? depotDestinationId,
  double? volume,
  DateTime? createdAt,
}) {
  return CoursDeRoute(
    id: id,
    fournisseurId: fournisseurId,
    produitId: produitId,
    depotDestinationId: depotDestinationId ?? depotPrincipalId,
    statut: statut,
    volume: volume ?? 10000.0,
    createdAt: createdAt ?? DateTime(2025, 11, 15),
    transporteur: 'Test Transport',
    plaqueCamion: 'TEST-001',
    chauffeur: 'Jean Test',
  );
}

/// Jeu de données CDR de référence (tous dans le dépôt principal)
final cdrChargement1 = createTestCdr(
  id: 'cdr-chargement-1',
  statut: StatutCours.chargement,
  volume: 12000.0,
  createdAt: DateTime(2025, 11, 10),
);

final cdrChargement2 = createTestCdr(
  id: 'cdr-chargement-2',
  statut: StatutCours.chargement,
  volume: 15000.0,
  createdAt: DateTime(2025, 11, 11),
);

final cdrTransit = createTestCdr(
  id: 'cdr-transit-1',
  statut: StatutCours.transit,
  volume: 18000.0,
  createdAt: DateTime(2025, 11, 12),
);

final cdrFrontiere = createTestCdr(
  id: 'cdr-frontiere-1',
  statut: StatutCours.frontiere,
  volume: 20000.0,
  createdAt: DateTime(2025, 11, 13),
);

final cdrArrive = createTestCdr(
  id: 'cdr-arrive-1',
  statut: StatutCours.arrive,
  volume: 22000.0,
  createdAt: DateTime(2025, 11, 14),
);

final cdrDecharge = createTestCdr(
  id: 'cdr-decharge-1',
  statut: StatutCours.decharge,
  volume: 25000.0,
  createdAt: DateTime(2025, 11, 15),
);

/// CDR dans un autre dépôt
final cdrAutreDepot = createTestCdr(
  id: 'cdr-autre-depot',
  statut: StatutCours.transit,
  depotDestinationId: depotSecondaireId,
  volume: 30000.0,
  createdAt: DateTime(2025, 11, 16),
);

// ════════════════════════════════════════════════════════════════════════════
// TESTS
// ════════════════════════════════════════════════════════════════════════════

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // TESTS: coursDeRouteListProvider (Liste complète)
  // ══════════════════════════════════════════════════════════════════════════

  group('CDR List Provider - Liste complète (coursDeRouteListProvider)', () {
    test('retourne une liste vide si aucun CDR en base', () async {
      // Arrange
      final container = createTestContainer(seedData: []);

      // Act
      final result = await container.read(coursDeRouteListProvider.future);

      // Assert
      expect(result, isEmpty);

      container.dispose();
    });

    test('retourne tous les CDR incluant les DECHARGE', () async {
      // Arrange
      final container = createTestContainer(
        seedData: [cdrChargement1, cdrTransit, cdrArrive, cdrDecharge],
      );

      // Act
      final result = await container.read(coursDeRouteListProvider.future);

      // Assert
      expect(result, hasLength(4));
      expect(
        result.any((cdr) => cdr.statut == StatutCours.decharge),
        isTrue,
        reason: 'coursDeRouteListProvider doit inclure les DECHARGE',
      );

      container.dispose();
    });

    test('retourne les CDR triés par createdAt décroissant', () async {
      // Arrange
      final cdrOld = createTestCdr(
        id: 'cdr-old',
        statut: StatutCours.chargement,
        createdAt: DateTime(2025, 11, 1),
      );
      final cdrNew = createTestCdr(
        id: 'cdr-new',
        statut: StatutCours.transit,
        createdAt: DateTime(2025, 11, 20),
      );
      final cdrMid = createTestCdr(
        id: 'cdr-mid',
        statut: StatutCours.frontiere,
        createdAt: DateTime(2025, 11, 10),
      );

      final container = createTestContainer(
        seedData: [cdrOld, cdrNew, cdrMid], // Ordre d'insertion non trié
      );

      // Act
      final result = await container.read(coursDeRouteListProvider.future);

      // Assert
      expect(result, hasLength(3));
      expect(result[0].id, equals('cdr-new'), reason: 'Plus récent en premier');
      expect(result[1].id, equals('cdr-mid'));
      expect(result[2].id, equals('cdr-old'), reason: 'Plus ancien en dernier');

      container.dispose();
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TESTS: coursDeRouteActifsProvider (Cours actifs, sans DECHARGE)
  // ══════════════════════════════════════════════════════════════════════════

  group('CDR List Provider - Cours actifs (coursDeRouteActifsProvider)', () {
    test('retourne uniquement les CDR non déchargés', () async {
      // Arrange
      final container = createTestContainer(
        seedData: [
          cdrChargement1,
          cdrChargement2,
          cdrTransit,
          cdrFrontiere,
          cdrArrive,
          cdrDecharge, // EXCLU
        ],
      );

      // Act
      final result = await container.read(coursDeRouteActifsProvider.future);

      // Assert
      expect(result, hasLength(5), reason: 'Tous sauf DECHARGE');
      expect(
        result.every((cdr) => cdr.statut != StatutCours.decharge),
        isTrue,
        reason: 'Aucun CDR DECHARGE dans la liste',
      );

      container.dispose();
    });

    test('retourne une liste vide si tous les CDR sont DECHARGE', () async {
      // Arrange
      final container = createTestContainer(
        seedData: [
          cdrDecharge,
          createTestCdr(
            id: 'cdr-decharge-2',
            statut: StatutCours.decharge,
            volume: 8000.0,
          ),
        ],
      );

      // Act
      final result = await container.read(coursDeRouteActifsProvider.future);

      // Assert
      expect(result, isEmpty, reason: 'Tous les CDR sont terminés');

      container.dispose();
    });

    test(
      'inclut tous les statuts actifs: CHARGEMENT, TRANSIT, FRONTIERE, ARRIVE',
      () async {
        // Arrange
        final container = createTestContainer(
          seedData: [cdrChargement1, cdrTransit, cdrFrontiere, cdrArrive],
        );

        // Act
        final result = await container.read(coursDeRouteActifsProvider.future);

        // Assert
        expect(result, hasLength(4));

        final statuts = result.map((cdr) => cdr.statut).toSet();
        expect(
          statuts,
          containsAll([
            StatutCours.chargement,
            StatutCours.transit,
            StatutCours.frontiere,
            StatutCours.arrive,
          ]),
        );

        container.dispose();
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TESTS: coursDeRouteByStatutProvider (Filtrage par statut)
  // ══════════════════════════════════════════════════════════════════════════

  group(
    'CDR List Provider - Filtrage par statut (coursDeRouteByStatutProvider)',
    () {
      late ProviderContainer container;

      setUp(() {
        container = createTestContainer(
          seedData: [
            cdrChargement1,
            cdrChargement2,
            cdrTransit,
            cdrFrontiere,
            cdrArrive,
            cdrDecharge,
          ],
        );
      });

      tearDown(() {
        container.dispose();
      });

      test(
        'filtre CHARGEMENT: ne retourne que les CDR au chargement',
        () async {
          // Act
          final result = await container.read(
            coursDeRouteByStatutProvider(StatutCours.chargement).future,
          );

          // Assert
          expect(result, hasLength(2));
          expect(
            result.every((cdr) => cdr.statut == StatutCours.chargement),
            isTrue,
          );
        },
      );

      test('filtre TRANSIT: ne retourne que les CDR en transit', () async {
        // Act
        final result = await container.read(
          coursDeRouteByStatutProvider(StatutCours.transit).future,
        );

        // Assert
        expect(result, hasLength(1));
        expect(result.single.statut, equals(StatutCours.transit));
      });

      test(
        'filtre FRONTIERE: ne retourne que les CDR à la frontière',
        () async {
          // Act
          final result = await container.read(
            coursDeRouteByStatutProvider(StatutCours.frontiere).future,
          );

          // Assert
          expect(result, hasLength(1));
          expect(result.single.statut, equals(StatutCours.frontiere));
        },
      );

      test('filtre ARRIVE: ne retourne que les CDR arrivés', () async {
        // Act
        final result = await container.read(
          coursDeRouteByStatutProvider(StatutCours.arrive).future,
        );

        // Assert
        expect(result, hasLength(1));
        expect(result.single.statut, equals(StatutCours.arrive));
      });

      test('filtre DECHARGE: ne retourne que les CDR déchargés', () async {
        // Act
        final result = await container.read(
          coursDeRouteByStatutProvider(StatutCours.decharge).future,
        );

        // Assert
        expect(result, hasLength(1));
        expect(result.single.statut, equals(StatutCours.decharge));
      });
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // TESTS: coursDeRouteArrivesProvider (CDR au statut ARRIVE)
  // ══════════════════════════════════════════════════════════════════════════

  group('CDR List Provider - Arrivés (coursDeRouteArrivesProvider)', () {
    test('retourne uniquement les CDR au statut ARRIVE', () async {
      // Arrange
      final cdrArrive2 = createTestCdr(
        id: 'cdr-arrive-2',
        statut: StatutCours.arrive,
        volume: 17000.0,
      );

      final container = createTestContainer(
        seedData: [
          cdrChargement1,
          cdrTransit,
          cdrArrive,
          cdrArrive2,
          cdrDecharge,
        ],
      );

      // Act
      final result = await container.read(coursDeRouteArrivesProvider.future);

      // Assert
      expect(result, hasLength(2));
      expect(result.every((cdr) => cdr.statut == StatutCours.arrive), isTrue);

      container.dispose();
    });

    test('retourne une liste vide si aucun CDR arrivé', () async {
      // Arrange
      final container = createTestContainer(
        seedData: [cdrChargement1, cdrTransit, cdrDecharge],
      );

      // Act
      final result = await container.read(coursDeRouteArrivesProvider.future);

      // Assert
      expect(result, isEmpty);

      container.dispose();
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TESTS: Logique métier - Classification par catégorie business
  // ══════════════════════════════════════════════════════════════════════════

  group('CDR List Provider - Classification métier', () {
    test('"Au chargement": uniquement les CDR en statut CHARGEMENT', () async {
      // Arrange
      final container = createTestContainer(
        seedData: [
          cdrChargement1,
          cdrChargement2,
          cdrTransit,
          cdrArrive,
          cdrDecharge,
        ],
      );

      // Act
      final result = await container.read(
        coursDeRouteByStatutProvider(StatutCours.chargement).future,
      );

      // Assert
      expect(result, hasLength(2), reason: '"Au chargement" = CHARGEMENT');
      expect(
        result.every((cdr) => cdr.statut == StatutCours.chargement),
        isTrue,
      );

      container.dispose();
    });

    test(
      '"En route": contient TRANSIT et FRONTIERE, mais pas CHARGEMENT ni ARRIVE ni DECHARGE',
      () async {
        // Arrange
        final container = createTestContainer(
          seedData: [
            cdrChargement1,
            cdrTransit,
            cdrFrontiere,
            cdrArrive,
            cdrDecharge,
          ],
        );

        // Act: Récupérer TRANSIT + FRONTIERE séparément et combiner
        final transitList = await container.read(
          coursDeRouteByStatutProvider(StatutCours.transit).future,
        );
        final frontiereList = await container.read(
          coursDeRouteByStatutProvider(StatutCours.frontiere).future,
        );

        final enRouteList = [...transitList, ...frontiereList];

        // Assert
        expect(
          enRouteList,
          hasLength(2),
          reason: '"En route" = TRANSIT + FRONTIERE',
        );
        expect(
          enRouteList.map((cdr) => cdr.statut).toSet(),
          containsAll([StatutCours.transit, StatutCours.frontiere]),
        );
        expect(
          enRouteList.any(
            (cdr) =>
                cdr.statut == StatutCours.chargement ||
                cdr.statut == StatutCours.arrive ||
                cdr.statut == StatutCours.decharge,
          ),
          isFalse,
          reason: 'CHARGEMENT, ARRIVE, DECHARGE exclus de "En route"',
        );

        container.dispose();
      },
    );

    test('"Arrivés": uniquement les CDR en statut ARRIVE', () async {
      // Arrange
      final container = createTestContainer(
        seedData: [
          cdrChargement1,
          cdrTransit,
          cdrFrontiere,
          cdrArrive,
          cdrDecharge,
        ],
      );

      // Act
      final result = await container.read(
        coursDeRouteByStatutProvider(StatutCours.arrive).future,
      );

      // Assert
      expect(result, hasLength(1), reason: '"Arrivés" = ARRIVE');
      expect(result.single.statut, equals(StatutCours.arrive));

      container.dispose();
    });

    test('DECHARGE: exclu de toutes les catégories actives', () async {
      // Arrange
      final container = createTestContainer(
        seedData: [
          cdrChargement1,
          cdrTransit,
          cdrFrontiere,
          cdrArrive,
          cdrDecharge,
        ],
      );

      // Act
      final actifs = await container.read(coursDeRouteActifsProvider.future);

      // Assert
      expect(
        actifs.any((cdr) => cdr.statut == StatutCours.decharge),
        isFalse,
        reason: 'DECHARGE ne doit jamais apparaître dans les actifs',
      );
      expect(actifs, hasLength(4), reason: 'Tous sauf DECHARGE');

      container.dispose();
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TESTS: coursDeRouteByIdProvider
  // ══════════════════════════════════════════════════════════════════════════

  group(
    'CDR List Provider - Récupération par ID (coursDeRouteByIdProvider)',
    () {
      test('retourne le CDR correspondant à l\'ID', () async {
        // Arrange
        final container = createTestContainer(
          seedData: [cdrChargement1, cdrTransit, cdrArrive],
        );

        // Act
        final result = await container.read(
          coursDeRouteByIdProvider(cdrTransit.id).future,
        );

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(cdrTransit.id));
        expect(result.statut, equals(StatutCours.transit));

        container.dispose();
      });

      test('retourne null si l\'ID n\'existe pas', () async {
        // Arrange
        final container = createTestContainer(
          seedData: [cdrChargement1, cdrTransit],
        );

        // Act
        final result = await container.read(
          coursDeRouteByIdProvider('id-inexistant').future,
        );

        // Assert
        expect(result, isNull);

        container.dispose();
      });
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // TESTS: Tri et stabilité
  // ══════════════════════════════════════════════════════════════════════════

  group('CDR List Provider - Tri par date', () {
    test('retourne les CDR triés par createdAt décroissant', () async {
      // Arrange
      final cdrJan = createTestCdr(
        id: 'cdr-jan',
        statut: StatutCours.chargement,
        createdAt: DateTime(2025, 1, 15),
      );
      final cdrMar = createTestCdr(
        id: 'cdr-mar',
        statut: StatutCours.transit,
        createdAt: DateTime(2025, 3, 15),
      );
      final cdrFeb = createTestCdr(
        id: 'cdr-feb',
        statut: StatutCours.frontiere,
        createdAt: DateTime(2025, 2, 15),
      );

      final container = createTestContainer(seedData: [cdrJan, cdrFeb, cdrMar]);

      // Act
      final result = await container.read(coursDeRouteListProvider.future);

      // Assert
      expect(result[0].id, equals('cdr-mar'), reason: 'Mars = plus récent');
      expect(result[1].id, equals('cdr-feb'));
      expect(result[2].id, equals('cdr-jan'), reason: 'Janvier = plus ancien');

      container.dispose();
    });

    test('gère les CDR sans date de création (null)', () async {
      // Arrange
      final cdrWithDate = createTestCdr(
        id: 'cdr-with-date',
        statut: StatutCours.transit,
        createdAt: DateTime(2025, 11, 15),
      );
      final cdrNoDate = CoursDeRoute(
        id: 'cdr-no-date',
        fournisseurId: fournisseurId,
        produitId: produitId,
        depotDestinationId: depotPrincipalId,
        statut: StatutCours.chargement,
        createdAt: null,
      );

      final container = createTestContainer(seedData: [cdrNoDate, cdrWithDate]);

      // Act
      final result = await container.read(coursDeRouteListProvider.future);

      // Assert: CDR avec date en premier (plus récent que epoch)
      expect(result, hasLength(2));
      expect(result[0].id, equals('cdr-with-date'));
      expect(result[1].id, equals('cdr-no-date'));

      container.dispose();
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TESTS: Scénario complet de référence
  // ══════════════════════════════════════════════════════════════════════════

  group('CDR List Provider - Scénario de référence complet', () {
    test(
      'scénario: 2 CHARGEMENT, 1 TRANSIT, 1 FRONTIERE, 1 ARRIVE, 1 DECHARGE',
      () async {
        // Arrange: Jeu de données de référence
        final container = createTestContainer(
          seedData: [
            cdrChargement1, // CHARGEMENT
            cdrChargement2, // CHARGEMENT
            cdrTransit, // TRANSIT
            cdrFrontiere, // FRONTIERE
            cdrArrive, // ARRIVE
            cdrDecharge, // DECHARGE (exclu des actifs)
          ],
        );

        // Act
        final allCdr = await container.read(coursDeRouteListProvider.future);
        final actifsCdr = await container.read(
          coursDeRouteActifsProvider.future,
        );
        final chargementCdr = await container.read(
          coursDeRouteByStatutProvider(StatutCours.chargement).future,
        );
        final arriveCdr = await container.read(
          coursDeRouteByStatutProvider(StatutCours.arrive).future,
        );
        final dechargeCdr = await container.read(
          coursDeRouteByStatutProvider(StatutCours.decharge).future,
        );

        // Assert
        expect(allCdr, hasLength(6), reason: 'Total = 6');
        expect(actifsCdr, hasLength(5), reason: 'Actifs = 5 (sans DECHARGE)');
        expect(chargementCdr, hasLength(2), reason: 'Au chargement = 2');
        expect(arriveCdr, hasLength(1), reason: 'Arrivés = 1');
        expect(dechargeCdr, hasLength(1), reason: 'Déchargés = 1');

        // Vérifier que DECHARGE n'est pas dans les actifs
        expect(
          actifsCdr.any((cdr) => cdr.id == cdrDecharge.id),
          isFalse,
          reason: 'DECHARGE exclu des actifs',
        );

        container.dispose();
      },
    );

    test(
      'calcul des compteurs métier correspond à la règle business',
      () async {
        // Arrange
        final container = createTestContainer(
          seedData: [
            cdrChargement1, // Au chargement
            cdrChargement2, // Au chargement
            cdrTransit, // En route
            cdrFrontiere, // En route
            cdrArrive, // Arrivés
            cdrDecharge, // EXCLU
          ],
        );

        // Act: Simuler le calcul des compteurs métier
        final chargement = await container.read(
          coursDeRouteByStatutProvider(StatutCours.chargement).future,
        );
        final transit = await container.read(
          coursDeRouteByStatutProvider(StatutCours.transit).future,
        );
        final frontiere = await container.read(
          coursDeRouteByStatutProvider(StatutCours.frontiere).future,
        );
        final arrive = await container.read(
          coursDeRouteByStatutProvider(StatutCours.arrive).future,
        );

        final auChargementCount = chargement.length;
        final enRouteCount = transit.length + frontiere.length;
        final arrivesCount = arrive.length;
        final totalActifs = auChargementCount + enRouteCount + arrivesCount;

        // Assert
        expect(auChargementCount, equals(2), reason: 'Au chargement = 2');
        expect(
          enRouteCount,
          equals(2),
          reason: 'En route = TRANSIT(1) + FRONTIERE(1) = 2',
        );
        expect(arrivesCount, equals(1), reason: 'Arrivés = 1');
        expect(
          totalActifs,
          equals(5),
          reason: 'Total actifs = 5 (DECHARGE exclu)',
        );

        container.dispose();
      },
    );
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TESTS: Provider Integration et invalidation
  // ══════════════════════════════════════════════════════════════════════════

  group('CDR List Provider - Intégration et invalidation', () {
    test('les providers peuvent être utilisés simultanément', () async {
      // Arrange
      final container = createTestContainer(
        seedData: [cdrChargement1, cdrTransit, cdrArrive, cdrDecharge],
      );

      // Act: Lire plusieurs providers en parallèle
      final results = await Future.wait([
        container.read(coursDeRouteListProvider.future),
        container.read(coursDeRouteActifsProvider.future),
        container.read(
          coursDeRouteByStatutProvider(StatutCours.chargement).future,
        ),
      ]);

      // Assert
      expect(results[0], hasLength(4)); // Tous
      expect(results[1], hasLength(3)); // Actifs
      expect(results[2], hasLength(1)); // CHARGEMENT

      container.dispose();
    });

    test('invalidation force un nouveau fetch', () async {
      // Arrange
      final container = createTestContainer(
        seedData: [cdrChargement1, cdrTransit],
      );

      // Act
      final result1 = await container.read(coursDeRouteListProvider.future);
      container.invalidate(coursDeRouteListProvider);
      final result2 = await container.read(coursDeRouteListProvider.future);

      // Assert: Les deux résultats sont équivalents (même données sous-jacentes)
      expect(result1.length, equals(result2.length));

      container.dispose();
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TESTS: CoursDeRouteFilterNotifier
  // ══════════════════════════════════════════════════════════════════════════

  group('CDR Filter Notifier', () {
    test('état initial est vide', () {
      // Arrange
      final container = ProviderContainer();

      // Act
      final filters = container.read(coursDeRouteFilterProvider);

      // Assert
      expect(filters, isEmpty);

      container.dispose();
    });

    test('filterByStatut ajoute le filtre statut', () {
      // Arrange
      final container = ProviderContainer();

      // Act
      container
          .read(coursDeRouteFilterProvider.notifier)
          .filterByStatut(StatutCours.transit);

      // Assert
      final filters = container.read(coursDeRouteFilterProvider);
      expect(filters['statut'], equals(StatutCours.transit));

      container.dispose();
    });

    test('filterByStatut avec null supprime le filtre statut', () {
      // Arrange
      final container = ProviderContainer();
      container
          .read(coursDeRouteFilterProvider.notifier)
          .filterByStatut(StatutCours.transit);

      // Act
      container.read(coursDeRouteFilterProvider.notifier).filterByStatut(null);

      // Assert
      final filters = container.read(coursDeRouteFilterProvider);
      expect(filters.containsKey('statut'), isFalse);

      container.dispose();
    });

    test('clearFilters efface tous les filtres', () {
      // Arrange
      final container = ProviderContainer();
      container
          .read(coursDeRouteFilterProvider.notifier)
          .filterByStatut(StatutCours.transit);
      container
          .read(coursDeRouteFilterProvider.notifier)
          .filterByFournisseur('fournisseur-123');

      // Act
      container.read(coursDeRouteFilterProvider.notifier).clearFilters();

      // Assert
      final filters = container.read(coursDeRouteFilterProvider);
      expect(filters, isEmpty);

      container.dispose();
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // TESTS: Volumes agrégés
  // ══════════════════════════════════════════════════════════════════════════

  group('CDR List Provider - Volumes', () {
    test('les volumes sont correctement préservés dans la liste', () async {
      // Arrange
      final container = createTestContainer(
        seedData: [
          cdrChargement1, // 12000 L
          cdrChargement2, // 15000 L
          cdrTransit, // 18000 L
        ],
      );

      // Act
      final result = await container.read(coursDeRouteListProvider.future);

      // Assert
      final totalVolume = result.fold<double>(
        0.0,
        (sum, cdr) => sum + (cdr.volume ?? 0.0),
      );
      expect(totalVolume, equals(45000.0));

      container.dispose();
    });

    test('volume null est traité correctement', () async {
      // Arrange
      final cdrNoVolume = CoursDeRoute(
        id: 'cdr-no-volume',
        fournisseurId: fournisseurId,
        produitId: produitId,
        depotDestinationId: depotPrincipalId,
        statut: StatutCours.chargement,
        volume: null,
      );

      final container = createTestContainer(
        seedData: [cdrNoVolume, cdrTransit],
      );

      // Act
      final result = await container.read(coursDeRouteListProvider.future);

      // Assert
      expect(result, hasLength(2));
      final cdrWithNullVolume = result.firstWhere(
        (c) => c.id == 'cdr-no-volume',
      );
      expect(cdrWithNullVolume.volume, isNull);

      container.dispose();
    });
  });
}
