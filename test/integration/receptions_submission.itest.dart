import 'package:flutter/material.dart';
@Tags(['integration'])
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/receptions/screens/reception_form_screen.dart';
import 'package:ml_pp_mvp/features/receptions/providers/reception_providers.dart'
    as RP;
import 'package:ml_pp_mvp/features/receptions/data/reception_service.dart';
import 'package:ml_pp_mvp/features/receptions/models/reception.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _SpyReceptionService extends ReceptionService {
  final void Function(Reception) onCall;
  _SpyReceptionService(this.onCall)
    : super.withClient(
        SupabaseClient('http://localhost', 'anon'),
        refRepo: FakeRefRepo(),
      );
  @override
  Future<Reception> createReception(Reception reception) async {
    onCall(reception);
    return reception.copyWith(id: 'rec-1');
  }
}

class FakeRefRepo extends ReferentielsRepo {
  FakeRefRepo() : super(Supabase.instance.client);

  @override
  Future<void> loadProduits() async {}

  @override
  Future<void> loadCiternesActives() async {}

  @override
  String? getProduitIdByCodeSync(String code) => 'prod-1';
}

void main() {
  testWidgets('Integration: Reception submission triggers service call', (
    tester,
  ) async {
    Reception? called;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          RP.receptionServiceProvider.overrideWith(
            (ref) => _SpyReceptionService((r) => called = r),
          ),
          RP.produitsListProvider.overrideWith(
            (ref) async => [
              {'id': 'p1', 'nom': 'Diesel'},
            ],
          ),
          RP.produitByIdProvider.overrideWith(
            (ref, id) async => {'id': 'p1', 'nom': 'Diesel', 'code': 'DSL'},
          ),
          RP.citernesByProduitProvider.overrideWith(
            (ref, id) async => [
              {'id': 'cit1', 'nom': 'Citerne 1'},
            ],
          ),
          RP.partenairesListProvider.overrideWith(
            (ref) async => [
              {'id': 'pa1', 'nom': 'Partenaire X'},
            ],
          ),
        ],
        child: const MaterialApp(home: ReceptionFormScreen()),
      ),
    );

    // select product
    await tester.pump();
    await tester.tap(find.byType(DropdownButtonFormField<String>).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Diesel').last);
    await tester.pumpAndSettle();

    // select citerne
    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Citerne 1').last);
    await tester.pumpAndSettle();

    // enter indices
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Index avant *'),
      '0',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Index après *'),
      '100',
    );

    // submit
    await tester.tap(find.widgetWithText(ElevatedButton, 'Enregistrer'));
    await tester.pumpAndSettle();

    expect(called, isNotNull);
    expect(called!.produitId, 'p1');
    expect(called!.citerneId, 'cit1');
  });
}
