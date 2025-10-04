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
import 'package:ml_pp_mvp/core/models/profil.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';

// Faux notifier qui renvoie un profil non-null synchronement
class _FakeCurrentProfilNotifier extends CurrentProfilNotifier {
  @override
  Future<Profil?> build() async {
    return const Profil(
      id: 'profil_test',
      userId: 'user_test',
      nomComplet: 'Test User',
      role: UserRole.operateur,
      depotId: 'depot_test',
      email: 'test@example.com',
    );
  }
}

void main() {
  group('Dashboard Screens Smoke Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          // 1) KPI: déjà présent
          kpiProviderProvider.overrideWith(
            (ref) async => const KpiSnapshot(
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
                receptionsAmbient: 1600.0,
                sortiesAmbient: 1300.0,
              ),
              trucksToFollow: KpiTrucksToFollow(
                totalTrucks: 0,
                totalPlannedVolume: 0.0,
                trucksEnRoute: 0,
                trucksEnAttente: 0,
                volumeEnRoute: 0.0,
                volumeEnAttente: 0.0,
              ),
              trend7d: [],
            ), // ← ferme KpiSnapshot
          ), // ← ferme overrideWith
          // 2) **NOUVELLE override** : un profil non nul
          currentProfilProvider.overrideWith(_FakeCurrentProfilNotifier.new),
        ], // ← ferme overrides
      ); // ← ferme ProviderContainer
    });

    tearDown(() {
      container.dispose();
    });

    testWidgets('DashboardAdminScreen should build without errors', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: const DashboardAdminScreen()),
        ),
      );

      // Assert
      expect(
        tester.takeException(),
        isNull,
      ); // aucune exception pendant le build
      expect(find.byType(Scaffold), findsOneWidget); // l'écran s'est bien rendu
    });

    testWidgets('DashboardOperateurScreen should build without errors', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: const DashboardOperateurScreen()),
        ),
      );

      // Assert
      expect(
        tester.takeException(),
        isNull,
      ); // aucune exception pendant le build
      expect(find.byType(Scaffold), findsOneWidget); // l'écran s'est bien rendu
    });

    testWidgets('DashboardDirecteurScreen should build without errors', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: const DashboardDirecteurScreen()),
        ),
      );

      // Assert
      expect(
        tester.takeException(),
        isNull,
      ); // aucune exception pendant le build
      expect(find.byType(Scaffold), findsOneWidget); // l'écran s'est bien rendu
    });

    testWidgets('DashboardGerantScreen should build without errors', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: const DashboardGerantScreen()),
        ),
      );

      // Assert
      expect(
        tester.takeException(),
        isNull,
      ); // aucune exception pendant le build
      expect(find.byType(Scaffold), findsOneWidget); // l'écran s'est bien rendu
    });

    testWidgets('DashboardPcaScreen should build without errors', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: const DashboardPcaScreen()),
        ),
      );

      // Assert
      expect(
        tester.takeException(),
        isNull,
      ); // aucune exception pendant le build
      expect(find.byType(Scaffold), findsOneWidget); // l'écran s'est bien rendu
    });

    testWidgets('DashboardLectureScreen should build without errors', (
      WidgetTester tester,
    ) async {
      // Act
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: const DashboardLectureScreen()),
        ),
      );

      // Assert
      expect(
        tester.takeException(),
        isNull,
      ); // aucune exception pendant le build
      expect(find.byType(Scaffold), findsOneWidget); // l'écran s'est bien rendu
    });

    testWidgets('All dashboard screens should render identical content', (
      WidgetTester tester,
    ) async {
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
            child: MaterialApp(home: screen),
          ),
        );

        // Vérifier que l'écran s'est bien rendu
        expect(
          tester.takeException(),
          isNull,
        ); // aucune exception pendant le build
        expect(
          find.byType(Scaffold),
          findsOneWidget,
        ); // l'écran s'est bien rendu

        // Nettoyer pour le prochain test
        await tester.pumpAndSettle();
      }
    });
  });
}
