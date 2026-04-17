import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/features/lots_finance/providers/fournisseur_finance_lot_providers.dart';
import 'package:ml_pp_mvp/features/lots_finance/widgets/fournisseur_paiement_form_sheet.dart';

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
              builder: (_) => const FournisseurPaiementFormSheet(factureId: 'fac-1'),
            );
          },
          child: const Text('open'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('form: validation montant > 0', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: const MaterialApp(home: _HostBottomSheet()),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Montant'), '0');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Montant invalide'), findsOneWidget);
  });

  testWidgets('form: loading puis fermeture au succès + trim des champs', (
    tester,
  ) async {
    final completer = Completer<void>();
    CreateFournisseurPaiementLotInput? captured;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          createFournisseurPaiementLotProvider.overrideWith((ref, input) async {
            captured = input;
            await completer.future;
          }),
        ],
        child: const MaterialApp(home: _HostBottomSheet()),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Montant'), '50');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mode paiement'),
      '  VIREMENT  ',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Référence'),
      '  REF-50  ',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Note'), '  note  ');

    await tester.tap(find.text('Enregistrer'));
    await tester.pump();

    expect(find.text('Enregistrement...'), findsOneWidget);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.text('Enregistrer un paiement'), findsNothing);
    expect(captured, isNotNull);
    expect(captured!.modePaiement, 'VIREMENT');
    expect(captured!.referencePaiement, 'REF-50');
    expect(captured!.note, 'note');
  });

  testWidgets('form: erreur submit affiche message', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          createFournisseurPaiementLotProvider.overrideWith((ref, input) async {
            throw Exception('db-error');
          }),
        ],
        child: const MaterialApp(home: _HostBottomSheet()),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Montant'), '20');
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Erreur lors de l’enregistrement du paiement.'), findsOneWidget);
  });
}
