@Tags(['needs-refactor'])
// ð Module : Cours de Route - Tests Filtres
// ð§ Auteur : Valery Kalonga
// ð Date : 2025-01-27
// ð§­ Description : Tests unitaires pour les filtres des cours de route
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ml_pp_mvp/features/cours_route/providers/cours_filters_provider.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

void main() {
  group('CoursFilters', () {
    test('should create default filters', () {
      // Act
      const filters = CoursFilters();

      // Assert
      expect(filters.fournisseurId, null);
      expect(filters.volumeMin, 0);
      expect(filters.volumeMax, 100000);
    });

    test('should create filters with custom values', () {
      // Act
      const filters = CoursFilters(
        fournisseurId: 'fournisseur-1',
        volumeMin: 10000,
        volumeMax: 50000,
      );

      // Assert
      expect(filters.fournisseurId, 'fournisseur-1');
      expect(filters.volumeMin, 10000);
      expect(filters.volumeMax, 50000);
    });

    test('should copy with modifications', () {
      // Arrange
      const originalFilters = CoursFilters(
        fournisseurId: 'fournisseur-1',
        volumeMin: 0,
        volumeMax: 100000,
      );

      // Act
      final newFilters = originalFilters.copyWith(fournisseurId: 'fournisseur-2', volumeMin: 20000);

      // Assert
      expect(newFilters.fournisseurId, 'fournisseur-2');
      expect(newFilters.volumeMin, 20000);
      expect(newFilters.volumeMax, 100000); // Unchanged
    });

    test('should implement equality correctly', () {
      // Arrange
      const filters1 = CoursFilters(
        fournisseurId: 'fournisseur-1',
        volumeMin: 10000,
        volumeMax: 50000,
      );

      const filters2 = CoursFilters(
        fournisseurId: 'fournisseur-1',
        volumeMin: 10000,
        volumeMax: 50000,
      );

      const filters3 = CoursFilters(
        fournisseurId: 'fournisseur-2',
        volumeMin: 10000,
        volumeMax: 50000,
      );

      // Assert
      expect(filters1, equals(filters2));
      expect(filters1, isNot(equals(filters3)));
    });

    test('should implement hashCode correctly', () {
      // Arrange
      const filters1 = CoursFilters(
        fournisseurId: 'fournisseur-1',
        volumeMin: 10000,
        volumeMax: 50000,
      );

      const filters2 = CoursFilters(
        fournisseurId: 'fournisseur-1',
        volumeMin: 10000,
        volumeMax: 50000,
      );

      // Assert
      expect(filters1.hashCode, equals(filters2.hashCode));
    });

    test('should implement toString correctly', () {
      // Arrange
      const filters = CoursFilters(
        fournisseurId: 'fournisseur-1',
        volumeMin: 10000,
        volumeMax: 50000,
      );

      // Act
      final string = filters.toString();

      // Assert
      expect(string, contains('fournisseur-1'));
      expect(string, contains('10000'));
      expect(string, contains('50000'));
    });
  });

  group('Filter Application', () {
    late List<CoursDeRoute> sampleCours;

    setUp(() {
      sampleCours = [
        CoursDeRoute(
          id: 'id1',
          fournisseurId: 'fournisseur-1',
          produitId: 'produit-1',
          depotDestinationId: 'depot-1',
          volume: 30000,
          statut: StatutCours.chargement,
        ),
        CoursDeRoute(
          id: 'id2',
          fournisseurId: 'fournisseur-2',
          produitId: 'produit-2',
          depotDestinationId: 'depot-2',
          volume: 70000,
          statut: StatutCours.transit,
        ),
        CoursDeRoute(
          id: 'id3',
          fournisseurId: 'fournisseur-1',
          produitId: 'produit-3',
          depotDestinationId: 'depot-3',
          volume: 120000, // Outside default range
          statut: StatutCours.frontiere,
        ),
      ];
    });

    test('should apply no filters by default', () {
      // Arrange
      const filters = CoursFilters();

      // Act
      final result = _applyFilters(sampleCours, filters);

      // Assert
      expect(result.length, 3);
      expect(result[0].id, 'id1');
      expect(result[1].id, 'id2');
      expect(result[2].id, 'id3');
    });

    test('should filter by fournisseur', () {
      // Arrange
      const filters = CoursFilters(fournisseurId: 'fournisseur-1');

      // Act
      final result = _applyFilters(sampleCours, filters);

      // Assert
      expect(result.length, 2);
      expect(result[0].id, 'id1');
      expect(result[1].id, 'id3');
    });

    test('should filter by volume range', () {
      // Arrange
      const filters = CoursFilters(volumeMin: 50000, volumeMax: 100000);

      // Act
      final result = _applyFilters(sampleCours, filters);

      // Assert
      expect(result.length, 1);
      expect(result[0].id, 'id2');
      expect(result[0].volume, 70000);
    });

    test('should filter by volume range excluding high volumes', () {
      // Arrange
      const filters = CoursFilters(volumeMin: 0, volumeMax: 100000);

      // Act
      final result = _applyFilters(sampleCours, filters);

      // Assert
      expect(result.length, 2);
      expect(result[0].id, 'id1');
      expect(result[1].id, 'id2');
      // id3 should be excluded (volume 120000 > 100000)
    });

    test('should combine fournisseur and volume filters', () {
      // Arrange
      const filters = CoursFilters(
        fournisseurId: 'fournisseur-1',
        volumeMin: 20000,
        volumeMax: 50000,
      );

      // Act
      final result = _applyFilters(sampleCours, filters);

      // Assert
      expect(result.length, 1);
      expect(result[0].id, 'id1');
      expect(result[0].fournisseurId, 'fournisseur-1');
      expect(result[0].volume, 30000);
    });

    test('should handle cours with null volume', () {
      // Arrange
      final coursWithNullVolume = [
        ...sampleCours,
        CoursDeRoute(
          id: 'id4',
          fournisseurId: 'fournisseur-1',
          produitId: 'produit-4',
          depotDestinationId: 'depot-4',
          volume: null, // Null volume
          statut: StatutCours.chargement,
        ),
      ];

      const filters = CoursFilters(volumeMin: 50000, volumeMax: 100000);

      // Act
      final result = _applyFilters(coursWithNullVolume, filters);

      // Assert
      expect(result.length, 1);
      expect(result[0].id, 'id2');
      // id4 should be excluded because volume is null
    });

    test('should return empty list when no matches', () {
      // Arrange
      const filters = CoursFilters(fournisseurId: 'non-existent', volumeMin: 0, volumeMax: 100000);

      // Act
      final result = _applyFilters(sampleCours, filters);

      // Assert
      expect(result.length, 0);
    });
  });

  group('Provider Integration', () {
    test('should provide default filters', () {
      // Arrange
      final container = ProviderContainer();

      // Act
      final filters = container.read(coursFiltersProvider);

      // Assert
      expect(filters.fournisseurId, null);
      expect(filters.volumeMin, 0);
      expect(filters.volumeMax, 100000);

      container.dispose();
    });

    test('should update filters state', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(coursFiltersProvider.notifier);

      // Act
      notifier.state = const CoursFilters(
        fournisseurId: 'fournisseur-1',
        volumeMin: 20000,
        volumeMax: 80000,
      );

      // Assert
      final updatedFilters = container.read(coursFiltersProvider);
      expect(updatedFilters.fournisseurId, 'fournisseur-1');
      expect(updatedFilters.volumeMin, 20000);
      expect(updatedFilters.volumeMax, 80000);

      container.dispose();
    });
  });
}

// Helper function to test filter application
// This mirrors the private _applyFilters function in cours_filters_provider.dart
List<CoursDeRoute> _applyFilters(List<CoursDeRoute> cours, CoursFilters filters) {
  return cours.where((c) {
    // Filtre par fournisseur
    final okFournisseur = (filters.fournisseurId == null)
        ? true
        : c.fournisseurId == filters.fournisseurId;

    // Filtre par volume (0-100 000 L)
    bool okVolume = true;
    if (c.volume != null) {
      if (c.volume! < filters.volumeMin) {
        okVolume = false;
      }
      if (c.volume! > filters.volumeMax) {
        okVolume = false;
      }
    }

    return okFournisseur && okVolume;
  }).toList();
}

