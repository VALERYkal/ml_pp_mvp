// 📌 Module : Dashboard KPI Sorties - Tests Widget
// 🧭 Description : Tests widget pour vérifier l'affichage de la carte KPI Sorties du jour

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/dashboard/widgets/role_dashboard.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart' show currentProfilProvider, CurrentProfilNotifier;
import 'package:ml_pp_mvp/core/models/profil.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';
import 'package:ml_pp_mvp/shared/providers/session_provider.dart';

/// Fake notifier pour currentProfilProvider dans les tests
class _FakeProfilNotifier extends CurrentProfilNotifier {
  final Profil? _profil;
  _FakeProfilNotifier(this._profil);

  @override
  Future<Profil?> build() async => _profil;
}

void main() {
  group('Dashboard KPI Sorties', () {
    testWidgets('Dashboard affiche correctement la carte KPI Sorties du jour',
        (WidgetTester tester) async {
      // 1. Construire un snapshot fake avec des données Sorties
      final fakeSnapshot = KpiSnapshot(
        receptionsToday: KpiNumberVolume.zero,
        sortiesToday: const KpiNumberVolume(
          count: 5,
          volume15c: 1400.0,
          volumeAmbient: 1500.0,
        ),
        stocks: KpiStocks.zero,
        balanceToday: KpiBalanceToday.zero,
        trucksToFollow: KpiTrucksToFollow.zero,
        trend7d: const [],
      );

      // 2. Créer un profil fake pour éviter les erreurs de profilProvider
      final fakeProfil = Profil(
        id: 'user-1',
        userId: 'user-1',
        email: 'test@example.com',
        role: UserRole.gerant,
        depotId: 'depot-1',
      );

      // 3. Override providers et afficher
      final container = ProviderContainer(
        overrides: [
          // Override auth state pour simuler un utilisateur connecté
          appAuthStateProvider.overrideWith((ref) => Stream.value(
            AppAuthState(
              session: null,
              authStream: const Stream.empty(),
            ),
          )),
          // Override profil provider
          currentProfilProvider.overrideWith(() => _FakeProfilNotifier(fakeProfil)),
          // Override KPI provider
          kpiProviderProvider.overrideWith((ref) async => fakeSnapshot),
        ],
      );

      addTearDown(container.dispose);

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

      // 4. Assertions sur la carte Sorties
      // Vérifier que la carte est présente via Key stable
      expect(
        find.byKey(const Key('kpi_sorties_today_card')),
        findsOneWidget,
        reason: 'La carte KPI Sorties doit être présente',
      );

      // Vérifier que le titre est affiché
      expect(
        find.textContaining('Sorties du jour'),
        findsOneWidget,
        reason: 'Le titre "Sorties du jour" doit être affiché',
      );

      // Vérifier que le count est affiché (formaté via fmtCount)
      // fmtCount(5) devrait donner "5" ou "5 camions"
      expect(
        find.textContaining('5'),
        findsWidgets,
        reason: 'Le count (5) doit être affiché quelque part dans la carte',
      );

      // Vérifier que le volume 15°C est affiché (formaté via fmtL)
      // fmtL(1400.0) utilise NumberFormat qui peut formater avec espaces/virgules
      // On vérifie qu'au moins un des formats possibles est présent
      final volume15cFound = find.textContaining('1 400').evaluate().isNotEmpty ||
          find.textContaining('1,400').evaluate().isNotEmpty ||
          find.textContaining('1400').evaluate().isNotEmpty;
      expect(
        volume15cFound,
        isTrue,
        reason: 'Le volume 15°C (1400) doit être affiché quelque part dans la carte (formaté comme "1 400 L", "1,400 L" ou "1400 L")',
      );

      // Vérifier que le volume ambiant est affiché
      // fmtL(1500.0) utilise NumberFormat qui peut formater avec espaces/virgules
      final volumeAmbientFound = find.textContaining('1 500').evaluate().isNotEmpty ||
          find.textContaining('1,500').evaluate().isNotEmpty ||
          find.textContaining('1500').evaluate().isNotEmpty;
      expect(
        volumeAmbientFound,
        isTrue,
        reason: 'Le volume ambiant (1500) doit être affiché quelque part dans la carte (formaté comme "1 500 L", "1,500 L" ou "1500 L")',
      );

      // Vérifier que l'icône est présente
      expect(
        find.byIcon(Icons.outbox_outlined),
        findsOneWidget,
        reason: 'L\'icône outbox_outlined doit être présente dans la carte Sorties',
      );
    });

    testWidgets('Dashboard affiche zéro quand il n\'y a pas de sorties',
        (WidgetTester tester) async {
      // 1. Construire un snapshot avec sorties à zéro
      final fakeSnapshot = KpiSnapshot(
        receptionsToday: KpiNumberVolume.zero,
        sortiesToday: KpiNumberVolume.zero,
        stocks: KpiStocks.zero,
        balanceToday: KpiBalanceToday.zero,
        trucksToFollow: KpiTrucksToFollow.zero,
        trend7d: const [],
      );

      // 2. Créer un profil fake
      final fakeProfil = Profil(
        id: 'user-1',
        userId: 'user-1',
        email: 'test@example.com',
        role: UserRole.gerant,
        depotId: 'depot-1',
      );

      // 3. Override providers et afficher
      final container = ProviderContainer(
        overrides: [
          // Override auth state pour simuler un utilisateur connecté
          appAuthStateProvider.overrideWith((ref) => Stream.value(
            AppAuthState(
              session: null,
              authStream: const Stream.empty(),
            ),
          )),
          // Override profil provider
          currentProfilProvider.overrideWith(() => _FakeProfilNotifier(fakeProfil)),
          // Override KPI provider
          kpiProviderProvider.overrideWith((ref) async => fakeSnapshot),
        ],
      );

      addTearDown(container.dispose);

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

      // 4. Assertions
      expect(
        find.byKey(const Key('kpi_sorties_today_card')),
        findsOneWidget,
        reason: 'La carte KPI Sorties doit être présente même avec des valeurs zéro',
      );

      expect(
        find.textContaining('Sorties du jour'),
        findsOneWidget,
        reason: 'Le titre "Sorties du jour" doit être affiché',
      );

      // Vérifier que le count zéro est affiché
      expect(
        find.textContaining('0'),
        findsWidgets,
        reason: 'Le count (0) doit être affiché quelque part dans la carte',
      );
    });
  });
}

