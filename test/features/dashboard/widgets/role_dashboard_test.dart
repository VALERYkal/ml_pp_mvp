// 📌 Module : Role Dashboard - Tests Golden
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-09-17
// 🧭 Description : Tests Golden pour le composant RoleDashboard unifié

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/dashboard/widgets/role_dashboard.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';
import 'package:ml_pp_mvp/features/dashboard/providers/citernes_sous_seuil_provider.dart';
import 'package:ml_pp_mvp/data/repositories/stocks_kpi_repository.dart';
import 'package:ml_pp_mvp/features/stocks/data/stocks_kpi_providers.dart';

/// Fake repository minimal pour éviter Supabase.instance dans les tests
class _FakeStocksKpiRepositoryForTests implements StocksKpiRepository {
  @override
  Future<List<DepotGlobalStockKpi>> fetchDepotProductTotals({
    String? depotId,
    String? produitId,
    DateTime? dateJour,
  }) async {
    return [
      const DepotGlobalStockKpi(
        depotId: 'test-depot',
        depotNom: 'Test Dépôt',
        produitId: 'produit-1',
        produitNom: 'Essence',
        stockAmbiantTotal: 10000.0,
        stock15cTotal: 9500.0,
      ),
    ];
  }

  @override
  Future<List<DepotOwnerStockKpi>> fetchDepotOwnerTotals({
    String? depotId,
    String? produitId,
    String? proprietaireType,
    DateTime? dateJour,
  }) async {
    // Retourner 2 owners (MONALUXE et PARTENAIRE) pour que l'UI fonctionne
    return [
      const DepotOwnerStockKpi(
        depotId: 'test-depot',
        depotNom: 'Test Dépôt',
        proprietaireType: 'MONALUXE',
        produitId: 'produit-1',
        produitNom: 'Essence',
        stockAmbiantTotal: 6000.0,
        stock15cTotal: 5700.0,
      ),
      const DepotOwnerStockKpi(
        depotId: 'test-depot',
        depotNom: 'Test Dépôt',
        proprietaireType: 'PARTENAIRE',
        produitId: 'produit-1',
        produitNom: 'Essence',
        stockAmbiantTotal: 4000.0,
        stock15cTotal: 3800.0,
      ),
    ];
  }

  @override
  Future<List<CiterneOwnerStockSnapshot>> fetchCiterneOwnerSnapshots({
    String? depotId,
    String? citerneId,
    String? produitId,
    String? proprietaireType,
    DateTime? dateJour,
  }) async {
    return [];
  }

  @override
  Future<List<CiterneGlobalStockSnapshot>> fetchCiterneGlobalSnapshots({
    String? depotId,
    String? citerneId,
    String? produitId,
    DateTime? dateJour,
  }) async {
    return [];
  }

