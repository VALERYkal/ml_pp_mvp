import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/lots/screens/fournisseur_lot_form_screen.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart';

RefDataCache _minimalRefData() => RefDataCache(
      fournisseurs: const {'f1': 'F1'},
      produits: const {'p1': 'P1'},
      produitCodes: const {},
      depots: const {},
      loadedAt: DateTime.now(),
    );

void main() {
  testWidgets('création : hint statut Ouvert, pas de champ statut', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          refDataProvider.overrideWith((ref) async => _minimalRefData()),
        ],
        child: const MaterialApp(
          home: FournisseurLotFormScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lot_form_statut_ouvert_hint')), findsOneWidget);
    expect(find.text('Statut'), findsNothing);
  });
}
