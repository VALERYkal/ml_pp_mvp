// 📌 Module : Cours de Route - Tests Provider KPI CDR
// 🧑 Auteur : Mona (IA Flutter/Supabase/Riverpod)
// 📅 Date : 2025-11-27
// 🧭 Description : Tests unitaires pour les KPI Cours de Route
//
// RÈGLE MÉTIER CDR (Cours de Route) :
// - "Au chargement" = CHARGEMENT uniquement
// - "En route" = TRANSIT + FRONTIERE
// - "Arrivés" = ARRIVE
// - DECHARGE = EXCLU (déjà pris en charge dans Réceptions/Stocks)
// - totalActifs = CHARGEMENT + TRANSIT + FRONTIERE + ARRIVE

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cdr_kpi_provider.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';

/// Fake service minimal pour les tests KPI CDR
/// Permet de simuler différents scénarios sans dépendre de Supabase
class FakeCoursDeRouteService implements CoursDeRouteService {
  final Map<String, int> _countByStatutData;
  final Map<String, int> _countByCategorieData;

  FakeCoursDeRouteService({
    Map<String, int>? countByStatutData,
    Map<String, int>? countByCategorieData,
  }) : _countByStatutData =
           countByStatutData ??
           {
             'CHARGEMENT': 0,
             'TRANSIT': 0,
             'FRONTIERE': 0,
             'ARRIVE': 0,
             'DECHARGE': 0,
           },
       _countByCategorieData =
           countByCategorieData ??
           {'en_route': 0, 'en_attente': 0, 'termines': 0};

  @override
  Future<Map<String, int>> countByStatut() async {
    return _countByStatutData;
  }

  @override
  Future<Map<String, int>> countByCategorie() async {
    return _countByCategorieData;
  }

  // Méthodes non utilisées dans les tests KPI - implémentation minimale
  @override
  Future<List<CoursDeRoute>> getAll() async => throw UnimplementedError();

  @override
  Future<List<CoursDeRoute>> getActifs() async => throw UnimplementedError();

  @override
  Future<CoursDeRoute?> getById(String id) async => throw UnimplementedError();

  @override
  Future<void> create(CoursDeRoute cours) async => throw UnimplementedError();

  @override
  Future<void> update(CoursDeRoute cours) async => throw UnimplementedError();

  @override
  Future<void> delete(String id) async => throw UnimplementedError();

  @override
  Future<void> updateStatut({
    required String id,
    required StatutCours to,
    bool fromReception = false,
  }) async => throw UnimplementedError();

  @override
  Future<List<CoursDeRoute>> getByStatut(StatutCours statut) async =>
      throw UnimplementedError();

  @override
  Future<bool> canTransition({
    required dynamic from,
    required dynamic to,
  }) async => throw UnimplementedError();

  @override
  Future<bool> applyTransition({
    required String cdrId,
    required dynamic from,
    required dynamic to,
    String? userId,
  }) async => throw UnimplementedError();
}

/// Structure de résultat KPI CDR (pour les tests de logique pure)
class CdrKpiResult {
  final int cdrCountChargement;
  final int cdrCountEnRoute;
  final int cdrCountArrive;
  final int cdrCountTotalActifs;
  final double totalPendingVolume;
  final double totalEnRouteVolume;
  final double totalArriveVolume;

  const CdrKpiResult({
    required this.cdrCountChargement,
    required this.cdrCountEnRoute,
    required this.cdrCountArrive,
    required this.cdrCountTotalActifs,
    required this.totalPendingVolume,
    required this.totalEnRouteVolume,
    required this.totalArriveVolume,
  });
}

