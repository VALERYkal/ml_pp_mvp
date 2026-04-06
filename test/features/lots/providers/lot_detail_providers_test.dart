import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/lots/models/fournisseur_lot.dart';
import 'package:ml_pp_mvp/features/lots/models/lot_detail_view.dart';
import 'package:ml_pp_mvp/features/lots/providers/fournisseur_lot_providers.dart';
import '../fake_fournisseur_lot_service.dart';

void main() {
  group('lotDetailProvider', () {
    test('retourne null si lot absent', () async {
      final fake = FakeFournisseurLotService(lotOverride: null);
      final container = ProviderContainer(
        overrides: [fournisseurLotServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final v = await container.read(lotDetailProvider('missing').future);
      expect(v, isNull);
    });

    test('retourne lot + CDR liés', () async {
      final lot = FournisseurLot.empty().copyWith(
        id: 'lot-1',
        fournisseurId: 'f1',
        produitId: 'p1',
        reference: 'REF-99',
      );
      final cdr = CoursDeRoute.empty().copyWith(
        id: 'cdr-1',
        fournisseurId: 'f1',
        produitId: 'p1',
        depotDestinationId: 'd1',
        plaqueCamion: 'XYZ',
        volume: 1000,
      );
      final fake = FakeFournisseurLotService(
        lotOverride: lot,
        cdrsForLot: [cdr],
      );
      final container = ProviderContainer(
        overrides: [fournisseurLotServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final LotDetailView? v = await container.read(
        lotDetailProvider('lot-1').future,
      );
      expect(v, isNotNull);
      expect(v!.lot.reference, 'REF-99');
      expect(v.cdrs, hasLength(1));
      expect(v.cdrs.single.plaqueCamion, 'XYZ');
    });
  });

  group('cdrAvailableForLotProvider', () {
    test('retourne CDR filtrés fournisseur + produit', () async {
      final lot = FournisseurLot.empty().copyWith(
        id: 'lot-1',
        fournisseurId: 'f1',
        produitId: 'p1',
      );
      final ok = CoursDeRoute.empty().copyWith(
        id: 'a',
        fournisseurId: 'f1',
        produitId: 'p1',
        depotDestinationId: 'd',
      );
      final otherF = CoursDeRoute.empty().copyWith(
        id: 'b',
        fournisseurId: 'f2',
        produitId: 'p1',
        depotDestinationId: 'd',
      );
      final fake = FakeFournisseurLotService(
        lotOverride: lot,
        available: [ok, otherF],
      );
      final container = ProviderContainer(
        overrides: [fournisseurLotServiceProvider.overrideWithValue(fake)],
      );
      addTearDown(container.dispose);

      final list = await container.read(cdrAvailableForLotProvider(lot).future);
      expect(list, hasLength(1));
      expect(list.single.id, 'a');
    });
  });
}
