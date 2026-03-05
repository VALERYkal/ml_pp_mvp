import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/receptions/screens/reception_form_screen.dart';
import 'package:ml_pp_mvp/features/receptions/providers/reception_providers.dart'
    as RP;
import 'package:ml_pp_mvp/features/receptions/data/reception_service.dart';
import 'package:ml_pp_mvp/shared/referentiels/referentiels.dart' as refs;
import 'package:ml_pp_mvp/features/receptions/data/partenaires_provider.dart'
    as rpart;
import 'package:ml_pp_mvp/shared/referentiels/role_provider.dart' as role;
import 'package:supabase_flutter/supabase_flutter.dart';

class _SpyReceptionService extends ReceptionService {
  final void Function(String, String, String) onCall;
  _SpyReceptionService(this.onCall)
    : super.withClient(
        SupabaseClient('http://localhost', 'anon'),
        refRepo: FakeRefRepo(),
      );
  @override
  Future<String> createValidated({
    String? coursDeRouteId,
    required String citerneId,
    required String produitId,
    required double indexAvant,
    required double indexApres,
    double? temperatureCAmb,
    double? densiteA15,
    double? volumeCorrige15C,
    String proprietaireType = 'MONALUXE',
    String? partenaireId,
    DateTime? dateReception,
    String? note,
  }) async {
    onCall(citerneId, produitId, proprietaireType);
    return 'rec-1';
  }
}

class FakeRefRepo extends refs.ReferentielsRepo {
  FakeRefRepo() : super(SupabaseClient('http://localhost', 'anon'));

  @override
  Future<List<refs.ProduitRef>> loadProduits() async {
    return [refs.ProduitRef(id: 'p1', code: 'DSL', nom: 'Diesel')];
  }

  @override
  Future<List<refs.CiterneRef>> loadCiternesActives() async {
    return [
      refs.CiterneRef(
        id: '57da330a-1305-4582-be45-ceab0f1aa795',
        nom: 'TANK1',
        produitId: 'p1',
        capaciteTotale: 10000,
        capaciteSecurite: 9000,
        depotId: '11111111-1111-1111-1111-111111111111',
        depotNom: '',
        statut: 'active',
      ),
    ];
  }

  @override
  String? getProduitIdByCodeSync(String code) => 'p1';
}

