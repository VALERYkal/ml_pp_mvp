@Tags(['integration'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ml_pp_mvp/features/receptions/screens/reception_form_screen.dart';
import 'package:ml_pp_mvp/features/receptions/providers/reception_providers.dart' as RP;
// import 'package:ml_pp_mvp/features/receptions/models/reception.dart'; // unused
// import 'package:ml_pp_mvp/features/receptions/models/owner_type.dart'; // unused

void main() {
  testWidgets('happy path: enregistrement reception affiche snackbar success', (tester) async {
    final overrides = <Override>[
      RP.produitsListProvider.overrideWith(
        (ref) async => [
          {'id': 'prod-1', 'nom': 'Diesel'},
        ],
      ),
      RP.citernesByProduitProvider.overrideWithProvider(
        (produitId) => FutureProvider(
          (ref) async => [
            {'id': 'cit-1', 'nom': 'Citerne A'},
          ],
        ),
      ),
      RP.createReceptionProvider.overrideWithProvider(
        (reception) => FutureProvider((ref) async => reception.copyWith(id: 'rec-1')),
      ),
      RP.partenairesListProvider.overrideWith((ref) async => const []),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(home: ReceptionFormScreen(coursId: 'cours-1')),
      ),
    );

    // Attendre chargement initial (produit prérempli par coursId n'est pas simulé ici)
    await tester.pump();

    // Sélection produit
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diesel').last);
    await tester.pumpAndSettle();

    // Sélection citerne
    await tester.tap(find.byType(DropdownButtonFormField<String>).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Citerne A').last);
    await tester.pumpAndSettle();

    // Index avant/après
    await tester.enterText(find.widgetWithText(TextFormField, 'Index avant *'), '0');
    await tester.enterText(find.widgetWithText(TextFormField, 'Index après *'), '1000');

    // Soumettre
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enregistrer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Snackbar succès
    expect(find.text('Réception enregistrée'), findsOneWidget);
  });
}
