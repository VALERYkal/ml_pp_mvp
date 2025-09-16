// 📌 Module : Cours de Route - Tests des Transitions
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Tests unitaires pour les transitions de statuts CDR

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

void main() {
  group('CoursDeRoute Transitions Tests', () {
    group('Valid Transitions', () {
      test('should allow chargement → transit', () {
        expect(
          CoursDeRouteStateMachine.canTransition(
            StatutCours.chargement, 
            StatutCours.transit
          ), 
          true
        );
      });

      test('should allow transit → frontiere', () {
        expect(
          CoursDeRouteStateMachine.canTransition(
            StatutCours.transit, 
            StatutCours.frontiere
          ), 
          true
        );
      });

      test('should allow frontiere → arrive', () {
        expect(
          CoursDeRouteStateMachine.canTransition(
            StatutCours.frontiere, 
            StatutCours.arrive
          ), 
          true
        );
      });

      test('should allow arrive → decharge (with reception)', () {
        expect(
          CoursDeRouteStateMachine.canTransition(
            StatutCours.arrive, 
            StatutCours.decharge,
            fromReception: true
          ), 
          true
        );
      });
    });

    group('Invalid Transitions', () {
      test('should not allow chargement → arrive (skip transit)', () {
        expect(
          CoursDeRouteStateMachine.canTransition(
            StatutCours.chargement, 
            StatutCours.arrive
          ), 
          false
        );
      });

      test('should not allow decharge → transit (backward)', () {
        expect(
          CoursDeRouteStateMachine.canTransition(
            StatutCours.decharge, 
            StatutCours.transit
          ), 
          false
        );
      });

      test('should not allow arrive → decharge without reception', () {
        expect(
          CoursDeRouteStateMachine.canTransition(
            StatutCours.arrive, 
            StatutCours.decharge,
            fromReception: false
          ), 
          false
        );
      });

      test('should not allow chargement → frontiere (skip transit)', () {
        expect(
          CoursDeRouteStateMachine.canTransition(
            StatutCours.chargement, 
            StatutCours.frontiere
          ), 
          false
        );
      });

      test('should not allow transit → decharge (skip steps)', () {
        expect(
          CoursDeRouteStateMachine.canTransition(
            StatutCours.transit, 
            StatutCours.decharge
          ), 
          false
        );
      });
    });

    group('UI Status Variants', () {
      test('should parse DB ASCII values correctly', () {
        expect(StatutCoursDb.parseDb('CHARGEMENT'), StatutCours.chargement);
        expect(StatutCoursDb.parseDb('TRANSIT'), StatutCours.transit);
        expect(StatutCoursDb.parseDb('FRONTIERE'), StatutCours.frontiere);
        expect(StatutCoursDb.parseDb('ARRIVE'), StatutCours.arrive);
        expect(StatutCoursDb.parseDb('DECHARGE'), StatutCours.decharge);
      });

      test('should parse legacy lowercase values', () {
        expect(StatutCoursDb.parseDb('chargement'), StatutCours.chargement);
        expect(StatutCoursDb.parseDb('transit'), StatutCours.transit);
        expect(StatutCoursDb.parseDb('frontiere'), StatutCours.frontiere);
        expect(StatutCoursDb.parseDb('arrive'), StatutCours.arrive);
        expect(StatutCoursDb.parseDb('decharge'), StatutCours.decharge);
      });

      test('should parse UI accented values', () {
        expect(StatutCoursDb.parseDb('frontière'), StatutCours.frontiere);
        expect(StatutCoursDb.parseDb('arrivé'), StatutCours.arrive);
        expect(StatutCoursDb.parseDb('déchargé'), StatutCours.decharge);
      });

      test('should convert to DB format correctly', () {
        expect(StatutCours.chargement.db, 'CHARGEMENT');
        expect(StatutCours.transit.db, 'TRANSIT');
        expect(StatutCours.frontiere.db, 'FRONTIERE');
        expect(StatutCours.arrive.db, 'ARRIVE');
        expect(StatutCours.decharge.db, 'DECHARGE');
      });

      test('should display UI labels correctly', () {
        expect(StatutCours.chargement.label, 'Chargement');
        expect(StatutCours.transit.label, 'Transit');
        expect(StatutCours.frontiere.label, 'Frontière');
        expect(StatutCours.arrive.label, 'Arrivé');
        expect(StatutCours.decharge.label, 'Déchargé');
      });
    });

    group('Next Status Logic', () {
      test('should return correct next status', () {
        expect(StatutCoursDb.next(StatutCours.chargement), StatutCours.transit);
        expect(StatutCoursDb.next(StatutCours.transit), StatutCours.frontiere);
        expect(StatutCoursDb.next(StatutCours.frontiere), StatutCours.arrive);
        expect(StatutCoursDb.next(StatutCours.arrive), StatutCours.decharge);
        expect(StatutCoursDb.next(StatutCours.decharge), null);
      });

      test('should return allowed next statuses', () {
        expect(
          CoursDeRouteStateMachine.getAllowedNext(StatutCours.chargement),
          {StatutCours.transit}
        );
        expect(
          CoursDeRouteStateMachine.getAllowedNext(StatutCours.transit),
          {StatutCours.frontiere}
        );
        expect(
          CoursDeRouteStateMachine.getAllowedNext(StatutCours.frontiere),
          {StatutCours.arrive}
        );
        expect(
          CoursDeRouteStateMachine.getAllowedNext(StatutCours.arrive),
          {StatutCours.decharge}
        );
        expect(
          CoursDeRouteStateMachine.getAllowedNext(StatutCours.decharge),
          <StatutCours>{}
        );
      });
    });

    group('Edge Cases', () {
      test('should handle invalid status strings', () {
        expect(StatutCoursDb.parseDb('INVALID'), StatutCours.chargement);
        expect(StatutCoursDb.parseDb(''), StatutCours.chargement);
        expect(StatutCoursDb.parseDb(null), StatutCours.chargement);
      });

      test('should handle empty allowed next for final status', () {
        final allowed = CoursDeRouteStateMachine.getAllowedNext(StatutCours.decharge);
        expect(allowed, isEmpty);
      });

      test('should validate complete progression sequence', () {
        final sequence = [
          StatutCours.chargement,
          StatutCours.transit,
          StatutCours.frontiere,
          StatutCours.arrive,
          StatutCours.decharge,
        ];

        for (int i = 0; i < sequence.length - 1; i++) {
          final current = sequence[i];
          final next = sequence[i + 1];
          
          if (next == StatutCours.decharge) {
            expect(
              CoursDeRouteStateMachine.canTransition(current, next, fromReception: true),
              true,
              reason: 'Transition from $current to $next should be allowed with reception'
            );
          } else {
            expect(
              CoursDeRouteStateMachine.canTransition(current, next),
              true,
              reason: 'Transition from $current to $next should be allowed'
            );
          }
        }
      });
    });
  });
}