void main() {
  testWidgets('Integration: Reception submission triggers service call', (
    tester,
  ) async {
    String? calledCiterneId;
    String? calledProduitId;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          receptionServiceProvider.overrideWith(
            (ref) => _SpyReceptionService((citerneId, produitId, _) {
              calledCiterneId = citerneId;
              calledProduitId = produitId;
            }),
          ),
          refs.referentielsRepoProvider.overrideWithValue(FakeRefRepo()),
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
              {'id': '57da330a-1305-4582-be45-ceab0f1aa795', 'nom': 'TANK1'},
            ],
          ),
          RP.partenairesListProvider.overrideWith(
            (ref) async => [
              {'id': 'pa1', 'nom': 'Partenaire X'},
            ],
          ),
          role.userRoleProvider.overrideWith((ref) async => 'gerant'),
          rpart.partenairesProvider.overrideWith(
            (ref) async => const [
              rpart.PartenaireItem(id: 'pa1', nom: 'Partenaire X'),
            ],
          ),
        ],
        child: MaterialApp.router(
          routerConfig: GoRouter(
            routes: [
              GoRoute(
                path: '/receptions',
                builder: (context, state) => const ReceptionFormScreen(),
              ),
            ],
            initialLocation: '/receptions',
          ),
        ),
      ),
    );

    // select product
    await tester.pump();
    await tester.pumpAndSettle(); // Attendre le chargement complet

    // Laisser un petit délai pour que les providers/stream builders terminent
    await tester.pump(const Duration(milliseconds: 100));

    // Basculer en mode PARTENAIRE pour activer la sélection produit
    final partenaireChipText = find.text('PARTENAIRE');
    final partenaireChip = find.ancestor(
      of: partenaireChipText,
      matching: find.byType(ChoiceChip),
    );
    expect(
      partenaireChip,
      findsOneWidget,
      reason:
          'Le ChoiceChip PARTENAIRE doit être présent pour sélectionner un produit.',
    );
    await tester.ensureVisible(partenaireChip);
    await tester.tap(partenaireChip);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Sélectionner un partenaire via l'autocomplete
    final partenaireField = find.widgetWithText(TextField, 'Partenaire');
    expect(
      partenaireField,
      findsOneWidget,
      reason:
          'Le champ Partenaire doit être présent pour sélectionner un partenaire.',
    );
    await tester.enterText(partenaireField, 'Partenaire X');
    await tester.pumpAndSettle();
    final partenaireOption = find.widgetWithText(ListTile, 'Partenaire X');
    expect(
      partenaireOption,
      findsWidgets,
      reason: 'L\'option Partenaire X doit apparaître dans la liste.',
    );
    await tester.tap(partenaireOption.first);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // Les produits sont sélectionnés via ChoiceChip avec le format "CODE · Nom"
    // Chercher le texte "DSL · Diesel" ou "Diesel" dans le widget tree puis taper le ChoiceChip
    await tester.pump(const Duration(milliseconds: 200));
    final productText = find.textContaining('Diesel');
    expect(
      productText,
      findsWidgets,
      reason:
          'Le texte du produit Diesel doit être présent avant de continuer le test.',
    );
    final productChip = find.ancestor(
      of: productText.first,
      matching: find.byType(ChoiceChip),
    );
    expect(
      productChip,
      findsOneWidget,
      reason:
          'Le ChoiceChip Diesel doit être présent avant de continuer le test.',
    );
    await tester.ensureVisible(productChip);
    await tester.tap(productChip);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // select citerne - Les citernes sont sélectionnées via RadioListTile
    // Attendre que les citernes soient chargées après la sélection du produit
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    // Chercher le texte "TANK1" dans un RadioListTile
    final citerneText = find.text('TANK1');
    expect(
      citerneText,
      findsWidgets,
      reason: 'Le texte "TANK1" doit être présent',
    );
    // Trouver le RadioListTile parent
    final citerneRadio = find.ancestor(
      of: citerneText.first,
      matching: find.byType(RadioListTile<String>),
    );
    if (citerneRadio.evaluate().isEmpty) {
      // Si pas de RadioListTile, taper directement sur le texte
      await tester.ensureVisible(citerneText.first);
      await tester.tap(citerneText.first);
    } else {
      await tester.ensureVisible(citerneRadio);
      await tester.tap(citerneRadio);
    }
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    // enter indices (Key-based finders pour stabilité Nightly)
    final indexAvant = find.byKey(const Key('reception_index_avant'));
    expect(indexAvant, findsOneWidget);
    await tester.enterText(indexAvant, '0');
    await tester.pump();

    final indexApres = find.byKey(const Key('reception_index_apres'));
    expect(indexApres, findsOneWidget);
    await tester.enterText(indexApres, '100');
    await tester.pump();

    // enter temperature and density (required fields)
    final tempField = find.byKey(const Key('reception_temp'));
    expect(tempField, findsOneWidget);
    await tester.enterText(tempField, '15');
    await tester.pump();

    final densField = find.byKey(const Key('reception_dens'));
    expect(densField, findsOneWidget);
    await tester.enterText(densField, '830');
    await tester.pump();

    // submit
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    final submitButton = find.byKey(const Key('reception_submit_btn'));
    expect(
      submitButton,
      findsOneWidget,
      reason:
          'Le bouton de soumission de la réception doit être présent dans le widget tree',
    );

    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(calledCiterneId, isNotNull);
    expect(calledProduitId, 'p1');
    expect(calledCiterneId, '57da330a-1305-4582-be45-ceab0f1aa795');
  });
}
