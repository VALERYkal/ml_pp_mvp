// 📌 Module : KPI Sorties - Tests unitaires fonction pure
// 🧭 Description : Tests isolés pour computeKpiSorties (sans Riverpod ni Supabase)

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_provider.dart';

void main() {
  group('computeKpiSorties', () {
    test('calcule correctement les volumes et le count', () {
      final rows = [
        {
          'proprietaire_type': 'MONALUXE',
          'volume_corrige_15c': 1000,
          'volume_ambiant': 1100,
        },
        {
          'proprietaire_type': 'PARTENAIRE',
          'volume_corrige_15c': 500,
          'volume_ambiant': 550,
        },
      ];

      final kpi = computeKpiSorties(rows);

      expect(kpi.count, 2);
      expect(kpi.volume15c, 1500);
      expect(kpi.volumeAmbient, 1650);
      expect(kpi.countMonaluxe, 1);
      expect(kpi.countPartenaire, 1);
    });

    test('gère les 15°C manquants sans crash', () {
      final rows = [
        {
          'proprietaire_type': 'MONALUXE',
          'volume_corrige_15c': null,
          'volume_15c': null,
          'volume_ambiant': 800,
        },
      ];

      final kpi = computeKpiSorties(rows);

      expect(kpi.count, 1);
      expect(kpi.volume15c, 0); // pas de fallback auto
      expect(kpi.volumeAmbient, 800);
      expect(kpi.countMonaluxe, 1);
      expect(kpi.countPartenaire, 0);
    });

    test('retourne des 0 quand il n\'y a pas de sorties', () {
      final kpi = computeKpiSorties([]);

      expect(kpi.count, 0);
      expect(kpi.volume15c, 0);
      expect(kpi.volumeAmbient, 0);
      expect(kpi.countMonaluxe, 0);
      expect(kpi.countPartenaire, 0);
    });

    test('gère les strings numériques avec virgules et points', () {
      final rows = [
        {
          'proprietaire_type': 'MONALUXE',
          'volume_corrige_15c': '1 000,5',
          'volume_ambiant': '1 050,7',
        },
        {
          'proprietaire_type': 'PARTENAIRE',
          'volume_corrige_15c': '500.25',
          'volume_ambiant': '510.75',
        },
      ];

      final kpi = computeKpiSorties(rows);

      // On ne teste pas au dixième près, juste la cohérence générale
      expect(kpi.count, 2);
      expect(kpi.volume15c, closeTo(1500.75, 0.01));
      expect(kpi.volumeAmbient, closeTo(1561.45, 0.01));
      expect(kpi.countMonaluxe, 1);
      expect(kpi.countPartenaire, 1);
    });

    test('gère les propriétaires en minuscules', () {
      final rows = [
        {
          'proprietaire_type': 'monaluxe',
          'volume_corrige_15c': 100,
          'volume_ambiant': 110,
        },
        {
          'proprietaire_type': 'partenaire',
          'volume_corrige_15c': 200,
          'volume_ambiant': 220,
        },
      ];

      final kpi = computeKpiSorties(rows);

      expect(kpi.count, 2);
      expect(kpi.countMonaluxe, 1);
      expect(kpi.countPartenaire, 1);
    });

    test('gère les propriétaires null ou inconnus', () {
      final rows = [
        {
          'proprietaire_type': null,
          'volume_corrige_15c': 100,
          'volume_ambiant': 110,
        },
        {
          'proprietaire_type': 'AUTRE',
          'volume_corrige_15c': 200,
          'volume_ambiant': 220,
        },
      ];

      final kpi = computeKpiSorties(rows);

      expect(kpi.count, 2);
      expect(kpi.countMonaluxe, 0);
      expect(kpi.countPartenaire, 0);
      expect(kpi.volume15c, 300);
      expect(kpi.volumeAmbient, 330);
    });

    test('utilise volume_corrige_15c si volume_15c est absent (fallback legacy)', () {
      final rows = [
        {
          'proprietaire_type': 'MONALUXE',
          'volume_15c': null,
          'volume_corrige_15c': 700,
          'volume_ambiant': 720,
        },
      ];

      final kpi = computeKpiSorties(rows);

      expect(kpi.count, 1);
      expect(kpi.volume15c, 700);
      expect(kpi.volumeAmbient, 720);
      expect(kpi.countMonaluxe, 1);
      expect(kpi.countPartenaire, 0);
    });

    test('priorise volume_15c lorsque volume_corrige_15c est aussi présent', () {
      final rows = [
        {
          'proprietaire_type': 'MONALUXE',
          'volume_15c': 100.0,
          'volume_corrige_15c': 999.0,
          'volume_ambiant': 110.0,
        },
      ];

      final kpi = computeKpiSorties(rows);

      expect(kpi.volume15c, 100.0);
    });
  });
}
