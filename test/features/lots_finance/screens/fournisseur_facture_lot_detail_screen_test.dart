import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/features/lots_finance/providers/fournisseur_finance_lot_providers.dart';
import 'package:ml_pp_mvp/features/lots_finance/screens/fournisseur_facture_lot_detail_screen.dart';

FournisseurFactureLot _facture(String id, String invoice) {
  return FournisseurFactureLot.fromMap({
    'facture_id': id,
    'invoice_no': invoice,
    'deal_reference': 'DEAL-X',
    'fournisseur_lot_id': 'lot-1',
    'nb_receptions': 2,
    'total_volume_15c': 1200,
    'total_volume_20c': 1180,
    'quantite_facturee_20c': 1180,
    'ecart_volume_20c': 0,
    'statut_rapprochement': 'rapproche',
    'prix_unitaire_usd': 1,
    'montant_total_usd': 120,
    'montant_regle_usd': 20,
    'solde_restant_usd': 100,
    'statut_paiement': 'partiel',
    'date_facture': '2026-04-10',
    'date_echeance': '2026-05-10',
    'created_at': '2026-04-10T12:00:00Z',
  });
}

FournisseurPaiementLot _paiement(
  String id, {
  required String factureId,
  required double montant,
  required String dateIso,
}) {
  return FournisseurPaiementLot.fromMap({
    'id': id,
    'fournisseur_facture_id': factureId,
    'date_paiement': dateIso,
    'montant_paye_usd': montant,
    'mode_paiement': 'VIREMENT',
    'reference_paiement': 'REF-$id',
    'note': 'note-$id',
    'created_at': dateIso,
  });
}

Widget _app(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      home: FournisseurFactureLotDetailScreen(factureId: 'fac-1'),
    ),
  );
}

void main() {
  testWidgets('detail: loading state', (tester) async {
    final completer = Completer<FournisseurFactureLot?>();
    await tester.pumpWidget(
      _app([
        fournisseurFactureLotByIdProvider.overrideWith((ref, _) => completer.future),
        fournisseurPaiementsLotByFactureIdProvider.overrideWith(
          (ref, _) async => const [],
        ),
      ]),
    );

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('detail: error state', (tester) async {
    await tester.pumpWidget(
      _app([
        fournisseurFactureLotByIdProvider.overrideWith(
          (ref, _) => Future<FournisseurFactureLot?>.error('err-detail'),
        ),
        fournisseurPaiementsLotByFactureIdProvider.overrideWith(
          (ref, _) async => const [],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('err-detail'), findsOneWidget);
  });

  testWidgets('detail: empty metier', (tester) async {
    await tester.pumpWidget(
      _app([
        fournisseurFactureLotByIdProvider.overrideWith((ref, _) async => null),
        fournisseurPaiementsLotByFactureIdProvider.overrideWith(
          (ref, _) async => const [],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Facture lot introuvable ou non disponible.'), findsOneWidget);
  });

  testWidgets('detail: affiche sections principales', (tester) async {
    await tester.pumpWidget(
      _app([
        fournisseurFactureLotByIdProvider.overrideWith(
          (ref, _) async => _facture('fac-1', 'INV-DETAIL'),
        ),
        fournisseurPaiementsLotByFactureIdProvider.overrideWith(
          (ref, _) async => const [],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('INV-DETAIL'), findsOneWidget);
    expect(find.text('Rapprochement'), findsOneWidget);
    expect(find.text('Montants', skipOffstage: false), findsOneWidget);
    expect(find.text('Contexte lot', skipOffstage: false), findsOneWidget);
    expect(find.text('Enregistrer un paiement'), findsOneWidget);
  });

  testWidgets('detail: affiche la facture avec paiements provider branché', (tester) async {
    await tester.pumpWidget(
      _app([
        fournisseurFactureLotByIdProvider.overrideWith(
          (ref, _) async => _facture('fac-1', 'INV-HIST'),
        ),
        fournisseurPaiementsLotByFactureIdProvider.overrideWith(
          (ref, _) async => [
            _paiement('p2', factureId: 'fac-1', montant: 80, dateIso: '2026-04-11T12:00:00Z'),
            _paiement('p1', factureId: 'fac-1', montant: 40, dateIso: '2026-04-10T12:00:00Z'),
          ],
        ),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('INV-HIST'), findsOneWidget);
  });

  testWidgets('detail: refresh déclenché après paiement réussi', (tester) async {
    var detailReads = 0;
    var paiementReads = 0;

    await tester.pumpWidget(
      _app([
        fournisseurFactureLotByIdProvider.overrideWith((ref, _) async {
          detailReads++;
          return _facture('fac-1', 'INV-REFRESH');
        }),
        fournisseurPaiementsLotByFactureIdProvider.overrideWith((ref, _) async {
          paiementReads++;
          return const [];
        }),
        createFournisseurPaiementLotProvider.overrideWith((ref, input) async {}),
      ]),
    );
    await tester.pumpAndSettle();

    final detailBefore = detailReads;
    final paiementsBefore = paiementReads;

    await tester.tap(find.text('Enregistrer un paiement'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Montant'), '10');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(detailReads, greaterThan(detailBefore));
    expect(paiementReads, greaterThan(paiementsBefore));
  });
}
