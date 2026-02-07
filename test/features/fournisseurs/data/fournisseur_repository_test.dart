// Module Fournisseurs — Tests unitaires repository (mock Supabase, pas Supabase.instance).

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/fournisseurs/data/repositories/supabase_fournisseur_repository.dart';
import '../../../support/fakes/fake_supabase_query.dart';

void main() {
  group('SupabaseFournisseurRepository', () {
    late FakeSupabaseClient fakeClient;
    late SupabaseFournisseurRepository repo;

    setUp(() {
      fakeClient = FakeSupabaseClient();
      repo = SupabaseFournisseurRepository(fakeClient);
    });

    test('fetchAllFournisseurs retourne la liste des fournisseurs', () async {
      // Ordre seed : le fake ne trie pas, le repo attend déjà trié par la DB
      fakeClient.setViewData('fournisseurs', [
        {
          'id': 'id-a',
          'nom': 'Alpha',
          'contact_personne': 'Contact A',
          'email': null,
          'telephone': null,
          'adresse': null,
          'pays': 'FR',
          'note_supplementaire': null,
          'created_at': '2026-01-02T12:00:00.000Z',
        },
        {
          'id': 'id-b',
          'nom': 'Beta',
          'contact_personne': null,
          'email': 'b@test.com',
          'telephone': null,
          'adresse': null,
          'pays': 'CD',
          'note_supplementaire': null,
          'created_at': '2026-01-01T12:00:00.000Z',
        },
      ]);

      final list = await repo.fetchAllFournisseurs();

      expect(list.length, 2);
      expect(list[0].nom, 'Alpha');
      expect(list[0].pays, 'FR');
      expect(list[0].contactPersonne, 'Contact A');
      expect(list[1].nom, 'Beta');
      expect(list[1].email, 'b@test.com');
      expect(fakeClient.fromCalls, ['fournisseurs']);
    });

    test('fetchAllFournisseurs retourne liste vide si aucune donnée', () async {
      fakeClient.setViewData('fournisseurs', []);

      final list = await repo.fetchAllFournisseurs();

      expect(list, isEmpty);
    });

    test('getById avec id vide retourne null', () async {
      final one = await repo.getById('');
      expect(one, isNull);
    });
  });
}
