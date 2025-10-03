import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/receptions/screens/reception_form_screen.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;
import 'package:ml_pp_mvp/shared/referentiels/role_provider.dart';

void main() {
  testWidgets('Navigation et éléments de base', (tester) async {
    final produits = refs.produitsRefProvider.overrideWith(
      (ref) => Future.value([
        refs.ProduitRef(id: 'p1', code: 'ESS', nom: 'Essence'),
      ]),
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

    // Vérifier que l'écran se charge correctement
    expect(find.text('Réceptions / Nouvelle réception'), findsOneWidget);
    expect(find.text('Propriétaire *'), findsOneWidget);
    expect(find.text('Monaluxe'), findsOneWidget);
    expect(find.text('Partenaire'), findsOneWidget);

    // Aller à l'étape 2
    await tester.tap(find.text('Suivant >'));
    await tester.pumpAndSettle();

    // Vérifier qu'on est bien à l'étape 2
    expect(find.text('[ Step 2/3 ]  Mesures & Citerne'), findsOneWidget);

    // Vérifier que les éléments de base sont présents
    expect(
      find.text('Citerne * (active, filtrée par produit)'),
      findsOneWidget,
    );
    expect(find.text('Index avant *'), findsOneWidget);
    expect(find.text('Index après *'), findsOneWidget);
    expect(find.text('Température (°C)'), findsOneWidget);
    expect(find.text('Densité @15°C'), findsOneWidget);
  });

  testWidgets('Sélection Monaluxe', (tester) async {
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

    // Étape 1: Vérifier que les éléments de base sont présents
    expect(find.text('Propriétaire *'), findsOneWidget);
    expect(find.text('Monaluxe'), findsOneWidget);
    expect(find.text('Partenaire'), findsOneWidget);

    // Sélectionner Monaluxe
    await tester.tap(find.text('Monaluxe'));
    await tester.pumpAndSettle();

    // Vérifier que le sélecteur de cours de route est présent
    expect(
      find.text(
        'Si MONALUXE → sélectionnez Cours de route (statut = "arrivé") *',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Sélection Partenaire', (tester) async {
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

    // Sélectionner Partenaire
    await tester.tap(find.text('Partenaire'));
    await tester.pumpAndSettle();

    // Aller à l'étape 2
    await tester.tap(find.text('Suivant >'));
    await tester.pumpAndSettle();

    // Vérifier qu'on est bien à l'étape 2
    expect(find.text('[ Step 2/3 ]  Mesures & Citerne'), findsOneWidget);

    // Vérifier que les éléments de base sont présents
    expect(
      find.text('Citerne * (active, filtrée par produit)'),
      findsOneWidget,
    );
    expect(find.text('Index avant *'), findsOneWidget);
    expect(find.text('Index après *'), findsOneWidget);
    expect(find.text('Température (°C)'), findsOneWidget);
    expect(find.text('Densité @15°C'), findsOneWidget);
  });
}
