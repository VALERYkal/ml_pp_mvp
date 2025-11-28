// 📌 Module : Cours de Route - Tests StatutCoursConverter
// 🧑 Auteur : Valery Kalonga / Mona (IA)
// 📅 Date : 2025-11-27
// 🧭 Description : Tests unitaires pour StatutCoursConverter (JSON serialization)

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

void main() {
  group('StatutCoursConverter - Méthodes statiques', () {
    test('fromDb accepte variantes accentuées et non accentuées', () {
      // Arrange & Act & Assert
      expect(StatutCoursConverter.fromDb('frontiere'), StatutCours.frontiere);
      expect(StatutCoursConverter.fromDb('frontière'), StatutCours.frontiere);
      expect(StatutCoursConverter.fromDb('arrive'), StatutCours.arrive);
      expect(StatutCoursConverter.fromDb('arrivé'), StatutCours.arrive);
      expect(StatutCoursConverter.fromDb('decharge'), StatutCours.decharge);
      expect(StatutCoursConverter.fromDb('déchargé'), StatutCours.decharge);
    });

    test('fromDb accepte toutes les valeurs MAJUSCULES', () {
      // Arrange & Act & Assert
      expect(StatutCoursConverter.fromDb('CHARGEMENT'), StatutCours.chargement);
      expect(StatutCoursConverter.fromDb('TRANSIT'), StatutCours.transit);
      expect(StatutCoursConverter.fromDb('FRONTIERE'), StatutCours.frontiere);
      expect(StatutCoursConverter.fromDb('ARRIVE'), StatutCours.arrive);
      expect(StatutCoursConverter.fromDb('DECHARGE'), StatutCours.decharge);
    });

    test('fromDb avec valeur inconnue retourne CHARGEMENT (fallback)', () {
      // Arrange & Act & Assert
      expect(StatutCoursConverter.fromDb('INCONNU'), StatutCours.chargement);
      expect(StatutCoursConverter.fromDb(''), StatutCours.chargement);
      expect(StatutCoursConverter.fromDb(null), StatutCours.chargement);
    });

    test('toDb retourne les formes majuscules sans accents pour tous les statuts', () {
      // Arrange & Act & Assert
      expect(StatutCoursConverter.toDb(StatutCours.chargement), 'CHARGEMENT');
      expect(StatutCoursConverter.toDb(StatutCours.transit), 'TRANSIT');
      expect(StatutCoursConverter.toDb(StatutCours.frontiere), 'FRONTIERE');
      expect(StatutCoursConverter.toDb(StatutCours.arrive), 'ARRIVE');
      expect(StatutCoursConverter.toDb(StatutCours.decharge), 'DECHARGE');
    });

    test('round-trip: toDb -> fromDb retourne le même statut', () {
      // Arrange: Tous les statuts
      final allStatuts = [
        StatutCours.chargement,
        StatutCours.transit,
        StatutCours.frontiere,
        StatutCours.arrive,
        StatutCours.decharge,
      ];

      // Act & Assert
      for (final statut in allStatuts) {
        final dbValue = StatutCoursConverter.toDb(statut);
        final parsed = StatutCoursConverter.fromDb(dbValue);
        expect(parsed, equals(statut),
            reason: 'Round-trip échoué pour $statut (db=$dbValue)');
      }
    });
  });

  group('StatutCoursConverter - Interface JsonConverter', () {
    const converter = StatutCoursConverter();

    test('fromJson() délègue à fromDb() et accepte toutes les variantes', () {
      // Arrange & Act & Assert
      expect(converter.fromJson('CHARGEMENT'), StatutCours.chargement);
      expect(converter.fromJson('TRANSIT'), StatutCours.transit);
      expect(converter.fromJson('FRONTIERE'), StatutCours.frontiere);
      expect(converter.fromJson('ARRIVE'), StatutCours.arrive);
      expect(converter.fromJson('DECHARGE'), StatutCours.decharge);
      
      // Variantes legacy
      expect(converter.fromJson('chargement'), StatutCours.chargement);
      expect(converter.fromJson('frontière'), StatutCours.frontiere);
      expect(converter.fromJson('arrivé'), StatutCours.arrive);
      expect(converter.fromJson('déchargé'), StatutCours.decharge);
    });

    test('toJson() délègue à toDb() et retourne MAJUSCULES', () {
      // Arrange & Act & Assert
      expect(converter.toJson(StatutCours.chargement), 'CHARGEMENT');
      expect(converter.toJson(StatutCours.transit), 'TRANSIT');
      expect(converter.toJson(StatutCours.frontiere), 'FRONTIERE');
      expect(converter.toJson(StatutCours.arrive), 'ARRIVE');
      expect(converter.toJson(StatutCours.decharge), 'DECHARGE');
    });

    test('round-trip JSON: toJson -> fromJson retourne le même statut', () {
      // Arrange: Tous les statuts
      final allStatuts = [
        StatutCours.chargement,
        StatutCours.transit,
        StatutCours.frontiere,
        StatutCours.arrive,
        StatutCours.decharge,
      ];

      // Act & Assert
      for (final statut in allStatuts) {
        final jsonValue = converter.toJson(statut);
        final parsed = converter.fromJson(jsonValue);
        expect(parsed, equals(statut),
            reason: 'Round-trip JSON échoué pour $statut (json=$jsonValue)');
      }
    });
  });
}


