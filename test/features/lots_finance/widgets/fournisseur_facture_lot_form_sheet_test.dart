import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/lots/models/fournisseur_lot.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/features/lots_finance/providers/fournisseur_finance_lot_providers.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/fournisseur_facture_lot_form_sheet.dart';
import 'package:postgrest/postgrest.dart';

FournisseurLot _lot(String id, String ref, {String? fournisseurNom}) {
  return FournisseurLot.fromMap({
    'id': id,
    'fournisseur_id': 'f-1',
    'produit_id': 'p-1',
    'reference': ref,
    'fournisseur_nom': fournisseurNom,
    'statut': 'ouvert',
  });
}

FournisseurFactureLot _createdFacture() {
  return FournisseurFactureLot.fromMap({
    'facture_id': 'new-id',
    'invoice_no': 'INV-X',
    'fournisseur_lot_id': 'lot-1',
    'quantite_facturee_20c': 100,
    'prix_unitaire_usd': 2,
    'montant_total_usd': 200,
    'montant_regle_usd': 0,
    'solde_restant_usd': 200,
    'statut_paiement': 'A_PAYER',
    'statut_rapprochement': 'A_RAPPROCHER',
    'date_facture': '2026-04-17',
  });
}

class _HostBottomSheet extends StatelessWidget {
  const _HostBottomSheet();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            showModalBottomSheet<bool>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const FournisseurFactureLotFormSheet(),
            );
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('formulaire facture: numéro obligatoire', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fournisseurLotsFacturablesProvider.overrideWith(
            (ref) async => [_lot('lot-1', 'REF-A', fournisseurNom: 'F1')],
          ),
        ],
        child: const MaterialApp(home: _HostBottomSheet()),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('REF-A · F1').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantité facturée 20 °C (L) *'),
      '10',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Prix unitaire USD *'),
      '1',
    );

    await tester.tap(find.text('Créer la facture'));
    await tester.pumpAndSettle();

    expect(find.text('Numéro de facture obligatoire'), findsOneWidget);
  });

  testWidgets('formulaire facture: succès ferme le sheet', (tester) async {
    final completer = Completer<FournisseurFactureLot>();
    CreateFournisseurFactureLotInput? captured;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fournisseurLotsFacturablesProvider.overrideWith(
            (ref) async => [_lot('lot-1', 'REF-A', fournisseurNom: 'F1')],
          ),
          createFournisseurFactureLotProvider.overrideWith((ref, input) async {
            captured = input;
            return completer.future;
          }),
        ],
        child: const MaterialApp(home: _HostBottomSheet()),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('REF-A · F1').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Numéro de facture *'),
      'INV-T-1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantité facturée 20 °C (L) *'),
      '100',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Prix unitaire USD *'),
      '2.5',
    );

    await tester.tap(find.text('Créer la facture'));
    await tester.pump();

    expect(find.text('Création...'), findsOneWidget);

    completer.complete(_createdFacture());
    await tester.pumpAndSettle();

    expect(find.text('Nouvelle facture lot'), findsNothing);
    expect(captured, isNotNull);
    expect(captured!.fournisseurLotId, 'lot-1');
    expect(captured!.invoiceNo, 'INV-T-1');
    expect(captured!.quantiteFacturee20c, 100);
    expect(captured!.prixUnitaireUsd, 2.5);
  });

  testWidgets('formulaire facture: erreur submit affiche message', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fournisseurLotsFacturablesProvider.overrideWith(
            (ref) async => [_lot('lot-1', 'REF-A', fournisseurNom: 'F1')],
          ),
          createFournisseurFactureLotProvider.overrideWith((ref, input) async {
            throw Exception('db-error');
          }),
        ],
        child: const MaterialApp(home: _HostBottomSheet()),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('REF-A · F1').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Numéro de facture *'),
      'INV-E-1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantité facturée 20 °C (L) *'),
      '10',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Prix unitaire USD *'),
      '1',
    );

    await tester.tap(find.text('Créer la facture'));
    await tester.pumpAndSettle();

    expect(
      find.text('Erreur lors de la création de la facture.'),
      findsOneWidget,
    );
  });

  testWidgets('formulaire facture: aucun lot facturable (C2)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fournisseurLotsFacturablesProvider.overrideWith((ref) async => const []),
        ],
        child: const MaterialApp(home: _HostBottomSheet()),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Aucun lot disponible pour facturation.'), findsOneWidget);
    expect(find.text('Créer la facture'), findsNothing);
    expect(find.text('Fermer'), findsOneWidget);
  });

  testWidgets('formulaire facture: doublon lot → message C2', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fournisseurLotsFacturablesProvider.overrideWith(
            (ref) async => [_lot('lot-1', 'REF-A', fournisseurNom: 'F1')],
          ),
          createFournisseurFactureLotProvider.overrideWith((ref, input) async {
            throw PostgrestException(
              message: 'duplicate key value violates unique constraint',
              code: '23505',
              details: 'Key (fournisseur_lot_id)=(lot-1) already exists.',
              hint: null,
            );
          }),
        ],
        child: const MaterialApp(home: _HostBottomSheet()),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('REF-A · F1').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Numéro de facture *'),
      'INV-DUP',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantité facturée 20 °C (L) *'),
      '10',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Prix unitaire USD *'),
      '1',
    );

    await tester.tap(find.text('Créer la facture'));
    await tester.pumpAndSettle();

    expect(
      find.text('Ce lot a déjà une facture fournisseur.'),
      findsOneWidget,
    );
  });

  testWidgets('formulaire facture: lot déjà facturé absent du dropdown', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          fournisseurLotsFacturablesProvider.overrideWith(
            (ref) async => [_lot('lot-libre', 'REF-LIBRE', fournisseurNom: 'Fx')],
          ),
        ],
        child: const MaterialApp(home: _HostBottomSheet()),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();

    expect(find.textContaining('REF-LIBRE'), findsWidgets);
    expect(find.textContaining('REF-DEJA-FACTURE'), findsNothing);
  });
}
