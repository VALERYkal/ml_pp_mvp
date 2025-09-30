import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/sorties/screens/sortie_form_screen.dart';
import 'package:ml_pp_mvp/features/sorties/providers/sortie_providers.dart'
    as P;
import 'package:ml_pp_mvp/features/sorties/data/sortie_service.dart';
import 'package:ml_pp_mvp/features/sorties/models/sortie_produit.dart';
import 'package:ml_pp_mvp/features/sorties/models/citerne_with_stock.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/shared/ui/ui_keys.dart';
import '../../test_supabase_bootstrap.dart';

class _SpySortieService extends SortieService {
  final void Function() onCall;
  _SpySortieService(this.onCall)
    : super(rpc: (fn, {params}) async {
        return {'id': 'spy-sortie-id'};
      });
  @override
  Future<SortieProduit> createSortie(
    SortieProduit sortie, {
    String? currentUserId,
  }) async {
    onCall();
    return sortie.copyWith(id: 'new-id');
  }
}

void main() {
  setUpAll(() async {
    await initSupabaseForTests();
  });

  testWidgets('SortieFormScreen se charge sans erreur avec la nouvelle interface', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          P.sortieServiceProvider.overrideWith(
            (ref) => _SpySortieService(() {}),
          ),
          P.produitsListProvider.overrideWith(
            (ref) async => [
              {'id': 'p1', 'nom': 'Diesel', 'code': 'DSL'},
            ],
          ),
          P.clientsListProvider.overrideWith(
            (ref) async => [
              {'id': 'c1', 'nom': 'Client A'},
            ],
          ),
          P.partenairesListProvider.overrideWith(
            (ref) async => [
              {'id': 'pa1', 'nom': 'Partenaire X'},
            ],
          ),
          P.produitByIdProvider.overrideWith(
            (ref, id) async => {'id': 'p1', 'nom': 'Diesel', 'code': 'DSL'},
          ),
          P.citernesByProduitProvider.overrideWith(
            (ref, id) async => [
              {'id': 'cit1', 'nom': 'Citerne 1'},
            ],
          ),
          P.citernesByProduitWithStockProvider('p1').overrideWith(
            (ref) async => [
              CiterneWithStockForSortie(
                id: 'cit1',
                nom: 'Citerne 1',
                capaciteTotale: 5000,
                stockAmbiant: 3000,
                stock15c: 2980,
                date: DateTime.now(),
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: SortieFormScreen()),
      ),
    );

    // Attendre que l'écran se charge
    await tester.pump();
    await tester.pumpAndSettle();

    // Vérifier que l'écran se charge avec la nouvelle interface
    expect(find.byType(SortieFormScreen), findsOneWidget);
    
    // Attendre que tous les widgets soient rendus
    await tester.pumpAndSettle();
    
    // Sections modernes
    expect(find.text('Propriété et Bénéficiaire'), findsOneWidget);
    expect(find.text('Produit et Citerne'), findsOneWidget);
    expect(find.text('Mesures et Calculs'), findsOneWidget);

    // Choix de propriété
    expect(find.text('MONALUXE'), findsOneWidget);
    expect(find.text('PARTENAIRE'), findsOneWidget);

    // Ensure ListView is fully rendered and scrolled to show the save button
    await tester.pumpAndSettle();
    
    // Scroll to the bottom to ensure the save button is visible
    final listView = find.byType(ListView);
    if (listView.evaluate().isNotEmpty) {
      await tester.drag(listView, const Offset(0, -1000));
      await tester.pumpAndSettle();
    }
    
    // CTA - Save button should be visible after scrolling
    expect(find.byKey(UiKeys.sortieSave), findsOneWidget);
  });

  testWidgets('SortieFormScreen permet la sélection de produit avec la nouvelle interface', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          P.sortieServiceProvider.overrideWith(
            (ref) => _SpySortieService(() {}),
          ),
          P.produitsListProvider.overrideWith(
            (ref) async => [
              {'id': 'p1', 'nom': 'Diesel', 'code': 'DSL'},
              {'id': 'p2', 'nom': 'Essence', 'code': 'ESS'},
            ],
          ),
          P.clientsListProvider.overrideWith(
            (ref) async => [
              {'id': 'c1', 'nom': 'Client A'},
            ],
          ),
          P.partenairesListProvider.overrideWith(
            (ref) async => [
              {'id': 'pa1', 'nom': 'Partenaire X'},
            ],
          ),
          P.produitByIdProvider.overrideWith(
            (ref, id) async => {'id': id, 'nom': 'Diesel', 'code': 'DSL'},
          ),
          P.citernesByProduitProvider.overrideWith(
            (ref, id) async => [
              {'id': 'cit1', 'nom': 'Citerne 1'},
            ],
          ),
          P.citernesByProduitWithStockProvider('p1').overrideWith(
            (ref) async => [
              CiterneWithStockForSortie(
                id: 'cit1',
                nom: 'Citerne 1',
                capaciteTotale: 5000,
                stockAmbiant: 3000,
                stock15c: 2980,
                date: DateTime.now(),
              ),
            ],
          ),
        ],
        child: const MaterialApp(home: SortieFormScreen()),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    // Vérifier que les produits sont affichés comme des chips
    expect(find.textContaining('DSL Diesel'), findsOneWidget);
    expect(find.textContaining('ESS Essence'), findsOneWidget);
    
    // Tester la sélection d'un produit
    await tester.tap(find.textContaining('DSL Diesel'));
    await tester.pumpAndSettle();
    
    // Vérifier que les citernes apparaissent après sélection du produit
    expect(find.text('Citerne 1'), findsOneWidget);
  });
}
