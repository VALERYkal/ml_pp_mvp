// 📌 Module : KPI Models - Tests unitaires
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-09-17
// 🧭 Description : Tests unitaires pour les modèles KPI unifiés

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/kpi/models/kpi_models.dart';

void main() {
  group('KPI Models Tests', () {
    group('KpiNumberVolume', () {
      test('should create KpiNumberVolume with correct values', () {
        // Arrange & Act
        const kpi = KpiNumberVolume(
          count: 5,
          volume15c: 2500.0,
          volumeAmbient: 2600.0,
        );

        // Assert
        expect(kpi.count, equals(5));
        expect(kpi.volume15c, equals(2500.0));
        expect(kpi.volumeAmbient, equals(2600.0));
      });

      test('should handle zero values', () {
        // Arrange & Act
        const kpi = KpiNumberVolume(
          count: 0,
          volume15c: 0.0,
          volumeAmbient: 0.0,
        );

        // Assert
        expect(kpi.count, equals(0));
        expect(kpi.volume15c, equals(0.0));
        expect(kpi.volumeAmbient, equals(0.0));
      });
    });

    group('KpiStocks', () {
      test('should create KpiStocks with correct values', () {
        // Arrange & Act
        const kpi = KpiStocks(
          totalAmbient: 15000.0,
          total15c: 14500.0,
          capacityTotal: 20000.0,
        );

        // Assert
        expect(kpi.totalAmbient, equals(15000.0));
        expect(kpi.total15c, equals(14500.0));
        expect(kpi.capacityTotal, equals(20000.0));
      });

      test('should calculate utilization ratio correctly', () {
        // Arrange & Act
        const kpi = KpiStocks(
          totalAmbient: 15000.0,
          total15c: 10000.0,
          capacityTotal: 20000.0,
        );

        // Assert
        expect(kpi.utilizationRatio, equals(0.5)); // 10000 / 20000 = 0.5
      });

      test('should handle zero capacity', () {
        // Arrange & Act
        const kpi = KpiStocks(
          totalAmbient: 1000.0,
          total15c: 1000.0,
          capacityTotal: 0.0,
        );

        // Assert
        expect(kpi.utilizationRatio, equals(0.0)); // Division par zéro = 0
      });

      test('should handle full capacity', () {
        // Arrange & Act
        const kpi = KpiStocks(
          totalAmbient: 20000.0,
          total15c: 20000.0,
          capacityTotal: 20000.0,
        );

        // Assert
        expect(kpi.utilizationRatio, equals(1.0)); // 20000 / 20000 = 1.0
      });
    });

    group('KpiBalanceToday', () {
      test('should create KpiBalanceToday with correct values', () {
        // Arrange & Act
        const kpi = KpiBalanceToday(
          receptions15c: 2500.0,
          sorties15c: 1800.0,
          receptionsAmbient: 0.0,
          sortiesAmbient: 0.0,
        );

        // Assert
        expect(kpi.receptions15c, equals(2500.0));
        expect(kpi.sorties15c, equals(1800.0));
      });

      test('should calculate positive delta correctly', () {
        // Arrange & Act
        const kpi = KpiBalanceToday(
          receptions15c: 2500.0,
          sorties15c: 1800.0,
          receptionsAmbient: 0.0,
          sortiesAmbient: 0.0,
        );

        // Assert
        expect(kpi.delta15c, equals(700.0)); // 2500 - 1800 = 700
      });

      test('should calculate negative delta correctly', () {
        // Arrange & Act
        const kpi = KpiBalanceToday(
          receptions15c: 1000.0,
          sorties15c: 1500.0,
          receptionsAmbient: 0.0,
          sortiesAmbient: 0.0,
        );

        // Assert
        expect(kpi.delta15c, equals(-500.0)); // 1000 - 1500 = -500
      });

      test('should handle zero delta', () {
        // Arrange & Act
        const kpi = KpiBalanceToday(
          receptions15c: 1000.0,
          sorties15c: 1000.0,
          receptionsAmbient: 0.0,
          sortiesAmbient: 0.0,
        );

        // Assert
        expect(kpi.delta15c, equals(0.0)); // 1000 - 1000 = 0
      });
    });

    group('KpiCiterneAlerte', () {
      test('should create KpiCiterneAlerte with correct values', () {
        // Arrange & Act
        const kpi = KpiCiterneAlerte(
          citerneId: 'citerne-123',
          libelle: 'Citerne A',
          stock15c: 500.0,
          capacity: 1000.0,
        );

        // Assert
        expect(kpi.citerneId, equals('citerne-123'));
        expect(kpi.libelle, equals('Citerne A'));
        expect(kpi.stock15c, equals(500.0));
        expect(kpi.capacity, equals(1000.0));
      });
    });

    group('KpiTrendPoint', () {
      test('should create KpiTrendPoint with correct values', () {
        // Arrange
        final date = DateTime(2025, 9, 17);

        // Act
        final kpi = KpiTrendPoint(
          day: date,
          receptions15c: 2000.0,
          sorties15c: 1500.0,
        );

        // Assert
        expect(kpi.day, equals(date));
        expect(kpi.receptions15c, equals(2000.0));
        expect(kpi.sorties15c, equals(1500.0));
      });
    });

    group('KpiSnapshot', () {
      test('should create complete KpiSnapshot', () {
        // Arrange
        final trendPoints = [
          KpiTrendPoint(
            day: DateTime(2025, 9, 10),
            receptions15c: 2000.0,
            sorties15c: 1500.0,
          ),
          KpiTrendPoint(
            day: DateTime(2025, 9, 11),
            receptions15c: 2200.0,
            sorties15c: 1600.0,
          ),
        ];

        // Act
        final snapshot = KpiSnapshot(
          receptionsToday: const KpiNumberVolume(
            count: 5,
            volume15c: 2500.0,
            volumeAmbient: 2600.0,
          ),
          sortiesToday: const KpiNumberVolume(
            count: 3,
            volume15c: 1800.0,
            volumeAmbient: 1900.0,
          ),
          stocks: const KpiStocks(
            totalAmbient: 15000.0,
            total15c: 14500.0,
            capacityTotal: 20000.0,
          ),
          balanceToday: const KpiBalanceToday(
            receptions15c: 2500.0,
            sorties15c: 1800.0,
            receptionsAmbient: 0.0,
            sortiesAmbient: 0.0,
          ),
          trucksToFollow: const KpiTrucksToFollow(
            totalTrucks: 0,
            totalPlannedVolume: 0.0,
            trucksEnRoute: 0,
            trucksEnAttente: 0,
            volumeEnRoute: 0.0,
            volumeEnAttente: 0.0,
          ),
          trend7d: trendPoints,
        );

        // Assert
        expect(snapshot.receptionsToday.count, equals(5));
        expect(snapshot.sortiesToday.count, equals(3));
        expect(snapshot.stocks.total15c, equals(14500.0));
        expect(snapshot.balanceToday.delta15c, equals(700.0));
        expect(snapshot.trend7d.length, equals(2));
      });

      test('should handle empty collections', () {
        // Act
        const snapshot = KpiSnapshot(
          receptionsToday: KpiNumberVolume(
            count: 0,
            volume15c: 0.0,
            volumeAmbient: 0.0,
          ),
          sortiesToday: KpiNumberVolume(
            count: 0,
            volume15c: 0.0,
            volumeAmbient: 0.0,
          ),
          stocks: KpiStocks(
            totalAmbient: 0.0,
            total15c: 0.0,
            capacityTotal: 0.0,
          ),
          balanceToday: KpiBalanceToday(
            receptions15c: 0.0,
            sorties15c: 0.0,
            receptionsAmbient: 0.0,
            sortiesAmbient: 0.0,
          ),
          trucksToFollow: KpiTrucksToFollow(
            totalTrucks: 0,
            totalPlannedVolume: 0.0,
            trucksEnRoute: 0,
            trucksEnAttente: 0,
            volumeEnRoute: 0.0,
            volumeEnAttente: 0.0,
          ),
          trend7d: [],
        );

        // Assert
        expect(snapshot.receptionsToday.count, equals(0));
        expect(snapshot.sortiesToday.count, equals(0));
        expect(snapshot.stocks.total15c, equals(0.0));
        expect(snapshot.balanceToday.delta15c, equals(0.0));
        expect(snapshot.trend7d.length, equals(0));
      });
    });
  });
}
