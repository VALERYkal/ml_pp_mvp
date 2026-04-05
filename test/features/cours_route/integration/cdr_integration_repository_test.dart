// 📌 Module : Cours de Route - Tests d'Intégration Repository
// 🧑 Auteur : Mona (IA Flutter/Supabase/Riverpod)
// 📅 Date : 2025-11-27
// 🧭 Description : Tests d'intégration pour valider la cohérence entre modèle, machine d'état et repository
//
// RÈGLE MÉTIER CDR (Cours de Route) :
// - Les statuts DB sont en MAJUSCULE : CHARGEMENT, TRANSIT, FRONTIERE, ARRIVE, DECHARGE
// - Toute transition doit passer par la machine d'état (CoursDeRouteStateMachine)
// - DECHARGE est terminal et exclu des listes actives
// - Les transitions invalides doivent être refusées

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';

// ════════════════════════════════════════════════════════════════════════════
// FAKE REPOSITORY IN-MEMORY
// ════════════════════════════════════════════════════════════════════════════

/// Fake repository CDR pour les tests d'intégration
/// Implémente les méthodes principales avec validation de la machine d'état
class FakeCoursDeRouteRepository implements CoursDeRouteService {
  final List<CoursDeRoute> _data = [];

  FakeCoursDeRouteRepository({List<CoursDeRoute>? seedData}) {
    if (seedData != null) {
      _data.addAll(seedData);
    }
  }

  @override
  Future<List<CoursDeRoute>> getAll() async {
    // Tri par createdAt décroissant (plus récent en premier)
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
    // Retourne uniquement les CDR non déchargés (logique métier)
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
    // Validation de base
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

    // Vérifier que le statut DB est bien en MAJUSCULE
    final statutDb = cours.statut.db;
    if (statutDb != statutDb.toUpperCase()) {
      throw StateError('Le statut DB doit être en MAJUSCULE: $statutDb');
    }

    _data.add(cours);
  }

