// 📌 Module : Cours de Route - Models
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-08-07
// 🗃️ Source SQL : Table `public.cours_de_route`
// 🧭 Description : Modèle de cours de route pour le suivi des transports de carburant

import 'package:freezed_annotation/freezed_annotation.dart';

part 'cours_de_route.freezed.dart';
part 'cours_de_route.g.dart';

/// Enum représentant les statuts possibles d'un cours de route
/// 
/// Les statuts suivent un ordre logique de progression :
/// - chargement : Le camion est en cours de chargement chez le fournisseur
/// - transit : Le camion est en route vers le dépôt
/// - frontiere : Le camion a franchi la frontière
/// - arrive : Le camion est arrivé au dépôt
/// - decharge : Le camion a été déchargé (cours terminé)
enum StatutCours {
  @JsonValue('chargement')
  chargement,
  @JsonValue('transit')
  transit,
  @JsonValue('frontiere')
  frontiere,
  @JsonValue('arrive')
  arrive,
  @JsonValue('decharge')
  decharge,
}

/// Extension de mapping DB (MAJUSCULES ASCII) et helpers label/next
extension StatutCoursDb on StatutCours {
  /// Valeur à écrire en base (MAJUSCULES ASCII)
  String get db {
    switch (this) {
      case StatutCours.chargement:
        return 'CHARGEMENT';
      case StatutCours.transit:
        return 'TRANSIT';
      case StatutCours.frontiere:
        return 'FRONTIERE';
      case StatutCours.arrive:
        return 'ARRIVE';
      case StatutCours.decharge:
        return 'DECHARGE';
    }
  }

  /// Libellé user-friendly
  String get label {
    switch (this) {
      case StatutCours.chargement:
        return 'Chargement';
      case StatutCours.transit:
        return 'Transit';
      case StatutCours.frontiere:
        return 'Frontière';
      case StatutCours.arrive:
        return 'Arrivé';
      case StatutCours.decharge:
        return 'Déchargé';
    }
  }

  /// Prochain statut (UI)
  static StatutCours? next(StatutCours s) {
    switch (s) {
      case StatutCours.chargement:
        return StatutCours.transit;
      case StatutCours.transit:
        return StatutCours.frontiere;
      case StatutCours.frontiere:
        return StatutCours.arrive;
      case StatutCours.arrive:
        return StatutCours.decharge; // via Réception
      case StatutCours.decharge:
        return null;
    }
  }

  /// Parse une valeur DB (MAJUSCULES) ou legacy (minuscules/accents)
  static StatutCours parseDb(String? raw) {
    switch (raw) {
      case 'CHARGEMENT':
        return StatutCours.chargement;
      case 'TRANSIT':
        return StatutCours.transit;
      case 'FRONTIERE':
        return StatutCours.frontiere;
      case 'ARRIVE':
        return StatutCours.arrive;
      case 'DECHARGE':
        return StatutCours.decharge;
      // Tolérance legacy
      case 'chargement':
        return StatutCours.chargement;
      case 'transit':
        return StatutCours.transit;
      case 'frontiere':
      case 'frontière':
        return StatutCours.frontiere;
      case 'arrive':
      case 'arrivé':
        return StatutCours.arrive;
      case 'decharge':
      case 'déchargé':
        return StatutCours.decharge;
      default:
        return StatutCours.chargement;
    }
  }
}

/// Convertisseur JSON pour l'enum StatutCours
///
/// Aligne la sérialisation avec le schéma SQL (accents) et accepte
/// les variantes accentuées et non accentuées en lecture.
class StatutCoursConverter implements JsonConverter<StatutCours, String> {
  const StatutCoursConverter();

  static StatutCours fromDb(String? value) => StatutCoursDb.parseDb(value);

  static String toDb(StatutCours statut) => statut.db;

  @override
  StatutCours fromJson(String json) => fromDb(json);

  @override
  String toJson(StatutCours statut) => toDb(statut);
}

