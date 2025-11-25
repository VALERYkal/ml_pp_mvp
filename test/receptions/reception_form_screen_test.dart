@Tags(['needs-refactor'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/receptions/screens/reception_form_screen.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;
import 'package:ml_pp_mvp/shared/referentiels/role_provider.dart';

void main() {
  testWidgets('Navigation et Ã©lÃ©ments de base', (tester) async {
    final produits = refs.produitsRefProvider.overrideWith(
      (ref) => Future.value([refs.ProduitRef(id: 'p1', code: 'ESS', nom: 'Essence')]),
    );

    final citernes = refs.citernesActivesProvider.overrideWith(
      (ref) => Future.value([
        refs.CiterneRef(
          id: 'c1',
          nom: 'Citerne 1',
          produitId: 'p1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
        ),
      ]),
    );

    final role = userRoleProvider.overrideWith((ref) => Future.value('admin'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [produits, citernes, role],
        child: const MaterialApp(home: ReceptionFormScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // VÃ©rifier que l'Ã©cran se charge correctement
    expect(find.text('RÃ©ceptions / Nouvelle rÃ©ception'), findsOneWidget);
    expect(find.text('PropriÃ©taire *'), findsOneWidget);
    expect(find.text('Monaluxe'), findsOneWidget);
    expect(find.text('Partenaire'), findsOneWidget);

    // Aller Ã  l'Ã©tape 2
    await tester.tap(find.text('Suivant >'));
    await tester.pumpAndSettle();

    // VÃ©rifier qu'on est bien Ã  l'Ã©tape 2
    expect(find.text('[ Step 2/3 ]  Mesures & Citerne'), findsOneWidget);

    // VÃ©rifier que les Ã©lÃ©ments de base sont prÃ©sents
    expect(find.text('Citerne * (active, filtrÃ©e par produit)'), findsOneWidget);
    expect(find.text('Index avant *'), findsOneWidget);
    expect(find.text('Index aprÃ¨s *'), findsOneWidget);
    expect(find.text('TempÃ©rature (Â°C)'), findsOneWidget);
    expect(find.text('DensitÃ© @15Â°C'), findsOneWidget);
  });

  testWidgets('SÃ©lection Monaluxe', (tester) async {
    final produits = refs.produitsRefProvider.overrideWith(
      (ref) => Future.value([
        refs.ProduitRef(id: 'p1', code: 'ESS', nom: 'Essence'),
        refs.ProduitRef(id: 'p2', code: 'AGO', nom: 'Gasoil'),
      ]),
    );

    final citernes = refs.citernesActivesProvider.overrideWith(
      (ref) => Future.value([
        refs.CiterneRef(
          id: 'c1',
          nom: 'Citerne Essence',
          produitId: 'p1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
        ),
        refs.CiterneRef(
          id: 'c2',
          nom: 'Citerne Gasoil',
          produitId: 'p2',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
        ),
      ]),
    );

    final role = userRoleProvider.overrideWith((ref) => Future.value('admin'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [produits, citernes, role],
        child: const MaterialApp(home: ReceptionFormScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // Ãtape 1: VÃ©rifier que les Ã©lÃ©ments de base sont prÃ©sents
    expect(find.text('PropriÃ©taire *'), findsOneWidget);
    expect(find.text('Monaluxe'), findsOneWidget);
    expect(find.text('Partenaire'), findsOneWidget);

    // SÃ©lectionner Monaluxe
    await tester.tap(find.text('Monaluxe'));
    await tester.pumpAndSettle();

    // VÃ©rifier que le sÃ©lecteur de cours de route est prÃ©sent
    expect(
      find.text('Si MONALUXE â sÃ©lectionnez Cours de route (statut = "arrivÃ©") *'),
      findsOneWidget,
    );
  });

  testWidgets('SÃ©lection Partenaire', (tester) async {
    final produits = refs.produitsRefProvider.overrideWith(
      (ref) => Future.value([
        refs.ProduitRef(id: 'p1', code: 'ESS', nom: 'Essence'),
        refs.ProduitRef(id: 'p2', code: 'AGO', nom: 'Gasoil'),
      ]),
    );

    final citernes = refs.citernesActivesProvider.overrideWith(
      (ref) => Future.value([
        refs.CiterneRef(
          id: 'c1',
          nom: 'Citerne Essence',
          produitId: 'p1',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
        ),
        refs.CiterneRef(
          id: 'c2',
          nom: 'Citerne Gasoil',
          produitId: 'p2',
          capaciteTotale: 1000.0,
          capaciteSecurite: 100.0,
          statut: 'active',
        ),
      ]),
    );

    final role = userRoleProvider.overrideWith((ref) => Future.value('admin'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [produits, citernes, role],
        child: const MaterialApp(home: ReceptionFormScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // SÃ©lectionner Partenaire
    await tester.tap(find.text('Partenaire'));
    await tester.pumpAndSettle();

    // Aller Ã  l'Ã©tape 2
    await tester.tap(find.text('Suivant >'));
    await tester.pumpAndSettle();

    // VÃ©rifier qu'on est bien Ã  l'Ã©tape 2
    expect(find.text('[ Step 2/3 ]  Mesures & Citerne'), findsOneWidget);

    // VÃ©rifier que les Ã©lÃ©ments de base sont prÃ©sents
    expect(find.text('Citerne * (active, filtrÃ©e par produit)'), findsOneWidget);
    expect(find.text('Index avant *'), findsOneWidget);
    expect(find.text('Index aprÃ¨s *'), findsOneWidget);
    expect(find.text('TempÃ©rature (Â°C)'), findsOneWidget);
    expect(find.text('DensitÃ© @15Â°C'), findsOneWidget);
  });
}