  @override
  Future<void> update(CoursDeRoute cours) async {
    // Validation de base
    if (cours.volume != null && cours.volume! <= 0) {
      throw ArgumentError('volume must be > 0');
    }

    final index = _data.indexWhere((c) => c.id == cours.id);
    if (index == -1) {
      throw StateError('Cours de route non trouvé: ${cours.id}');
    }

    // Vérifier que le statut DB est bien en MAJUSCULE
    final statutDb = cours.statut.db;
    if (statutDb != statutDb.toUpperCase()) {
      throw StateError('Le statut DB doit être en MAJUSCULE: $statutDb');
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

    // ✅ VALIDATION MACHINE D'ÉTAT : Utiliser CoursDeRouteStateMachine
    if (!CoursDeRouteStateMachine.canTransition(
      from,
      to,
      fromReception: fromReception,
    )) {
      throw StateError(
        'Transition non autorisée: ${from.db} -> ${to.db} (fromReception: $fromReception)',
      );
    }

    // Vérifier que le statut DB est bien en MAJUSCULE
    final statutDb = to.db;
    if (statutDb != statutDb.toUpperCase()) {
      throw StateError('Le statut DB doit être en MAJUSCULE: $statutDb');
    }

    // Appliquer la transition
    _data[index] = current.copyWith(statut: to);
  }

  // Méthodes non utilisées dans les tests d'intégration (implémentées pour compatibilité)
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
}

// ════════════════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ════════════════════════════════════════════════════════════════════════════

/// Crée un scénario de référence avec tous les statuts CDR
List<CoursDeRoute> _createScenarioReference() {
  final baseDate = DateTime(2025, 11, 27);
  final depotId = '11111111-1111-1111-1111-111111111111';
  final fournisseurId = '22222222-2222-2222-2222-222222222222';
  final produitId = '33333333-3333-3333-3333-333333333333';

  return [
    // CDR en CHARGEMENT
    CoursDeRoute(
      id: 'cdr-001-chargement',
      fournisseurId: fournisseurId,
      produitId: produitId,
      depotDestinationId: depotId,
      plaqueCamion: 'ABC-123',
      transporteur: 'Transport Express',
      volume: 10000.0,
      statut: StatutCours.chargement,
      createdAt: baseDate.subtract(const Duration(days: 1)),
    ),

    // CDR en TRANSIT
    CoursDeRoute(
      id: 'cdr-002-transit',
      fournisseurId: fournisseurId,
      produitId: produitId,
      depotDestinationId: depotId,
      plaqueCamion: 'DEF-456',
      transporteur: 'Transport Express',
      volume: 15000.0,
      statut: StatutCours.transit,
      createdAt: baseDate.subtract(const Duration(days: 2)),
    ),

    // CDR en FRONTIERE
    CoursDeRoute(
      id: 'cdr-003-frontiere',
      fournisseurId: fournisseurId,
      produitId: produitId,
      depotDestinationId: depotId,
      plaqueCamion: 'GHI-789',
      transporteur: 'Transport Express',
      volume: 20000.0,
      statut: StatutCours.frontiere,
      createdAt: baseDate.subtract(const Duration(days: 3)),
    ),

    // CDR en ARRIVE
    CoursDeRoute(
      id: 'cdr-004-arrive',
      fournisseurId: fournisseurId,
      produitId: produitId,
      depotDestinationId: depotId,
      plaqueCamion: 'JKL-012',
      transporteur: 'Transport Express',
      volume: 25000.0,
      statut: StatutCours.arrive,
      createdAt: baseDate.subtract(const Duration(days: 4)),
    ),

    // CDR en DECHARGE (terminal)
    CoursDeRoute(
      id: 'cdr-005-decharge',
      fournisseurId: fournisseurId,
      produitId: produitId,
      depotDestinationId: depotId,
      plaqueCamion: 'MNO-345',
      transporteur: 'Transport Express',
      volume: 30000.0,
      statut: StatutCours.decharge,
      createdAt: baseDate.subtract(const Duration(days: 5)),
    ),
  ];
}

/// Crée un repository avec le scénario de référence
FakeCoursDeRouteRepository _buildRepositoryAvecScenarioDeReference() {
  return FakeCoursDeRouteRepository(seedData: _createScenarioReference());
}

// ════════════════════════════════════════════════════════════════════════════
// TESTS D'INTÉGRATION
// ════════════════════════════════════════════════════════════════════════════

void main() {
  group('Repository - fetch', () {
    test(
      'CDR Repository Integration - fetchAll retourne tous les CDR sans filtrage',
      () async {
        // Arrange
        final repository = _buildRepositoryAvecScenarioDeReference();

        // Act
        final result = await repository.getAll();

        // Assert
        expect(result, hasLength(5));
        expect(
          result.map((cdr) => cdr.statut),
          containsAll([
            StatutCours.chargement,
            StatutCours.transit,
            StatutCours.frontiere,
            StatutCours.arrive,
            StatutCours.decharge,
          ]),
        );

        // Vérifier le tri par createdAt décroissant
        expect(result.first.id, equals('cdr-001-chargement')); // Plus récent
        expect(result.last.id, equals('cdr-005-decharge')); // Plus ancien
      },
    );

    test(
      'CDR Repository Integration - fetchActifs exclut les CDR déchargés',
      () async {
        // Arrange
        final repository = _buildRepositoryAvecScenarioDeReference();

        // Act
        final result = await repository.getActifs();

        // Assert
        expect(result, hasLength(4)); // 5 total - 1 DECHARGE = 4 actifs
        expect(
          result.map((cdr) => cdr.statut),
          containsAll([
            StatutCours.chargement,
            StatutCours.transit,
            StatutCours.frontiere,
            StatutCours.arrive,
          ]),
        );
        expect(
          result.any((cdr) => cdr.statut == StatutCours.decharge),
          isFalse,
        );
      },
    );
  });

  group('Repository - getById', () {
    test(
      'CDR Repository Integration - getById retourne le bon CDR pour un id existant',
      () async {
        // Arrange
        final repository = _buildRepositoryAvecScenarioDeReference();
        const idRecherche = 'cdr-002-transit';

        // Act
        final result = await repository.getById(idRecherche);

        // Assert
        expect(result, isNotNull);
        expect(result!.id, equals(idRecherche));
        expect(result.statut, equals(StatutCours.transit));
        expect(result.plaqueCamion, equals('DEF-456'));
        expect(result.volume, equals(15000.0));
      },
    );

    test(
      'CDR Repository Integration - getById retourne null pour un id inexistant',
      () async {
        // Arrange
        final repository = _buildRepositoryAvecScenarioDeReference();
        const idInexistant = 'cdr-999-inexistant';

        // Act
        final result = await repository.getById(idInexistant);

        // Assert
        expect(result, isNull);
      },
    );
  });

  group('Repository - transitions', () {
    test(
      'CDR Repository Integration - updateStatut applique correctement la transition CHARGEMENT -> TRANSIT',
      () async {
        // Arrange
        final repository = _buildRepositoryAvecScenarioDeReference();
        const id = 'cdr-001-chargement';

        // Vérifier l'état initial
        final avant = await repository.getById(id);
        expect(avant!.statut, equals(StatutCours.chargement));

        // Act
        await repository.updateStatut(
          id: id,
          to: StatutCours.transit,
          fromReception: false,
        );

        // Assert
        final apres = await repository.getById(id);
        expect(apres!.statut, equals(StatutCours.transit));

        // Vérifier que le statut DB est bien en MAJUSCULE
        expect(apres.statut.db, equals('TRANSIT'));
      },
    );

    test(
      'CDR Repository Integration - updateStatut refuse une transition invalide (ex: CHARGEMENT -> DECHARGE)',
      () async {
        // Arrange
        final repository = _buildRepositoryAvecScenarioDeReference();
        const id = 'cdr-001-chargement';

        // Act & Assert
        expect(
          () => repository.updateStatut(
            id: id,
            to: StatutCours.decharge,
            fromReception: false,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Transition non autorisée'),
            ),
          ),
        );

        // Vérifier que le statut n'a pas changé
        final apres = await repository.getById(id);
        expect(apres!.statut, equals(StatutCours.chargement));
      },
    );

    test(
      'CDR Repository Integration - updateStatut refuse une transition invalide (ex: TRANSIT -> ARRIVE)',
      () async {
        // Arrange
        final repository = _buildRepositoryAvecScenarioDeReference();
        const id = 'cdr-002-transit';

        // Act & Assert
        // TRANSIT -> ARRIVE est invalide (doit passer par FRONTIERE)
        expect(
          () => repository.updateStatut(
            id: id,
            to: StatutCours.arrive,
            fromReception: false,
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Transition non autorisée'),
            ),
          ),
        );

        // Vérifier que le statut n'a pas changé
        final apres = await repository.getById(id);
        expect(apres!.statut, equals(StatutCours.transit));
      },
    );

    test(
      'CDR Repository Integration - updateStatut accepte la transition ARRIVE -> DECHARGE avec fromReception=true',
      () async {
        // Arrange
        final repository = _buildRepositoryAvecScenarioDeReference();
        const id = 'cdr-004-arrive';

        // Vérifier l'état initial
        final avant = await repository.getById(id);
        expect(avant!.statut, equals(StatutCours.arrive));

        // Act
        await repository.updateStatut(
          id: id,
          to: StatutCours.decharge,
          fromReception: true, // ✅ Requis pour ARRIVE -> DECHARGE
        );

        // Assert
        final apres = await repository.getById(id);
        expect(apres!.statut, equals(StatutCours.decharge));
        expect(apres.statut.db, equals('DECHARGE'));
      },
    );

    test(
      'CDR Repository Integration - updateStatut refuse ARRIVE -> DECHARGE sans fromReception',
      () async {
        // Arrange
        final repository = _buildRepositoryAvecScenarioDeReference();
        const id = 'cdr-004-arrive';

        // Act & Assert
        expect(
          () => repository.updateStatut(
            id: id,
            to: StatutCours.decharge,
            fromReception: false, // ❌ Doit être true
          ),
          throwsA(
            isA<StateError>().having(
              (e) => e.message,
              'message',
              contains('Transition non autorisée'),
            ),
          ),
        );
      },
    );

    test(
      'CDR Repository Integration - séquence complète de transitions valides',
      () async {
        // Arrange
        final repository = FakeCoursDeRouteRepository();
        final nouveauCdr = CoursDeRoute(
          id: 'cdr-sequence-test',
          fournisseurId: '22222222-2222-2222-2222-222222222222',
          produitId: '33333333-3333-3333-3333-333333333333',
          depotDestinationId: '11111111-1111-1111-1111-111111111111',
          plaqueCamion: 'SEQ-001',
          volume: 10000.0,
          statut: StatutCours.chargement,
          createdAt: DateTime(2025, 11, 27),
        );

        await repository.create(nouveauCdr);

        // Act & Assert : CHARGEMENT -> TRANSIT
        await repository.updateStatut(
          id: nouveauCdr.id,
          to: StatutCours.transit,
        );
        var cdr = await repository.getById(nouveauCdr.id);
        expect(cdr!.statut, equals(StatutCours.transit));

        // TRANSIT -> FRONTIERE
        await repository.updateStatut(
          id: nouveauCdr.id,
          to: StatutCours.frontiere,
        );
        cdr = await repository.getById(nouveauCdr.id);
        expect(cdr!.statut, equals(StatutCours.frontiere));

        // FRONTIERE -> ARRIVE
        await repository.updateStatut(
          id: nouveauCdr.id,
          to: StatutCours.arrive,
        );
        cdr = await repository.getById(nouveauCdr.id);
        expect(cdr!.statut, equals(StatutCours.arrive));

        // ARRIVE -> DECHARGE (avec fromReception)
        await repository.updateStatut(
          id: nouveauCdr.id,
          to: StatutCours.decharge,
          fromReception: true,
        );
        cdr = await repository.getById(nouveauCdr.id);
        expect(cdr!.statut, equals(StatutCours.decharge));

        // Vérifier que DECHARGE est terminal (pas de transition possible)
        expect(
          () => repository.updateStatut(
            id: nouveauCdr.id,
            to: StatutCours.transit,
          ),
          throwsA(isA<StateError>()),
        );
      },
    );
  });

  group('Repository - synchronisation DB', () {
    test(
      'CDR Repository Integration - les statuts en base (CHARGEMENT, TRANSIT, FRONTIERE, ARRIVE, DECHARGE) restent synchronisés avec StatutCours.db',
      () async {
        // Arrange
        final repository = _buildRepositoryAvecScenarioDeReference();

        // Act
        final all = await repository.getAll();

        // Assert : Vérifier que tous les statuts DB sont en MAJUSCULE
        for (final cdr in all) {
          final statutDb = cdr.statut.db;
          expect(
            statutDb,
            equals(statutDb.toUpperCase()),
            reason: 'Le statut DB doit être en MAJUSCULE pour ${cdr.id}',
          );

          // Vérifier la cohérence enum -> DB -> enum
          final parsed = StatutCoursDb.parseDb(statutDb);
          expect(
            parsed,
            equals(cdr.statut),
            reason:
                'Round-trip enum -> DB -> enum doit être cohérent pour ${cdr.id}',
          );
        }

        // Vérifier tous les statuts attendus
        final statutsDb = all.map((cdr) => cdr.statut.db).toSet();
        expect(
          statutsDb,
          containsAll([
            'CHARGEMENT',
            'TRANSIT',
            'FRONTIERE',
            'ARRIVE',
            'DECHARGE',
          ]),
        );
      },
    );

    test(
      'CDR Repository Integration - create valide que le statut DB est en MAJUSCULE',
      () async {
        // Arrange
        final repository = FakeCoursDeRouteRepository();
        final nouveauCdr = CoursDeRoute(
          id: 'cdr-test-create',
          fournisseurId: '22222222-2222-2222-2222-222222222222',
          produitId: '33333333-3333-3333-3333-333333333333',
          depotDestinationId: '11111111-1111-1111-1111-111111111111',
          plaqueCamion: 'TEST-001',
          volume: 10000.0,
          statut: StatutCours.transit,
          createdAt: DateTime(2025, 11, 27),
        );

        // Act
        await repository.create(nouveauCdr);

        // Assert
        final cdr = await repository.getById('cdr-test-create');
        expect(cdr, isNotNull);
        expect(cdr!.statut.db, equals('TRANSIT')); // MAJUSCULE
        expect(cdr.statut.db, equals(cdr.statut.db.toUpperCase()));
      },
    );

    test(
      'CDR Repository Integration - update valide que le statut DB est en MAJUSCULE',
      () async {
        // Arrange
        final repository = _buildRepositoryAvecScenarioDeReference();
        const id = 'cdr-001-chargement';
        final cdr = (await repository.getById(id))!;

        // Act
        final cdrModifie = cdr.copyWith(statut: StatutCours.transit);
        await repository.update(cdrModifie);

        // Assert
        final cdrApres = await repository.getById(id);
        expect(cdrApres!.statut.db, equals('TRANSIT')); // MAJUSCULE
        expect(cdrApres.statut.db, equals(cdrApres.statut.db.toUpperCase()));
      },
    );
  });
}
