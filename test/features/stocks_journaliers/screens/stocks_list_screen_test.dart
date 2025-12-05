import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/stocks_journaliers/providers/stocks_providers.dart';
import 'package:ml_pp_mvp/features/stocks_journaliers/screens/stocks_list_screen.dart';

void main() {
  // Taille d'écran par défaut pour les tests (évite les problèmes de layout)
  const testScreenSize = Size(800, 1200);

  group('StocksListScreen', () {
    testWidgets('Affiche un loader quand l\'état est en chargement', (tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(testScreenSize);
      final container = ProviderContainer(
        overrides: [
          stocksListProvider.overrideWith(
            (ref) async {
              // Simuler un chargement en cours
              await Future.delayed(const Duration(milliseconds: 100));
              return const StocksDataWithMeta(
                stocks: [],
                requestedDate: '2025-01-15',
                actualDataDate: '2025-01-15',
                isFallback: false,
              );
            },
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const StocksListScreen(),
          ),
        ),
      );
      await tester.pump(); // Premier pump pour afficher le loading

      // Assert - Vérifier que le loader est présent pendant le chargement
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Chargement des stocks...'), findsOneWidget);

      // Purger le Timer en laissant le temps au Future.delayed de se terminer
      await tester.pump(const Duration(milliseconds: 200));
      
      // Nettoyer la taille d'écran
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('Affiche un message d\'erreur quand le provider est en erreur', (tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(testScreenSize);
      final error = Exception('Erreur de test');
      final container = ProviderContainer(
        overrides: [
          stocksListProvider.overrideWith(
            (ref) async {
              throw error;
            },
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const StocksListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Erreur de chargement des stocks'), findsOneWidget);
      
      // Nettoyer la taille d'écran
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('Affiche "Aucun stock trouvé" quand la liste est vide', (tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(testScreenSize);
      final container = ProviderContainer(
        overrides: [
          stocksListProvider.overrideWith(
            (ref) async => const StocksDataWithMeta(
              stocks: [],
              requestedDate: '2025-01-15',
              actualDataDate: '2025-01-15',
              isFallback: false,
            ),
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const StocksListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Aucun stock trouvé'), findsOneWidget);
      expect(find.text('Aucun stock n\'a été trouvé pour cette date et ces filtres.'), findsOneWidget);
      
      // Nettoyer la taille d'écran
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });

    testWidgets('Affiche les données quand le provider renvoie des stocks', (tester) async {
      // Arrange
      await tester.binding.setSurfaceSize(testScreenSize);
      final fakeStocks = [
        StockRowView(
          id: 'stock-1',
          dateJour: '2025-01-15',
          citerneId: 'citerne-1',
          citerneNom: 'Citerne Test 1',
          capaciteTotale: 10000.0,
          capaciteSecurite: 1000.0,
          produitId: 'produit-1',
          produitNom: 'Essence',
          stockAmbiant: 5000.0,
          stock15c: 5000.0,
        ),
        StockRowView(
          id: 'stock-2',
          dateJour: '2025-01-15',
          citerneId: 'citerne-2',
          citerneNom: 'Citerne Test 2',
          capaciteTotale: 8000.0,
          capaciteSecurite: 800.0,
          produitId: 'produit-2',
          produitNom: 'Gasoil',
          stockAmbiant: 4000.0,
          stock15c: 4000.0,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          stocksListProvider.overrideWith(
            (ref) async => StocksDataWithMeta(
              stocks: fakeStocks,
              requestedDate: '2025-01-15',
              actualDataDate: '2025-01-15',
              isFallback: false,
            ),
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const StocksListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Vérifier que les données sont affichées
      expect(find.text('Citerne Test 1'), findsOneWidget);
      expect(find.text('Citerne Test 2'), findsOneWidget);
      expect(find.text('Essence'), findsOneWidget);
      expect(find.text('Gasoil'), findsOneWidget);
      // Vérifier que le DataTable est présent
      expect(find.byType(DataTable), findsOneWidget);
      
      // Nettoyer la taille d'écran
      addTearDown(() => tester.binding.setSurfaceSize(null));
    });
  });
}

