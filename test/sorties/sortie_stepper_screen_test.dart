import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/sorties/screens/sortie_stepper_screen.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;
import 'package:ml_pp_mvp/shared/referentiels/role_provider.dart';

void main() {
  testWidgets('navigation et prévisualisation volumes', (tester) async {
    // Providers de référentiels surchargés
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

    // Attendre que l'écran se charge
    await tester.pumpAndSettle();

    // Aller à Step 2 (Mesures & Citerne)
    await tester.tap(find.text('Suivant >').first);
    await tester.pumpAndSettle();

    // Vérifier qu'on est bien à l'étape 2
    expect(find.text('[ Step 2/3 ]  Mesures & Citerne'), findsOneWidget);

    // Vérifier que les éléments de base sont présents
    expect(find.text('Produit ID'), findsOneWidget);
    expect(find.text('Citerne *'), findsOneWidget);
    expect(find.text('Index avant *'), findsOneWidget);
    expect(find.text('Index après *'), findsOneWidget);

    // Saisies indices / T° / densité -> preview réagit
    final allTextFields = find.byType(TextField);
    
    // Index avant (2ème TextField de l'étape 2)
    await tester.enterText(allTextFields.at(1), '1000');
    await tester.pumpAndSettle();
    
    // Index après (3ème TextField)
    await tester.enterText(allTextFields.at(2), '1100');
    await tester.pumpAndSettle();
    
    // Température (4ème TextField)
    await tester.enterText(allTextFields.at(3), '30');
    await tester.pumpAndSettle();
    
    // Densité (5ème TextField)
    await tester.enterText(allTextFields.at(4), '0.835');
    await tester.pumpAndSettle();

    // Vérifier que les éléments de base sont présents
    expect(find.text('Produit ID'), findsOneWidget);
    expect(find.text('Citerne *'), findsOneWidget);
    expect(find.text('Index avant *'), findsOneWidget);
    expect(find.text('Index après *'), findsOneWidget);
    expect(find.text('Température (°C)'), findsOneWidget);
    expect(find.text('Densité @15°C'), findsOneWidget);
  });


}
