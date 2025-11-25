import 'package:freezed_annotation/freezed_annotation.dart';

part 'cours_de_route.freezed.dart';
part 'cours_de_route.g.dart';

enum StatutCours {
  chargement,
  transit,
  frontiere,
  arrive,
  decharge,
  inconnu,
}

extension StatutCoursDbMapper on StatutCours {
  /// Valeur à stocker en base (Supabase)
  String toDb() {
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
      case StatutCours.inconnu:
      default:
        return 'CHARGEMENT';
    }
  }

  /// Label lisible pour la UI
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
      case StatutCours.inconnu:
      default:
        return 'Inconnu';
    }
  }
}

/// Conversion inverse : valeur DB (texte) -> enum
StatutCours statutCoursFromDb(dynamic raw) {
  if (raw is! String) return StatutCours.inconnu;

  switch (raw.toUpperCase()) {
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
    default:
      return StatutCours.inconnu;
  }
}

/// Retourne le prochain statut métier dans le flux standard.
StatutCours? nextStatutCours(StatutCours current) {
  switch (current) {
    case StatutCours.chargement:
      return StatutCours.transit;
    case StatutCours.transit:
      return StatutCours.frontiere;
    case StatutCours.frontiere:
      return StatutCours.arrive;
    case StatutCours.arrive:
      return StatutCours.decharge;
    case StatutCours.decharge:
    case StatutCours.inconnu:
      return null;
  }
}

@freezed
class CoursDeRoute with _$CoursDeRoute {
  const factory CoursDeRoute({
    required String id,
    @JsonKey(name: 'fournisseur_id') required String fournisseurId,
    @JsonKey(name: 'produit_id') required String produitId,

    // champs d'affichage non sérialisés
    @JsonKey(includeFromJson: false, includeToJson: false) String? produitNom,

    @JsonKey(name: 'produit_code') String? produitCode,
    @JsonKey(name: 'depot_destination_id') required String depotDestinationId,
    String? transporteur,
    @JsonKey(name: 'plaque_camion') String? plaqueCamion,
    @JsonKey(name: 'plaque_remorque') String? plaqueRemorque,
    String? chauffeur,
    @JsonKey(includeFromJson: false, includeToJson: false) String? chauffeurNom,
    double? volume,
    String? pays,
    @JsonKey(name: 'date_chargement') DateTime? dateChargement,
    @JsonKey(name: 'date_arrivee_prevue') DateTime? dateArriveePrevue,
    @JsonKey(name: 'statut') required StatutCours statut,
    String? note,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _CoursDeRoute;

  factory CoursDeRoute.fromJson(Map<String, dynamic> json) =>
      _$CoursDeRouteFromJson(json);

  /// Mapping sûr pour les données Supabase (rows)
  factory CoursDeRoute.fromMap(Map<String, dynamic> map) {
    final json = Map<String, dynamic>.from(map);

    if (json.containsKey('statut')) {
      json['statut'] = statutCoursFromDb(json['statut']).name;
    }

    return CoursDeRoute.fromJson(json);
  }
}
