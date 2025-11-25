import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_admin_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_directeur_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_gerant_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_operateur_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_pca_screen.dart';
import 'package:ml_pp_mvp/features/dashboard/screens/dashboard_lecture_screen.dart';

import 'package:ml_pp_mvp/features/dashboard/widgets/role_dashboard.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/profil.dart';

/// Fake CurrentProfilNotifier pour éviter tout accès réel à Supabase
class FakeCurrentProfilNotifier extends CurrentProfilNotifier {
  FakeCurrentProfilNotifier(this._profil);

  final Profil? _profil;

  @override
  Future<Profil?> build() async => _profil;
}

void main() {
  // Profil de test simple, réutilisé dans tous les tests
  const testProfil = Profil(
    id: 'test-profil',
    userId: 'user-123',
    nomComplet: 'Test Admin',
    role: 'admin',
    depotId: 'depot-1',
    email: 'admin@test.com',
  );

  ProviderScope _buildScope(Widget child) {
    return ProviderScope(
      overrides: [
        // On bypasse complètement la logique réelle des KPI
        kpiProviderProvider.overrideWith((ref) => KpiSnapshot.empty),

        // On force le profil courant pour éviter tout appel réseau
        currentProfilProvider.overrideWith(
          () => FakeCurrentProfilNotifier(testProfil),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('Dashboard screens smoke tests', () {
    testWidgets(
      'DashboardAdminScreen rend un RoleDashboard sans crasher',
      (tester) async {
        await tester.pumpWidget(
          _buildScope(const DashboardAdminScreen()),
        );

        // On laisse le FutureProvider se résoudre
        await tester.pumpAndSettle();

        expect(find.byType(RoleDashboard), findsOneWidget);
      },
    );

    testWidgets(
      'Toutes les screens de dashboard par rôle se construisent correctement',
      (tester) async {
        final screens = <Widget>[
          const DashboardAdminScreen(),
          const DashboardDirecteurScreen(),
          const DashboardGerantScreen(),
          const DashboardOperateurScreen(),
          const DashboardPcaScreen(),
          const DashboardLectureScreen(),
        ];

        for (final screen in screens) {
          await tester.pumpWidget(_buildScope(screen));
          await tester.pumpAndSettle();

          expect(
            find.byType(RoleDashboard),
            findsOneWidget,
            reason:
                'RoleDashboard doit être présent pour ${screen.runtimeType}',
          );
        }
      },
    );
  });
}
