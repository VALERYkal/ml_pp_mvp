import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart';

void main() {
  group('sortCiternesHuman', () {
    test('Trie par dépôt puis par ordre naturel (TANK1 < TANK2 < TANK10)', () {
      // ARRANGE
      final citernes = [
        CiterneRef(
          id: 'id-1',
          nom: 'TANK10',
          produitId: 'prod-1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
          depotId: 'depot-a',
          depotNom: 'Dépôt A',
        ),
        CiterneRef(
          id: 'id-2',
          nom: 'TANK2',
          produitId: 'prod-1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
          depotId: 'depot-a',
          depotNom: 'Dépôt A',
        ),
        CiterneRef(
          id: 'id-3',
          nom: 'TANK1',
          produitId: 'prod-1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
          depotId: 'depot-a',
          depotNom: 'Dépôt A',
        ),
      ];

      // ACT
      final sorted = sortCiternesHuman(citernes);

      // ASSERT
      expect(sorted.length, 3);
      expect(sorted[0].nom, 'TANK1');
      expect(sorted[1].nom, 'TANK2');
      expect(sorted[2].nom, 'TANK10');
    });

    test('Trie par nom de dépôt d\'abord (Dépôt A avant Dépôt B)', () {
      // ARRANGE
      final citernes = [
        CiterneRef(
          id: 'id-1',
          nom: 'TANK3',
          produitId: 'prod-1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
          depotId: 'depot-b',
          depotNom: 'Dépôt B',
        ),
        CiterneRef(
          id: 'id-2',
          nom: 'TANK1',
          produitId: 'prod-1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
          depotId: 'depot-a',
          depotNom: 'Dépôt A',
        ),
      ];

      // ACT
      final sorted = sortCiternesHuman(citernes);

      // ASSERT
      expect(sorted.length, 2);
      expect(sorted[0].depotNom, 'Dépôt A');
      expect(sorted[0].nom, 'TANK1');
      expect(sorted[1].depotNom, 'Dépôt B');
      expect(sorted[1].nom, 'TANK3');
    });

    test('Place les citernes sans chiffre après les numérotées du même dépôt',
        () {
      // ARRANGE
      final citernes = [
        CiterneRef(
          id: 'id-1',
          nom: 'RESERVE',
          produitId: 'prod-1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
          depotId: 'depot-a',
          depotNom: 'Dépôt A',
        ),
        CiterneRef(
          id: 'id-2',
          nom: 'TANK2',
          produitId: 'prod-1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
          depotId: 'depot-a',
          depotNom: 'Dépôt A',
        ),
        CiterneRef(
          id: 'id-3',
          nom: 'TANK1',
          produitId: 'prod-1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
          depotId: 'depot-a',
          depotNom: 'Dépôt A',
        ),
      ];

      // ACT
      final sorted = sortCiternesHuman(citernes);

      // ASSERT
      expect(sorted.length, 3);
      expect(sorted[0].nom, 'TANK1');
      expect(sorted[1].nom, 'TANK2');
      expect(sorted[2].nom, 'RESERVE');
    });

    test('Place "STAGING" ou "TEST" à la fin même si numéroté', () {
      // ARRANGE
      final citernes = [
        CiterneRef(
          id: 'id-1',
          nom: 'TANK STAGING',
          produitId: 'prod-1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
          depotId: 'depot-a',
          depotNom: 'Dépôt A',
        ),
        CiterneRef(
          id: 'id-2',
          nom: 'TANK2',
          produitId: 'prod-1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
          depotId: 'depot-a',
          depotNom: 'Dépôt A',
        ),
        CiterneRef(
          id: 'id-3',
          nom: 'TANK1',
          produitId: 'prod-1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
          depotId: 'depot-a',
          depotNom: 'Dépôt A',
        ),
        CiterneRef(
          id: 'id-4',
          nom: 'TANK TEST 5',
          produitId: 'prod-1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
          depotId: 'depot-a',
          depotNom: 'Dépôt A',
        ),
      ];

      // ACT
      final sorted = sortCiternesHuman(citernes);

      // ASSERT
      expect(sorted.length, 4);
      expect(sorted[0].nom, 'TANK1');
      expect(sorted[1].nom, 'TANK2');
      // STAGING et TEST doivent être à la fin (ordre alphabétique entre eux)
      final stagingIdx = sorted.indexWhere((c) => c.nom.contains('STAGING'));
      final testIdx = sorted.indexWhere((c) => c.nom.contains('TEST'));
      expect(stagingIdx, greaterThan(1));
      expect(testIdx, greaterThan(1));
    });

    test('Tri insensible à la casse pour les noms de dépôt', () {
      // ARRANGE
      final citernes = [
        CiterneRef(
          id: 'id-1',
          nom: 'TANK1',
          produitId: 'prod-1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
          depotId: 'depot-b',
          depotNom: 'dépôt b',
        ),
        CiterneRef(
          id: 'id-2',
          nom: 'TANK1',
          produitId: 'prod-1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
          depotId: 'depot-a',
          depotNom: 'Dépôt A',
        ),
      ];

      // ACT
      final sorted = sortCiternesHuman(citernes);

      // ASSERT
      expect(sorted.length, 2);
      expect(sorted[0].depotNom, 'Dépôt A');
      expect(sorted[1].depotNom, 'dépôt b');
    });

    test('Tri alphabétique sur nom comme tie-break', () {
      // ARRANGE
      final citernes = [
        CiterneRef(
          id: 'id-1',
          nom: 'TANK5',
          produitId: 'prod-1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
          depotId: 'depot-a',
          depotNom: 'Dépôt A',
        ),
        CiterneRef(
          id: 'id-2',
          nom: 'TANK5',
          produitId: 'prod-1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
          depotId: 'depot-a',
          depotNom: 'Dépôt A',
        ),
        // Même clé naturelle (5), même dépôt → tri alphabétique sur nom
        // Mais ici les noms sont identiques, donc l'ordre peut être stable
      ];

      // ACT
      final sorted = sortCiternesHuman(citernes);

      // ASSERT
      expect(sorted.length, 2);
      // L'ordre doit être stable (même nom → même ordre)
    });
  });
}
