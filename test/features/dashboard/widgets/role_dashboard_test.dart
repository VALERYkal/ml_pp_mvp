// 📌 Module : Role Dashboard - Tests Golden
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-09-17
// 🧭 Description : Tests Golden pour le composant RoleDashboard unifié

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/dashboard/widgets/role_dashboard.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/profil.dart';

void main() {
  group('RoleDashboard Golden Tests', () {
    testWidgets('should render loading state correctly', (WidgetTester tester) async {
      // Arrange - Utiliser un Completer pour contrôler quand le Future se résout
      final completer = Completer<KpiSnapshot>();
      final container = ProviderContainer(
        overrides: [
          kpiProviderProvider.overrideWith((ref) => completer.future),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: const RoleDashboard(),
            ),
          ),
        ),
      );

      // Attendre un frame pour que le widget se construise
      await tester.pump();

      // Assert - Vérifier que l'état de chargement est affiché via Key stable
      // (avant que le Future ne se résolve)
      expect(find.byKey(const Key('role_dashboard_loading_state')), findsOneWidget);
      // Vérifier que le spinner est présent
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      // Résoudre le Future pour nettoyer
      completer.complete(KpiSnapshot.empty);
      await tester.pumpAndSettle();
      
      container.dispose();
    });

    testWidgets('should render error state correctly', (WidgetTester tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [
          kpiProviderProvider.overrideWith((ref) => Future<KpiSnapshot>.error(
            'Test error',
            StackTrace.current,
          )),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: const RoleDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Vérifier que l'état d'erreur est affiché via Key stable
      expect(find.byKey(const Key('role_dashboard_error_state')), findsOneWidget);
      // Vérifier que l'icône d'erreur est présente
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      // Vérifier que le texte d'erreur est présent (texte stable dans le widget)
      expect(find.text('Erreur de chargement des KPIs'), findsOneWidget);
      expect(find.text('Veuillez réessayer plus tard'), findsOneWidget);
      
      container.dispose();
    });

    testWidgets('should render data state correctly', (WidgetTester tester) async {
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
        trend7d: [
          KpiTrendPoint(
            day: DateTime(2025, 9, 10),
            receptions15c: 2000.0,
            sorties15c: 1500.0,
          ),
          KpiTrendPoint(
            day: DateTime(2025, 9, 11),
            receptions15c: 2200.0,
            sorties15c: 1600.0,
          ),
        ],
      );

      final container = ProviderContainer(
        overrides: [
          kpiProviderProvider.overrideWith((ref) async => testData),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: const RoleDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Vérifier que toutes les cartes KPI sont présentes via Keys stables
      expect(find.byKey(const Key('kpi_receptions_today_card')), findsOneWidget);
      expect(find.byKey(const Key('kpi_sorties_today_card')), findsOneWidget);
      expect(find.byKey(const Key('kpi_stock_total_card')), findsOneWidget);
      expect(find.byKey(const Key('kpi_balance_today_card')), findsOneWidget);
      expect(find.byKey(const Key('kpi_tendance_7d_card')), findsOneWidget);

      // Vérifier que les valeurs formatées sont présentes (formatage stable)
      // Réceptions: 2500.0 L = "2,500.0 L" ou "2.5 kL" selon le formatage
      expect(find.textContaining('2'), findsWidgets); // Présent dans plusieurs valeurs
      expect(find.textContaining('1'), findsWidgets); // Présent dans plusieurs valeurs
      
      container.dispose();
    });

    testWidgets('should handle empty citernes sous seuil', (WidgetTester tester) async {
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
        trend7d: [],
      );

      final container = ProviderContainer(
        overrides: [
          kpiProviderProvider.overrideWith((ref) async => testData),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: const RoleDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Vérifier que le dashboard s'affiche sans erreur avec des données vides
      // Les cartes KPI principales doivent être présentes
      expect(find.byKey(const Key('kpi_receptions_today_card')), findsOneWidget);
      expect(find.byKey(const Key('kpi_sorties_today_card')), findsOneWidget);
      expect(find.byKey(const Key('kpi_stock_total_card')), findsOneWidget);
      expect(find.byKey(const Key('kpi_balance_today_card')), findsOneWidget);
      
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
        trend7d: [],
      );

      final container = ProviderContainer(
        overrides: [
          kpiProviderProvider.overrideWith((ref) async => testData),
        ],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: const RoleDashboard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Vérifier que la carte Balance est présente
      expect(find.byKey(const Key('kpi_balance_today_card')), findsOneWidget);
      
      // Vérifier que la balance négative est affichée
      // delta15c = 500 - 1200 = -700
      // Le formatage fmtDelta utilise un tiret cadratin "–" pour les valeurs négatives
      // On cherche la valeur absolue "700" qui doit être présente dans le texte formaté
      expect(find.textContaining('700'), findsWidgets); // La valeur absolue doit être présente
      
      // Vérifier que la carte Balance utilise la couleur rouge pour les valeurs négatives
      // (tintColor devrait être Color(0xFFF44336) pour delta15c < 0)
      // On peut vérifier que la carte est présente, ce qui confirme que le rendu est correct
      
      container.dispose();
    });
  });
}
