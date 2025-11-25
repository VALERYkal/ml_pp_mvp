import 'package:freezed_annotation/freezed_annotation.dart';

part 'profil.freezed.dart';
part 'profil.g.dart';

@freezed
class Profil with _$Profil {
  const factory Profil({
    required String id,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'nom_complet') String? nomComplet,
    required String role,
    @JsonKey(name: 'depot_id') String? depotId,
    String? email,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _Profil;

  factory Profil.fromJson(Map<String, dynamic> json) => _$ProfilFromJson(json);
}
