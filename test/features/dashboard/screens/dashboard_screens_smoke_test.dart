// 📌 Module : Dashboard Screens - Tests Smoke E2E
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-09-17
// 🧭 Description : Tests Smoke pour vérifier que tous les écrans de dashboard se construisent correctement

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_admin_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_operateur_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_directeur_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_gerant_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_pca_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_lecture_screen.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/profil.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/shared/providers/session_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as Riverpod;
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart'
    show CurrentProfilNotifier;
import 'package:ml_pp_mvp/features/dashboard/providers/citernes_sous_seuil_provider.dart';
import 'package:ml_pp_mvp/data/repositories/stocks_kpi_repository.dart';
import 'package:ml_pp_mvp/features/stocks/data/stocks_kpi_providers.dart';

/// Fake notifier pour currentProfilProvider dans les tests
class _FakeProfilNotifier extends CurrentProfilNotifier {
  final Profil? _profil;
  _FakeProfilNotifier(this._profil);

  @override
  Future<Profil?> build() async => _profil;
}

/// Fake repository minimal pour éviter Supabase.instance dans les tests smoke
class _FakeStocksKpiRepositoryForSmokeTests implements StocksKpiRepository {
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
/// Note: Les screens passés en paramètre (DashboardAdminScreen, etc.) créent déjà leur propre Scaffold via RoleDashboard
Widget _appWithRouter(Widget child, {String initialLocation = "/"}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: "/",
        pageBuilder: (context, state) =>
            MaterialPage(key: state.pageKey, child: child),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('Dashboard Screens Smoke Tests', () {
    // Helper pour créer un Profil de test avec un rôle donné
    Profil _createTestProfil(UserRole role) {
      return Profil(
        id: 'test-profil-${role.name}',
        userId: 'test-user-${role.name}',
        role: role,
        email: '${role.name}@test.com',
        depotId: 'test-depot',
      );
    }

    // Helper pour créer un ProviderContainer avec tous les overrides nécessaires
    ProviderContainer _createTestContainer({
      required UserRole role,
      KpiSnapshot? kpiData,
    }) {
      final profil = _createTestProfil(role);
      final kpiSnapshot =
          kpiData ??
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
              receptionsAmbient: 1600.0,
              sortiesAmbient: 1300.0,
            ),
            trucksToFollow: KpiTrucksToFollow.zero,
          );

      return ProviderContainer(
        overrides: [
          // Override auth state pour simuler un utilisateur connecté
          // Utilise un Stream qui émet immédiatement une valeur puis se termine
          appAuthStateProvider.overrideWith(
            (ref) => Stream.value(
              AppAuthState(
                session:
                    null, // On n'a pas besoin d'une vraie session pour les tests
                authStream: const Stream.empty(),
              ),
            ),
          ),
          // Override profil provider pour retourner le profil de test
          currentProfilProvider.overrideWith(() => _FakeProfilNotifier(profil)),
          // Override KPI provider avec les données de test
          kpiProviderProvider.overrideWith((ref) async => kpiSnapshot),
          // Override citernes sous seuil provider
          citernesSousSeuilProvider.overrideWith((ref) async => []),
          // Override stocksKpiRepositoryProvider pour éviter Supabase.instance
          stocksKpiRepositoryProvider.overrideWith(
            (ref) => _FakeStocksKpiRepositoryForSmokeTests(),
          ),
        ],
      );
    }

    // Helper pour construire un widget de dashboard avec les providers
    // Retourne le container pour pouvoir le disposer dans les tests
    (Widget, ProviderContainer) _buildDashboardForRole(
      Widget screen,
      UserRole role,
    ) {
      final container = _createTestContainer(role: role);
      final widget = UncontrolledProviderScope(
        container: container,
        child: _appWithRouter(screen),
      );
      return (widget, container);
    }

    testWidgets('DashboardAdminScreen should build without errors', (
      WidgetTester tester,
    ) async {
      // Act
      final (widget, container) = _buildDashboardForRole(
        const DashboardAdminScreen(),
        UserRole.admin,
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(DashboardAdminScreen), findsOneWidget);
      // Vérifier que la carte KPI Réceptions est présente via sa Key stable
      expect(
        find.byKey(const Key('kpi_receptions_today_card')),
        findsOneWidget,
      );
      // Vérifier que la section "Vue d'ensemble" est présente
      expect(find.textContaining('Vue d\'ensemble'), findsOneWidget);

      container.dispose();
    });

    testWidgets('DashboardOperateurScreen should build without errors', (
      WidgetTester tester,
    ) async {
      // Act
      final (widget, container) = _buildDashboardForRole(
        const DashboardOperateurScreen(),
        UserRole.operateur,
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(DashboardOperateurScreen), findsOneWidget);
      expect(
        find.byKey(const Key('kpi_receptions_today_card')),
        findsOneWidget,
      );
      expect(find.textContaining('Vue d\'ensemble'), findsOneWidget);

      container.dispose();
    });

    testWidgets('DashboardDirecteurScreen should build without errors', (
      WidgetTester tester,
    ) async {
      // Act
      final (widget, container) = _buildDashboardForRole(
        const DashboardDirecteurScreen(),
        UserRole.directeur,
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(DashboardDirecteurScreen), findsOneWidget);
      expect(
        find.byKey(const Key('kpi_receptions_today_card')),
        findsOneWidget,
      );
      expect(find.textContaining('Vue d\'ensemble'), findsOneWidget);

      container.dispose();
    });

    testWidgets('DashboardGerantScreen should build without errors', (
      WidgetTester tester,
    ) async {
      // Act
      final (widget, container) = _buildDashboardForRole(
        const DashboardGerantScreen(),
        UserRole.gerant,
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(DashboardGerantScreen), findsOneWidget);
      expect(
        find.byKey(const Key('kpi_receptions_today_card')),
        findsOneWidget,
      );
      expect(find.textContaining('Vue d\'ensemble'), findsOneWidget);

      container.dispose();
    });

    testWidgets('DashboardPcaScreen should build without errors', (
      WidgetTester tester,
    ) async {
      // Act
      final (widget, container) = _buildDashboardForRole(
        const DashboardPcaScreen(),
        UserRole.pca,
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(DashboardPcaScreen), findsOneWidget);
      expect(
        find.byKey(const Key('kpi_receptions_today_card')),
        findsOneWidget,
      );
      expect(find.textContaining('Vue d\'ensemble'), findsOneWidget);

      container.dispose();
    });

    testWidgets('DashboardLectureScreen should build without errors', (
      WidgetTester tester,
    ) async {
      // Act
      final (widget, container) = _buildDashboardForRole(
        const DashboardLectureScreen(),
        UserRole.lecture,
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(DashboardLectureScreen), findsOneWidget);
      expect(
        find.byKey(const Key('kpi_receptions_today_card')),
        findsOneWidget,
      );
      expect(find.textContaining('Vue d\'ensemble'), findsOneWidget);

      container.dispose();
    });

    testWidgets('All dashboard screens should render KPI section correctly', (
      WidgetTester tester,
    ) async {
      // Arrange - Liste de tous les écrans de dashboard avec leurs rôles
      final screens = [
        (const DashboardAdminScreen(), UserRole.admin),
        (const DashboardOperateurScreen(), UserRole.operateur),
        (const DashboardDirecteurScreen(), UserRole.directeur),
        (const DashboardGerantScreen(), UserRole.gerant),
        (const DashboardPcaScreen(), UserRole.pca),
        (const DashboardLectureScreen(), UserRole.lecture),
      ];

      // Act & Assert - Vérifier que chaque écran se construit correctement
      for (final (screen, role) in screens) {
        final (widget, container) = _buildDashboardForRole(screen, role);
        await tester.pumpWidget(widget);
        await tester.pumpAndSettle();

        // Vérifier que l'écran est présent
        expect(find.byType(screen.runtimeType), findsOneWidget);

        // Vérifier que la carte KPI Réceptions est présente (via Key stable)
        expect(
          find.byKey(const Key('kpi_receptions_today_card')),
          findsOneWidget,
          reason:
              'La carte KPI Réceptions doit être présente pour le rôle ${role.name}',
        );

        // Vérifier que la section "Vue d'ensemble" est présente
        expect(
          find.textContaining('Vue d\'ensemble'),
          findsOneWidget,
          reason:
              'La section "Vue d\'ensemble" doit être présente pour le rôle ${role.name}',
        );

        // Dispose le container pour éviter les timers pendants
        container.dispose();
      }
    });
  });
}
