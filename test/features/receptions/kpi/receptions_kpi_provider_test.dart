// 📌 Module : Réceptions - Tests Providers KPI
// 🧭 Description : Tests unitaires pour les providers KPI réceptions

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/features/receptions/kpi/receptions_kpi_provider.dart';
import 'package:ml_pp_mvp/features/receptions/kpi/receptions_kpi_repository.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';
import 'package:ml_pp_mvp/features/profil/providers/profil_provider.dart' show currentProfilProvider, CurrentProfilNotifier;
import 'package:ml_pp_mvp/core/models/profil.dart';
import 'package:ml_pp_mvp/core/models/user_role.dart';

class FakeReceptionsKpiRepository implements ReceptionsKpiRepository {
  final KpiNumberVolume _returnValue;

  FakeReceptionsKpiRepository(this._returnValue);

  @override
  Future<KpiNumberVolume> getReceptionsKpiForDay(
    DateTime day, {
    String? depotId,
  }) async {
    return _returnValue;
  }

  @override
  SupabaseClient get client => throw UnimplementedError();
}

class _CapturingFakeReceptionsKpiRepository implements ReceptionsKpiRepository {
  final KpiNumberVolume _returnValue;
  final void Function(String?) _onCall;

  _CapturingFakeReceptionsKpiRepository(this._returnValue, this._onCall);

  @override
  Future<KpiNumberVolume> getReceptionsKpiForDay(
    DateTime day, {
    String? depotId,
  }) async {
    _onCall(depotId);
    return _returnValue;
  }

  @override
  SupabaseClient get client => throw UnimplementedError();
}

void main() {
  group('receptionsKpiTodayProvider', () {
    test('retourne les KPI du jour depuis le repository', () async {
      // Arrange
      final expectedKpi = KpiNumberVolume(
        count: 3,
        volume15c: 12345.0,
        volumeAmbient: 12000.0,
      );

      final fakeRepo = FakeReceptionsKpiRepository(expectedKpi);

      final container = ProviderContainer(
        overrides: [
          receptionsKpiRepositoryProvider.overrideWithValue(fakeRepo),
          currentProfilProvider.overrideWith(
            () => _FakeProfilNotifier(
              const Profil(
                id: 'user-1',
                email: 'test@example.com',
                role: UserRole.operateur,
                depotId: null,
              ),
            ),
          ),
        ],
      );

      // Act
      final result = await container.read(receptionsKpiTodayProvider.future);

      // Assert
      expect(result.count, equals(3));
      expect(result.volume15c, equals(12345.0));
      expect(result.volumeAmbient, equals(12000.0));
    });

    test('retourne zéro si aucune réception', () async {
      // Arrange
      final fakeRepo = FakeReceptionsKpiRepository(KpiNumberVolume.zero);

      final container = ProviderContainer(
        overrides: [
          receptionsKpiRepositoryProvider.overrideWithValue(fakeRepo),
          currentProfilProvider.overrideWith(
            () => _FakeProfilNotifier(
              const Profil(
                id: 'user-1',
                email: 'test@example.com',
                role: UserRole.operateur,
                depotId: null,
              ),
            ),
          ),
        ],
      );

      // Act
      final result = await container.read(receptionsKpiTodayProvider.future);

      // Assert
      expect(result.count, equals(0));
      expect(result.volume15c, equals(0.0));
      expect(result.volumeAmbient, equals(0.0));
    });

    test('passe le depotId au repository si présent dans le profil', () async {
      // Arrange
      final depotId = 'depot-123';
      final expectedKpi = KpiNumberVolume(
        count: 2,
        volume15c: 5000.0,
        volumeAmbient: 4900.0,
      );

      String? capturedDepotId;
      final fakeRepo = _CapturingFakeReceptionsKpiRepository(expectedKpi, (depotId) {
        capturedDepotId = depotId;
      });

      final container = ProviderContainer(
        overrides: [
          receptionsKpiRepositoryProvider.overrideWithValue(fakeRepo),
          currentProfilProvider.overrideWith(
            () => _FakeProfilNotifier(
              Profil(
                id: 'user-1',
                email: 'test@example.com',
                role: UserRole.operateur,
                depotId: depotId,
              ),
            ),
          ),
        ],
      );

      // Act
      await container.read(receptionsKpiTodayProvider.future);

      // Assert
      expect(capturedDepotId, equals(depotId));
    });
  });
}

// Fake notifier pour currentProfilProvider
class _FakeProfilNotifier extends CurrentProfilNotifier {
  final Profil? _value;

  _FakeProfilNotifier(this._value);

  @override
  Future<Profil?> build() async => _value;
}

