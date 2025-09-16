// 📌 Module : Cours de Route - Tests
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-08-07
// 🧭 Description : Tests unitaires pour le modèle CoursDeRoute

import 'package:flutter_test/flutter_test.dart';
import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

void main() {
  group('CoursDeRoute Model Tests', () {
    test('should create CoursDeRoute from JSON', () {
      final json = {
        'id': 'test-id',
        'fournisseur_id': 'fournisseur-1',
        'produit_id': 'produit-1',
        'depot_destination_id': 'depot-1',
        'transporteur': 'Transport Express',
        'plaque_camion': 'ABC123',
        'chauffeur': 'Jean Dupont',
        'volume': 50000.0,
        'date_chargement': '2025-08-07T10:00:00Z',
        'date_arrivee_prevue': '2025-08-08T10:00:00Z',
        'pays': 'RDC',
        'statut': 'transit',
        'note': 'Test note',
        'created_at': '2025-08-07T09:00:00Z',
        'updated_at': '2025-08-07T09:30:00Z',
      };

      final cours = CoursDeRoute.fromMap(json);

      expect(cours.id, 'test-id');
      expect(cours.fournisseurId, 'fournisseur-1');
      expect(cours.produitId, 'produit-1');
      expect(cours.depotDestinationId, 'depot-1');
      expect(cours.transporteur, 'Transport Express');
      expect(cours.plaqueCamion, 'ABC123');
      expect(cours.chauffeur, 'Jean Dupont');
      expect(cours.volume, 50000.0);
      expect(cours.pays, 'RDC');
      expect(cours.statut, StatutCours.transit);
      expect(cours.note, 'Test note');
      expect(cours.dateChargement, DateTime.parse('2025-08-07T10:00:00Z'));
      expect(cours.dateArriveePrevue, DateTime.parse('2025-08-08T10:00:00Z'));
      expect(cours.createdAt, DateTime.parse('2025-08-07T09:00:00Z'));
      expect(cours.updatedAt, DateTime.parse('2025-08-07T09:30:00Z'));
    });

    test('should serialize CoursDeRoute to JSON', () {
      final cours = CoursDeRoute(
        id: 'test-id',
        fournisseurId: 'fournisseur-1',
        produitId: 'produit-1',
        depotDestinationId: 'depot-1',
        transporteur: 'Transport Express',
        plaqueCamion: 'ABC123',
        chauffeur: 'Jean Dupont',
        volume: 50000.0,
        pays: 'RDC',
        statut: StatutCours.transit,
        note: 'Test note',
        dateChargement: DateTime.parse('2025-08-07T10:00:00Z'),
        dateArriveePrevue: DateTime.parse('2025-08-08T10:00:00Z'),
        createdAt: DateTime.parse('2025-08-07T09:00:00Z'),
        updatedAt: DateTime.parse('2025-08-07T09:30:00Z'),
      );

      final map = cours.toJson();

      expect(map['id'], 'test-id');
      expect(map['fournisseur_id'], 'fournisseur-1');
      expect(map['produit_id'], 'produit-1');
      expect(map['depot_destination_id'], 'depot-1');
      expect(map['transporteur'], 'Transport Express');
      expect(map['plaque_camion'], 'ABC123');
      expect(map['chauffeur'], 'Jean Dupont');
      expect(map['volume'], 50000.0);
      expect(map['pays'], 'RDC');
      expect(map['statut'], 'TRANSIT');
      expect(map['note'], 'Test note');
    });

    test('should handle legacy field names in fromMap', () {
      final json = {
        'id': 'test-id',
        'fournisseur_id': 'fournisseur-1',
        'produit_id': 'produit-1',
        'depot_destination_id': 'depot-1',
        'chauffeur_nom': 'Jean Dupont', // Legacy field
        'depart_pays': 'RDC',           // Legacy field
        'statut': 'CHARGEMENT',
      };

      final cours = CoursDeRoute.fromMap(json);

      expect(cours.chauffeur, 'Jean Dupont');
      expect(cours.pays, 'RDC');
      expect(cours.statut, StatutCours.chargement);
    });

    test('should create empty CoursDeRoute', () {
      final cours = CoursDeRoute.empty();

      expect(cours.id, '');
      expect(cours.fournisseurId, '');
      expect(cours.produitId, '');
      expect(cours.depotDestinationId, '');
      expect(cours.transporteur, null);
      expect(cours.statut, StatutCours.chargement);
    });

    test('should check if cours is actif', () {
      final coursActif = CoursDeRoute(
        id: 'test',
        fournisseurId: 'fournisseur',
        produitId: 'produit',
        depotDestinationId: 'depot',
        statut: StatutCours.transit,
      );

      final coursTermine = CoursDeRoute(
        id: 'test',
        fournisseurId: 'fournisseur',
        produitId: 'produit',
        depotDestinationId: 'depot',
        statut: StatutCours.decharge,
      );

          expect(CoursDeRouteUtils.isActif(coursActif), true);
    expect(CoursDeRouteUtils.isActif(coursTermine), false);
    });

    test('should get next statut', () {
      final cours = CoursDeRoute(
        id: 'test',
        fournisseurId: 'fournisseur',
        produitId: 'produit',
        depotDestinationId: 'depot',
        statut: StatutCours.chargement,
      );

      expect(CoursDeRouteUtils.getStatutSuivant(cours), StatutCours.transit);
    });

    test('should not progress when at final statut', () {
      final cours = CoursDeRoute(
        id: 'test',
        fournisseurId: 'fournisseur',
        produitId: 'produit',
        depotDestinationId: 'depot',
        statut: StatutCours.decharge,
      );

      expect(CoursDeRouteUtils.peutProgresser(cours), false);
      expect(CoursDeRouteUtils.getStatutSuivant(cours), null);
    });

    test('should validate all statut transitions', () {
      // Test progression normale avec des cours
      final coursChargement = CoursDeRoute(
        id: 'test',
        fournisseurId: 'fournisseur',
        produitId: 'produit',
        depotDestinationId: 'depot',
        statut: StatutCours.chargement,
      );
      
      final coursTransit = coursChargement.copyWith(statut: StatutCours.transit);
      final coursFrontiere = coursChargement.copyWith(statut: StatutCours.frontiere);
      final coursArrive = coursChargement.copyWith(statut: StatutCours.arrive);
      final coursDecharge = coursChargement.copyWith(statut: StatutCours.decharge);
      
      expect(CoursDeRouteUtils.getStatutSuivant(coursChargement), StatutCours.transit);
      expect(CoursDeRouteUtils.getStatutSuivant(coursTransit), StatutCours.frontiere);
      expect(CoursDeRouteUtils.getStatutSuivant(coursFrontiere), StatutCours.arrive);
      expect(CoursDeRouteUtils.getStatutSuivant(coursArrive), StatutCours.decharge);
      expect(CoursDeRouteUtils.getStatutSuivant(coursDecharge), null);
    });

    test('should validate statut from database', () {
      expect(StatutCoursDb.parseDb('CHARGEMENT'), StatutCours.chargement);
      expect(StatutCoursDb.parseDb('TRANSIT'), StatutCours.transit);
      expect(StatutCoursDb.parseDb('FRONTIERE'), StatutCours.frontiere);
      expect(StatutCoursDb.parseDb('ARRIVE'), StatutCours.arrive);
      expect(StatutCoursDb.parseDb('DECHARGE'), StatutCours.decharge);
      
      // Test fallback pour valeurs invalides
      expect(StatutCoursDb.parseDb('INVALID'), StatutCours.chargement);
      expect(StatutCoursDb.parseDb(''), StatutCours.chargement);
    });

    test('should validate statut to database format', () {
      expect(StatutCours.chargement.db, 'CHARGEMENT');
      expect(StatutCours.transit.db, 'TRANSIT');
      expect(StatutCours.frontiere.db, 'FRONTIERE');
      expect(StatutCours.arrive.db, 'ARRIVE');
      expect(StatutCours.decharge.db, 'DECHARGE');
    });

    test('should validate statut labels', () {
      expect(StatutCours.chargement.label, 'Chargement');
      expect(StatutCours.transit.label, 'Transit');
      expect(StatutCours.frontiere.label, 'Frontière');
      expect(StatutCours.arrive.label, 'Arrivé');
      expect(StatutCours.decharge.label, 'Déchargé');
    });

    test('should validate volume constraints', () {
      final coursValid = CoursDeRoute(
        id: 'test',
        fournisseurId: 'fournisseur',
        produitId: 'produit',
        depotDestinationId: 'depot',
        volume: 50000,
      );

      final coursInvalid = CoursDeRoute(
        id: 'test',
        fournisseurId: 'fournisseur',
        produitId: 'produit',
        depotDestinationId: 'depot',
        volume: -100,
      );

      expect(coursValid.volume, 50000);
      expect(coursInvalid.volume, -100);
    });

    test('should validate required fields', () {
      expect(() => CoursDeRoute(
        id: '',
        fournisseurId: '', // Empty - should be valid for empty constructor
        produitId: '',
        depotDestinationId: '',
      ), returnsNormally);
    });

    test('should handle null optional fields', () {
      final cours = CoursDeRoute(
        id: 'test',
        fournisseurId: 'fournisseur',
        produitId: 'produit',
        depotDestinationId: 'depot',
        transporteur: null,
        plaqueRemorque: null,
        note: null,
      );

      expect(cours.transporteur, null);
      expect(cours.plaqueRemorque, null);
      expect(cours.note, null);
    });
  });
}
