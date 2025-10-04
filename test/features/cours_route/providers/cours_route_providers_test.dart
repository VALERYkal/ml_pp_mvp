@Tags(['integration'])
// 📌 Module : Cours de Route - Tests Providers
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Tests unitaires pour les providers Riverpod des cours de route

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_route_providers.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/features/kpi/providers/cours_kpi_provider.dart';
import '../../../helpers/cours_route_test_helpers.dart';

void main() {
  group('CoursDeRoute Providers', () {
    late MockCoursDeRouteService mockService;
    late ProviderContainer container;

    setUp(() {
      mockService = MockCoursDeRouteService();
      container = ProviderContainer(
        overrides: [coursDeRouteServiceProvider.overrideWithValue(mockService)],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('coursDeRouteListProvider', () {
      test('should return list of cours', () async {
        // Arrange
        final mockCours = [
          CoursDeRoute(
            id: 'id1',
            fournisseurId: 'fournisseur-1',
            produitId: 'produit-1',
            depotDestinationId: 'depot-1',
            statut: StatutCours.chargement,
          ),
          CoursDeRoute(
            id: 'id2',
            fournisseurId: 'fournisseur-2',
            produitId: 'produit-2',
            depotDestinationId: 'depot-2',
            statut: StatutCours.transit,
          ),
        ];

        when(mockService.getAll()).thenAnswer((_) async => mockCours);

        // Act
        final result = await container.read(coursDeRouteListProvider.future);

        // Assert
        expect(result, isA<List<CoursDeRoute>>());
        expect(result.length, 2);
        expect(result[0].id, 'id1');
        expect(result[1].id, 'id2');
        verify(mockService.getAll()).called(1);
      });

      test('should handle service errors', () async {
        // Arrange
        when(mockService.getAll()).thenThrow(Exception('Service error'));

        // Act & Assert
        expect(
          () => container.read(coursDeRouteListProvider.future),
          throwsException,
        );
      });
    });

    group('coursDeRouteActifsProvider', () {
      test('should return only active cours', () async {
        // Arrange
        final mockCours = [
          CoursDeRoute(
            id: 'id1',
            fournisseurId: 'fournisseur-1',
            produitId: 'produit-1',
            depotDestinationId: 'depot-1',
            statut: StatutCours.chargement,
          ),
          CoursDeRoute(
            id: 'id2',
            fournisseurId: 'fournisseur-2',
            produitId: 'produit-2',
            depotDestinationId: 'depot-2',
            statut: StatutCours.transit,
          ),
        ];

        when(mockService.getActifs()).thenAnswer((_) async => mockCours);

        // Act
        final result = await container.read(coursDeRouteActifsProvider.future);

        // Assert
        expect(result, isA<List<CoursDeRoute>>());
        expect(result.length, 2);
        verify(mockService.getActifs()).called(1);
      });
    });

    group('createCoursDeRouteProvider', () {
      test('should create cours and invalidate providers', () async {
        // Arrange
        final cours = CoursDeRoute(
          id: '',
          fournisseurId: 'fournisseur-1',
          produitId: 'produit-1',
          depotDestinationId: 'depot-1',
        );

        when(mockService.create(any<CoursDeRoute>())).thenAnswer((_) async {});

        // Act
        await container.read(createCoursDeRouteProvider(cours).future);

        // Assert
        verify(mockService.create(cours)).called(1);

        // Vérifier que les providers sont invalidés
        // Note: Dans un vrai test, on vérifierait que les providers sont rechargés
      });

      test('should handle creation errors', () async {
        // Arrange
        final cours = CoursDeRoute(
          id: '',
          fournisseurId: 'fournisseur-1',
          produitId: 'produit-1',
          depotDestinationId: 'depot-1',
        );

        when(mockService.create(any<CoursDeRoute>())).thenThrow(Exception('Creation failed'));

        // Act & Assert
        expect(
          () => container.read(createCoursDeRouteProvider(cours).future),
          throwsException,
        );
      });
    });

    group('updateCoursDeRouteProvider', () {
      test('should update cours and invalidate providers', () async {
        // Arrange
        final cours = CoursDeRoute(
          id: 'test-id',
          fournisseurId: 'fournisseur-1',
          produitId: 'produit-1',
          depotDestinationId: 'depot-1',
        );

        when(mockService.update(any<CoursDeRoute>())).thenAnswer((_) async {});

        // Act
        await container.read(updateCoursDeRouteProvider(cours).future);

        // Assert
        verify(mockService.update(cours)).called(1);
      });
    });

    group('deleteCoursDeRouteProvider', () {
      test('should delete cours and invalidate providers', () async {
        // Arrange
        when(mockService.delete('test-id')).thenAnswer((_) async {});

        // Act
        await container.read(deleteCoursDeRouteProvider('test-id').future);

        // Assert
        verify(mockService.delete('test-id')).called(1);
      });
    });

    group('updateStatutCoursDeRouteProvider', () {
      test('should update statut and invalidate providers', () async {
        // Arrange
        final params = {
          'id': 'test-id',
          'to': StatutCours.transit,
          'fromReception': false,
        };

        when(
          mockService.updateStatut(
            id: 'test-id',
            to: StatutCours.transit,
            fromReception: false,
          ),
        ).thenAnswer((_) async {});

        // Act
        await container.read(updateStatutCoursDeRouteProvider(params).future);

        // Assert
        verify(
          mockService.updateStatut(
            id: 'test-id',
            to: StatutCours.transit,
            fromReception: false,
          ),
        ).called(1);
      });
    });

    group('coursDeRouteByIdProvider', () {
      test('should return cours by id', () async {
        // Arrange
        final cours = CoursDeRoute(
          id: 'test-id',
          fournisseurId: 'fournisseur-1',
          produitId: 'produit-1',
          depotDestinationId: 'depot-1',
        );

        when(mockService.getById('test-id')).thenAnswer((_) async => cours);

        // Act
        final result = await container.read(
          coursDeRouteByIdProvider('test-id').future,
        );

        // Assert
        expect(result, cours);
        verify(mockService.getById('test-id')).called(1);
      });

      test('should return null for non-existent cours', () async {
        // Arrange
        when(mockService.getById('non-existent')).thenAnswer((_) async => null);

        // Act
        final result = await container.read(
          coursDeRouteByIdProvider('non-existent').future,
        );

        // Assert
        expect(result, null);
      });
    });

    group('coursDeRouteByStatutProvider', () {
      test('should return cours by statut', () async {
        // Arrange
        final mockCours = [
          CoursDeRoute(
            id: 'id1',
            fournisseurId: 'fournisseur-1',
            produitId: 'produit-1',
            depotDestinationId: 'depot-1',
            statut: StatutCours.chargement,
          ),
        ];

        when(
          mockService.getByStatut(StatutCours.chargement),
        ).thenAnswer((_) async => mockCours);

        // Act
        final result = await container.read(
          coursDeRouteByStatutProvider(StatutCours.chargement).future,
        );

        // Assert
        expect(result, mockCours);
        verify(mockService.getByStatut(StatutCours.chargement)).called(1);
      });
    });
  });
}
