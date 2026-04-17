import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/fournisseur_paiements_list.dart';

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('paiements list: empty state', (tester) async {
    await tester.pumpWidget(
      _app(const FournisseurPaiementsList(paiements: [])),
    );

    expect(find.text('Paiements'), findsOneWidget);
    expect(find.text('Aucun paiement enregistré pour cette facture.'), findsOneWidget);
  });

  testWidgets('paiements list: affiche les paiements dans l ordre fourni', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        const FournisseurPaiementsList(
          paiements: [
            FournisseurPaiementListItem(
              datePaiement: null,
              montantUsd: 90,
              modePaiement: 'VIREMENT',
              reference: 'REF-90',
              note: 'N1',
            ),
            FournisseurPaiementListItem(
              datePaiement: null,
              montantUsd: 40,
              modePaiement: 'CASH',
              reference: 'REF-40',
              note: null,
            ),
          ],
        ),
      ),
    );

    expect(find.text('90.00 USD'), findsOneWidget);
    expect(find.text('40.00 USD'), findsOneWidget);

    final first = tester.getTopLeft(find.text('90.00 USD')).dy;
    final second = tester.getTopLeft(find.text('40.00 USD')).dy;
    expect(first, lessThan(second));
  });
}
