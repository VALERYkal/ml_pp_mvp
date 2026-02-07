// Filtre et tri fournisseurs — tests unitaires (fonctions pures, pas Supabase).

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/fournisseurs/domain/models/fournisseur.dart';
import 'package:ml_pp_mvp/features/fournisseurs/presentation/utils/fournisseur_list_utils.dart';

void main() {
  final list = [
    const Fournisseur(
      id: '1',
      nom: 'Alpha',
      pays: 'France',
      contactPersonne: 'Alice',
    ),
    const Fournisseur(
      id: '2',
      nom: 'Beta',
      pays: 'Belgique',
      contactPersonne: 'Bob',
    ),
    const Fournisseur(
      id: '3',
      nom: 'Gamma',
      pays: 'CD',
      contactPersonne: 'Charlie',
    ),
  ];

  group('filterFournisseurs', () {
    test('query vide retourne toute la liste', () {
      expect(filterFournisseurs(list, ''), list);
      expect(filterFournisseurs(list, '   '), list);
    });

    test('filtre par nom (case-insensitive)', () {
      expect(filterFournisseurs(list, 'alpha'), hasLength(1));
      expect(filterFournisseurs(list, 'ALPHA')[0].nom, 'Alpha');
      expect(filterFournisseurs(list, 'beta'), hasLength(1));
    });

    test('filtre par pays', () {
      expect(filterFournisseurs(list, 'fran'), hasLength(1));
      expect(filterFournisseurs(list, 'France')[0].nom, 'Alpha');
      expect(filterFournisseurs(list, 'bel'), hasLength(1));
      expect(filterFournisseurs(list, 'Belgique')[0].nom, 'Beta');
    });

    test('filtre par contact_personne', () {
      expect(filterFournisseurs(list, 'Bob'), hasLength(1));
      expect(filterFournisseurs(list, 'Charlie')[0].nom, 'Gamma');
      expect(filterFournisseurs(list, 'alice'), hasLength(1));
    });

    test('aucun match retourne liste vide', () {
      expect(filterFournisseurs(list, 'xyz'), isEmpty);
    });
  });

  group('sortFournisseursByNom', () {
    test('asc trie A→Z', () {
      final sorted = sortFournisseursByNom(list, true);
      expect(sorted.map((e) => e.nom).toList(), ['Alpha', 'Beta', 'Gamma']);
    });

    test('desc trie Z→A', () {
      final sorted = sortFournisseursByNom(list, false);
      expect(sorted.map((e) => e.nom).toList(), ['Gamma', 'Beta', 'Alpha']);
    });

    test('ne modifie pas la liste originale', () {
      final copy = List<Fournisseur>.from(list);
      sortFournisseursByNom(list, true);
      expect(list, copy);
    });
  });
}
