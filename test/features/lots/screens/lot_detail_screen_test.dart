import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/lots/models/fournisseur_lot.dart';
import 'package:ml_pp_mvp/features/lots/models/lot_detail_view.dart';
import 'package:ml_pp_mvp/features/lots/providers/fournisseur_lot_providers.dart';
import 'package:ml_pp_mvp/features/lots/screens/lot_detail_screen.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';
import '../fake_fournisseur_lot_service.dart';

RefDataCache _emptyRefData() => RefDataCache(
      fournisseurs: const {},
      produits: const {},
      produitCodes: const {},
      depots: const {},
      loadedAt: DateTime.now(),
    );

/// `lotDetail` reflète l’état courant du fake (invalidation après clôture, etc.).
Override lotDetailProviderOverride(FakeFournisseurLotService fake) {
  return lotDetailProvider.overrideWith((ref, id) async {
    final l = fake.lotOverride;
    if (l == null || id != l.id) return null;
    return LotDetailView(lot: l, cdrs: fake.cdrsForLot);
  });
}

void main() {
  testWidgets('affiche la synthèse et la référence du lot', (tester) async {
    final lot = FournisseurLot.empty().copyWith(
      id: 'lot-1',
      fournisseurId: 'f1',
      produitId: 'p1',
      reference: 'REF-UI',
      note: 'Note test',
    );
    final cdr = CoursDeRoute.empty().copyWith(
      id: 'cdr-1',
      fournisseurId: 'f1',
      produitId: 'p1',
      depotDestinationId: 'd1',
      plaqueCamion: 'AB-123-CD',
      statut: StatutCours.arrive,
      volume: 5000,
    );
    final fake = FakeFournisseurLotService(
      lotOverride: lot,
      cdrsForLot: [cdr],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fournisseurLotServiceProvider.overrideWithValue(fake),
          lotDetailProviderOverride(fake),
          userRoleProvider.overrideWith((ref) => UserRole.operateur),
          refDataProvider.overrideWith((ref) async => _emptyRefData()),
        ],
        child: const MaterialApp(
          home: LotDetailScreen(lotId: 'lot-1'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('REF-UI'), findsWidgets);
    expect(find.byKey(const Key('lot_detail_summary_cdr_card')), findsOneWidget);
    expect(find.byKey(const Key('lot_detail_summary_volume_card')), findsOneWidget);
    expect(find.byKey(const Key('lot_detail_discharge_progress')), findsOneWidget);
    expect(find.byKey(const Key('lot_detail_cdr_section_title')), findsOneWidget);
    expect(find.text('AB-123-CD'), findsOneWidget);
  });

  testWidgets('bouton Ajouter CDR masqué en lecture seule (PCA)', (
    tester,
  ) async {
    final lot = FournisseurLot.empty().copyWith(
      id: 'lot-1',
      fournisseurId: 'f1',
      produitId: 'p1',
      reference: 'REF-R',
    );
    final fake = FakeFournisseurLotService(lotOverride: lot);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fournisseurLotServiceProvider.overrideWithValue(fake),
          lotDetailProviderOverride(fake),
          userRoleProvider.overrideWith((ref) => UserRole.pca),
          refDataProvider.overrideWith((ref) async => _emptyRefData()),
        ],
        child: const MaterialApp(
          home: LotDetailScreen(lotId: 'lot-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Ajouter CDR au lot'), findsNothing);
    expect(find.text('Clôturer le lot'), findsNothing);
    expect(find.byKey(const Key('lot_detail_summary_cdr_card')), findsOneWidget);
    expect(find.byKey(const Key('lot_detail_summary_volume_card')), findsOneWidget);
    expect(find.byKey(const Key('lot_detail_discharge_progress')), findsNothing);
  });

  testWidgets('lot ouvert + rôle écriture : clôture visible', (tester) async {
    final lot = FournisseurLot.empty().copyWith(
      id: 'lot-1',
      fournisseurId: 'f1',
      produitId: 'p1',
      reference: 'REF-O',
      statut: StatutFournisseurLot.ouvert,
    );
    final fake = FakeFournisseurLotService(lotOverride: lot);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fournisseurLotServiceProvider.overrideWithValue(fake),
          lotDetailProviderOverride(fake),
          userRoleProvider.overrideWith((ref) => UserRole.admin),
          refDataProvider.overrideWith((ref) async => _emptyRefData()),
        ],
        child: const MaterialApp(
          home: LotDetailScreen(lotId: 'lot-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('lot_detail_close_lot_button')), findsOneWidget);
  });

  testWidgets('clôture confirmée : service, refresh, SnackBar', (
    tester,
  ) async {
    final lot = FournisseurLot.empty().copyWith(
      id: 'lot-1',
      fournisseurId: 'f1',
      produitId: 'p1',
      reference: 'REF-C',
      statut: StatutFournisseurLot.ouvert,
    );
    final fake = FakeFournisseurLotService(lotOverride: lot, cdrsForLot: const []);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fournisseurLotServiceProvider.overrideWithValue(fake),
          lotDetailProviderOverride(fake),
          userRoleProvider.overrideWith((ref) => UserRole.directeur),
          refDataProvider.overrideWith((ref) async => _emptyRefData()),
        ],
        child: const MaterialApp(
          home: LotDetailScreen(lotId: 'lot-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final closeBtn = find.byKey(const Key('lot_detail_close_lot_button'));
    await tester.ensureVisible(closeBtn);
    await tester.pumpAndSettle();
    await tester.tap(closeBtn);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clôturer'));
    await tester.pumpAndSettle();

    expect(fake.closeLotCalls, ['lot-1']);
    expect(fake.lotOverride!.statut, StatutFournisseurLot.cloture);
    expect(find.text('Lot clôturé'), findsOneWidget);
    expect(find.byKey(const Key('lot_detail_close_lot_button')), findsNothing);
    expect(find.byKey(const Key('lot_detail_closed_notice')), findsOneWidget);
  });

  testWidgets('lot déjà clôturé : pas clôture / pas ajout / pas détacher', (
    tester,
  ) async {
    final lot = FournisseurLot.empty().copyWith(
      id: 'lot-1',
      fournisseurId: 'f1',
      produitId: 'p1',
      reference: 'REF-X',
      statut: StatutFournisseurLot.cloture,
    );
    final cdr = CoursDeRoute.empty().copyWith(
      id: 'cdr-1',
      fournisseurId: 'f1',
      produitId: 'p1',
      depotDestinationId: 'd1',
      plaqueCamion: 'ZZ-000-ZZ',
      statut: StatutCours.transit,
    );
    final fake = FakeFournisseurLotService(
      lotOverride: lot,
      cdrsForLot: [cdr],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fournisseurLotServiceProvider.overrideWithValue(fake),
          lotDetailProviderOverride(fake),
          userRoleProvider.overrideWith((ref) => UserRole.admin),
          refDataProvider.overrideWith((ref) async => _emptyRefData()),
        ],
        child: const MaterialApp(
          home: LotDetailScreen(lotId: 'lot-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lot_detail_close_lot_button')), findsNothing);
    expect(find.text('Ajouter CDR au lot'), findsNothing);
    expect(find.text('Détacher'), findsNothing);
    expect(find.byKey(const Key('lot_detail_closed_notice')), findsOneWidget);
    expect(find.text('ZZ-000-ZZ'), findsOneWidget);
  });
}
