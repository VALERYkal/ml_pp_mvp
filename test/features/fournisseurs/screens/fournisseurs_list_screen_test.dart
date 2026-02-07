// Module Fournisseurs — Widget tests écran liste (recherche, tri, Keys, navigation, pas Supabase).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/fournisseurs/domain/models/fournisseur.dart';
import 'package:ml_pp_mvp/features/fournisseurs/presentation/screens/fournisseur_detail_screen.dart';
import 'package:ml_pp_mvp/features/fournisseurs/presentation/screens/fournisseurs_list_screen.dart';
import 'package:ml_pp_mvp/features/fournisseurs/providers/fournisseur_providers.dart';

final _threeFournisseurs = [
  const Fournisseur(
    id: '1',
    nom: 'Alpha',
    pays: 'France',
    contactPersonne: 'Alice',
  ),
  const Fournisseur(
    id: '2',
    nom: 'Beta',
    pays: 'Belgique',
    contactPersonne: 'Bob',
  ),
  const Fournisseur(
    id: '3',
    nom: 'Gamma',
    pays: 'CD',
    contactPersonne: 'Charlie',
  ),
];

void main() {
  group('FournisseursListScreen', () {
    testWidgets('affiche le titre Fournisseurs', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fournisseursListProvider.overrideWith(
                (ref) => Future.value(<Fournisseur>[])),
          ],
          child: const MaterialApp(
            home: FournisseursListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Fournisseurs'), findsOneWidget);
    });

    testWidgets('build sans erreur avec liste vide', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fournisseursListProvider.overrideWith(
                (ref) => Future.value(<Fournisseur>[])),
          ],
          child: const MaterialApp(
            home: FournisseursListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Fournisseurs'), findsOneWidget);
    });

    testWidgets('empty state affiche message et aide', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fournisseursListProvider.overrideWith(
                (ref) => Future.value(<Fournisseur>[])),
          ],
          child: const MaterialApp(
            home: FournisseursListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aucun fournisseur'), findsOneWidget);
      expect(find.text('Vérifie la recherche ou le référentiel DB.'), findsOneWidget);
    });

    testWidgets('présente les Keys search, sort, list et row', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fournisseursListProvider.overrideWith(
                (ref) => Future.value(_threeFournisseurs)),
          ],
          child: const MaterialApp(
            home: FournisseursListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(keyFournisseursSearch), findsOneWidget);
      expect(find.byKey(keyFournisseursSortToggle), findsOneWidget);
      expect(find.byKey(keyFournisseursList), findsOneWidget);
      expect(find.byKey(keyFournisseursRow('1')), findsOneWidget);
      expect(find.byKey(keyFournisseursRow('2')), findsOneWidget);
      expect(find.byKey(keyFournisseursRow('3')), findsOneWidget);
    });

    testWidgets('build sans erreur avec données', (tester) async {
      final list = [
        const Fournisseur(id: '1', nom: 'Fournisseur A', pays: 'FR'),
        const Fournisseur(id: '2', nom: 'Fournisseur B', pays: 'CD'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fournisseursListProvider.overrideWith((ref) => Future.value(list)),
          ],
          child: const MaterialApp(
            home: FournisseursListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Fournisseur A'), findsOneWidget);
      expect(find.text('Fournisseur B'), findsOneWidget);
    });

    testWidgets('recherche filtre par pays et contact_personne', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fournisseursListProvider.overrideWith(
                (ref) => Future.value(_threeFournisseurs)),
          ],
          child: const MaterialApp(
            home: FournisseursListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Gamma'), findsOneWidget);

      await tester.enterText(find.byKey(keyFournisseursSearch), 'Belgique');
      await tester.pumpAndSettle();

      expect(find.text('Beta'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Gamma'), findsNothing);

      await tester.enterText(find.byKey(keyFournisseursSearch), 'Charlie');
      await tester.pumpAndSettle();

      expect(find.text('Gamma'), findsOneWidget);
      expect(find.text('Alpha'), findsNothing);
      expect(find.text('Beta'), findsNothing);
    });

    testWidgets('tri toggle inverse l\'ordre par nom', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fournisseursListProvider.overrideWith(
                (ref) => Future.value(_threeFournisseurs)),
          ],
          child: const MaterialApp(
            home: FournisseursListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final listTiles = find.byType(ListTile);
      expect(listTiles, findsNWidgets(3));
      expect((tester.widgetList(listTiles).first as ListTile).title, isA<Text>());
      expect(((tester.widgetList(listTiles).first as ListTile).title as Text).data, 'Alpha');

      await tester.tap(find.byKey(keyFournisseursSortToggle));
      await tester.pumpAndSettle();

      expect((tester.widgetList(listTiles).first as ListTile).title, isA<Text>());
      expect(((tester.widgetList(listTiles).first as ListTile).title as Text).data, 'Gamma');
    });

    testWidgets('tap fournisseur row navigue vers détail', (tester) async {
      final router = GoRouter(
        initialLocation: '/fournisseurs',
        routes: [
          GoRoute(
            path: '/fournisseurs',
            builder: (_, __) => const FournisseursListScreen(),
          ),
          GoRoute(
            path: '/fournisseurs/:id',
            builder: (_, state) {
              final id = state.pathParameters['id']!;
              return FournisseurDetailScreen(fournisseurId: id);
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            fournisseursListProvider.overrideWith(
                (ref) => Future.value(_threeFournisseurs)),
            fournisseurDetailProvider.overrideWith((ref, id) {
              Fournisseur? found;
              for (final f in _threeFournisseurs) {
                if (f.id == id) {
                  found = f;
                  break;
                }
              }
              return Future.value(found);
            }),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(keyFournisseursRow('1')));
      await tester.pumpAndSettle();

      expect(find.byType(FournisseurDetailScreen), findsOneWidget);
    });
  });
}
