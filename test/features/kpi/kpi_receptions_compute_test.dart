// 📌 Module : KPI Réceptions - Tests unitaires fonction pure
// 🧭 Description : Tests isolés pour computeKpiReceptions (sans Riverpod ni Supabase)

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/kpi/providers/kpi_provider.dart';

void main() {
  group('computeKpiReceptions', () {
    test('calcule correctement les volumes et le count', () {
      final rows = [
        {
          'volume_ambiant': 800,
          'volume_corrige_15c': 750,
          'proprietaire_type': 'MONALUXE',
        },
        {
          'volume_ambiant': '900',
          'volume_corrige_15c': '850',
          'proprietaire_type': 'PARTENAIRE',
        },
      ];

      final kpi = computeKpiReceptions(rows);

      expect(kpi.count, 2);
      expect(kpi.volumeAmbient, 1700.0);
      expect(kpi.volume15c, 1600.0);
      expect(kpi.countMonaluxe, 1);
      expect(kpi.countPartenaire, 1);
    });

    test('gère les 15°C manquants sans crash', () {
      final rows = [
        {
          'volume_ambiant': 1000,
          'volume_corrige_15c': null,
          'proprietaire_type': 'MONALUXE',
        },
      ];

      final kpi = computeKpiReceptions(rows);

      expect(kpi.count, 1);
      expect(kpi.volumeAmbient, 1000.0);
      expect(kpi.volume15c, 0.0); // pas de fallback
      expect(kpi.countMonaluxe, 1);
      expect(kpi.countPartenaire, 0);
    });

    test('retourne des 0 quand il n\'y a pas de réceptions', () {
      final kpi = computeKpiReceptions([]);

      expect(kpi.count, 0);
      expect(kpi.volumeAmbient, 0.0);
      expect(kpi.volume15c, 0.0);
      expect(kpi.countMonaluxe, 0);
      expect(kpi.countPartenaire, 0);
    });

    test('gère les strings numériques avec virgules et points', () {
      final rows = [
        {
          'volume_ambiant': '1,234.5',
          'volume_corrige_15c': '1,200.0',
          'proprietaire_type': 'MONALUXE',
        },
        {
          'volume_ambiant': '2.345,67',
          'volume_corrige_15c': '2.300,50',
          'proprietaire_type': 'PARTENAIRE',
        },
      ];

      final kpi = computeKpiReceptions(rows);

      // Format US : "1,234.5" -> 1234.5
      // Format européen : "2.345,67" -> 2345.67
      expect(kpi.count, 2);
      expect(kpi.volumeAmbient, closeTo(3580.17, 0.01)); // 1234.5 + 2345.67
      expect(kpi.volume15c, closeTo(3500.5, 0.01)); // 1200.0 + 2300.5
    });

    test('gère les propriétaires en minuscules', () {
      final rows = [
        {
          'volume_ambiant': 100,
          'volume_corrige_15c': 95,
          'proprietaire_type': 'monaluxe', // minuscule
        },
        {
          'volume_ambiant': 200,
          'volume_corrige_15c': 190,
          'proprietaire_type': 'partenaire', // minuscule
        },
      ];

      final kpi = computeKpiReceptions(rows);

      expect(kpi.countMonaluxe, 1);
      expect(kpi.countPartenaire, 1);
    });

    test('gère les propriétaires null ou inconnus', () {
      final rows = [
        {
          'volume_ambiant': 100,
          'volume_corrige_15c': 95,
          'proprietaire_type': null,
        },
        {
          'volume_ambiant': 200,
          'volume_corrige_15c': 190,
          'proprietaire_type': 'AUTRE',
        },
      ];

      final kpi = computeKpiReceptions(rows);

      expect(kpi.count, 2);
      expect(kpi.countMonaluxe, 0);
      expect(kpi.countPartenaire, 0);
    });

    test('utilise volume_15c si volume_corrige_15c est absent', () {
      final rows = [
        {
          'volume_ambiant': 100,
          'volume_15c': 95, // fallback sur volume_15c
          'proprietaire_type': 'MONALUXE',
        },
      ];

      final kpi = computeKpiReceptions(rows);

      expect(kpi.volume15c, 95.0);
    });
  });
}

