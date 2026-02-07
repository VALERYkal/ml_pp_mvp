// Module Fournisseurs — Sprint 1 (lecture seule).
// Source de vérité : public.fournisseurs. Champs exacts, pas de status/actif.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'fournisseur.freezed.dart';
part 'fournisseur.g.dart';

/// Modèle immutable d'un fournisseur (table public.fournisseurs).
@freezed
class Fournisseur with _$Fournisseur {
  const factory Fournisseur({
    required String id,
    required String nom,
    @JsonKey(name: 'contact_personne') String? contactPersonne,
    String? email,
    String? telephone,
    String? adresse,
    String? pays,
    @JsonKey(name: 'note_supplementaire') String? noteSupplementaire,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Fournisseur;

  factory Fournisseur.fromJson(Map<String, dynamic> json) =>
      _$FournisseurFromJson(json);
}
