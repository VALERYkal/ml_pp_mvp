// 📌 Module : Dashboard - Tests KPI Camions à Suivre
// 🧑 Auteur : Mona (IA Flutter/Supabase/Riverpod)
// 📅 Date : 2025-11-27
// 🧭 Description : Tests unitaires pour le KPI "Camions à suivre"
//
// RÈGLE MÉTIER CDR (Cours de Route) :
// - DECHARGE est EXCLU (cours terminé, déjà pris en charge dans Réceptions/Stocks)
// - "Au chargement" (trucksLoading) = CHARGEMENT
// - "En route" (trucksOnRoute) = TRANSIT + FRONTIERE
// - "Arrivés" (trucksArrived) = ARRIVE
// - totalCamionsASuivre = cours non déchargés (CHARGEMENT + TRANSIT + FRONTIERE + ARRIVE)

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';

void main() {
  group('KPI Camions à Suivre - Tests Logique Métier (3 catégories)', () {
    /// Simule la logique de calcul du KPI telle qu'implémentée dans _fetchTrucksToFollow
    /// RÈGLE MÉTIER avec 3 catégories:
    /// - Au chargement = CHARGEMENT
    /// - En route = TRANSIT + FRONTIERE
    /// - Arrivés = ARRIVE
    KpiTrucksToFollow calculateKpi(
      List<Map<String, dynamic>> coursDeRouteData,
    ) {
      // Statuts non déchargés - On exclut uniquement DECHARGE
      const statutsNonDecharges = [
        'CHARGEMENT',
        'TRANSIT',
        'FRONTIERE',
        'ARRIVE',
      ];

      // Filtrer les cours de route non déchargés
      final filtered = coursDeRouteData.where((row) {
        final rawStatut = (row['statut'] as String?)?.trim();
        if (rawStatut == null) return false;
        final statut = rawStatut.toUpperCase();
        return statutsNonDecharges.contains(statut);
      }).toList();

      int trucksLoading = 0; // Au chargement
      int trucksOnRoute = 0; // En route
      int trucksArrived = 0; // Arrivés
      double volumeLoading = 0.0;
      double volumeOnRoute = 0.0;
      double volumeArrived = 0.0;

      for (final row in filtered) {
        final rawStatut = (row['statut'] as String?)?.trim();
        if (rawStatut == null) continue;

        final statut = rawStatut.toUpperCase();
        final volume = (row['volume'] as num?)?.toDouble() ?? 0.0;

        if (statut == 'CHARGEMENT') {
          // Au chargement = camions chez le fournisseur
          trucksLoading++;
          volumeLoading += volume;
        } else if (statut == 'TRANSIT' || statut == 'FRONTIERE') {
          // En route = TRANSIT + FRONTIERE
          trucksOnRoute++;
          volumeOnRoute += volume;
        } else if (statut == 'ARRIVE') {
          // Arrivés = camions arrivés au dépôt mais pas encore déchargés
          trucksArrived++;
          volumeArrived += volume;
        }
      }

      return KpiTrucksToFollow(
        totalTrucks: trucksLoading + trucksOnRoute + trucksArrived,
        totalPlannedVolume: volumeLoading + volumeOnRoute + volumeArrived,
        trucksLoading: trucksLoading,
        trucksOnRoute: trucksOnRoute,
        trucksArrived: trucksArrived,
        volumeLoading: volumeLoading,
        volumeOnRoute: volumeOnRoute,
        volumeArrived: volumeArrived,
      );
    }

    test(
      'Scénario de référence: 2 CHARGEMENT, 1 TRANSIT, 1 FRONTIERE, 1 ARRIVE, 1 DECHARGE',
      () {
        // Arrange: Scénario de référence complet
        final coursDeRouteData = [
          {'id': '1', 'volume': 10000, 'statut': 'CHARGEMENT'}, // Au chargement
          {'id': '2', 'volume': 15000, 'statut': 'CHARGEMENT'}, // Au chargement
          {'id': '3', 'volume': 20000, 'statut': 'TRANSIT'}, // En route
          {'id': '4', 'volume': 25000, 'statut': 'FRONTIERE'}, // En route
          {'id': '5', 'volume': 30000, 'statut': 'ARRIVE'}, // Arrivés
          {'id': '6', 'volume': 35000, 'statut': 'DECHARGE'}, // EXCLU
        ];

        // Act
        final result = calculateKpi(coursDeRouteData);

        // Assert - Critères d'acceptation
        expect(
          result.totalTrucks,
          equals(5),
          reason: 'Total = 5 camions non déchargés (DECHARGE exclu)',
        );
        expect(
          result.trucksLoading,
          equals(2),
          reason: 'Au chargement = 2 (CHARGEMENT)',
        );
        expect(
          result.trucksOnRoute,
          equals(2),
          reason: 'En route = 2 (TRANSIT + FRONTIERE)',
        );
        expect(result.trucksArrived, equals(1), reason: 'Arrivés = 1 (ARRIVE)');

        // Vérification des volumes
        expect(
          result.volumeLoading,
          equals(25000.0),
          reason: 'Vol. chargement = 10000 + 15000 = 25000 L',
        );
        expect(
          result.volumeOnRoute,
          equals(45000.0),
          reason: 'Vol. en route = 20000 + 25000 = 45000 L',
        );
        expect(
          result.volumeArrived,
          equals(30000.0),
          reason: 'Vol. arrivés = 30000 L',
        );
        expect(
          result.totalPlannedVolume,
          equals(100000.0),
          reason: 'Volume total = 25000 + 45000 + 30000 = 100000 L',
        );
      },
    );

    test('CHARGEMENT uniquement → tous au chargement', () {
      // Arrange
      final coursDeRouteData = [
        {'id': '1', 'volume': 10000, 'statut': 'CHARGEMENT'},
        {'id': '2', 'volume': 20000, 'statut': 'CHARGEMENT'},
      ];

      // Act
      final result = calculateKpi(coursDeRouteData);

      // Assert
      expect(result.totalTrucks, equals(2));
      expect(result.trucksLoading, equals(2));
      expect(result.trucksOnRoute, equals(0));
      expect(result.trucksArrived, equals(0));
      expect(result.volumeLoading, equals(30000.0));
    });

    test('TRANSIT et FRONTIERE → tous en route', () {
      // Arrange
      final coursDeRouteData = [
        {'id': '1', 'volume': 15000, 'statut': 'TRANSIT'},
        {'id': '2', 'volume': 20000, 'statut': 'FRONTIERE'},
      ];

      // Act
      final result = calculateKpi(coursDeRouteData);

      // Assert
      expect(result.totalTrucks, equals(2));
      expect(result.trucksLoading, equals(0));
      expect(
        result.trucksOnRoute,
        equals(2),
        reason: 'TRANSIT + FRONTIERE = en route',
      );
      expect(result.trucksArrived, equals(0));
      expect(result.volumeOnRoute, equals(35000.0));
    });

    test('ARRIVE uniquement → tous arrivés', () {
      // Arrange
      final coursDeRouteData = [
        {'id': '1', 'volume': 25000, 'statut': 'ARRIVE'},
        {'id': '2', 'volume': 30000, 'statut': 'ARRIVE'},
      ];

      // Act
      final result = calculateKpi(coursDeRouteData);

      // Assert
      expect(result.totalTrucks, equals(2));
      expect(result.trucksLoading, equals(0));
      expect(result.trucksOnRoute, equals(0));
      expect(
        result.trucksArrived,
        equals(2),
        reason: 'ARRIVE = arrivés (pas encore déchargés)',
      );
      expect(result.volumeArrived, equals(55000.0));
    });

    test('DECHARGE uniquement → tous exclus', () {
      // Arrange
      final coursDeRouteData = [
        {'id': '1', 'volume': 10000, 'statut': 'DECHARGE'},
        {'id': '2', 'volume': 20000, 'statut': 'DECHARGE'},
      ];

      // Act
      final result = calculateKpi(coursDeRouteData);

      // Assert: Aucun camion compté (tous déchargés)
      expect(result.totalTrucks, equals(0));
      expect(result.trucksLoading, equals(0));
      expect(result.trucksOnRoute, equals(0));
      expect(result.trucksArrived, equals(0));
      expect(result.totalPlannedVolume, equals(0.0));
    });

    test('Liste vide → valeurs à zéro', () {
      // Arrange
      final coursDeRouteData = <Map<String, dynamic>>[];

      // Act
      final result = calculateKpi(coursDeRouteData);

      // Assert
      expect(result.totalTrucks, equals(0));
      expect(result.totalPlannedVolume, equals(0.0));
      expect(result.trucksLoading, equals(0));
      expect(result.trucksOnRoute, equals(0));
      expect(result.trucksArrived, equals(0));
    });

    test('Volume null → traité comme 0', () {
      // Arrange
      final coursDeRouteData = [
        {'id': '1', 'volume': null, 'statut': 'TRANSIT'},
        {'id': '2', 'volume': 20000, 'statut': 'FRONTIERE'},
      ];

      // Act
      final result = calculateKpi(coursDeRouteData);

      // Assert
      expect(result.totalTrucks, equals(2));
      expect(result.trucksOnRoute, equals(2));
      expect(
        result.volumeOnRoute,
        equals(20000.0),
        reason: 'Volume null traité comme 0',
      );
    });

    test('Statuts en minuscules → normalisés', () {
      // Arrange
      final coursDeRouteData = [
        {'id': '1', 'volume': 10000, 'statut': 'chargement'},
        {'id': '2', 'volume': 15000, 'statut': 'transit'},
        {'id': '3', 'volume': 20000, 'statut': 'arrive'},
        {'id': '4', 'volume': 25000, 'statut': 'decharge'},
      ];

      // Act
      final result = calculateKpi(coursDeRouteData);

      // Assert
      expect(
        result.totalTrucks,
        equals(3),
        reason: 'Statuts convertis en majuscules, DECHARGE exclu',
      );
      expect(result.trucksLoading, equals(1));
      expect(result.trucksOnRoute, equals(1));
      expect(result.trucksArrived, equals(1));
    });

    test('Statuts avec espaces → trimés', () {
      // Arrange
      final coursDeRouteData = [
        {'id': '1', 'volume': 15000, 'statut': ' TRANSIT '},
        {'id': '2', 'volume': 20000, 'statut': '  ARRIVE  '},
      ];

      // Act
      final result = calculateKpi(coursDeRouteData);

      // Assert
      expect(result.totalTrucks, equals(2), reason: 'Les espaces sont trimés');
      expect(result.trucksOnRoute, equals(1));
      expect(result.trucksArrived, equals(1));
    });
  });

  group('KpiTrucksToFollow Model Tests', () {
    test('KpiTrucksToFollow.zero retourne des valeurs à zéro', () {
      const zero = KpiTrucksToFollow.zero;

      expect(zero.totalTrucks, equals(0));
      expect(zero.totalPlannedVolume, equals(0.0));
      expect(zero.trucksLoading, equals(0));
      expect(zero.trucksOnRoute, equals(0));
      expect(zero.trucksArrived, equals(0));
      expect(zero.volumeLoading, equals(0.0));
      expect(zero.volumeOnRoute, equals(0.0));
      expect(zero.volumeArrived, equals(0.0));
    });

    test('KpiTrucksToFollow.fromNullable gère les valeurs null', () {
      final result = KpiTrucksToFollow.fromNullable(
        totalTrucks: null,
        totalPlannedVolume: null,
        trucksLoading: null,
        trucksOnRoute: null,
        trucksArrived: null,
        volumeLoading: null,
        volumeOnRoute: null,
        volumeArrived: null,
      );

      expect(result.totalTrucks, equals(0));
      expect(result.totalPlannedVolume, equals(0.0));
      expect(result.trucksLoading, equals(0));
      expect(result.trucksOnRoute, equals(0));
      expect(result.trucksArrived, equals(0));
    });

    test('KpiTrucksToFollow.fromNullable convertit les num en double', () {
      final result = KpiTrucksToFollow.fromNullable(
        totalTrucks: 6,
        totalPlannedVolume: 150000, // int
        trucksLoading: 2,
        trucksOnRoute: 2,
        trucksArrived: 2,
        volumeLoading: 50000.5,
        volumeOnRoute: 60000.5,
        volumeArrived: 39999.0,
      );

      expect(result.totalTrucks, equals(6));
      expect(result.totalPlannedVolume, equals(150000.0));
      expect(result.trucksLoading, equals(2));
      expect(result.trucksOnRoute, equals(2));
      expect(result.trucksArrived, equals(2));
      expect(result.volumeLoading, equals(50000.5));
      expect(result.volumeOnRoute, equals(60000.5));
      expect(result.volumeArrived, equals(39999.0));
    });
  });
}