/// Calcule les KPI CDR à partir de données mockées
/// RÈGLE MÉTIER :
/// - Au chargement = CHARGEMENT
/// - En route = TRANSIT + FRONTIERE
/// - Arrivés = ARRIVE
/// - DECHARGE = EXCLU
CdrKpiResult calculateCdrKpi(List<Map<String, dynamic>> coursDeRouteData) {
  const statutsActifs = ['CHARGEMENT', 'TRANSIT', 'FRONTIERE', 'ARRIVE'];

  int chargementCount = 0;
  int enRouteCount = 0;
  int arriveCount = 0;
  double volumeChargement = 0.0;
  double volumeEnRoute = 0.0;
  double volumeArrive = 0.0;

  for (final row in coursDeRouteData) {
    final rawStatut = (row['statut'] as String?)?.trim();
    if (rawStatut == null) continue;

    final statut = rawStatut.toUpperCase();
    if (!statutsActifs.contains(statut)) continue; // Exclut DECHARGE

    final volume = (row['volume'] as num?)?.toDouble() ?? 0.0;

    if (statut == 'CHARGEMENT') {
      chargementCount++;
      volumeChargement += volume;
    } else if (statut == 'TRANSIT' || statut == 'FRONTIERE') {
      enRouteCount++;
      volumeEnRoute += volume;
    } else if (statut == 'ARRIVE') {
      arriveCount++;
      volumeArrive += volume;
    }
  }

  return CdrKpiResult(
    cdrCountChargement: chargementCount,
    cdrCountEnRoute: enRouteCount,
    cdrCountArrive: arriveCount,
    cdrCountTotalActifs: chargementCount + enRouteCount + arriveCount,
    totalPendingVolume: volumeChargement,
    totalEnRouteVolume: volumeEnRoute,
    totalArriveVolume: volumeArrive,
  );
}

