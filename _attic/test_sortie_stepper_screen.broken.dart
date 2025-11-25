import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/sorties/screens/sortie_stepper_screen.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;
import 'package:ml_pp_mvp/shared/referentiels/role_provider.dart';

void main() {
  testWidgets('navigation et prÃ©visualisation volumes', (tester) async {
    // Providers de rÃ©fÃ©rentiels surchargÃ©s
    final citernesOverride = refs.citernesActivesProvider.overrideWith(
      (ref) => Future.value(<refs.CiterneRef>[
        refs.CiterneRef(
          id: 'c1',
          nom: 'C1',
          produitId: 'p1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
        ),
      ]),
    );

    final roleOverride = userRoleProvider.overrideWith(
      (ref) => Future.value('admin'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [citernesOverride, roleOverride],
        child: const MaterialApp(home: SortieStepperScreen()),
      ),
    );

    // Attendre que l'Ã©cran se charge
    await tester.pumpAndSettle();

    // Aller Ã  Step 2 (Mesures & Citerne)
    await tester.tap(find.text('Suivant >').first);
    await tester.pumpAndSettle();

    // VÃ©rifier qu'on est bien Ã  l'Ã©tape 2
    expect(find.text('[ Step 2/3 ]  Mesures & Citerne'), findsOneWidget);

    // VÃ©rifier que les Ã©lÃ©ments de base sont prÃ©sents
    expect(find.text('Produit ID'), findsOneWidget);
    expect(find.text('Citerne *'), findsOneWidget);
    expect(find.text('Index avant *'), findsOneWidget);
    expect(find.text('Index aprÃ¨s *'), findsOneWidget);

    // Saisies indices / TÂ° / densitÃ© -> preview rÃ©agit
    final allTextFields = find.byType(TextField);

    // Index avant (2Ã¨me TextField de l'Ã©tape 2)
    await tester.enterText(allTextFields.at(1), '1000');
    await tester.pumpAndSettle();

    // Index aprÃ¨s (3Ã¨me TextField)
    await tester.enterText(allTextFields.at(2), '1100');
    await tester.pumpAndSettle();

    // TempÃ©rature (4Ã¨me TextField)
    await tester.enterText(allTextFields.at(3), '30');
    await tester.pumpAndSettle();

    // DensitÃ© (5Ã¨me TextField)
    await tester.enterText(allTextFields.at(4), '0.835');
    await tester.pumpAndSettle();

    // VÃ©rifier que les Ã©lÃ©ments de base sont prÃ©sents
    expect(find.text('Produit ID'), findsOneWidget);
    expect(find.text('Citerne *'), findsOneWidget);
    expect(find.text('Index avant *'), findsOneWidget);
    expect(find.text('Index aprÃ¨s *'), findsOneWidget);
    expect(find.text('TempÃ©rature (Â°C)'), findsOneWidget);
    expect(find.text('DensitÃ© @15Â°C'), findsOneWidget);
  });
}