/// Modèle de cours de route pour ML_PP MVP
/// 
/// Représente un transport de carburant depuis un fournisseur vers un dépôt.
/// Chaque cours contient toutes les informations nécessaires pour le suivi
/// logistique : transporteur, produit, volume, statut, etc.
/// 
/// Ce modèle est utilisé pour :
/// - Le suivi des transports entrants
/// - L'alimentation du module de réception
/// - La traçabilité complète des flux logistiques
/// - La gestion des statuts de progression
/// 
/// Exemple d'utilisation avec Supabase :
/// ```dart
/// final data = await supabase.from('cours_de_route').select().eq('statut', 'transit');
/// final cours = data.map((json) => CoursDeRoute.fromJson(json)).toList();
/// ```
@freezed
class CoursDeRoute with _$CoursDeRoute {
  const factory CoursDeRoute({
    /// Identifiant unique du cours de route (clé primaire)
    /// Généré automatiquement par Supabase (UUID v4)
    required String id,
    
    /// Référence vers `fournisseurs.id`
    /// Fournisseur source du carburant
    @JsonKey(name: 'fournisseur_id') required String fournisseurId,
    
    /// Référence vers `produits.id`
    /// Type de produit transporté (essence, diesel, etc.)
    @JsonKey(name: 'produit_id') required String produitId,
    
    /// Nom du produit (via jointure produits)
    @JsonKey(ignore: true)
    String? produitNom,
    
    /// Code du produit (jointure avec table produits)
    /// Exemple : "ESS", "GO"
    @JsonKey(name: 'produit_code') String? produitCode,
    
    
    
    /// Référence vers `depots.id`
    /// Dépôt de destination du transport
    @JsonKey(name: 'depot_destination_id') required String depotDestinationId,
    
    /// Nom du transporteur
    /// Exemple : "Transport Express SARL"
    String? transporteur,
    
    /// Plaques d'immatriculation du camion
    /// Format : "ABC123" ou "ABC-123"
    @JsonKey(name: 'plaque_camion') String? plaqueCamion,
    
    /// Plaque d'immatriculation de la remorque
    /// Format : "ABC123" ou "ABC-123"
    @JsonKey(name: 'plaque_remorque') String? plaqueRemorque,
    
    /// Nom du chauffeur (legacy or display)
    /// Exemple : "Jean Dupont"
    String? chauffeur,

    /// Champ d'affichage dédié si la colonne `chauffeur_nom` existe côté DB
    @JsonKey(ignore: true)
    String? chauffeurNom,
    
    /// Volume transporté en litres
    /// Volume brut (non corrigé à 15°C)
    double? volume,
    
    /// Date de chargement prévue
    /// Date de départ du fournisseur
    @JsonKey(name: 'date_chargement') DateTime? dateChargement,
    
    /// Date d'arrivée prévue au dépôt
    /// Date estimée d'arrivée
    @JsonKey(name: 'date_arrivee_prevue') DateTime? dateArriveePrevue,
    
    /// Pays de départ
    /// Exemple : "RDC", "Zambie"
    String? pays,
    
    /// Statut actuel du cours de route
    /// Détermine l'étape de progression du transport
    @JsonKey(name: 'statut') @StatutCoursConverter() @Default(StatutCours.chargement) StatutCours statut,
    
    /// Note ou commentaire additionnel
    /// Information complémentaire sur le transport
    String? note,
    
    /// Timestamp de création automatique (`now()`)
    /// Enregistré automatiquement par Supabase lors de l'insertion
    @JsonKey(name: 'created_at') DateTime? createdAt,
    
    /// Timestamp de dernière modification
    /// Mis à jour automatiquement par Supabase lors des modifications
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _CoursDeRoute;

  /// Crée un CoursDeRoute à partir d'un Map JSON (json_serializable)
  factory CoursDeRoute.fromJson(Map<String, dynamic> json) => _$CoursDeRouteFromJson(json);
  
  /// Crée un cours de route vide pour les tests ou initialisation
  /// Tous les champs sont null sauf id, fournisseurId, produitId, depotDestinationId qui sont requis
  factory CoursDeRoute.empty() => const CoursDeRoute(
    id: '',
    fournisseurId: '',
    produitId: '',
    depotDestinationId: '',
  );
  
  /// Crée un CoursDeRoute à partir des données Supabase (snake_case)
  /// 
  /// [data] : Données brutes de Supabase avec les noms de champs en snake_case
  /// 
  /// Retourne :
  /// - `CoursDeRoute` : Le cours de route désérialisé
  /// 
  /// Utilisé pour :
  /// - La conversion directe des données Supabase
  /// - La gestion des noms de champs en snake_case
  /// 
  /// Exemple :
  /// ```dart
  /// final data = await supabase.from('cours_de_route').select().eq('statut', 'transit');
  /// final cours = data.map((json) => CoursDeRoute.fromMap(json)).toList();
  /// ```
  static CoursDeRoute fromMap(Map<String, dynamic> data) {
    // Validation du statut
    final statutString = data['statut'] as String?;
    final statut = StatutCoursConverter.fromDb(statutString);
    
    // Conversion des dates
    DateTime? dateChargement;
    if (data['date_chargement'] != null) {
      dateChargement = DateTime.parse(data['date_chargement'].toString());
    }
    
    DateTime? dateArriveePrevue;
    if (data['date_arrivee_prevue'] != null) {
      dateArriveePrevue = DateTime.parse(data['date_arrivee_prevue'].toString());
    }
    
    DateTime? createdAt;
    if (data['created_at'] != null) {
      createdAt = DateTime.parse(data['created_at'].toString());
    }
    
    DateTime? updatedAt;
    if (data['updated_at'] != null) {
      updatedAt = DateTime.parse(data['updated_at'].toString());
    }
    
    return CoursDeRoute(
      id: (data['id'] ?? '') as String,
      fournisseurId: (data['fournisseur_id'] ?? '') as String,
      produitId: (data['produit_id'] ?? '') as String,
      // jointure produits(nom) -> data['produits']['nom'] si présent, sinon champ aplati produit_nom
      produitNom: (data['produits'] is Map<String, dynamic>)
          ? (data['produits'] as Map<String, dynamic>)['nom'] as String?
          : data['produit_nom'] as String?,
      produitCode: data['produit_code'] as String?,
      depotDestinationId: (data['depot_destination_id'] ?? '') as String,
      transporteur: data['transporteur'] as String?,
      plaqueCamion: data['plaque_camion'] as String?,
      plaqueRemorque: data['plaque_remorque'] as String?,
      // Compatibilité schéma: chauffeur | chauffeur_nom
      chauffeur: (data['chauffeur'] ?? data['chauffeur_nom']) as String?,
      // Affichage dédié si colonne chauffeur_nom à part
      chauffeurNom: data['chauffeur_nom'] as String?,
      volume: (data['volume'] as num?)?.toDouble(),
      dateChargement: dateChargement,
      dateArriveePrevue: dateArriveePrevue,
      // Compatibilité schéma: pays | depart_pays
      pays: (data['pays'] ?? data['depart_pays']) as String?,
      statut: statut,
      note: data['note'] as String?,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Machine d'états sécurisée pour les cours de route
class CoursDeRouteStateMachine {
  /// Transitions autorisées entre les statuts
  static const Map<StatutCours, Set<StatutCours>> allowedNext = {
    StatutCours.chargement: {StatutCours.transit},
    StatutCours.transit: {StatutCours.frontiere},
    StatutCours.frontiere: {StatutCours.arrive},
    StatutCours.arrive: {StatutCours.decharge},
    StatutCours.decharge: <StatutCours>{},
  };

  /// Vérifie si une transition est autorisée
  /// 
  /// [from] : Statut actuel
  /// [to] : Statut cible
  /// [fromReception] : Si la transition vers déchargé provient d'une réception validée
  /// 
  /// Retourne :
  /// - `true` : La transition est autorisée
  /// - `false` : La transition est interdite
  static bool canTransition(StatutCours from, StatutCours to, {bool fromReception = false}) {
    // Vérifier si la transition est dans les transitions autorisées
    if (!allowedNext[from]!.contains(to)) {
      return false;
    }
    
    // Passage à déchargé uniquement via réception validée
    if (to == StatutCours.decharge && !fromReception) {
      return false;
    }
    
    return true;
  }

  /// Retourne les statuts autorisés depuis le statut actuel
  /// 
  /// [current] : Statut actuel
  /// 
  /// Retourne :
  /// - `Set<StatutCours>` : Les statuts autorisés
  static Set<StatutCours> getAllowedNext(StatutCours current) {
    return allowedNext[current] ?? <StatutCours>{};
  }
}

/// Méthodes utilitaires pour les cours de route
class CoursDeRouteUtils {
  /// Vérifie si le cours est actif (non déchargé)
  /// 
  /// [cours] : Le cours de route à vérifier
  /// 
  /// Retourne :
  /// - `true` : Le cours est en cours (chargement, transit, frontiere, arrive)
  /// - `false` : Le cours est terminé (decharge)
  static bool isActif(CoursDeRoute cours) => cours.statut != StatutCours.decharge;
  
  /// Vérifie si le cours peut passer au statut suivant
  /// 
  /// [cours] : Le cours de route à vérifier
  /// 
  /// Retourne :
  /// - `true` : Le cours peut progresser vers le statut suivant
  /// - `false` : Le cours est au statut final (decharge)
  static bool peutProgresser(CoursDeRoute cours) => cours.statut != StatutCours.decharge;
  
  /// Retourne le statut suivant dans la progression logique
  /// 
  /// [cours] : Le cours de route
  /// 
  /// Retourne :
  /// - `StatutCours` : Le prochain statut dans la séquence
  /// - `null` : Si le cours est au statut final
  static StatutCours? getStatutSuivant(CoursDeRoute cours) {
    switch (cours.statut) {
      case StatutCours.chargement:
        return StatutCours.transit;
      case StatutCours.transit:
        return StatutCours.frontiere;
      case StatutCours.frontiere:
        return StatutCours.arrive;
      case StatutCours.arrive:
        return StatutCours.decharge;
      case StatutCours.decharge:
        return null; // Statut final
    }
  }
}
