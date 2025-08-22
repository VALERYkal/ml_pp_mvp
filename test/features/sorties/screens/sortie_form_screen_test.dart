import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/sorties/screens/sortie_form_screen.dart';
import 'package:ml_pp_mvp/features/sorties/providers/sortie_providers.dart' as P;
import 'package:ml_pp_mvp/features/sorties/data/sortie_service.dart';
import 'package:ml_pp_mvp/features/sorties/models/sortie_produit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _SpySortieService extends SortieService {
  final void Function() onCall;
  _SpySortieService(this.onCall) : super.withClient(SupabaseClient('http://localhost', 'anon'));
  @override
  Future<SortieProduit> createSortie(SortieProduit sortie, {String? currentUserId}) async {
    onCall();
    return sortie.copyWith(id: 'new-id');
  }
}

void main() {
  testWidgets('SortieFormScreen UI validations and submit', (tester) async {
    var called = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          P.sortieServiceProvider.overrideWith((ref) => _SpySortieService(() { called = true; })),
          P.produitsListProvider.overrideWith((ref) async => [
                {'id': 'p1', 'nom': 'Diesel'}
              ]),
          P.clientsListProvider.overrideWith((ref) async => [
                {'id': 'c1', 'nom': 'Client A'}
              ]),
          P.partenairesListProvider.overrideWith((ref) async => [
                {'id': 'pa1', 'nom': 'Partenaire X'}
              ]),
          P.produitByIdProvider.overrideWith((ref, id) async => {'id': 'p1', 'nom': 'Diesel', 'code': 'DSL'}),
          P.citernesByProduitProvider.overrideWith((ref, id) async => [
                {'id': 'cit1', 'nom': 'Citerne 1'}
              ]),
        ],
        child: const MaterialApp(home: SortieFormScreen()),
      ),
    );

    // Select product
    await tester.pump();
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diesel').last);
    await tester.pumpAndSettle();

    // Select citerne
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Citerne 1').last);
    await tester.pumpAndSettle();

    // Optional beneficiary: select client
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Client A').last);
    await tester.pumpAndSettle();

    // Enter indices
    await tester.enterText(find.widgetWithText(TextFormField, 'Index avant'), '1000');
    await tester.enterText(find.widgetWithText(TextFormField, 'Index après'), '1200');

    // Submit: s'assurer que le bouton est visible puis taper
    final submitKey = find.byKey(const Key('sortie_submit'));
    await tester.ensureVisible(submitKey);
    await tester.tap(submitKey);
    await tester.pumpAndSettle();
    expect(called, isTrue);
  });
}

