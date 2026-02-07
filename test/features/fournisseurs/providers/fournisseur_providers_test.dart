// Module Fournisseurs — Tests providers (AsyncValue, pas Supabase.instance).

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/fournisseurs/domain/models/fournisseur.dart';
import 'package:ml_pp_mvp/features/fournisseurs/domain/repositories/fournisseur_repository.dart';
import 'package:ml_pp_mvp/features/fournisseurs/providers/fournisseur_providers.dart';

/// Fake repository pour tests (aucune dépendance Supabase).
class FakeFournisseurRepository implements FournisseurRepository {
  final List<Fournisseur> _list;
  final Fournisseur? _byId;

  FakeFournisseurRepository({List<Fournisseur>? list, Fournisseur? byId})
      : _list = list ?? [],
        _byId = byId;

  @override
  Future<List<Fournisseur>> fetchAllFournisseurs() async => List.from(_list);

  @override
  Future<Fournisseur?> getById(String id) async => _byId;
}

void main() {
  group('fournisseursListProvider', () {
    test('loading puis data avec liste vide', () async {
      final container = ProviderContainer(
        overrides: [
          fournisseurRepositoryProvider.overrideWithValue(
            FakeFournisseurRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final list = await container.read(fournisseursListProvider.future);
      expect(list, isEmpty);
    });

    test('AsyncValue data contient les fournisseurs', () async {
      final seed = [
        const Fournisseur(id: '1', nom: 'F1', pays: 'CD'),
        const Fournisseur(id: '2', nom: 'F2', pays: 'FR'),
      ];
      final container = ProviderContainer(
        overrides: [
          fournisseurRepositoryProvider.overrideWithValue(
            FakeFournisseurRepository(list: seed),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(fournisseursListProvider.future);
      final asyncValue = container.read(fournisseursListProvider);
      expect(asyncValue.hasValue, isTrue);
      expect(asyncValue.value, hasLength(2));
      expect(asyncValue.value![0].nom, 'F1');
      expect(asyncValue.value![1].nom, 'F2');
    });

    test('override avec erreur : le future throw', () async {
      final container = ProviderContainer(
        overrides: [
          fournisseurRepositoryProvider.overrideWithValue(
            _ThrowingRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(fournisseursListProvider.future),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('fournisseurDetailProvider', () {
    test('retourne null quand absent', () async {
      final container = ProviderContainer(
        overrides: [
          fournisseurRepositoryProvider.overrideWithValue(
            FakeFournisseurRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final f = await container.read(fournisseurDetailProvider('id-x').future);
      expect(f, isNull);
    });

    test('retourne le fournisseur quand présent', () async {
      const fourn = Fournisseur(id: 'id-1', nom: 'Détail F', pays: 'BE');
      final container = ProviderContainer(
        overrides: [
          fournisseurRepositoryProvider.overrideWithValue(
            FakeFournisseurRepository(byId: fourn),
          ),
        ],
      );
      addTearDown(container.dispose);

      final f = await container.read(fournisseurDetailProvider('id-1').future);
      expect(f, isNotNull);
      expect(f!.nom, 'Détail F');
    });
  });
}

class _ThrowingRepository implements FournisseurRepository {
  @override
  Future<List<Fournisseur>> fetchAllFournisseurs() async {
    throw Exception('Test error');
  }

  @override
  Future<Fournisseur?> getById(String id) async => null;
}
