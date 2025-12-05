// 📌 Module : KPI Sorties - Tests provider
// 🧭 Description : Tests Riverpod pour sortiesKpiTodayProvider (sans Supabase ni RLS)

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_provider.dart';
import 'package:ml_pp_mvp/features/sorties/kpi/sorties_kpi_provider.dart';
import 'package:riverpod/riverpod.dart';

void main() {
  group('sortiesKpiTodayProvider', () {
    test('agrège correctement les données depuis sortiesRawTodayProvider', () async {
      final rowsFixture = [
        {
          'volume_ambiant': 500,
          'volume_corrige_15c': 480,
          'proprietaire_type': 'MONALUXE',
        },
        {
          'volume_ambiant': 700,
          'volume_corrige_15c': 680,
          'proprietaire_type': 'PARTENAIRE',
        },
      ];

      final container = ProviderContainer(
        overrides: [
          sortiesRawTodayProvider.overrideWith((ref) async => rowsFixture),
        ],
      );

      addTearDown(container.dispose);

      final kpi = await container.read(sortiesKpiTodayProvider.future);

      expect(kpi.count, 2);
      expect(kpi.volumeAmbient, 1200.0);
      expect(kpi.volume15c, 1160.0);
      expect(kpi.countMonaluxe, 1);
      expect(kpi.countPartenaire, 1);
    });

    test('retourne des valeurs zéro quand il n\'y a pas de sorties', () async {
      final container = ProviderContainer(
        overrides: [
          sortiesRawTodayProvider.overrideWith((ref) async => []),
        ],
      );

      addTearDown(container.dispose);

      final kpi = await container.read(sortiesKpiTodayProvider.future);

      expect(kpi.count, 0);
      expect(kpi.volumeAmbient, 0.0);
      expect(kpi.volume15c, 0.0);
      expect(kpi.countMonaluxe, 0);
      expect(kpi.countPartenaire, 0);
    });

    test('gère les valeurs null sans crash', () async {
      final rowsFixture = [
        {
          'volume_ambiant': null,
          'volume_corrige_15c': null,
          'proprietaire_type': null,
        },
        {
          'volume_ambiant': 100,
          'volume_corrige_15c': 95,
          'proprietaire_type': 'MONALUXE',
        },
      ];

      final container = ProviderContainer(
        overrides: [
          sortiesRawTodayProvider.overrideWith((ref) async => rowsFixture),
        ],
      );

      addTearDown(container.dispose);

      final kpi = await container.read(sortiesKpiTodayProvider.future);

      expect(kpi.count, 2);
      expect(kpi.volumeAmbient, 100.0); // null = 0, donc 0 + 100
      expect(kpi.volume15c, 95.0); // null = 0, donc 0 + 95
      expect(kpi.countMonaluxe, 1);
      expect(kpi.countPartenaire, 0);
    });

    test('convertit correctement en KpiNumberVolume', () async {
      final rowsFixture = [
        {
          'volume_ambiant': 500,
          'volume_corrige_15c': 480,
          'proprietaire_type': 'MONALUXE',
        },
      ];

      final container = ProviderContainer(
        overrides: [
          sortiesRawTodayProvider.overrideWith((ref) async => rowsFixture),
        ],
      );

      addTearDown(container.dispose);

      final kpi = await container.read(sortiesKpiTodayProvider.future);
      final volume = kpi.toKpiNumberVolume();

      expect(volume.count, 1);
      expect(volume.volumeAmbient, 500.0);
      expect(volume.volume15c, 480.0);
    });
  });
}

