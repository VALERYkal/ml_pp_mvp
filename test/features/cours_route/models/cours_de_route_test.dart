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
  });
}
