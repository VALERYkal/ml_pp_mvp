// 📌 Module : Role Dashboard - Tests Golden
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-09-17
// 🧭 Description : Tests Golden pour le composant RoleDashboard unifié

@Tags(['needs-refactor'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/dashboard/widgets/role_dashboard.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';

void main() {
  group('RoleDashboard Golden Tests', () {
    testWidgets('should render loading state correctly', (WidgetTester tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [kpiProviderProvider.overrideWith((ref) async => throw 'Loading...')],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: const RoleDashboard())),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Vue d\'ensemble'), findsOneWidget);

      container.dispose();
    });

    testWidgets('should render error state correctly', (WidgetTester tester) async {
      // Arrange
      final container = ProviderContainer(
        overrides: [kpiProviderProvider.overrideWith((ref) async => throw 'Test error')],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: const RoleDashboard())),
        ),
      );

      // Assert
      expect(find.text('Erreur chargement KPIs: Test error'), findsOneWidget);

      container.dispose();
    });

    testWidgets('should render data state correctly', (WidgetTester tester) async {
      // Arrange - Données de test
      final testData = KpiSnapshot(
        receptionsToday: const KpiNumberVolume(count: 5, volume15c: 2500.0, volumeAmbient: 2600.0),
        sortiesToday: const KpiNumberVolume(count: 3, volume15c: 1800.0, volumeAmbient: 1900.0),
        stocks: const KpiStocks(totalAmbient: 15000.0, total15c: 14500.0, capacityTotal: 20000.0),
        balanceToday: const KpiBalanceToday(
          receptions15c: 2500.0,
          sorties15c: 1800.0,
          receptionsAmbient: 2600.0,
          sortiesAmbient: 1900.0,
        ),
        trucksToFollow: const KpiTrucksToFollow(
          totalTrucks: 1,
          totalPlannedVolume: 0.0,
          trucksEnRoute: 0,
          trucksEnAttente: 1,
          volumeEnRoute: 0.0,
          volumeEnAttente: 0.0,
        ),
        trend7d: [
          KpiTrendPoint(day: DateTime(2025, 9, 10), receptions15c: 2000.0, sorties15c: 1500.0),
          KpiTrendPoint(day: DateTime(2025, 9, 11), receptions15c: 2200.0, sorties15c: 1600.0),
        ],
      );

      final container = ProviderContainer(
        overrides: [kpiProviderProvider.overrideWith((ref) async => testData)],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: const RoleDashboard())),
        ),
      );

      // Assert - Vérifier que tous les KPIs sont affichés
      expect(find.text('Réceptions du jour'), findsOneWidget);
      expect(find.text('Sorties du jour'), findsOneWidget);
      expect(find.text('Stock total (15°C)'), findsOneWidget);
      expect(find.text('Balance du jour'), findsOneWidget);
      expect(find.text('Camions à suivre'), findsOneWidget);
      expect(find.text('Tendance 7 jours'), findsOneWidget);

      // Vérifier les valeurs affichées
      expect(find.text('2.5 kL'), findsNWidgets(2)); // Réceptions et Stock
      expect(find.text('1.8 kL'), findsOneWidget); // Sorties
      expect(find.text('+700 L'), findsOneWidget); // Balance positive
      expect(find.text('1'), findsOneWidget); // 1 camion à suivre
      expect(find.text('4.2 kL'), findsOneWidget); // Tendance 7j

      container.dispose();
    });

    testWidgets('should handle empty citernes sous seuil', (WidgetTester tester) async {
      // Arrange - Données sans alertes
      final testData = KpiSnapshot(
        receptionsToday: const KpiNumberVolume(count: 2, volume15c: 1000.0, volumeAmbient: 1050.0),
        sortiesToday: const KpiNumberVolume(count: 1, volume15c: 800.0, volumeAmbient: 850.0),
        stocks: const KpiStocks(totalAmbient: 10000.0, total15c: 9500.0, capacityTotal: 15000.0),
        balanceToday: const KpiBalanceToday(
          receptions15c: 1000.0,
          sorties15c: 800.0,
          receptionsAmbient: 1050.0,
          sortiesAmbient: 850.0,
        ),
        trucksToFollow: const KpiTrucksToFollow(
          totalTrucks: 0,
          totalPlannedVolume: 0.0,
          trucksEnRoute: 0,
          trucksEnAttente: 0,
          volumeEnRoute: 0.0,
          volumeEnAttente: 0.0,
        ),
        trend7d: [],
      );

      final container = ProviderContainer(
        overrides: [kpiProviderProvider.overrideWith((ref) async => testData)],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: const RoleDashboard())),
        ),
      );

      // Assert
      expect(find.text('0'), findsOneWidget); // 0 camions à suivre
      expect(find.text('Aucun camion'), findsOneWidget);

      container.dispose();
    });

    testWidgets('should handle negative balance', (WidgetTester tester) async {
      // Arrange - Balance négative (plus de sorties que de réceptions)
      final testData = KpiSnapshot(
        receptionsToday: const KpiNumberVolume(count: 1, volume15c: 500.0, volumeAmbient: 520.0),
        sortiesToday: const KpiNumberVolume(count: 2, volume15c: 1200.0, volumeAmbient: 1250.0),
        stocks: const KpiStocks(totalAmbient: 8000.0, total15c: 7800.0, capacityTotal: 12000.0),
        balanceToday: const KpiBalanceToday(
          receptions15c: 500.0,
          sorties15c: 1200.0,
          receptionsAmbient: 520.0,
          sortiesAmbient: 1250.0,
        ),
        trucksToFollow: const KpiTrucksToFollow(
          totalTrucks: 0,
          totalPlannedVolume: 0.0,
          trucksEnRoute: 0,
          trucksEnAttente: 0,
          volumeEnRoute: 0.0,
          volumeEnAttente: 0.0,
        ),
        trend7d: [],
      );

      final container = ProviderContainer(
        overrides: [kpiProviderProvider.overrideWith((ref) async => testData)],
      );

      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: Scaffold(body: const RoleDashboard())),
        ),
      );

      // Assert
      expect(find.text('-700 L'), findsOneWidget); // Balance négative

      container.dispose();
    });
  });
}
