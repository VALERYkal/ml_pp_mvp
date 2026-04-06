// 📌 Module : Lots — Models
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2026-04-06
// 🗃️ Source SQL : Table `public.fournisseur_lot`
// 🧭 Description : Modèle de lot fournisseur pour regrouper plusieurs CDR
// et préparer le rapprochement logistique / facturation.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'fournisseur_lot.freezed.dart';
part 'fournisseur_lot.g.dart';

/// Statuts possibles d'un lot fournisseur.
///
/// - ouvert  : lot encore en cours d'utilisation
/// - cloture : plus de nouveaux CDR attendus
/// - facture : lot déjà facturé côté fournisseur
enum StatutFournisseurLot {
  @JsonValue('ouvert')
  ouvert,

  @JsonValue('cloture')
  cloture,

  @JsonValue('facture')
  facture,
}

/// Helpers de mapping DB / UI pour le statut de lot.
extension StatutFournisseurLotX on StatutFournisseurLot {
  /// Valeur DB.
  String get db {
    switch (this) {
      case StatutFournisseurLot.ouvert:
        return 'ouvert';
      case StatutFournisseurLot.cloture:
        return 'cloture';
      case StatutFournisseurLot.facture:
        return 'facture';
    }
  }

  /// Libellé user-friendly.
  String get label {
    switch (this) {
      case StatutFournisseurLot.ouvert:
        return 'Ouvert';
      case StatutFournisseurLot.cloture:
        return 'Clôturé';
      case StatutFournisseurLot.facture:
        return 'Facturé';
    }
  }

  static StatutFournisseurLot parseDb(String? raw) {
    switch (raw) {
      case 'ouvert':
        return StatutFournisseurLot.ouvert;
      case 'cloture':
      case 'clôturé':
      case 'cloturé':
        return StatutFournisseurLot.cloture;
      case 'facture':
      case 'facturé':
        return StatutFournisseurLot.facture;
      default:
        return StatutFournisseurLot.ouvert;
    }
  }
}

/// Convertisseur JSON pour StatutFournisseurLot.
class StatutFournisseurLotConverter
    implements JsonConverter<StatutFournisseurLot, String> {
  const StatutFournisseurLotConverter();

  static StatutFournisseurLot fromDb(String? value) =>
      StatutFournisseurLotX.parseDb(value);

  static String toDb(StatutFournisseurLot statut) => statut.db;

  @override
  StatutFournisseurLot fromJson(String json) => fromDb(json);

  @override
  String toJson(StatutFournisseurLot object) => toDb(object);
}

/// Modèle de lot fournisseur.
///
/// Représente un regroupement logique de plusieurs CDR provenant d'un même
/// fournisseur et d'un même produit.
///
/// Ce modèle sert à :
/// - regrouper plusieurs camions sous une même référence fournisseur
/// - préparer le rapprochement logistique
/// - préparer le rapprochement de facturation
@freezed
class FournisseurLot with _$FournisseurLot {
  const factory FournisseurLot({
    /// Identifiant unique du lot
    required String id,

    /// Référence vers `fournisseurs.id`
    @JsonKey(name: 'fournisseur_id') required String fournisseurId,

    /// Nom du fournisseur (jointure / affichage)
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? fournisseurNom,

    /// Référence vers `produits.id`
    @JsonKey(name: 'produit_id') required String produitId,

    /// Nom du produit (jointure / affichage)
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? produitNom,

    /// Code produit (jointure / affichage)
    @JsonKey(name: 'produit_code') String? produitCode,

    /// Référence métier fournisseur
    required String reference,

    /// Date du lot
    @JsonKey(name: 'date_lot') DateTime? dateLot,

    /// Statut du lot
    @JsonKey(name: 'statut')
    @StatutFournisseurLotConverter()
    @Default(StatutFournisseurLot.ouvert)
    StatutFournisseurLot statut,

    /// Note libre
    String? note,

    /// Date de création
    @JsonKey(name: 'created_at') DateTime? createdAt,

    /// Date de mise à jour
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _FournisseurLot;

  factory FournisseurLot.fromJson(Map<String, dynamic> json) =>
      _$FournisseurLotFromJson(json);

  factory FournisseurLot.empty() => const FournisseurLot(
    id: '',
    fournisseurId: '',
    produitId: '',
    reference: '',
  );

  /// Mapping direct depuis un row Supabase.
  static FournisseurLot fromMap(Map<String, dynamic> data) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.parse(value.toString());
    }

    return FournisseurLot(
      id: (data['id'] ?? '') as String,
      fournisseurId: (data['fournisseur_id'] ?? '') as String,
      fournisseurNom: (data['fournisseurs'] is Map<String, dynamic>)
          ? (data['fournisseurs'] as Map<String, dynamic>)['nom'] as String?
          : data['fournisseur_nom'] as String?,
      produitId: (data['produit_id'] ?? '') as String,
      produitNom: (data['produits'] is Map<String, dynamic>)
          ? (data['produits'] as Map<String, dynamic>)['nom'] as String?
          : data['produit_nom'] as String?,
      produitCode: data['produit_code'] as String?,
      reference: (data['reference'] ?? '') as String,
      dateLot: parseDate(data['date_lot']),
      statut: StatutFournisseurLotConverter.fromDb(data['statut'] as String?),
      note: data['note'] as String?,
      createdAt: parseDate(data['created_at']),
      updatedAt: parseDate(data['updated_at']),
    );
  }
}