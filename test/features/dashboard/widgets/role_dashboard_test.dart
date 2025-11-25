import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ml_pp_mvp/features/dashboard/widgets/role_dashboard.dart';
import 'package:ml_pp_mvp/features/dashboard/widgets/kpi_card.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_provider.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart';
import 'package:ml_pp_mvp/core/models/profil.dart';

/// Fake CurrentProfilNotifier pour isoler le dashboard
class FakeCurrentProfilNotifier extends CurrentProfilNotifier {
  FakeCurrentProfilNotifier(this._profil);

  final Profil? _profil;

  @override
  Future<Profil?> build() async => _profil;
}

void main() {
  const testProfil = Profil(
    id: 'test-profil',
    userId: 'user-123',
    nomComplet: 'Test User',
    role: 'admin',
    depotId: 'depot-1',
    email: 'admin@test.com',
  );

  /// Construit ProviderScope avec snapshot KPI injecté
  ProviderScope _buildScope(Widget child, {required KpiSnapshot snapshot}) {
    return ProviderScope(
      overrides: [
        kpiProviderProvider.overrideWith((ref) => snapshot),
        currentProfilProvider.overrideWith(
          () => FakeCurrentProfilNotifier(testProfil),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('RoleDashboard', () {
    testWidgets(
      'se construit sans erreur avec KpiSnapshot.empty',
      (tester) async {
        await tester.pumpWidget(
          _buildScope(const RoleDashboard(), snapshot: KpiSnapshot.empty),
        );

        await tester.pumpAndSettle();

        expect(find.byType(RoleDashboard), findsOneWidget);
      },
    );

    testWidgets(
      'affiche au moins une KpiCard lorsque les données KPI sont disponibles',
      (tester) async {
        /// 👉 Snap NON vide pour forcer l'affichage de KpiCard
        final snapshot = KpiSnapshot(
          receptions: KpiReceptions(
            count: 12,
            volume15c: 5000,
            volumeAmbient: 5200,
          ),
          stock: KpiStock(
            total15c: 15000,
            totalAmbient: 15500,
            capacityTotal: 20000,
          ),
          balance: KpiBalance(
            delta15c: +3000,
            deltaAmbient: +3200,
          ),
          tendance: KpiTendance(
            sumIn: 7000,
            sumOut: 4000,
            net: 3000,
          ),
        );

        await tester.pumpWidget(
          _buildScope(const RoleDashboard(), snapshot: snapshot),
        );

        await tester.pumpAndSettle();

        // Vérifie qu’au moins une carte KPI est présente
        expect(find.byType(KpiCard), findsWidgets);
      },
    );
  });
}
