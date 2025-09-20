// 📌 Module : Dashboard Screens - Tests Smoke E2E
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-09-17
// 🧭 Description : Tests Smoke pour vérifier que tous les écrans de dashboard se construisent correctement

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_admin_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_operateur_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_directeur_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_gerant_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_pca_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_lecture_screen.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';

void main() {
  group('Dashboard Screens Smoke Tests', () {
    late ProviderContainer container;

    setUp(() {
      // Mock du provider KPI avec des données de test
      container = ProviderContainer(
        overrides: [
          kpiProviderProvider.overrideWith((ref) => AsyncValue.data(
            const KpiSnapshot(
              receptionsToday: KpiNumberVolume(
                count: 3,
                volume15c: 1500.0,
                volumeAmbient: 1600.0,
              ),
              sortiesToday: KpiNumberVolume(
                count: 2,
                volume15c: 1200.0,
                volumeAmbient: 1300.0,
              ),
              stocks: KpiStocks(
                totalAmbient: 10000.0,
                total15c: 9500.0,
                capacityTotal: 15000.0,
              ),
              balanceToday: KpiBalanceToday(
                receptions15c: 1500.0,
                sorties15c: 1200.0,
              ),
              citernesSousSeuil: [],
              trend7d: [],
            ),
          )),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('DashboardAdminScreen should build without errors', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const DashboardAdminScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(DashboardAdminScreen), findsOneWidget);
      expect(find.text('Vue d\'ensemble'), findsOneWidget);
      expect(find.text('Réceptions du jour'), findsOneWidget);
      expect(find.text('Sorties du jour'), findsOneWidget);
      expect(find.text('Stock total (15°C)'), findsOneWidget);
      expect(find.text('Balance du jour'), findsOneWidget);
      expect(find.text('Citernes sous seuil'), findsOneWidget);
      expect(find.text('Tendance 7 jours'), findsOneWidget);
    });

    testWidgets('DashboardOperateurScreen should build without errors', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const DashboardOperateurScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(DashboardOperateurScreen), findsOneWidget);
      expect(find.text('Vue d\'ensemble'), findsOneWidget);
      expect(find.text('Réceptions du jour'), findsOneWidget);
      expect(find.text('Sorties du jour'), findsOneWidget);
      expect(find.text('Stock total (15°C)'), findsOneWidget);
      expect(find.text('Balance du jour'), findsOneWidget);
      expect(find.text('Citernes sous seuil'), findsOneWidget);
      expect(find.text('Tendance 7 jours'), findsOneWidget);
    });

    testWidgets('DashboardDirecteurScreen should build without errors', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const DashboardDirecteurScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(DashboardDirecteurScreen), findsOneWidget);
      expect(find.text('Vue d\'ensemble'), findsOneWidget);
      expect(find.text('Réceptions du jour'), findsOneWidget);
      expect(find.text('Sorties du jour'), findsOneWidget);
      expect(find.text('Stock total (15°C)'), findsOneWidget);
      expect(find.text('Balance du jour'), findsOneWidget);
      expect(find.text('Citernes sous seuil'), findsOneWidget);
      expect(find.text('Tendance 7 jours'), findsOneWidget);
    });

    testWidgets('DashboardGerantScreen should build without errors', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const DashboardGerantScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(DashboardGerantScreen), findsOneWidget);
      expect(find.text('Vue d\'ensemble'), findsOneWidget);
      expect(find.text('Réceptions du jour'), findsOneWidget);
      expect(find.text('Sorties du jour'), findsOneWidget);
      expect(find.text('Stock total (15°C)'), findsOneWidget);
      expect(find.text('Balance du jour'), findsOneWidget);
      expect(find.text('Citernes sous seuil'), findsOneWidget);
      expect(find.text('Tendance 7 jours'), findsOneWidget);
    });

    testWidgets('DashboardPcaScreen should build without errors', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const DashboardPcaScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(DashboardPcaScreen), findsOneWidget);
      expect(find.text('Vue d\'ensemble'), findsOneWidget);
      expect(find.text('Réceptions du jour'), findsOneWidget);
      expect(find.text('Sorties du jour'), findsOneWidget);
      expect(find.text('Stock total (15°C)'), findsOneWidget);
      expect(find.text('Balance du jour'), findsOneWidget);
      expect(find.text('Citernes sous seuil'), findsOneWidget);
      expect(find.text('Tendance 7 jours'), findsOneWidget);
    });

    testWidgets('DashboardLectureScreen should build without errors', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const DashboardLectureScreen(),
          ),
        ),
      );

      // Assert
      expect(find.byType(DashboardLectureScreen), findsOneWidget);
      expect(find.text('Vue d\'ensemble'), findsOneWidget);
      expect(find.text('Réceptions du jour'), findsOneWidget);
      expect(find.text('Sorties du jour'), findsOneWidget);
      expect(find.text('Stock total (15°C)'), findsOneWidget);
      expect(find.text('Balance du jour'), findsOneWidget);
      expect(find.text('Citernes sous seuil'), findsOneWidget);
      expect(find.text('Tendance 7 jours'), findsOneWidget);
    });

    testWidgets('All dashboard screens should render identical content', (WidgetTester tester) async {
      // Arrange - Liste de tous les écrans de dashboard
      final screens = [
        const DashboardAdminScreen(),
        const DashboardOperateurScreen(),
        const DashboardDirecteurScreen(),
        const DashboardGerantScreen(),
        const DashboardPcaScreen(),
        const DashboardLectureScreen(),
      ];

      // Act & Assert - Vérifier que chaque écran se construit correctement
      for (final screen in screens) {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              home: screen,
            ),
          ),
        );

        // Vérifier que tous les KPIs sont présents
        expect(find.text('Vue d\'ensemble'), findsOneWidget);
        expect(find.text('Réceptions du jour'), findsOneWidget);
        expect(find.text('Sorties du jour'), findsOneWidget);
        expect(find.text('Stock total (15°C)'), findsOneWidget);
        expect(find.text('Balance du jour'), findsOneWidget);
        expect(find.text('Citernes sous seuil'), findsOneWidget);
        expect(find.text('Tendance 7 jours'), findsOneWidget);

        // Nettoyer pour le prochain test
        await tester.pumpAndSettle();
      }
    });
  });
}
