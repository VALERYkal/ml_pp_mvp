import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/sorties/screens/sortie_form_screen.dart';
import 'package:ml_pp_mvp/features/sorties/providers/sortie_providers.dart'
    as SP;
import 'package:ml_pp_mvp/features/sorties/data/sortie_service.dart';
import 'package:ml_pp_mvp/features/sorties/models/sortie_produit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _SpySortieService extends SortieService {
  final void Function(SortieProduit) onCall;
  _SpySortieService(this.onCall)
    : super(SupabaseClient('http://localhost', 'anon'));
  @override
  Future<String> createValidated({
    required String citerneId,
    required String produitId,
    double? indexAvant,
    double? indexApres,
    double? temperatureCAmb,
    double? densiteA15,
    double? volumeCorrige15C,
    String proprietaireType = 'MONALUXE',
    String? clientId,
    String? partenaireId,
    String? chauffeurNom,
    String? plaqueCamion,
    String? plaqueRemorque,
    String? transporteur,
    String? note,
    DateTime? dateSortie,
  }) async {
    final sortie = SortieProduit(
      id: '',
      citerneId: citerneId,
      produitId: produitId,
      clientId: clientId,
      partenaireId: partenaireId,
      indexAvant: indexAvant,
      indexApres: indexApres,
    );
    onCall(sortie);
    return 'out-1';
  }
}

void main() {
  testWidgets('Integration: Sortie submission triggers service call', (
    tester,
  ) async {
    SortieProduit? called;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          SP.sortieServiceProvider.overrideWith(
            (ref) => _SpySortieService((s) => called = s),
          ),
          SP.produitsListProvider.overrideWith(
            (ref) async => [
              {'id': 'p1', 'nom': 'Diesel'},
            ],
          ),
          SP.clientsListProvider.overrideWith(
            (ref) async => [
              {'id': 'c1', 'nom': 'Client A'},
            ],
          ),
          SP.partenairesListProvider.overrideWith(
            (ref) async => [
              {'id': 'pa1', 'nom': 'Partenaire X'},
            ],
          ),
          SP.produitByIdProvider.overrideWith(
            (ref, id) async => {'id': 'p1', 'nom': 'Diesel', 'code': 'DSL'},
          ),
          SP.citernesByProduitProvider.overrideWith(
            (ref, id) async => [
              {'id': 'cit1', 'nom': 'Citerne 1'},
            ],
          ),
        ],
        child: const MaterialApp(home: SortieFormScreen()),
      ),
    );

    // Select product
    await tester.pump();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diesel').last);
    await tester.pumpAndSettle();

    // Select citerne
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Citerne 1').last);
    await tester.pumpAndSettle();

    // Select client (beneficiary)
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Client A').last);
    await tester.pumpAndSettle();

    // Enter indices
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Index avant'),
      '0',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Index après'),
      '100',
    );

    // Submit (assurer visibilité)
    final submitKey = find.byKey(const Key('sortie_submit'));
    await tester.ensureVisible(submitKey);
    await tester.tap(submitKey);
    await tester.pumpAndSettle();

    expect(called, isNotNull);
    expect(called!.produitId, 'p1');
    expect(called!.citerneId, 'cit1');
  });
}
