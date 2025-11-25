// ð Module : Cours de Route - Fixtures de Test
// ð§ Auteur : Valery Kalonga
// ð Date : 2025-01-27
// ð§­ Description : Fixtures et donnÃ©es de test pour le module CDR

import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';
import 'package:ml_pp_mvp/shared/providers/ref_data_provider.dart' show RefDataCache;

/// Fixtures pour les tests du module Cours de Route
class CoursRouteFixtures {
  /// CrÃ©e un cours de route valide pour les tests
  static CoursDeRoute validCours() {
    return CoursDeRoute(
      id: 'test-id',
      fournisseurId: 'fournisseur-1',
      produitId: 'produit-1',
      depotDestinationId: 'depot-1',
      transporteur: 'Transport Express',
      plaqueCamion: 'ABC123',
      chauffeur: 'Jean Dupont',
      volume: 50000,
      pays: 'RDC',
      statut: StatutCours.chargement,
      note: 'Test note',
      dateChargement: DateTime.now().subtract(const Duration(days: 1)),
      dateArriveePrevue: DateTime.now().add(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );
  }

  /// CrÃ©e un cours de route invalide pour les tests
  static CoursDeRoute invalidCours() {
    return CoursDeRoute(
      id: '',
      fournisseurId: '', // Invalid - empty
      produitId: '', // Invalid - empty
      depotDestinationId: '', // Invalid - empty
      volume: -100, // Invalid - negative
      dateChargement: DateTime.now().add(const Duration(days: 1)), // Invalid - future date
    );
  }

  /// CrÃ©e un cours de route au statut spÃ©cifique
  static CoursDeRoute coursWithStatut(StatutCours statut) {
    return CoursDeRoute(
      id: 'test-id',
      fournisseurId: 'fournisseur-1',
      produitId: 'produit-1',
      depotDestinationId: 'depot-1',
      statut: statut,
    );
  }

  /// CrÃ©e un cours de route avec un fournisseur spÃ©cifique
  static CoursDeRoute coursWithFournisseur(String fournisseurId) {
    return CoursDeRoute(
      id: 'test-id',
      fournisseurId: fournisseurId,
      produitId: 'produit-1',
      depotDestinationId: 'depot-1',
    );
  }

  /// CrÃ©e un cours de route avec un volume spÃ©cifique
  static CoursDeRoute coursWithVolume(double volume) {
    return CoursDeRoute(
      id: 'test-id',
      fournisseurId: 'fournisseur-1',
      produitId: 'produit-1',
      depotDestinationId: 'depot-1',
      volume: volume,
    );
  }

  /// CrÃ©e un cours de route avec une plaque spÃ©cifique
  static CoursDeRoute coursWithPlaque(String plaque) {
    return CoursDeRoute(
      id: 'test-id',
      fournisseurId: 'fournisseur-1',
      produitId: 'produit-1',
      depotDestinationId: 'depot-1',
      plaqueCamion: plaque,
    );
  }

  /// CrÃ©e une liste d'exemple de cours de route
  static List<CoursDeRoute> sampleList() {
    return [
      CoursDeRoute(
        id: 'id1',
        fournisseurId: 'fournisseur-1',
        produitId: 'produit-1',
        depotDestinationId: 'depot-1',
        plaqueCamion: 'ABC123',
        chauffeur: 'Jean Dupont',
        volume: 30000,
        statut: StatutCours.chargement,
      ),
      CoursDeRoute(
        id: 'id2',
        fournisseurId: 'fournisseur-2',
        produitId: 'produit-2',
        depotDestinationId: 'depot-2',
        plaqueCamion: 'DEF456',
        chauffeur: 'Marie Martin',
        volume: 70000,
        statut: StatutCours.transit,
      ),
      CoursDeRoute(
        id: 'id3',
        fournisseurId: 'fournisseur-1',
        produitId: 'produit-3',
        depotDestinationId: 'depot-3',
        plaqueCamion: 'GHI789',
        chauffeur: 'Pierre Durand',
        volume: 120000,
        statut: StatutCours.frontiere,
      ),
      CoursDeRoute(
        id: 'id4',
        fournisseurId: 'fournisseur-3',
        produitId: 'produit-1',
        depotDestinationId: 'depot-1',
        plaqueCamion: 'JKL012',
        chauffeur: 'Sophie Leroy',
        volume: 50000,
        statut: StatutCours.arrive,
      ),
      CoursDeRoute(
        id: 'id5',
        fournisseurId: 'fournisseur-2',
        produitId: 'produit-2',
        depotDestinationId: 'depot-2',
        plaqueCamion: 'MNO345',
        chauffeur: 'Luc Moreau',
        volume: 80000,
        statut: StatutCours.decharge,
      ),
    ];
  }

  /// CrÃ©e une liste de cours actifs (non dÃ©chargÃ©s)
  static List<CoursDeRoute> activeCoursList() {
    return sampleList().where((c) => c.statut != StatutCours.decharge).toList();
  }

  /// CrÃ©e une liste de cours par statut
  static List<CoursDeRoute> coursByStatut(StatutCours statut) {
    return sampleList().where((c) => c.statut == statut).toList();
  }

  /// CrÃ©e une liste de cours par fournisseur
  static List<CoursDeRoute> coursByFournisseur(String fournisseurId) {
    return sampleList().where((c) => c.fournisseurId == fournisseurId).toList();
  }

  /// CrÃ©e une liste de cours par dÃ©pÃ´t
  static List<CoursDeRoute> coursByDepot(String depotId) {
    return sampleList().where((c) => c.depotDestinationId == depotId).toList();
  }

  /// CrÃ©e une liste de cours dans une plage de volume
  static List<CoursDeRoute> coursByVolumeRange(double minVolume, double maxVolume) {
    return sampleList().where((c) {
      if (c.volume == null) return false;
      return c.volume! >= minVolume && c.volume! <= maxVolume;
    }).toList();
  }

  /// CrÃ©e des donnÃ©es de rÃ©fÃ©rence pour les tests
  static RefDataCache refDataCache() {
    return RefDataCache(
      fournisseurs: {
        'fournisseur-1': 'Total',
        'fournisseur-2': 'Shell',
        'fournisseur-3': 'ExxonMobil',
      },
      produits: {'produit-1': 'Essence', 'produit-2': 'Gasoil / AGO', 'produit-3': 'KÃ©rosÃ¨ne'},
      produitCodes: {'produit-1': 'ESS', 'produit-2': 'AGO', 'produit-3': 'KER'},
      depots: {
        'depot-1': 'DÃ©pÃ´t Kinshasa',
        'depot-2': 'DÃ©pÃ´t Lubumbashi',
        'depot-3': 'DÃ©pÃ´t Matadi',
      },
      loadedAt: DateTime.now(),
    );
  }

  /// CrÃ©e des donnÃ©es JSON pour les tests de sÃ©rialisation
  static Map<String, dynamic> validJson() {
    return {
      'id': 'test-id',
      'fournisseur_id': 'fournisseur-1',
      'produit_id': 'produit-1',
      'depot_destination_id': 'depot-1',
      'transporteur': 'Transport Express',
      'plaque_camion': 'ABC123',
      'chauffeur_nom': 'Jean Dupont',
      'volume': 50000.0,
      'depart_pays': 'RDC',
      'statut': 'CHARGEMENT',
      'note': 'Test note',
      'date_chargement': '2025-01-26',
      'date_arrivee_prevue': '2025-01-28',
      'created_at': '2025-01-26T10:00:00Z',
      'updated_at': '2025-01-26T11:00:00Z',
    };
  }

  /// CrÃ©e des donnÃ©es JSON avec des champs legacy
  static Map<String, dynamic> legacyJson() {
    return {
      'id': 'test-id',
      'fournisseur_id': 'fournisseur-1',
      'produit_id': 'produit-1',
      'depot_destination_id': 'depot-1',
      'chauffeur_nom': 'Jean Dupont', // Legacy field
      'depart_pays': 'RDC', // Legacy field
      'statut': 'CHARGEMENT',
    };
  }

  /// CrÃ©e des donnÃ©es JSON invalides
  static Map<String, dynamic> invalidJson() {
    return {
      'id': '',
      'fournisseur_id': '',
      'produit_id': '',
      'depot_destination_id': '',
      'volume': -100,
      'statut': 'INVALID_STATUT',
    };
  }

  /// CrÃ©e des donnÃ©es de test pour les filtres
  static Map<String, dynamic> filterTestData() {
    return {
      'fournisseurs': {
        'fournisseur-1': 'Total',
        'fournisseur-2': 'Shell',
        'fournisseur-3': 'ExxonMobil',
      },
      'volumes': [30000, 50000, 70000, 120000, 80000],
      'statuts': [
        StatutCours.chargement,
        StatutCours.transit,
        StatutCours.frontiere,
        StatutCours.arrive,
        StatutCours.decharge,
      ],
    };
  }

  /// CrÃ©e des donnÃ©es de test pour les transitions de statut
  static Map<StatutCours, StatutCours?> statutTransitions() {
    return {
      StatutCours.chargement: StatutCours.transit,
      StatutCours.transit: StatutCours.frontiere,
      StatutCours.frontiere: StatutCours.arrive,
      StatutCours.arrive: StatutCours.decharge,
      StatutCours.decharge: null,
    };
  }

  /// CrÃ©e des donnÃ©es de test pour la validation des plaques
  static Map<String, bool> plaqueValidationData() {
    return {
      'ABC123': true,
      'ABC-123': true,
      '123ABC': true,
      'ABC 123': true,
      '': false,
      'INVALID': false,
      '123': false,
      'ABC-123-456': false,
    };
  }

  /// CrÃ©e des donnÃ©es de test pour la validation des volumes
  static Map<double, bool> volumeValidationData() {
    return {1000: true, 50000: true, 200000: true, 0: false, -100: false, 300000: false};
  }

  /// CrÃ©e des donnÃ©es de test pour la validation des dates
  static Map<DateTime, bool> dateValidationData() {
    final now = DateTime.now();
    return {
      now.subtract(const Duration(days: 1)): true,
      now.subtract(const Duration(hours: 1)): true,
      now: true,
      now.add(const Duration(hours: 1)): false,
      now.add(const Duration(days: 1)): false,
    };
  }
}

