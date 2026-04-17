import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/lots_finance/models/fournisseur_finance_lot_models.dart';
import 'package:ml_pp_mvp/features/lots_finance/providers/fournisseur_finance_lot_providers.dart';
import 'package:ml_pp_mvp/features/lots_finance/screens/fournisseur_facture_lot_detail_screen.dart';
import 'package:ml_pp_mvp/features/lots_finance/screens/fournisseur_facture_lot_list_screen.dart';

FournisseurFactureLot _facture(String id, String invoice) {
  return FournisseurFactureLot.fromMap({
    'facture_id': id,
    'invoice_no': invoice,
    'deal_reference': 'DEAL-$invoice',
    'fournisseur_lot_id': 'lot-1',
    'nb_receptions': 1,
    'total_volume_15c': 1000,
    'total_volume_20c': 980,
    'quantite_facturee_20c': 980,
    'ecart_volume_20c': 0,
    'statut_rapprochement': 'rapproche',
    'prix_unitaire_usd': 1,
    'montant_total_usd': 100,
    'montant_regle_usd': 20,
    'solde_restant_usd': 80,
    'statut_paiement': 'partiel',
    'date_facture': '2026-04-10',
    'date_echeance': '2026-05-10',
    'created_at': '2026-04-10T12:00:00Z',
  });
}

Widget _appWithList({
  required List<Override> overrides,
  GoRouter? router,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig:
          router ??
          GoRouter(
            initialLocation: '/finance/factures-lot',
            routes: [
              GoRoute(
                path: '/finance/factures-lot',
                builder: (_, __) => const FournisseurFactureLotListScreen(),
              ),
            ],
          ),
    ),
  );
}

void main() {
  testWidgets('liste: loading state', (tester) async {
    final completer = Completer<List<FournisseurFactureLot>>();
    await tester.pumpWidget(
      _appWithList(
        overrides: [
          fournisseurFacturesLotProvider.overrideWith((ref) => completer.future),
        ],
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('liste: error state', (tester) async {
    await tester.pumpWidget(
      _appWithList(
        overrides: [
          fournisseurFacturesLotProvider.overrideWith(
            (ref) => Future<List<FournisseurFactureLot>>.error('boom'),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('boom'), findsOneWidget);
    expect(find.text('Réessayer'), findsOneWidget);
  });

  testWidgets('liste: empty state', (tester) async {
    await tester.pumpWidget(
      _appWithList(
        overrides: [
          fournisseurFacturesLotProvider.overrideWith((ref) async => const []),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aucune facture lot disponible.'), findsOneWidget);
  });

  testWidgets('liste: data state affiche les factures', (tester) async {
    await tester.pumpWidget(
      _appWithList(
        overrides: [
          fournisseurFacturesLotProvider.overrideWith(
            (ref) async => [_facture('f1', 'INV-001')],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('INV-001'), findsOneWidget);
    expect(find.text('DEAL-INV-001'), findsOneWidget);
  });

  testWidgets('liste: tap item navigue vers détail', (tester) async {
    final router = GoRouter(
      initialLocation: '/finance/factures-lot',
      routes: [
        GoRoute(
          path: '/finance/factures-lot',
          builder: (_, __) => const FournisseurFactureLotListScreen(),
        ),
        GoRoute(
          path: '/finance/factures-lot/:factureId',
          builder: (_, state) => FournisseurFactureLotDetailScreen(
            factureId: state.pathParameters['factureId']!,
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      _appWithList(
        router: router,
        overrides: [
          fournisseurFacturesLotProvider.overrideWith(
            (ref) async => [_facture('f-nav', 'INV-NAV')],
          ),
          fournisseurFactureLotByIdProvider.overrideWith(
            (ref, id) async => _facture(id, 'INV-NAV'),
          ),
          fournisseurPaiementsLotByFactureIdProvider.overrideWith(
            (ref, _) async => const [],
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('INV-NAV'));
    await tester.pumpAndSettle();

    expect(find.text('Détail facture lot'), findsOneWidget);
    expect(find.text('INV-NAV'), findsOneWidget);
  });
}
