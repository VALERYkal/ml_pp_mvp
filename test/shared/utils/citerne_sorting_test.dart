import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/shared/utils/citerne_sorting.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart';

void main() {
  group('extractFirstNumber', () {
    test('extrait le premier nombre d\'une chaîne', () {
      expect(extractFirstNumber('TANK12'), 12);
      expect(extractFirstNumber('TANK1'), 1);
      expect(extractFirstNumber('Cuve 5'), 5);
      expect(extractFirstNumber('Cuve 10'), 10);
      expect(extractFirstNumber('TANK123'), 123);
    });

    test('retourne 999999 si aucun nombre trouvé', () {
      expect(extractFirstNumber('Alpha'), 999999);
      expect(extractFirstNumber('Beta'), 999999);
      expect(extractFirstNumber(''), 999999);
      expect(extractFirstNumber('Cuve A'), 999999);
    });

    test('extrait le premier nombre même avec texte avant/après', () {
      expect(extractFirstNumber('TANK12'), 12);
      expect(extractFirstNumber('Cuve 2 litres'), 2);
      expect(extractFirstNumber('Reservoir 100L'), 100);
    });
  });

  group('sortCiternesForReception', () {
    test('trie TANK1..TANK6 dans l\'ordre numérique', () {
      final citernes = [
        CiterneRef(
          id: '1',
          nom: 'TANK3',
          produitId: 'p1',
          capaciteTotale: 1000,
          capaciteSecurite: 100,
          statut: 'active',
        ),
        CiterneRef(
          id: '2',
          nom: 'TANK1',
          produitId: 'p1',
          capaciteTotale: 1000,
          capaciteSecurite: 100,
          statut: 'active',
        ),
        CiterneRef(
          id: '3',
          nom: 'TANK6',
          produitId: 'p1',
          capaciteTotale: 1000,
          capaciteSecurite: 100,
          statut: 'active',
        ),
        CiterneRef(
          id: '4',
          nom: 'TANK2',
          produitId: 'p1',
          capaciteTotale: 1000,
          capaciteSecurite: 100,
          statut: 'active',
        ),
      ];

      final sorted = sortCiternesForReception(citernes);

      expect(sorted.length, 4);
      expect(sorted[0].nom, 'TANK1');
      expect(sorted[1].nom, 'TANK2');
      expect(sorted[2].nom, 'TANK3');
      expect(sorted[3].nom, 'TANK6');
    });

    test('trie mix avec texte: Cuve 10, Cuve 2, Cuve A', () {
      final citernes = [
        CiterneRef(
          id: '1',
          nom: 'Cuve 10',
          produitId: 'p1',
          capaciteTotale: 1000,
          capaciteSecurite: 100,
          statut: 'active',
        ),
        CiterneRef(
          id: '2',
          nom: 'Cuve 2',
          produitId: 'p1',
          capaciteTotale: 1000,
          capaciteSecurite: 100,
          statut: 'active',
        ),
        CiterneRef(
          id: '3',
          nom: 'Cuve A',
          produitId: 'p1',
          capaciteTotale: 1000,
          capaciteSecurite: 100,
          statut: 'active',
        ),
      ];

      final sorted = sortCiternesForReception(citernes);

      expect(sorted.length, 3);
      expect(sorted[0].nom, 'Cuve 2');
      expect(sorted[1].nom, 'Cuve 10');
      expect(sorted[2].nom, 'Cuve A');
    });

    test('trie alphabétiquement si aucun chiffre', () {
      final citernes = [
        CiterneRef(
          id: '1',
          nom: 'Beta',
          produitId: 'p1',
          capaciteTotale: 1000,
          capaciteSecurite: 100,
          statut: 'active',
        ),
        CiterneRef(
          id: '2',
          nom: 'Alpha',
          produitId: 'p1',
          capaciteTotale: 1000,
          capaciteSecurite: 100,
          statut: 'active',
        ),
      ];

      final sorted = sortCiternesForReception(citernes);

      expect(sorted.length, 2);
      expect(sorted[0].nom, 'Alpha');
      expect(sorted[1].nom, 'Beta');
    });

    test('trie avec numéros identiques: tri alphabétique', () {
      final citernes = [
        CiterneRef(
          id: '1',
          nom: 'TANK5B',
          produitId: 'p1',
          capaciteTotale: 1000,
          capaciteSecurite: 100,
          statut: 'active',
        ),
        CiterneRef(
          id: '2',
          nom: 'TANK5A',
          produitId: 'p1',
          capaciteTotale: 1000,
          capaciteSecurite: 100,
          statut: 'active',
        ),
      ];

      final sorted = sortCiternesForReception(citernes);

      expect(sorted.length, 2);
      expect(sorted[0].nom, 'TANK5A');
      expect(sorted[1].nom, 'TANK5B');
    });

    test('trie avec mix numéros et texte: numéros d\'abord', () {
      final citernes = [
        CiterneRef(
          id: '1',
          nom: 'Alpha',
          produitId: 'p1',
          capaciteTotale: 1000,
          capaciteSecurite: 100,
          statut: 'active',
        ),
        CiterneRef(
          id: '2',
          nom: 'TANK1',
          produitId: 'p1',
          capaciteTotale: 1000,
          capaciteSecurite: 100,
          statut: 'active',
        ),
        CiterneRef(
          id: '3',
          nom: 'Beta',
          produitId: 'p1',
          capaciteTotale: 1000,
          capaciteSecurite: 100,
          statut: 'active',
        ),
      ];

      final sorted = sortCiternesForReception(citernes);

      expect(sorted.length, 3);
      expect(sorted[0].nom, 'TANK1'); // Numéro d'abord
      expect(sorted[1].nom, 'Alpha'); // Puis alphabétique
      expect(sorted[2].nom, 'Beta');
    });

    test('gère liste vide', () {
      final sorted = sortCiternesForReception([]);
      expect(sorted, isEmpty);
    });

    test('gère liste avec un seul élément', () {
      final citernes = [
        CiterneRef(
          id: '1',
          nom: 'TANK1',
          produitId: 'p1',
          capaciteTotale: 1000,
          capaciteSecurite: 100,
          statut: 'active',
        ),
      ];

      final sorted = sortCiternesForReception(citernes);
      expect(sorted.length, 1);
      expect(sorted[0].nom, 'TANK1');
    });
  });
}
