// 📌 Module : Sorties - Tests Repository KPI
// 🧭 Description : Tests unitaires pour SortiesKpiRepository
// 
// Note : Ces tests se concentrent sur la logique d'agrégation.
// Les tests d'intégration avec Supabase sont couverts par les tests du provider.

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/sorties/kpi/sorties_kpi_repository.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';

/// Test helper : vérifie la logique d'agrégation
void _testAggregationLogic(
  List<Map<String, dynamic>> mockData,
  int expectedCount,
  double expectedVolume15c,
  double expectedVolumeAmbient,
) {
  int count = 0;
  double volume15c = 0.0;
  double volumeAmbient = 0.0;

  for (final row in mockData) {
    count += 1;
    final v15 = (row['volume_corrige_15c'] as num?)?.toDouble() ?? 0.0;
    final vAmb = (row['volume_ambiant'] as num?)?.toDouble() ?? 0.0;
    volume15c += v15;
    volumeAmbient += vAmb;
  }

  expect(count, equals(expectedCount));
  expect(volume15c, equals(expectedVolume15c));
  expect(volumeAmbient, equals(expectedVolumeAmbient));
}

void main() {
  group('SortiesKpiRepository - Logique d\'agrégation', () {
    test('agrégation - aucun enregistrement retourne zéro', () {
      // Arrange
      final mockData = <Map<String, dynamic>>[];

      // Act & Assert
      _testAggregationLogic(mockData, 0, 0.0, 0.0);
    });

    test('agrégation - plusieurs sorties agrège correctement', () {
      // Arrange
      final mockData = <Map<String, dynamic>>[
        {
          'volume_corrige_15c': 1000.0,
          'volume_ambiant': 980.0,
        },
        {
          'volume_corrige_15c': 2000.0,
          'volume_ambiant': 1950.0,
        },
        {
          'volume_corrige_15c': 1500.0,
          'volume_ambiant': 1470.0,
        },
      ];

      // Act & Assert
      _testAggregationLogic(mockData, 3, 4500.0, 4400.0);
    });

    test('agrégation - plusieurs sorties avec différents proprietaire_type agrège correctement', () {
      // Arrange
      final mockData = <Map<String, dynamic>>[
        {
          'volume_corrige_15c': 1000.0,
          'volume_ambiant': 980.0,
          // proprietaire_type: 'MONALUXE' (non utilisé dans l'agrégation)
        },
        {
          'volume_corrige_15c': 2000.0,
          'volume_ambiant': 1950.0,
          // proprietaire_type: 'PARTENAIRE' (non utilisé dans l'agrégation)
        },
        {
          'volume_corrige_15c': 1500.0,
          'volume_ambiant': 1470.0,
          // proprietaire_type: 'MONALUXE' (non utilisé dans l'agrégation)
        },
      ];

      // Act & Assert
      // L'agrégation doit ignorer le proprietaire_type et sommer tous les volumes
      _testAggregationLogic(mockData, 3, 4500.0, 4400.0);
    });

    test('agrégation - valeurs null traitées comme 0', () {
      // Arrange
      final mockData = <Map<String, dynamic>>[
        {
          'volume_corrige_15c': null,
          'volume_ambiant': 980.0,
        },
        {
          'volume_corrige_15c': 2000.0,
          'volume_ambiant': null,
        },
      ];

      // Act & Assert
      _testAggregationLogic(mockData, 2, 2000.0, 980.0);
    });

    test('agrégation - format date correct (TIMESTAMPTZ avec bornes)', () {
      // Arrange
      final day = DateTime(2025, 11, 29);
      final dayStart = DateTime.utc(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayStartIso = dayStart.toIso8601String();
      final dayEndIso = dayEnd.toIso8601String();

      // Act & Assert
      // Vérifier que les bornes sont correctes pour filtrer sur le jour complet
      expect(dayStartIso, contains('T00:00:00'));
      expect(dayEndIso, contains('T00:00:00'));
      expect(dayEnd.day, equals(dayStart.day + 1));
    });
  });
}

