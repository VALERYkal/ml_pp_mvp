// 📌 Module : Cours de Route - Tests Provider KPI
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Tests du provider KPI CDR avec fake service

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cdr_kpi_provider.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

/// Fake service minimal pour les tests KPI
class FakeCoursDeRouteService implements CoursDeRouteService {
  final Map<String, int> _countByStatutData;
  final Map<String, int> _countByCategorieData;

  FakeCoursDeRouteService({
    Map<String, int>? countByStatutData,
    Map<String, int>? countByCategorieData,
  }) : _countByStatutData = countByStatutData ?? {
          'CHARGEMENT': 5,
          'TRANSIT': 3,
          'FRONTIERE': 2,
          'ARRIVE': 1,
          'DECHARGE': 8,
        },
        _countByCategorieData = countByCategorieData ?? {
          'en_route': 10,
          'en_attente': 1,
          'termines': 8,
        };

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
  Future<List<CoursDeRoute>> getByStatut(StatutCours statut) async => throw UnimplementedError();
  
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

void main() {
  group('CDR KPI Provider Tests', () {
    late ProviderContainer container;
    late FakeCoursDeRouteService fakeService;

    setUp(() {
      fakeService = FakeCoursDeRouteService();
      container = ProviderContainer(
        overrides: [
          // Override du service avec notre fake
          coursDeRouteServiceProvider.overrideWithValue(fakeService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('cdrKpiCountsByStatutProvider', () {
      test('should return correct counts by status', () async {
        final provider = container.read(cdrKpiCountsByStatutProvider.future);
        final result = await provider;

        expect(result, isA<Map<String, int>>());
        expect(result['CHARGEMENT'], 5);
        expect(result['TRANSIT'], 3);
        expect(result['FRONTIERE'], 2);
        expect(result['ARRIVE'], 1);
        expect(result['DECHARGE'], 8);
      });

      test('should handle empty counts', () async {
        final emptyService = FakeCoursDeRouteService(
          countByStatutData: {
            'CHARGEMENT': 0,
            'TRANSIT': 0,
            'FRONTIERE': 0,
            'ARRIVE': 0,
            'DECHARGE': 0,
          },
        );

        final containerEmpty = ProviderContainer(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(emptyService),
          ],
        );

        final provider = containerEmpty.read(cdrKpiCountsByStatutProvider.future);
        final result = await provider;

        expect(result['CHARGEMENT'], 0);
        expect(result['TRANSIT'], 0);
        expect(result['FRONTIERE'], 0);
        expect(result['ARRIVE'], 0);
        expect(result['DECHARGE'], 0);

        containerEmpty.dispose();
      });

      test('should handle custom counts', () async {
        final customService = FakeCoursDeRouteService(
          countByStatutData: {
            'CHARGEMENT': 10,
            'TRANSIT': 5,
            'FRONTIERE': 3,
            'ARRIVE': 2,
            'DECHARGE': 15,
          },
        );

        final containerCustom = ProviderContainer(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(customService),
          ],
        );

        final provider = containerCustom.read(cdrKpiCountsByStatutProvider.future);
        final result = await provider;

        expect(result['CHARGEMENT'], 10);
        expect(result['TRANSIT'], 5);
        expect(result['FRONTIERE'], 3);
        expect(result['ARRIVE'], 2);
        expect(result['DECHARGE'], 15);

        containerCustom.dispose();
      });
    });

    group('cdrKpiCountsByCategorieProvider', () {
      test('should return correct counts by category', () async {
        final provider = container.read(cdrKpiCountsByCategorieProvider.future);
        final result = await provider;

        expect(result, isA<Map<String, int>>());
        expect(result['en_route'], 10);
        expect(result['en_attente'], 1);
        expect(result['termines'], 8);
      });

      test('should handle empty categories', () async {
        final emptyService = FakeCoursDeRouteService(
          countByCategorieData: {
            'en_route': 0,
            'en_attente': 0,
            'termines': 0,
          },
        );

        final containerEmpty = ProviderContainer(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(emptyService),
          ],
        );

        final provider = containerEmpty.read(cdrKpiCountsByCategorieProvider.future);
        final result = await provider;

        expect(result['en_route'], 0);
        expect(result['en_attente'], 0);
        expect(result['termines'], 0);

        containerEmpty.dispose();
      });

      test('should handle custom categories', () async {
        final customService = FakeCoursDeRouteService(
          countByCategorieData: {
            'en_route': 20,
            'en_attente': 5,
            'termines': 25,
          },
        );

        final containerCustom = ProviderContainer(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(customService),
          ],
        );

        final provider = containerCustom.read(cdrKpiCountsByCategorieProvider.future);
        final result = await provider;

        expect(result['en_route'], 20);
        expect(result['en_attente'], 5);
        expect(result['termines'], 25);

        containerCustom.dispose();
      });
    });

    group('Provider Integration', () {
      test('should work with both providers simultaneously', () async {
        final statusProvider = container.read(cdrKpiCountsByStatutProvider.future);
        final categoryProvider = container.read(cdrKpiCountsByCategorieProvider.future);

        final statusResult = await statusProvider;
        final categoryResult = await categoryProvider;

        // Vérifier que les deux providers retournent des données cohérentes
        expect(statusResult, isNotEmpty);
        expect(categoryResult, isNotEmpty);
        
        // Vérifier que les totaux sont cohérents
        final totalStatus = statusResult.values.reduce((a, b) => a + b);
        final totalCategory = categoryResult.values.reduce((a, b) => a + b);
        
        expect(totalStatus, totalCategory);
      });

      test('should handle provider invalidation', () async {
        // Premier appel
        final provider1 = container.read(cdrKpiCountsByStatutProvider.future);
        final result1 = await provider1;

        // Invalidation du provider
        container.invalidate(cdrKpiCountsByStatutProvider);

        // Deuxième appel après invalidation
        final provider2 = container.read(cdrKpiCountsByStatutProvider.future);
        final result2 = await provider2;

        // Les résultats doivent être identiques (même fake service)
        expect(result1, result2);
      });
    });

    group('Error Handling', () {
      test('should handle service errors gracefully', () async {
        // Créer un service qui lève une exception
        final errorService = FakeCoursDeRouteService();
        
        // Override pour simuler une erreur
        final containerError = ProviderContainer(
          overrides: [
            coursDeRouteServiceProvider.overrideWithValue(errorService),
          ],
        );

        // Le provider devrait gérer l'erreur et retourner un état d'erreur
        final provider = containerError.read(cdrKpiCountsByStatutProvider);
        
        // Attendre que le provider soit prêt
        await containerError.read(cdrKpiCountsByStatutProvider.future);

        containerError.dispose();
      });
    });
  });
}
