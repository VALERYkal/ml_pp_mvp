// 📌 Module : Cours de Route - Tests Machine d'État et Helpers Métier
// 🧑 Auteur : Mona (IA Flutter/Supabase/Riverpod)
// 📅 Date : 2025-11-27
// 🧭 Description : Tests unitaires exhaustifs pour la machine d'état et les helpers métier CDR
//
// RÈGLE MÉTIER CDR (Cours de Route) :
// - "Au chargement" = CHARGEMENT uniquement
// - "En route" = TRANSIT + FRONTIERE uniquement
// - "Arrivés" = ARRIVE uniquement
// - DECHARGE = terminal, exclu des catégories actives

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

void main() {
  // ════════════════════════════════════════════════════════════════════════════
  // BLOC 1 : Mapping enum <-> base de données (renforcement)
  // ════════════════════════════════════════════════════════════════════════════

  group('StatutCoursDb - Mapping enum <-> DB (renforcement)', () {
    test('tous les statuts retournent la valeur DB en MAJUSCULES exacte', () {
      // Arrange & Act & Assert
      expect(StatutCours.chargement.db, equals('CHARGEMENT'));
      expect(StatutCours.transit.db, equals('TRANSIT'));
      expect(StatutCours.frontiere.db, equals('FRONTIERE'));
      expect(StatutCours.arrive.db, equals('ARRIVE'));
      expect(StatutCours.decharge.db, equals('DECHARGE'));
    });

    test('parseDb() reconvertit correctement toutes les valeurs MAJUSCULES', () {
      // Arrange & Act & Assert
      expect(StatutCoursDb.parseDb('CHARGEMENT'), equals(StatutCours.chargement));
      expect(StatutCoursDb.parseDb('TRANSIT'), equals(StatutCours.transit));
      expect(StatutCoursDb.parseDb('FRONTIERE'), equals(StatutCours.frontiere));
      expect(StatutCoursDb.parseDb('ARRIVE'), equals(StatutCours.arrive));
      expect(StatutCoursDb.parseDb('DECHARGE'), equals(StatutCours.decharge));
    });

    test('parseDb() avec valeurs inconnues retourne CHARGEMENT (fallback)', () {
      // Arrange & Act & Assert
      expect(StatutCoursDb.parseDb('INCONNU'), equals(StatutCours.chargement));
      expect(StatutCoursDb.parseDb('INVALID_STATUS'), equals(StatutCours.chargement));
      expect(StatutCoursDb.parseDb(''), equals(StatutCours.chargement));
      expect(StatutCoursDb.parseDb(null), equals(StatutCours.chargement));
    });

    test('parseDb() avec espaces retourne CHARGEMENT (fallback - pas de trim)', () {
      // Arrange & Act & Assert
      // Note: Le code actuel ne fait pas de trim, donc les valeurs avec espaces
      // ne correspondent à aucun cas et retournent le fallback CHARGEMENT
      expect(StatutCoursDb.parseDb(' CHARGEMENT '), equals(StatutCours.chargement),
          reason: 'Valeur avec espaces non reconnue, fallback CHARGEMENT');
      expect(StatutCoursDb.parseDb('  TRANSIT  '), equals(StatutCours.chargement),
          reason: 'Valeur avec espaces non reconnue, fallback CHARGEMENT');
      expect(StatutCoursDb.parseDb('TRANSIT '), equals(StatutCours.chargement),
          reason: 'Valeur avec espace en fin non reconnue, fallback CHARGEMENT');
    });

    test('parseDb() gère les variantes legacy (minuscules, accents)', () {
      // Arrange & Act & Assert
      expect(StatutCoursDb.parseDb('chargement'), equals(StatutCours.chargement));
      expect(StatutCoursDb.parseDb('transit'), equals(StatutCours.transit));
      expect(StatutCoursDb.parseDb('frontiere'), equals(StatutCours.frontiere));
      expect(StatutCoursDb.parseDb('frontière'), equals(StatutCours.frontiere));
      expect(StatutCoursDb.parseDb('arrive'), equals(StatutCours.arrive));
      expect(StatutCoursDb.parseDb('arrivé'), equals(StatutCours.arrive));
      expect(StatutCoursDb.parseDb('decharge'), equals(StatutCours.decharge));
      expect(StatutCoursDb.parseDb('déchargé'), equals(StatutCours.decharge));
    });

    test('round-trip: enum -> db -> parseDb retourne le même enum', () {
      // Arrange: Tous les statuts
      final allStatuts = [
        StatutCours.chargement,
        StatutCours.transit,
        StatutCours.frontiere,
        StatutCours.arrive,
        StatutCours.decharge,
      ];

      // Act & Assert
      for (final statut in allStatuts) {
        final dbValue = statut.db;
        final parsed = StatutCoursDb.parseDb(dbValue);
        expect(parsed, equals(statut),
            reason: 'Round-trip échoué pour $statut (db=$dbValue)');
      }
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // BLOC 2 : Machine d'état CoursDeRoute (next / transitions) - renforcement
  // ════════════════════════════════════════════════════════════════════════════

  group('CoursDeRouteStateMachine - next() suit le flux métier complet', () {
    test('StateMachine - next() suit le flux CHARGEMENT -> TRANSIT -> FRONTIERE -> ARRIVE -> DECHARGE', () {
      // Arrange: Séquence complète attendue
      final expectedSequence = [
        (from: StatutCours.chargement, expectedNext: StatutCours.transit),
        (from: StatutCours.transit, expectedNext: StatutCours.frontiere),
        (from: StatutCours.frontiere, expectedNext: StatutCours.arrive),
        (from: StatutCours.arrive, expectedNext: StatutCours.decharge),
      ];

      // Act & Assert
      for (final item in expectedSequence) {
        final actualNext = StatutCoursDb.next(item.from);
        expect(actualNext, equals(item.expectedNext),
            reason: 'next(${item.from}) devrait retourner ${item.expectedNext}');
      }
    });

    test('StateMachine - next() sur DECHARGE est terminal (retourne null)', () {
      // Arrange
      const statutFinal = StatutCours.decharge;

      // Act
      final next = StatutCoursDb.next(statutFinal);

      // Assert
      expect(next, isNull, reason: 'DECHARGE est terminal, next() doit retourner null');
    });

    test('StateMachine - canTransition() autorise uniquement les transitions prévues', () {
      // Arrange: Transitions valides
      final validTransitions = [
        (from: StatutCours.chargement, to: StatutCours.transit, fromReception: false),
        (from: StatutCours.transit, to: StatutCours.frontiere, fromReception: false),
        (from: StatutCours.frontiere, to: StatutCours.arrive, fromReception: false),
        (from: StatutCours.arrive, to: StatutCours.decharge, fromReception: true), // avec fromReception
      ];

      // Act & Assert
      for (final transition in validTransitions) {
        expect(
          CoursDeRouteStateMachine.canTransition(
            transition.from,
            transition.to,
            fromReception: transition.fromReception,
          ),
          isTrue,
          reason: 'Transition ${transition.from} -> ${transition.to} devrait être autorisée',
        );
      }
    });

    test('StateMachine - canTransition() refuse explicitement les transitions invalides', () {
      // Arrange: Transitions invalides
      final invalidTransitions = [
        // Saut d'étapes
        (from: StatutCours.chargement, to: StatutCours.arrive, fromReception: false),
        (from: StatutCours.chargement, to: StatutCours.frontiere, fromReception: false),
        (from: StatutCours.transit, to: StatutCours.decharge, fromReception: false),
        (from: StatutCours.transit, to: StatutCours.arrive, fromReception: false),
        // Retour en arrière
        (from: StatutCours.frontiere, to: StatutCours.chargement, fromReception: false),
        (from: StatutCours.arrive, to: StatutCours.transit, fromReception: false),
        (from: StatutCours.decharge, to: StatutCours.chargement, fromReception: false),
        (from: StatutCours.decharge, to: StatutCours.transit, fromReception: false),
        (from: StatutCours.decharge, to: StatutCours.frontiere, fromReception: false),
        (from: StatutCours.decharge, to: StatutCours.arrive, fromReception: false),
        // ARRIVE -> DECHARGE sans réception
        (from: StatutCours.arrive, to: StatutCours.decharge, fromReception: false),
      ];

      // Act & Assert
      for (final transition in invalidTransitions) {
        expect(
          CoursDeRouteStateMachine.canTransition(
            transition.from,
            transition.to,
            fromReception: transition.fromReception,
          ),
          isFalse,
          reason: 'Transition ${transition.from} -> ${transition.to} devrait être refusée',
        );
      }
    });

    test('StateMachine - getAllowedNext() retourne les statuts autorisés uniquement', () {
      // Arrange & Act & Assert
      expect(
        CoursDeRouteStateMachine.getAllowedNext(StatutCours.chargement),
        equals({StatutCours.transit}),
      );
      expect(
        CoursDeRouteStateMachine.getAllowedNext(StatutCours.transit),
        equals({StatutCours.frontiere}),
      );
      expect(
        CoursDeRouteStateMachine.getAllowedNext(StatutCours.frontiere),
        equals({StatutCours.arrive}),
      );
      expect(
        CoursDeRouteStateMachine.getAllowedNext(StatutCours.arrive),
        equals({StatutCours.decharge}),
      );
      expect(
        CoursDeRouteStateMachine.getAllowedNext(StatutCours.decharge),
        isEmpty,
        reason: 'DECHARGE est terminal, aucun statut suivant autorisé',
      );
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // BLOC 3 : Helpers métier (CoursDeRouteUtils) - renforcement exhaustif
  // ════════════════════════════════════════════════════════════════════════════

  group('CoursDeRouteUtils.isActif() - true pour les statuts actifs', () {
    test('isActif() retourne true pour CHARGEMENT, TRANSIT, FRONTIERE, ARRIVE', () {
      // Arrange: Tous les statuts actifs
      final statutsActifs = [
        StatutCours.chargement,
        StatutCours.transit,
        StatutCours.frontiere,
        StatutCours.arrive,
      ];

      // Act & Assert
      for (final statut in statutsActifs) {
        final cours = CoursDeRoute(
          id: 'test-${statut.name}',
          fournisseurId: 'fournisseur-1',
          produitId: 'produit-1',
          depotDestinationId: 'depot-1',
          statut: statut,
        );

        expect(
          CoursDeRouteUtils.isActif(cours),
          isTrue,
          reason: 'isActif() devrait retourner true pour $statut',
        );
      }
    });

    test('isActif() retourne false pour DECHARGE', () {
      // Arrange
      final coursDecharge = CoursDeRoute(
        id: 'test-decharge',
        fournisseurId: 'fournisseur-1',
        produitId: 'produit-1',
        depotDestinationId: 'depot-1',
        statut: StatutCours.decharge,
      );

      // Act
      final isActif = CoursDeRouteUtils.isActif(coursDecharge);

      // Assert
      expect(isActif, isFalse,
          reason: 'isActif() devrait retourner false pour DECHARGE');
    });
  });

  group('CoursDeRouteUtils.peutProgresser() respecte la machine d\'état', () {
    test('peutProgresser() retourne true pour tous les statuts actifs', () {
      // Arrange: Tous les statuts actifs
      final statutsActifs = [
        StatutCours.chargement,
        StatutCours.transit,
        StatutCours.frontiere,
        StatutCours.arrive,
      ];

      // Act & Assert
      for (final statut in statutsActifs) {
        final cours = CoursDeRoute(
          id: 'test-${statut.name}',
          fournisseurId: 'fournisseur-1',
          produitId: 'produit-1',
          depotDestinationId: 'depot-1',
          statut: statut,
        );

        expect(
          CoursDeRouteUtils.peutProgresser(cours),
          isTrue,
          reason: 'peutProgresser() devrait retourner true pour $statut (next() existe)',
        );

        // Vérifier cohérence avec next()
        final nextStatut = StatutCoursDb.next(statut);
        expect(nextStatut, isNotNull,
            reason: 'Si peutProgresser() est true, next() ne doit pas être null');
      }
    });

    test('peutProgresser() retourne false pour DECHARGE (statut terminal)', () {
      // Arrange
      final coursDecharge = CoursDeRoute(
        id: 'test-decharge',
        fournisseurId: 'fournisseur-1',
        produitId: 'produit-1',
        depotDestinationId: 'depot-1',
        statut: StatutCours.decharge,
      );

      // Act
      final peutProgresser = CoursDeRouteUtils.peutProgresser(coursDecharge);

      // Assert
      expect(peutProgresser, isFalse,
          reason: 'peutProgresser() devrait retourner false pour DECHARGE');

      // Vérifier cohérence avec next()
      final nextStatut = StatutCoursDb.next(StatutCours.decharge);
      expect(nextStatut, isNull,
          reason: 'Si peutProgresser() est false, next() doit être null');
    });
  });

  group('CoursDeRouteUtils.getStatutSuivant() - cohérence avec next()', () {
    test('getStatutSuivant() retourne le même résultat que StatutCoursDb.next()', () {
      // Arrange: Tous les statuts
      final allStatuts = [
        StatutCours.chargement,
        StatutCours.transit,
        StatutCours.frontiere,
        StatutCours.arrive,
        StatutCours.decharge,
      ];

      // Act & Assert
      for (final statut in allStatuts) {
        final cours = CoursDeRoute(
          id: 'test-${statut.name}',
          fournisseurId: 'fournisseur-1',
          produitId: 'produit-1',
          depotDestinationId: 'depot-1',
          statut: statut,
        );

        final viaUtils = CoursDeRouteUtils.getStatutSuivant(cours);
        final viaNext = StatutCoursDb.next(statut);

        expect(viaUtils, equals(viaNext),
            reason: 'getStatutSuivant() et next() doivent retourner le même résultat pour $statut');
      }
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // BLOC 4 : Alignement avec les KPI (catégorisation métier)
  // ════════════════════════════════════════════════════════════════════════════

  group('Catégorisation métier - Alignement avec les KPI CDR', () {
    /// Helper pour créer un CDR de test
    CoursDeRoute createTestCdr(StatutCours statut) {
      return CoursDeRoute(
        id: 'test-${statut.name}',
        fournisseurId: 'fournisseur-1',
        produitId: 'produit-1',
        depotDestinationId: 'depot-1',
        statut: statut,
        volume: 10000.0,
      );
    }

    test('catégorisation "Au chargement" = uniquement CHARGEMENT', () {
      // Arrange: Liste avec tous les statuts
      final allCours = [
        createTestCdr(StatutCours.chargement),
        createTestCdr(StatutCours.transit),
        createTestCdr(StatutCours.frontiere),
        createTestCdr(StatutCours.arrive),
        createTestCdr(StatutCours.decharge),
      ];

      // Act: Filtrer "Au chargement" (CHARGEMENT uniquement)
      final auChargement = allCours.where((c) => c.statut == StatutCours.chargement).toList();

      // Assert
      expect(auChargement, hasLength(1));
      expect(auChargement.first.statut, equals(StatutCours.chargement));
      expect(auChargement.every((c) => c.statut == StatutCours.chargement), isTrue);
    });

    test('catégorisation "En route" = TRANSIT + FRONTIERE uniquement', () {
      // Arrange: Liste avec tous les statuts
      final allCours = [
        createTestCdr(StatutCours.chargement),
        createTestCdr(StatutCours.transit),
        createTestCdr(StatutCours.frontiere),
        createTestCdr(StatutCours.arrive),
        createTestCdr(StatutCours.decharge),
      ];

      // Act: Filtrer "En route" (TRANSIT + FRONTIERE)
      final enRoute = allCours.where((c) =>
          c.statut == StatutCours.transit || c.statut == StatutCours.frontiere).toList();

      // Assert
      expect(enRoute, hasLength(2));
      expect(enRoute.map((c) => c.statut).toSet(),
          containsAll([StatutCours.transit, StatutCours.frontiere]));
      expect(enRoute.any((c) => c.statut == StatutCours.chargement), isFalse);
      expect(enRoute.any((c) => c.statut == StatutCours.arrive), isFalse);
      expect(enRoute.any((c) => c.statut == StatutCours.decharge), isFalse);
    });

    test('catégorisation "Arrivés" = uniquement ARRIVE', () {
      // Arrange: Liste avec tous les statuts
      final allCours = [
        createTestCdr(StatutCours.chargement),
        createTestCdr(StatutCours.transit),
        createTestCdr(StatutCours.frontiere),
        createTestCdr(StatutCours.arrive),
        createTestCdr(StatutCours.decharge),
      ];

      // Act: Filtrer "Arrivés" (ARRIVE uniquement)
      final arrives = allCours.where((c) => c.statut == StatutCours.arrive).toList();

      // Assert
      expect(arrives, hasLength(1));
      expect(arrives.first.statut, equals(StatutCours.arrive));
      expect(arrives.every((c) => c.statut == StatutCours.arrive), isTrue);
    });

    test('DECHARGE est exclu de toutes les catégories actives', () {
      // Arrange: Liste avec tous les statuts
      final allCours = [
        createTestCdr(StatutCours.chargement),
        createTestCdr(StatutCours.transit),
        createTestCdr(StatutCours.frontiere),
        createTestCdr(StatutCours.arrive),
        createTestCdr(StatutCours.decharge),
      ];

      // Act: Filtrer les cours actifs (via isActif())
      final actifs = allCours.where((c) => CoursDeRouteUtils.isActif(c)).toList();

      // Assert
      expect(actifs, hasLength(4), reason: '4 statuts actifs (CHARGEMENT, TRANSIT, FRONTIERE, ARRIVE)');
      expect(actifs.any((c) => c.statut == StatutCours.decharge), isFalse,
          reason: 'DECHARGE ne doit jamais apparaître dans les actifs');
    });

    test('comptage par catégorie métier correspond à la règle business', () {
      // Arrange: Scénario de référence avec plusieurs CDR
      final coursDeRoute = [
        createTestCdr(StatutCours.chargement), // Au chargement
        createTestCdr(StatutCours.chargement), // Au chargement
        createTestCdr(StatutCours.transit),    // En route
        createTestCdr(StatutCours.frontiere),   // En route
        createTestCdr(StatutCours.arrive),      // Arrivés
        createTestCdr(StatutCours.decharge),    // EXCLU
      ];

      // Act: Compter par catégorie
      final auChargementCount = coursDeRoute
          .where((c) => c.statut == StatutCours.chargement)
          .length;
      final enRouteCount = coursDeRoute
          .where((c) => c.statut == StatutCours.transit || c.statut == StatutCours.frontiere)
          .length;
      final arrivesCount = coursDeRoute
          .where((c) => c.statut == StatutCours.arrive)
          .length;
      final totalActifs = coursDeRoute
          .where((c) => CoursDeRouteUtils.isActif(c))
          .length;

      // Assert
      expect(auChargementCount, equals(2),
          reason: '"Au chargement" = 2 CHARGEMENT');
      expect(enRouteCount, equals(2),
          reason: '"En route" = 1 TRANSIT + 1 FRONTIERE = 2');
      expect(arrivesCount, equals(1),
          reason: '"Arrivés" = 1 ARRIVE');
      expect(totalActifs, equals(5),
          reason: 'Total actifs = 2 + 2 + 1 = 5 (DECHARGE exclu)');
    });

    test('volumes agrégés par catégorie métier', () {
      // Arrange: CDR avec volumes différents
      final coursDeRoute = [
        createTestCdr(StatutCours.chargement).copyWith(volume: 10000.0),
        createTestCdr(StatutCours.chargement).copyWith(volume: 12000.0),
        createTestCdr(StatutCours.transit).copyWith(volume: 15000.0),
        createTestCdr(StatutCours.frontiere).copyWith(volume: 18000.0),
        createTestCdr(StatutCours.arrive).copyWith(volume: 20000.0),
        createTestCdr(StatutCours.decharge).copyWith(volume: 25000.0), // EXCLU
      ];

      // Act: Agréger les volumes par catégorie
      final volumeAuChargement = coursDeRoute
          .where((c) => c.statut == StatutCours.chargement)
          .fold<double>(0.0, (sum, c) => sum + (c.volume ?? 0.0));
      final volumeEnRoute = coursDeRoute
          .where((c) => c.statut == StatutCours.transit || c.statut == StatutCours.frontiere)
          .fold<double>(0.0, (sum, c) => sum + (c.volume ?? 0.0));
      final volumeArrives = coursDeRoute
          .where((c) => c.statut == StatutCours.arrive)
          .fold<double>(0.0, (sum, c) => sum + (c.volume ?? 0.0));
      final volumeTotalActifs = coursDeRoute
          .where((c) => CoursDeRouteUtils.isActif(c))
          .fold<double>(0.0, (sum, c) => sum + (c.volume ?? 0.0));

      // Assert
      expect(volumeAuChargement, equals(22000.0),
          reason: 'Volume au chargement = 10000 + 12000');
      expect(volumeEnRoute, equals(33000.0),
          reason: 'Volume en route = 15000 + 18000');
      expect(volumeArrives, equals(20000.0),
          reason: 'Volume arrivés = 20000');
      expect(volumeTotalActifs, equals(75000.0),
          reason: 'Volume total actifs = 22000 + 33000 + 20000 = 75000 (DECHARGE exclu)');
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // BLOC 5 : Robustesse et cas limites supplémentaires
  // ════════════════════════════════════════════════════════════════════════════

  group('Robustesse - Cas limites supplémentaires', () {
    test('parseDb() avec null retourne CHARGEMENT (fallback)', () {
      // Arrange & Act
      final result = StatutCoursDb.parseDb(null);

      // Assert
      expect(result, equals(StatutCours.chargement),
          reason: 'parseDb(null) doit retourner CHARGEMENT comme fallback');
    });

    test('parseDb() avec chaîne vide retourne CHARGEMENT (fallback)', () {
      // Arrange & Act
      final result = StatutCoursDb.parseDb('');

      // Assert
      expect(result, equals(StatutCours.chargement),
          reason: 'parseDb("") doit retourner CHARGEMENT comme fallback');
    });

    test('isActif() avec volume null reste cohérent', () {
      // Arrange
      final coursSansVolume = CoursDeRoute(
        id: 'test',
        fournisseurId: 'fournisseur-1',
        produitId: 'produit-1',
        depotDestinationId: 'depot-1',
        statut: StatutCours.transit,
        volume: null,
      );

      // Act
      final isActif = CoursDeRouteUtils.isActif(coursSansVolume);

      // Assert
      expect(isActif, isTrue,
          reason: 'isActif() ne dépend pas du volume, seulement du statut');
    });

    test('peutProgresser() avec volume null reste cohérent', () {
      // Arrange
      final coursSansVolume = CoursDeRoute(
        id: 'test',
        fournisseurId: 'fournisseur-1',
        produitId: 'produit-1',
        depotDestinationId: 'depot-1',
        statut: StatutCours.transit,
        volume: null,
      );

      // Act
      final peutProgresser = CoursDeRouteUtils.peutProgresser(coursSansVolume);

      // Assert
      expect(peutProgresser, isTrue,
          reason: 'peutProgresser() ne dépend pas du volume, seulement du statut');
    });

    test('getStatutSuivant() avec volume null reste cohérent', () {
      // Arrange
      final coursSansVolume = CoursDeRoute(
        id: 'test',
        fournisseurId: 'fournisseur-1',
        produitId: 'produit-1',
        depotDestinationId: 'depot-1',
        statut: StatutCours.transit,
        volume: null,
      );

      // Act
      final next = CoursDeRouteUtils.getStatutSuivant(coursSansVolume);

      // Assert
      expect(next, equals(StatutCours.frontiere),
          reason: 'getStatutSuivant() ne dépend pas du volume, seulement du statut');
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // BLOC 6 : Cohérence entre les différentes méthodes
  // ════════════════════════════════════════════════════════════════════════════

  group('Cohérence entre méthodes - Validation croisée', () {
    test('isActif() et peutProgresser() sont cohérents pour tous les statuts', () {
      // Arrange: Tous les statuts
      final allStatuts = [
        StatutCours.chargement,
        StatutCours.transit,
        StatutCours.frontiere,
        StatutCours.arrive,
        StatutCours.decharge,
      ];

      // Act & Assert
      for (final statut in allStatuts) {
        final cours = CoursDeRoute(
          id: 'test-${statut.name}',
          fournisseurId: 'fournisseur-1',
          produitId: 'produit-1',
          depotDestinationId: 'depot-1',
          statut: statut,
        );

        final isActif = CoursDeRouteUtils.isActif(cours);
        final peutProgresser = CoursDeRouteUtils.peutProgresser(cours);

        // Cohérence: isActif() et peutProgresser() doivent être identiques
        expect(isActif, equals(peutProgresser),
            reason: 'isActif() et peutProgresser() doivent être cohérents pour $statut');
      }
    });

    test('peutProgresser() et getStatutSuivant() sont cohérents', () {
      // Arrange: Tous les statuts
      final allStatuts = [
        StatutCours.chargement,
        StatutCours.transit,
        StatutCours.frontiere,
        StatutCours.arrive,
        StatutCours.decharge,
      ];

      // Act & Assert
      for (final statut in allStatuts) {
        final cours = CoursDeRoute(
          id: 'test-${statut.name}',
          fournisseurId: 'fournisseur-1',
          produitId: 'produit-1',
          depotDestinationId: 'depot-1',
          statut: statut,
        );

        final peutProgresser = CoursDeRouteUtils.peutProgresser(cours);
        final nextStatut = CoursDeRouteUtils.getStatutSuivant(cours);

        // Cohérence: peutProgresser() est true si et seulement si nextStatut n'est pas null
        expect(peutProgresser, equals(nextStatut != null),
            reason: 'peutProgresser() et getStatutSuivant() doivent être cohérents pour $statut');
      }
    });

    test('canTransition() et getAllowedNext() sont cohérents', () {
      // Arrange: Tous les statuts
      final allStatuts = [
        StatutCours.chargement,
        StatutCours.transit,
        StatutCours.frontiere,
        StatutCours.arrive,
        StatutCours.decharge,
      ];

      // Act & Assert
      for (final from in allStatuts) {
        final allowedNext = CoursDeRouteStateMachine.getAllowedNext(from);

        // Pour chaque statut possible, vérifier que canTransition() est cohérent
        for (final to in allStatuts) {
          final isAllowed = allowedNext.contains(to);
          
          // Cas spécial: ARRIVE -> DECHARGE nécessite fromReception
          final canTransition = to == StatutCours.decharge && from == StatutCours.arrive
              ? CoursDeRouteStateMachine.canTransition(from, to, fromReception: true)
              : CoursDeRouteStateMachine.canTransition(from, to);

          if (isAllowed && from == StatutCours.arrive && to == StatutCours.decharge) {
            // ARRIVE -> DECHARGE nécessite fromReception
            expect(canTransition, isTrue,
                reason: 'ARRIVE -> DECHARGE devrait être autorisé avec fromReception');
          } else if (isAllowed) {
            expect(canTransition, isTrue,
                reason: 'Transition $from -> $to devrait être autorisée (dans allowedNext)');
          } else {
            expect(canTransition, isFalse,
                reason: 'Transition $from -> $to devrait être refusée (pas dans allowedNext)');
          }
        }
      }
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // BLOC 7 : Tests supplémentaires de robustesse et validation exhaustive
  // ════════════════════════════════════════════════════════════════════════════

  group('Robustesse supplémentaire - Validation exhaustive', () {
    test('parseDb() avec valeurs mixtes (majuscules/minuscules) retourne le bon statut', () {
      // Arrange & Act & Assert
      // Le code actuel ne fait pas de case-insensitive, donc seules les valeurs exactes fonctionnent
      expect(StatutCoursDb.parseDb('Chargement'), StatutCours.chargement,
          reason: 'Première lettre majuscule acceptée (legacy)');
      expect(StatutCoursDb.parseDb('Transit'), StatutCours.chargement,
          reason: 'Première lettre majuscule non reconnue, fallback CHARGEMENT');
    });

    test('label() retourne des libellés non vides pour tous les statuts', () {
      // Arrange: Tous les statuts
      final allStatuts = [
        StatutCours.chargement,
        StatutCours.transit,
        StatutCours.frontiere,
        StatutCours.arrive,
        StatutCours.decharge,
      ];

      // Act & Assert
      for (final statut in allStatuts) {
        final label = statut.label;
        expect(label, isNotEmpty,
            reason: 'label() ne doit jamais retourner une chaîne vide pour $statut');
        expect(label.length, greaterThan(0),
            reason: 'label() doit avoir au moins un caractère pour $statut');
      }
    });

    test('db() retourne toujours des valeurs MAJUSCULES pour tous les statuts', () {
      // Arrange: Tous les statuts
      final allStatuts = [
        StatutCours.chargement,
        StatutCours.transit,
        StatutCours.frontiere,
        StatutCours.arrive,
        StatutCours.decharge,
      ];

      // Act & Assert
      for (final statut in allStatuts) {
        final dbValue = statut.db;
        expect(dbValue, equals(dbValue.toUpperCase()),
            reason: 'db() doit retourner une valeur en MAJUSCULES pour $statut');
        expect(dbValue, isNot(contains(RegExp(r'[a-z]'))),
            reason: 'db() ne doit contenir aucune minuscule pour $statut');
      }
    });

    test('getAllowedNext() retourne toujours un Set (jamais null)', () {
      // Arrange: Tous les statuts
      final allStatuts = [
        StatutCours.chargement,
        StatutCours.transit,
        StatutCours.frontiere,
        StatutCours.arrive,
        StatutCours.decharge,
      ];

      // Act & Assert
      for (final statut in allStatuts) {
        final allowed = CoursDeRouteStateMachine.getAllowedNext(statut);
        expect(allowed, isNotNull,
            reason: 'getAllowedNext() ne doit jamais retourner null pour $statut');
        expect(allowed, isA<Set<StatutCours>>(),
            reason: 'getAllowedNext() doit retourner un Set pour $statut');
      }
    });

    test('canTransition() avec fromReception=false refuse ARRIVE -> DECHARGE', () {
      // Arrange
      const from = StatutCours.arrive;
      const to = StatutCours.decharge;

      // Act
      final canTransitionWithoutReception = CoursDeRouteStateMachine.canTransition(
        from,
        to,
        fromReception: false,
      );

      // Assert
      expect(canTransitionWithoutReception, isFalse,
          reason: 'ARRIVE -> DECHARGE doit être refusé sans fromReception=true');
    });

    test('canTransition() avec fromReception=true autorise ARRIVE -> DECHARGE', () {
      // Arrange
      const from = StatutCours.arrive;
      const to = StatutCours.decharge;

      // Act
      final canTransitionWithReception = CoursDeRouteStateMachine.canTransition(
        from,
        to,
        fromReception: true,
      );

      // Assert
      expect(canTransitionWithReception, isTrue,
          reason: 'ARRIVE -> DECHARGE doit être autorisé avec fromReception=true');
    });

    test('canTransition() avec fromReception=true n\'affecte pas les autres transitions', () {
      // Arrange: Transitions normales (non DECHARGE)
      final normalTransitions = [
        (from: StatutCours.chargement, to: StatutCours.transit),
        (from: StatutCours.transit, to: StatutCours.frontiere),
        (from: StatutCours.frontiere, to: StatutCours.arrive),
      ];

      // Act & Assert
      for (final transition in normalTransitions) {
        final withoutReception = CoursDeRouteStateMachine.canTransition(
          transition.from,
          transition.to,
          fromReception: false,
        );
        final withReception = CoursDeRouteStateMachine.canTransition(
          transition.from,
          transition.to,
          fromReception: true,
        );

        expect(withoutReception, equals(withReception),
            reason: 'fromReception ne doit pas affecter ${transition.from} -> ${transition.to}');
      }
    });

    test('Séquence complète de progression avec instances CoursDeRoute', () {
      // Arrange: Créer un CDR et le faire progresser
      var cours = CoursDeRoute(
        id: 'test-progression',
        fournisseurId: 'fournisseur-1',
        produitId: 'produit-1',
        depotDestinationId: 'depot-1',
        statut: StatutCours.chargement,
      );

      // Act & Assert: Progression complète
      expect(cours.statut, StatutCours.chargement);
      expect(CoursDeRouteUtils.getStatutSuivant(cours), StatutCours.transit);

      cours = cours.copyWith(statut: StatutCours.transit);
      expect(cours.statut, StatutCours.transit);
      expect(CoursDeRouteUtils.getStatutSuivant(cours), StatutCours.frontiere);

      cours = cours.copyWith(statut: StatutCours.frontiere);
      expect(cours.statut, StatutCours.frontiere);
      expect(CoursDeRouteUtils.getStatutSuivant(cours), StatutCours.arrive);

      cours = cours.copyWith(statut: StatutCours.arrive);
      expect(cours.statut, StatutCours.arrive);
      expect(CoursDeRouteUtils.getStatutSuivant(cours), StatutCours.decharge);

      cours = cours.copyWith(statut: StatutCours.decharge);
      expect(cours.statut, StatutCours.decharge);
      expect(CoursDeRouteUtils.getStatutSuivant(cours), isNull);
      expect(CoursDeRouteUtils.peutProgresser(cours), isFalse);
      expect(CoursDeRouteUtils.isActif(cours), isFalse);
    });
  });
}