void main() {
  // ════════════════════════════════════════════════════════════════════════════
  // TESTS LOGIQUE MÉTIER PURE (sans provider)
  // ════════════════════════════════════════════════════════════════════════════

  group('CDR KPI - Logique Métier Pure', () {
    group('Test 1: Aucun CDR en base', () {
      test('tous les compteurs = 0', () {
        // Arrange
        final coursDeRouteData = <Map<String, dynamic>>[];

        // Act
        final result = calculateCdrKpi(coursDeRouteData);

        // Assert
        expect(result.cdrCountChargement, equals(0));
        expect(result.cdrCountEnRoute, equals(0));
        expect(result.cdrCountArrive, equals(0));
        expect(result.cdrCountTotalActifs, equals(0));
        expect(result.totalPendingVolume, equals(0.0));
        expect(result.totalEnRouteVolume, equals(0.0));
        expect(result.totalArriveVolume, equals(0.0));
      });
    });

    group('Test 2: Seulement des CHARGEMENT', () {
      test('2 x CHARGEMENT → cdrCountChargement = 2', () {
        // Arrange
        final coursDeRouteData = [
          {'id': '1', 'statut': 'CHARGEMENT', 'volume': 10000},
          {'id': '2', 'statut': 'CHARGEMENT', 'volume': 12000},
        ];

        // Act
        final result = calculateCdrKpi(coursDeRouteData);

        // Assert
        expect(
          result.cdrCountChargement,
          equals(2),
          reason: 'Au chargement = 2',
        );
        expect(result.cdrCountEnRoute, equals(0), reason: 'En route = 0');
        expect(result.cdrCountArrive, equals(0), reason: 'Arrivés = 0');
        expect(
          result.cdrCountTotalActifs,
          equals(2),
          reason: 'Total actifs = 2',
        );
        expect(
          result.totalPendingVolume,
          equals(22000.0),
          reason: 'Volume au chargement = 10000 + 12000',
        );
      });
    });

    group('Test 3: Seulement des EN ROUTE', () {
      test('1 x TRANSIT + 1 x FRONTIERE → cdrCountEnRoute = 2', () {
        // Arrange
        final coursDeRouteData = [
          {'id': '1', 'statut': 'TRANSIT', 'volume': 15000},
          {'id': '2', 'statut': 'FRONTIERE', 'volume': 18000},
        ];

        // Act
        final result = calculateCdrKpi(coursDeRouteData);

        // Assert
        expect(result.cdrCountChargement, equals(0));
        expect(
          result.cdrCountEnRoute,
          equals(2),
          reason: 'En route = TRANSIT + FRONTIERE',
        );
        expect(result.cdrCountArrive, equals(0));
        expect(result.cdrCountTotalActifs, equals(2));
        expect(
          result.totalEnRouteVolume,
          equals(33000.0),
          reason: 'Volume en route = 15000 + 18000',
        );
      });
    });

    group('Test 4: Seulement des ARRIVE', () {
      test('3 x ARRIVE → cdrCountArrive = 3', () {
        // Arrange
        final coursDeRouteData = [
          {'id': '1', 'statut': 'ARRIVE', 'volume': 20000},
          {'id': '2', 'statut': 'ARRIVE', 'volume': 25000},
          {'id': '3', 'statut': 'ARRIVE', 'volume': 30000},
        ];

        // Act
        final result = calculateCdrKpi(coursDeRouteData);

        // Assert
        expect(result.cdrCountChargement, equals(0));
        expect(result.cdrCountEnRoute, equals(0));
        expect(result.cdrCountArrive, equals(3), reason: 'Arrivés = 3');
        expect(
          result.cdrCountTotalActifs,
          equals(3),
          reason: 'Total actifs = 3',
        );
        expect(
          result.totalArriveVolume,
          equals(75000.0),
          reason: 'Volume arrivés = 20000 + 25000 + 30000',
        );
      });
    });

    group('Test 5: Combinaison complète avec DECHARGE exclu', () {
      test(
        '1 CHARGEMENT + 2 EN ROUTE + 1 ARRIVE + 1 DECHARGE → totalActifs = 4',
        () {
          // Arrange: Scénario de référence
          final coursDeRouteData = [
            {'id': '1', 'statut': 'CHARGEMENT', 'volume': 10000}, // Compté
            {'id': '2', 'statut': 'TRANSIT', 'volume': 15000}, // Compté
            {'id': '3', 'statut': 'FRONTIERE', 'volume': 18000}, // Compté
            {'id': '4', 'statut': 'ARRIVE', 'volume': 20000}, // Compté
            {'id': '5', 'statut': 'DECHARGE', 'volume': 25000}, // EXCLU
          ];

          // Act
          final result = calculateCdrKpi(coursDeRouteData);

          // Assert
          expect(
            result.cdrCountChargement,
            equals(1),
            reason: 'Au chargement = 1',
          );
          expect(
            result.cdrCountEnRoute,
            equals(2),
            reason: 'En route = 2 (TRANSIT + FRONTIERE)',
          );
          expect(result.cdrCountArrive, equals(1), reason: 'Arrivés = 1');
          expect(
            result.cdrCountTotalActifs,
            equals(4),
            reason: 'Total actifs = 4 (DECHARGE exclu)',
          );

          // Volumes
          expect(result.totalPendingVolume, equals(10000.0));
          expect(result.totalEnRouteVolume, equals(33000.0));
          expect(result.totalArriveVolume, equals(20000.0));

          // DECHARGE ne doit pas apparaître dans les totaux
          final totalVolume =
              result.totalPendingVolume +
              result.totalEnRouteVolume +
              result.totalArriveVolume;
          expect(
            totalVolume,
            equals(63000.0),
            reason: 'Volume DECHARGE (25000) non inclus',
          );
        },
      );

      test('DECHARGE uniquement → tous les compteurs = 0', () {
        // Arrange
        final coursDeRouteData = [
          {'id': '1', 'statut': 'DECHARGE', 'volume': 10000},
          {'id': '2', 'statut': 'DECHARGE', 'volume': 15000},
          {'id': '3', 'statut': 'DECHARGE', 'volume': 20000},
        ];

        // Act
        final result = calculateCdrKpi(coursDeRouteData);

        // Assert: DECHARGE n'apparaît nulle part
        expect(result.cdrCountChargement, equals(0));
        expect(result.cdrCountEnRoute, equals(0));
        expect(result.cdrCountArrive, equals(0));
        expect(
          result.cdrCountTotalActifs,
          equals(0),
          reason: 'Tous DECHARGE = 0 actifs',
        );
        expect(result.totalPendingVolume, equals(0.0));
        expect(result.totalEnRouteVolume, equals(0.0));
        expect(result.totalArriveVolume, equals(0.0));
      });
    });

    group('Test 6: Volumes agrégés', () {
      test('Volumes correctement agrégés par catégorie', () {
        // Arrange
        final coursDeRouteData = [
          {'id': '1', 'statut': 'CHARGEMENT', 'volume': 10000},
          {'id': '2', 'statut': 'CHARGEMENT', 'volume': 12000},
          {'id': '3', 'statut': 'TRANSIT', 'volume': 15000},
        ];

        // Act
        final result = calculateCdrKpi(coursDeRouteData);

        // Assert
        expect(
          result.totalPendingVolume,
          equals(22000.0),
          reason: 'Volume CHARGEMENT = 10000 + 12000',
        );
        expect(
          result.totalEnRouteVolume,
          equals(15000.0),
          reason: 'Volume EN ROUTE = 15000',
        );
        expect(
          result.totalArriveVolume,
          equals(0.0),
          reason: 'Volume ARRIVE = 0',
        );
      });

      test('Volume null traité comme 0', () {
        // Arrange
        final coursDeRouteData = [
          {'id': '1', 'statut': 'CHARGEMENT', 'volume': null},
          {'id': '2', 'statut': 'TRANSIT', 'volume': 15000},
        ];

        // Act
        final result = calculateCdrKpi(coursDeRouteData);

        // Assert
        expect(result.cdrCountChargement, equals(1));
        expect(result.cdrCountEnRoute, equals(1));
        expect(
          result.totalPendingVolume,
          equals(0.0),
          reason: 'Volume null = 0',
        );
        expect(result.totalEnRouteVolume, equals(15000.0));
      });
    });

    group('Cas limites', () {
      test('Statuts en minuscules → normalisés', () {
        // Arrange
        final coursDeRouteData = [
          {'id': '1', 'statut': 'chargement', 'volume': 10000},
          {'id': '2', 'statut': 'transit', 'volume': 15000},
          {'id': '3', 'statut': 'arrive', 'volume': 20000},
          {'id': '4', 'statut': 'decharge', 'volume': 25000}, // EXCLU
        ];

        // Act
        final result = calculateCdrKpi(coursDeRouteData);

        // Assert
        expect(
          result.cdrCountTotalActifs,
          equals(3),
          reason: 'Statuts convertis en majuscules',
        );
        expect(result.cdrCountChargement, equals(1));
        expect(result.cdrCountEnRoute, equals(1));
        expect(result.cdrCountArrive, equals(1));
      });

      test('Statuts avec espaces → trimés', () {
        // Arrange
        final coursDeRouteData = [
          {'id': '1', 'statut': ' TRANSIT ', 'volume': 15000},
          {'id': '2', 'statut': '  ARRIVE  ', 'volume': 20000},
        ];

        // Act
        final result = calculateCdrKpi(coursDeRouteData);

        // Assert
        expect(
          result.cdrCountTotalActifs,
          equals(2),
          reason: 'Les espaces sont trimés',
        );
        expect(result.cdrCountEnRoute, equals(1));
        expect(result.cdrCountArrive, equals(1));
      });

      test('Statut null → ignoré', () {
        // Arrange
        final coursDeRouteData = [
          {'id': '1', 'statut': null, 'volume': 10000},
          {'id': '2', 'statut': 'TRANSIT', 'volume': 15000},
        ];

        // Act
        final result = calculateCdrKpi(coursDeRouteData);

        // Assert
        expect(
          result.cdrCountTotalActifs,
          equals(1),
          reason: 'Statut null ignoré',
        );
        expect(result.cdrCountEnRoute, equals(1));
      });

      test('Statut inconnu → ignoré', () {
        // Arrange
        final coursDeRouteData = [
          {'id': '1', 'statut': 'INCONNU', 'volume': 10000},
          {'id': '2', 'statut': 'TRANSIT', 'volume': 15000},
        ];

        // Act
        final result = calculateCdrKpi(coursDeRouteData);

        // Assert
        expect(
          result.cdrCountTotalActifs,
          equals(1),
          reason: 'Statut inconnu ignoré',
        );
      });
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // TESTS PROVIDER (avec FakeService)
  // ════════════════════════════════════════════════════════════════════════════

  group('CDR KPI Provider Tests', () {
    late ProviderContainer container;
    late FakeCoursDeRouteService fakeService;

    setUp(() {
      fakeService = FakeCoursDeRouteService();
      container = ProviderContainer(
        overrides: [coursDeRouteServiceProvider.overrideWithValue(fakeService)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('cdrKpiCountsByStatutProvider', () {
      test('retourne les compteurs par statut', () async {
        // Arrange
        final service = FakeCoursDeRouteService(
          countByStatutData: {
            'CHARGEMENT': 2,
            'TRANSIT': 1,
            'FRONTIERE': 1,
            'ARRIVE': 1,
            'DECHARGE': 3,
          },
        );

        final testContainer = ProviderContainer(
          overrides: [coursDeRouteServiceProvider.overrideWithValue(service)],
        );

        // Act
        final result = await testContainer.read(
          cdrKpiCountsByStatutProvider.future,
        );

        // Assert
        expect(result['CHARGEMENT'], equals(2));
        expect(result['TRANSIT'], equals(1));
        expect(result['FRONTIERE'], equals(1));
        expect(result['ARRIVE'], equals(1));
        expect(result['DECHARGE'], equals(3));

        testContainer.dispose();
      });

      test('base vide → tous les compteurs à 0', () async {
        // Arrange
        final emptyService = FakeCoursDeRouteService(
          countByStatutData: {
            'CHARGEMENT': 0,
            'TRANSIT': 0,
            'FRONTIERE': 0,
            'ARRIVE': 0,
            'DECHARGE': 0,
          },
        );

        final testContainer = ProviderContainer(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(emptyService),
          ],
        );

        // Act
        final result = await testContainer.read(
          cdrKpiCountsByStatutProvider.future,
        );

        // Assert
        expect(result['CHARGEMENT'], equals(0));
        expect(result['TRANSIT'], equals(0));
        expect(result['FRONTIERE'], equals(0));
        expect(result['ARRIVE'], equals(0));
        expect(result['DECHARGE'], equals(0));

        testContainer.dispose();
      });
    });

    group('cdrKpiCountsByCategorieProvider', () {
      test('retourne les compteurs par catégorie métier', () async {
        // Arrange
        final service = FakeCoursDeRouteService(
          countByCategorieData: {
            'en_route': 4, // CHARGEMENT + TRANSIT + FRONTIERE
            'en_attente': 1, // ARRIVE
            'termines': 3, // DECHARGE
          },
        );

        final testContainer = ProviderContainer(
          overrides: [coursDeRouteServiceProvider.overrideWithValue(service)],
        );

        // Act
        final result = await testContainer.read(
          cdrKpiCountsByCategorieProvider.future,
        );

        // Assert
        expect(result['en_route'], equals(4));
        expect(result['en_attente'], equals(1));
        expect(result['termines'], equals(3));

        testContainer.dispose();
      });
    });

    group('Provider Integration', () {
      test('les deux providers peuvent être utilisés simultanément', () async {
        // Arrange
        final service = FakeCoursDeRouteService(
          countByStatutData: {
            'CHARGEMENT': 2,
            'TRANSIT': 1,
            'FRONTIERE': 1,
            'ARRIVE': 1,
            'DECHARGE': 3,
          },
          countByCategorieData: {'en_route': 4, 'en_attente': 1, 'termines': 3},
        );

        final testContainer = ProviderContainer(
          overrides: [coursDeRouteServiceProvider.overrideWithValue(service)],
        );

        // Act
        final byStatut = await testContainer.read(
          cdrKpiCountsByStatutProvider.future,
        );
        final byCategorie = await testContainer.read(
          cdrKpiCountsByCategorieProvider.future,
        );

        // Assert
        expect(byStatut, isNotEmpty);
        expect(byCategorie, isNotEmpty);

        // Vérifier la cohérence
        final totalActifsByStatut =
            (byStatut['CHARGEMENT'] ?? 0) +
            (byStatut['TRANSIT'] ?? 0) +
            (byStatut['FRONTIERE'] ?? 0) +
            (byStatut['ARRIVE'] ?? 0);

        final totalActifsByCategorie =
            (byCategorie['en_route'] ?? 0) + (byCategorie['en_attente'] ?? 0);

        expect(totalActifsByStatut, equals(5));
        expect(totalActifsByCategorie, equals(5));

        testContainer.dispose();
      });

      test('invalidation du provider force un nouveau fetch', () async {
        // Act
        final result1 = await container.read(
          cdrKpiCountsByStatutProvider.future,
        );

        container.invalidate(cdrKpiCountsByStatutProvider);

        final result2 = await container.read(
          cdrKpiCountsByStatutProvider.future,
        );

        // Assert: Les résultats doivent être identiques (même fake service)
        expect(result1, equals(result2));
      });
    });
  });

  // ════════════════════════════════════════════════════════════════════════════
  // TESTS KpiTrucksToFollow MODEL
  // ════════════════════════════════════════════════════════════════════════════

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
        totalTrucks: 5,
        totalPlannedVolume: 63000, // int
        trucksLoading: 1,
        trucksOnRoute: 2,
        trucksArrived: 2,
        volumeLoading: 10000.5,
        volumeOnRoute: 33000.0,
        volumeArrived: 19999.5,
      );

      expect(result.totalTrucks, equals(5));
      expect(result.totalPlannedVolume, equals(63000.0));
      expect(result.trucksLoading, equals(1));
      expect(result.trucksOnRoute, equals(2));
      expect(result.trucksArrived, equals(2));
      expect(result.volumeLoading, equals(10000.5));
      expect(result.volumeOnRoute, equals(33000.0));
      expect(result.volumeArrived, equals(19999.5));
    });

    test('Correspondance avec la logique métier', () {
      // RÈGLE MÉTIER:
      // - trucksLoading = CHARGEMENT
      // - trucksOnRoute = TRANSIT + FRONTIERE
      // - trucksArrived = ARRIVE
      // - DECHARGE = EXCLU

      final kpi = KpiTrucksToFollow(
        totalTrucks: 4, // 1 CHARGEMENT + 2 EN ROUTE + 1 ARRIVE
        totalPlannedVolume: 63000.0,
        trucksLoading: 1, // CHARGEMENT
        trucksOnRoute: 2, // TRANSIT + FRONTIERE
        trucksArrived: 1, // ARRIVE
        volumeLoading: 10000.0,
        volumeOnRoute: 33000.0,
        volumeArrived: 20000.0,
      );

      // Vérifier la cohérence
      expect(
        kpi.totalTrucks,
        equals(kpi.trucksLoading + kpi.trucksOnRoute + kpi.trucksArrived),
      );
      expect(
        kpi.totalPlannedVolume,
        equals(kpi.volumeLoading + kpi.volumeOnRoute + kpi.volumeArrived),
      );
    });
  });
}