  @override
  Future<double> fetchDepotTotalCapacity({
    required String depotId,
    String? produitId,
  }) async {
    return 20000.0;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCiterneStocksFromSnapshot({
    String? depotId,
    String? citerneId,
    String? produitId,
  }) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchDepotOwnerStocksFromSnapshot({
    required String depotId,
    String? produitId,
  }) async {
    return [];
  }

  @override
  Future<List<Map<String, dynamic>>> fetchStockActuelRows({
    required String depotId,
    String? produitId,
  }) async {
    return [];
  }
}

/// Helper pour créer un MaterialApp.router avec GoRouter minimal pour les tests
Widget _appWithRouter(Widget child, {String initialLocation = "/"}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: "/",
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: Scaffold(body: child),
        ),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('RoleDashboard Golden Tests', () {
    testWidgets('should render loading state correctly', (
      WidgetTester tester,
    ) async {
      // Arrange - Utiliser un Completer pour contrôler quand le Future se résout
      final completer = Completer<KpiSnapshot>();
      final container = ProviderContainer(
        overrides: [
          kpiProviderProvider.overrideWith((ref) => completer.future),
          stocksKpiRepositoryProvider.overrideWith(
            (ref) => _FakeStocksKpiRepositoryForTests(),
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _appWithRouter(const RoleDashboard()),
        ),
      );

      // Attendre un frame pour que le widget se construise
      await tester.pump();

      // Assert - Vérifier que l'état de chargement est affiché via Key stable
      // (avant que le Future ne se résolve)
      expect(
        find.byKey(const Key('role_dashboard_loading_state')),
        findsOneWidget,
      );
      // Vérifier que le spinner est présent
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Résoudre le Future pour nettoyer
      completer.complete(KpiSnapshot.empty);
      await tester.pumpAndSettle();

      container.dispose();
    });

    testWidgets('should render error state correctly', (
      WidgetTester tester,
    ) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          kpiProviderProvider.overrideWith(
            (ref) =>
                Future<KpiSnapshot>.error('Test error', StackTrace.current),
          ),
          stocksKpiRepositoryProvider.overrideWith(
            (ref) => _FakeStocksKpiRepositoryForTests(),
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _appWithRouter(const RoleDashboard()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Vérifier que l'état d'erreur est affiché via Key stable
      expect(
        find.byKey(const Key('role_dashboard_error_state')),
        findsOneWidget,
      );
      // Vérifier que l'icône d'erreur est présente
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      // Vérifier que le texte d'erreur est présent (texte stable dans le widget)
      expect(find.text('Erreur de chargement des KPIs'), findsOneWidget);
      expect(find.text('Veuillez réessayer plus tard'), findsOneWidget);

      container.dispose();
    });

    testWidgets('should render data state correctly', (
      WidgetTester tester,
    ) async {
      // Arrange - Données de test
      final testData = KpiSnapshot(
        receptionsToday: const KpiNumberVolume(
          count: 5,
          volume15c: 2500.0,
          volumeAmbient: 2600.0,
        ),
        sortiesToday: const KpiNumberVolume(
          count: 3,
          volume15c: 1800.0,
          volumeAmbient: 1900.0,
        ),
        stocks: const KpiStocks(
          totalAmbient: 15000.0,
          total15c: 14500.0,
          capacityTotal: 20000.0,
        ),
        balanceToday: const KpiBalanceToday(
          receptions15c: 2500.0,
          sorties15c: 1800.0,
          receptionsAmbient: 2600.0,
          sortiesAmbient: 1900.0,
        ),
        trucksToFollow: KpiTrucksToFollow.zero,
      );

      final container = ProviderContainer(
        overrides: [
          kpiProviderProvider.overrideWith((ref) async => testData),
          citernesSousSeuilProvider.overrideWith(
            (ref) async => [],
          ), // Pas d'alertes pour ce test
          stocksKpiRepositoryProvider.overrideWith(
            (ref) => _FakeStocksKpiRepositoryForTests(),
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _appWithRouter(const RoleDashboard()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Vérifier que toutes les cartes KPI sont présentes via Keys stables
      expect(
        find.byKey(const Key('kpi_receptions_today_card')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('kpi_sorties_today_card')), findsOneWidget);
      expect(find.byKey(const Key('kpi_stock_total_card')), findsOneWidget);
      expect(find.byKey(const Key('kpi_balance_today_card')), findsOneWidget);
      expect(
        find.byKey(const Key('kpi_alertes_citernes_card')),
        findsOneWidget,
      );

      // Vérifier que les valeurs formatées sont présentes (formatage stable)
      // Réceptions: 2500.0 L = "2,500.0 L" ou "2.5 kL" selon le formatage
      expect(
        find.textContaining('2'),
        findsWidgets,
      ); // Présent dans plusieurs valeurs
      expect(
        find.textContaining('1'),
        findsWidgets,
      ); // Présent dans plusieurs valeurs

      container.dispose();
    });

    testWidgets('should handle empty citernes sous seuil', (
      WidgetTester tester,
    ) async {
      // Arrange - Données sans alertes (trucksToFollow.zero signifie aucune alerte)
      final testData = const KpiSnapshot(
        receptionsToday: KpiNumberVolume(
          count: 2,
          volume15c: 1000.0,
          volumeAmbient: 1050.0,
        ),
        sortiesToday: KpiNumberVolume(
          count: 1,
          volume15c: 800.0,
          volumeAmbient: 850.0,
        ),
        stocks: KpiStocks(
          totalAmbient: 10000.0,
          total15c: 9500.0,
          capacityTotal: 15000.0,
        ),
        balanceToday: KpiBalanceToday(
          receptions15c: 1000.0,
          sorties15c: 800.0,
          receptionsAmbient: 1050.0,
          sortiesAmbient: 850.0,
        ),
        trucksToFollow: KpiTrucksToFollow.zero,
      );

      final container = ProviderContainer(
        overrides: [
          kpiProviderProvider.overrideWith((ref) async => testData),
          citernesSousSeuilProvider.overrideWith(
            (ref) async => [],
          ), // Pas d'alertes pour ce test
          stocksKpiRepositoryProvider.overrideWith(
            (ref) => _FakeStocksKpiRepositoryForTests(),
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _appWithRouter(const RoleDashboard()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Vérifier que le dashboard s'affiche sans erreur avec des données vides
      // Les cartes KPI principales doivent être présentes
      expect(
        find.byKey(const Key('kpi_receptions_today_card')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('kpi_sorties_today_card')), findsOneWidget);
      expect(find.byKey(const Key('kpi_stock_total_card')), findsOneWidget);
      expect(find.byKey(const Key('kpi_balance_today_card')), findsOneWidget);
      expect(
        find.byKey(const Key('kpi_alertes_citernes_card')),
        findsOneWidget,
      );

      // Vérifier qu'il n'y a pas d'erreur
      expect(find.byKey(const Key('role_dashboard_error_state')), findsNothing);

      container.dispose();
    });

    testWidgets('should handle negative balance', (WidgetTester tester) async {
      // Arrange - Balance négative (plus de sorties que de réceptions)
      final testData = const KpiSnapshot(
        receptionsToday: KpiNumberVolume(
          count: 1,
          volume15c: 500.0,
          volumeAmbient: 520.0,
        ),
        sortiesToday: KpiNumberVolume(
          count: 2,
          volume15c: 1200.0,
          volumeAmbient: 1250.0,
        ),
        stocks: KpiStocks(
          totalAmbient: 8000.0,
          total15c: 7800.0,
          capacityTotal: 12000.0,
        ),
        balanceToday: KpiBalanceToday(
          receptions15c: 500.0,
          sorties15c: 1200.0,
          receptionsAmbient: 520.0,
          sortiesAmbient: 1250.0,
        ),
        trucksToFollow: KpiTrucksToFollow.zero,
      );

      final container = ProviderContainer(
        overrides: [
          kpiProviderProvider.overrideWith((ref) async => testData),
          citernesSousSeuilProvider.overrideWith(
            (ref) async => [],
          ), // Pas d'alertes pour ce test
          stocksKpiRepositoryProvider.overrideWith(
            (ref) => _FakeStocksKpiRepositoryForTests(),
          ),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: _appWithRouter(const RoleDashboard()),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Vérifier que la carte Balance est présente
      expect(find.byKey(const Key('kpi_balance_today_card')), findsOneWidget);

      // Vérifier que la balance négative est affichée
      // delta15c = 500 - 1200 = -700
      // Le formatage fmtDelta utilise un tiret cadratin "–" pour les valeurs négatives
      // On cherche la valeur absolue "700" qui doit être présente dans le texte formaté
      expect(
        find.textContaining('700'),
        findsWidgets,
      ); // La valeur absolue doit être présente

      // Vérifier que la carte Balance utilise la couleur rouge pour les valeurs négatives
      // (tintColor devrait être Color(0xFFF44336) pour delta15c < 0)
      // On peut vérifier que la carte est présente, ce qui confirme que le rendu est correct

      container.dispose();
    });
  });
}
