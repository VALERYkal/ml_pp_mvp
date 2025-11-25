// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sortie_produit.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SortieProduit _$SortieProduitFromJson(Map<String, dynamic> json) {
  return _SortieProduit.fromJson(json);
}

/// @nodoc
mixin _$SortieProduit {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'citerne_id')
  String get citerneId => throw _privateConstructorUsedError;
  @JsonKey(name: 'produit_id')
  String get produitId => throw _privateConstructorUsedError;
  @JsonKey(name: 'client_id')
  String? get clientId => throw _privateConstructorUsedError;
  @JsonKey(name: 'partenaire_id')
  String? get partenaireId => throw _privateConstructorUsedError;
  @JsonKey(name: 'index_avant')
  double get indexAvant => throw _privateConstructorUsedError;
  @JsonKey(name: 'index_apres')
  double get indexApres => throw _privateConstructorUsedError;
  @JsonKey(name: 'volume_ambiant')
  double? get volumeAmbiant => throw _privateConstructorUsedError;
  @JsonKey(name: 'volume_corrige_15c')
  double? get volumeCorrige15c => throw _privateConstructorUsedError;
  @JsonKey(name: 'temperature_ambiante_c')
  double? get temperatureAmbianteC => throw _privateConstructorUsedError;
  @JsonKey(name: 'densite_a_15')
  double? get densiteA15 => throw _privateConstructorUsedError;
  @JsonKey(name: 'statut')
  String get statut => throw _privateConstructorUsedError;
  @JsonKey(name: 'proprietaire_type')
  String get proprietaireType => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_sortie')
  DateTime? get dateSortie => throw _privateConstructorUsedError;
  @JsonKey(name: 'chauffeur_nom')
  String? get chauffeurNom => throw _privateConstructorUsedError;
  @JsonKey(name: 'plaque_camion')
  String? get plaqueCamion => throw _privateConstructorUsedError;
  @JsonKey(name: 'plaque_remorque')
  String? get plaqueRemorque => throw _privateConstructorUsedError;
  @JsonKey(name: 'transporteur')
  String? get transporteur => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  String? get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'validated_by')
  String? get validatedBy => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;

  /// Serializes this SortieProduit to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SortieProduit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SortieProduitCopyWith<SortieProduit> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SortieProduitCopyWith<$Res> {
  factory $SortieProduitCopyWith(
          SortieProduit value, $Res Function(SortieProduit) then) =
      _$SortieProduitCopyWithImpl<$Res, SortieProduit>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'citerne_id') String citerneId,
      @JsonKey(name: 'produit_id') String produitId,
      @JsonKey(name: 'client_id') String? clientId,
      @JsonKey(name: 'partenaire_id') String? partenaireId,
      @JsonKey(name: 'index_avant') double indexAvant,
      @JsonKey(name: 'index_apres') double indexApres,
      @JsonKey(name: 'volume_ambiant') double? volumeAmbiant,
      @JsonKey(name: 'volume_corrige_15c') double? volumeCorrige15c,
      @JsonKey(name: 'temperature_ambiante_c') double? temperatureAmbianteC,
      @JsonKey(name: 'densite_a_15') double? densiteA15,
      @JsonKey(name: 'statut') String statut,
      @JsonKey(name: 'proprietaire_type') String proprietaireType,
      @JsonKey(name: 'date_sortie') DateTime? dateSortie,
      @JsonKey(name: 'chauffeur_nom') String? chauffeurNom,
      @JsonKey(name: 'plaque_camion') String? plaqueCamion,
      @JsonKey(name: 'plaque_remorque') String? plaqueRemorque,
      @JsonKey(name: 'transporteur') String? transporteur,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'created_by') String? createdBy,
      @JsonKey(name: 'validated_by') String? validatedBy,
      String? note});
}

/// @nodoc
class _$SortieProduitCopyWithImpl<$Res, $Val extends SortieProduit>
    implements $SortieProduitCopyWith<$Res> {
  _$SortieProduitCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SortieProduit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? citerneId = null,
    Object? produitId = null,
    Object? clientId = freezed,
    Object? partenaireId = freezed,
    Object? indexAvant = null,
    Object? indexApres = null,
    Object? volumeAmbiant = freezed,
    Object? volumeCorrige15c = freezed,
    Object? temperatureAmbianteC = freezed,
    Object? densiteA15 = freezed,
    Object? statut = null,
    Object? proprietaireType = null,
    Object? dateSortie = freezed,
    Object? chauffeurNom = freezed,
    Object? plaqueCamion = freezed,
    Object? plaqueRemorque = freezed,
    Object? transporteur = freezed,
    Object? createdAt = freezed,
    Object? createdBy = freezed,
    Object? validatedBy = freezed,
    Object? note = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      citerneId: null == citerneId
          ? _value.citerneId
          : citerneId // ignore: cast_nullable_to_non_nullable
              as String,
      produitId: null == produitId
          ? _value.produitId
          : produitId // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: freezed == clientId
          ? _value.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String?,
      partenaireId: freezed == partenaireId
          ? _value.partenaireId
          : partenaireId // ignore: cast_nullable_to_non_nullable
              as String?,
      indexAvant: null == indexAvant
          ? _value.indexAvant
          : indexAvant // ignore: cast_nullable_to_non_nullable
              as double,
      indexApres: null == indexApres
          ? _value.indexApres
          : indexApres // ignore: cast_nullable_to_non_nullable
              as double,
      volumeAmbiant: freezed == volumeAmbiant
          ? _value.volumeAmbiant
          : volumeAmbiant // ignore: cast_nullable_to_non_nullable
              as double?,
      volumeCorrige15c: freezed == volumeCorrige15c
          ? _value.volumeCorrige15c
          : volumeCorrige15c // ignore: cast_nullable_to_non_nullable
              as double?,
      temperatureAmbianteC: freezed == temperatureAmbianteC
          ? _value.temperatureAmbianteC
          : temperatureAmbianteC // ignore: cast_nullable_to_non_nullable
              as double?,
      densiteA15: freezed == densiteA15
          ? _value.densiteA15
          : densiteA15 // ignore: cast_nullable_to_non_nullable
              as double?,
      statut: null == statut
          ? _value.statut
          : statut // ignore: cast_nullable_to_non_nullable
              as String,
      proprietaireType: null == proprietaireType
          ? _value.proprietaireType
          : proprietaireType // ignore: cast_nullable_to_non_nullable
              as String,
      dateSortie: freezed == dateSortie
          ? _value.dateSortie
          : dateSortie // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      chauffeurNom: freezed == chauffeurNom
          ? _value.chauffeurNom
          : chauffeurNom // ignore: cast_nullable_to_non_nullable
              as String?,
      plaqueCamion: freezed == plaqueCamion
          ? _value.plaqueCamion
          : plaqueCamion // ignore: cast_nullable_to_non_nullable
              as String?,
      plaqueRemorque: freezed == plaqueRemorque
          ? _value.plaqueRemorque
          : plaqueRemorque // ignore: cast_nullable_to_non_nullable
              as String?,
      transporteur: freezed == transporteur
          ? _value.transporteur
          : transporteur // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      validatedBy: freezed == validatedBy
          ? _value.validatedBy
          : validatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SortieProduitImplCopyWith<$Res>
    implements $SortieProduitCopyWith<$Res> {
  factory _$$SortieProduitImplCopyWith(
          _$SortieProduitImpl value, $Res Function(_$SortieProduitImpl) then) =
      __$$SortieProduitImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'citerne_id') String citerneId,
      @JsonKey(name: 'produit_id') String produitId,
      @JsonKey(name: 'client_id') String? clientId,
      @JsonKey(name: 'partenaire_id') String? partenaireId,
      @JsonKey(name: 'index_avant') double indexAvant,
      @JsonKey(name: 'index_apres') double indexApres,
      @JsonKey(name: 'volume_ambiant') double? volumeAmbiant,
      @JsonKey(name: 'volume_corrige_15c') double? volumeCorrige15c,
      @JsonKey(name: 'temperature_ambiante_c') double? temperatureAmbianteC,
      @JsonKey(name: 'densite_a_15') double? densiteA15,
      @JsonKey(name: 'statut') String statut,
      @JsonKey(name: 'proprietaire_type') String proprietaireType,
      @JsonKey(name: 'date_sortie') DateTime? dateSortie,
      @JsonKey(name: 'chauffeur_nom') String? chauffeurNom,
      @JsonKey(name: 'plaque_camion') String? plaqueCamion,
      @JsonKey(name: 'plaque_remorque') String? plaqueRemorque,
      @JsonKey(name: 'transporteur') String? transporteur,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'created_by') String? createdBy,
      @JsonKey(name: 'validated_by') String? validatedBy,
      String? note});
}

/// @nodoc
class __$$SortieProduitImplCopyWithImpl<$Res>
    extends _$SortieProduitCopyWithImpl<$Res, _$SortieProduitImpl>
    implements _$$SortieProduitImplCopyWith<$Res> {
  __$$SortieProduitImplCopyWithImpl(
      _$SortieProduitImpl _value, $Res Function(_$SortieProduitImpl) _then)
      : super(_value, _then);

  /// Create a copy of SortieProduit
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? citerneId = null,
    Object? produitId = null,
    Object? clientId = freezed,
    Object? partenaireId = freezed,
    Object? indexAvant = null,
    Object? indexApres = null,
    Object? volumeAmbiant = freezed,
    Object? volumeCorrige15c = freezed,
    Object? temperatureAmbianteC = freezed,
    Object? densiteA15 = freezed,
    Object? statut = null,
    Object? proprietaireType = null,
    Object? dateSortie = freezed,
    Object? chauffeurNom = freezed,
    Object? plaqueCamion = freezed,
    Object? plaqueRemorque = freezed,
    Object? transporteur = freezed,
    Object? createdAt = freezed,
    Object? createdBy = freezed,
    Object? validatedBy = freezed,
    Object? note = freezed,
  }) {
    return _then(_$SortieProduitImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      citerneId: null == citerneId
          ? _value.citerneId
          : citerneId // ignore: cast_nullable_to_non_nullable
              as String,
      produitId: null == produitId
          ? _value.produitId
          : produitId // ignore: cast_nullable_to_non_nullable
              as String,
      clientId: freezed == clientId
          ? _value.clientId
          : clientId // ignore: cast_nullable_to_non_nullable
              as String?,
      partenaireId: freezed == partenaireId
          ? _value.partenaireId
          : partenaireId // ignore: cast_nullable_to_non_nullable
              as String?,
      indexAvant: null == indexAvant
          ? _value.indexAvant
          : indexAvant // ignore: cast_nullable_to_non_nullable
              as double,
      indexApres: null == indexApres
          ? _value.indexApres
          : indexApres // ignore: cast_nullable_to_non_nullable
              as double,
      volumeAmbiant: freezed == volumeAmbiant
          ? _value.volumeAmbiant
          : volumeAmbiant // ignore: cast_nullable_to_non_nullable
              as double?,
      volumeCorrige15c: freezed == volumeCorrige15c
          ? _value.volumeCorrige15c
          : volumeCorrige15c // ignore: cast_nullable_to_non_nullable
              as double?,
      temperatureAmbianteC: freezed == temperatureAmbianteC
          ? _value.temperatureAmbianteC
          : temperatureAmbianteC // ignore: cast_nullable_to_non_nullable
              as double?,
      densiteA15: freezed == densiteA15
          ? _value.densiteA15
          : densiteA15 // ignore: cast_nullable_to_non_nullable
              as double?,
      statut: null == statut
          ? _value.statut
          : statut // ignore: cast_nullable_to_non_nullable
              as String,
      proprietaireType: null == proprietaireType
          ? _value.proprietaireType
          : proprietaireType // ignore: cast_nullable_to_non_nullable
              as String,
      dateSortie: freezed == dateSortie
          ? _value.dateSortie
          : dateSortie // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      chauffeurNom: freezed == chauffeurNom
          ? _value.chauffeurNom
          : chauffeurNom // ignore: cast_nullable_to_non_nullable
              as String?,
      plaqueCamion: freezed == plaqueCamion
          ? _value.plaqueCamion
          : plaqueCamion // ignore: cast_nullable_to_non_nullable
              as String?,
      plaqueRemorque: freezed == plaqueRemorque
          ? _value.plaqueRemorque
          : plaqueRemorque // ignore: cast_nullable_to_non_nullable
              as String?,
      transporteur: freezed == transporteur
          ? _value.transporteur
          : transporteur // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      validatedBy: freezed == validatedBy
          ? _value.validatedBy
          : validatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SortieProduitImpl implements _SortieProduit {
  const _$SortieProduitImpl(
      {required this.id,
      @JsonKey(name: 'citerne_id') required this.citerneId,
      @JsonKey(name: 'produit_id') required this.produitId,
      @JsonKey(name: 'client_id') this.clientId,
      @JsonKey(name: 'partenaire_id') this.partenaireId,
      @JsonKey(name: 'index_avant') required this.indexAvant,
      @JsonKey(name: 'index_apres') required this.indexApres,
      @JsonKey(name: 'volume_ambiant') this.volumeAmbiant,
      @JsonKey(name: 'volume_corrige_15c') this.volumeCorrige15c,
      @JsonKey(name: 'temperature_ambiante_c') this.temperatureAmbianteC,
      @JsonKey(name: 'densite_a_15') this.densiteA15,
      @JsonKey(name: 'statut') required this.statut,
      @JsonKey(name: 'proprietaire_type') required this.proprietaireType,
      @JsonKey(name: 'date_sortie') this.dateSortie,
      @JsonKey(name: 'chauffeur_nom') this.chauffeurNom,
      @JsonKey(name: 'plaque_camion') this.plaqueCamion,
      @JsonKey(name: 'plaque_remorque') this.plaqueRemorque,
      @JsonKey(name: 'transporteur') this.transporteur,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'created_by') this.createdBy,
      @JsonKey(name: 'validated_by') this.validatedBy,
      this.note});

  factory _$SortieProduitImpl.fromJson(Map<String, dynamic> json) =>
      _$$SortieProduitImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'citerne_id')
  final String citerneId;
  @override
  @JsonKey(name: 'produit_id')
  final String produitId;
  @override
  @JsonKey(name: 'client_id')
  final String? clientId;
  @override
  @JsonKey(name: 'partenaire_id')
  final String? partenaireId;
  @override
  @JsonKey(name: 'index_avant')
  final double indexAvant;
  @override
  @JsonKey(name: 'index_apres')
  final double indexApres;
  @override
  @JsonKey(name: 'volume_ambiant')
  final double? volumeAmbiant;
  @override
  @JsonKey(name: 'volume_corrige_15c')
  final double? volumeCorrige15c;
  @override
  @JsonKey(name: 'temperature_ambiante_c')
  final double? temperatureAmbianteC;
  @override
  @JsonKey(name: 'densite_a_15')
  final double? densiteA15;
  @override
  @JsonKey(name: 'statut')
  final String statut;
  @override
  @JsonKey(name: 'proprietaire_type')
  final String proprietaireType;
  @override
  @JsonKey(name: 'date_sortie')
  final DateTime? dateSortie;
  @override
  @JsonKey(name: 'chauffeur_nom')
  final String? chauffeurNom;
  @override
  @JsonKey(name: 'plaque_camion')
  final String? plaqueCamion;
  @override
  @JsonKey(name: 'plaque_remorque')
  final String? plaqueRemorque;
  @override
  @JsonKey(name: 'transporteur')
  final String? transporteur;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @override
  @JsonKey(name: 'validated_by')
  final String? validatedBy;
  @override
  final String? note;

  @override
  String toString() {
    return 'SortieProduit(id: $id, citerneId: $citerneId, produitId: $produitId, clientId: $clientId, partenaireId: $partenaireId, indexAvant: $indexAvant, indexApres: $indexApres, volumeAmbiant: $volumeAmbiant, volumeCorrige15c: $volumeCorrige15c, temperatureAmbianteC: $temperatureAmbianteC, densiteA15: $densiteA15, statut: $statut, proprietaireType: $proprietaireType, dateSortie: $dateSortie, chauffeurNom: $chauffeurNom, plaqueCamion: $plaqueCamion, plaqueRemorque: $plaqueRemorque, transporteur: $transporteur, createdAt: $createdAt, createdBy: $createdBy, validatedBy: $validatedBy, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SortieProduitImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.citerneId, citerneId) ||
                other.citerneId == citerneId) &&
            (identical(other.produitId, produitId) ||
                other.produitId == produitId) &&
            (identical(other.clientId, clientId) ||
                other.clientId == clientId) &&
            (identical(other.partenaireId, partenaireId) ||
                other.partenaireId == partenaireId) &&
            (identical(other.indexAvant, indexAvant) ||
                other.indexAvant == indexAvant) &&
            (identical(other.indexApres, indexApres) ||
                other.indexApres == indexApres) &&
            (identical(other.volumeAmbiant, volumeAmbiant) ||
                other.volumeAmbiant == volumeAmbiant) &&
            (identical(other.volumeCorrige15c, volumeCorrige15c) ||
                other.volumeCorrige15c == volumeCorrige15c) &&
            (identical(other.temperatureAmbianteC, temperatureAmbianteC) ||
                other.temperatureAmbianteC == temperatureAmbianteC) &&
            (identical(other.densiteA15, densiteA15) ||
                other.densiteA15 == densiteA15) &&
            (identical(other.statut, statut) || other.statut == statut) &&
            (identical(other.proprietaireType, proprietaireType) ||
                other.proprietaireType == proprietaireType) &&
            (identical(other.dateSortie, dateSortie) ||
                other.dateSortie == dateSortie) &&
            (identical(other.chauffeurNom, chauffeurNom) ||
                other.chauffeurNom == chauffeurNom) &&
            (identical(other.plaqueCamion, plaqueCamion) ||
                other.plaqueCamion == plaqueCamion) &&
            (identical(other.plaqueRemorque, plaqueRemorque) ||
                other.plaqueRemorque == plaqueRemorque) &&
            (identical(other.transporteur, transporteur) ||
                other.transporteur == transporteur) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.validatedBy, validatedBy) ||
                other.validatedBy == validatedBy) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        citerneId,
        produitId,
        clientId,
        partenaireId,
        indexAvant,
        indexApres,
        volumeAmbiant,
        volumeCorrige15c,
        temperatureAmbianteC,
        densiteA15,
        statut,
        proprietaireType,
        dateSortie,
        chauffeurNom,
        plaqueCamion,
        plaqueRemorque,
        transporteur,
        createdAt,
        createdBy,
        validatedBy,
        note
      ]);

  /// Create a copy of SortieProduit
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SortieProduitImplCopyWith<_$SortieProduitImpl> get copyWith =>
      __$$SortieProduitImplCopyWithImpl<_$SortieProduitImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SortieProduitImplToJson(
      this,
    );
  }
}

abstract class _SortieProduit implements SortieProduit {
  const factory _SortieProduit(
      {required final String id,
      @JsonKey(name: 'citerne_id') required final String citerneId,
      @JsonKey(name: 'produit_id') required final String produitId,
      @JsonKey(name: 'client_id') final String? clientId,
      @JsonKey(name: 'partenaire_id') final String? partenaireId,
      @JsonKey(name: 'index_avant') required final double indexAvant,
      @JsonKey(name: 'index_apres') required final double indexApres,
      @JsonKey(name: 'volume_ambiant') final double? volumeAmbiant,
      @JsonKey(name: 'volume_corrige_15c') final double? volumeCorrige15c,
      @JsonKey(name: 'temperature_ambiante_c')
      final double? temperatureAmbianteC,
      @JsonKey(name: 'densite_a_15') final double? densiteA15,
      @JsonKey(name: 'statut') required final String statut,
      @JsonKey(name: 'proprietaire_type')
      required final String proprietaireType,
      @JsonKey(name: 'date_sortie') final DateTime? dateSortie,
      @JsonKey(name: 'chauffeur_nom') final String? chauffeurNom,
      @JsonKey(name: 'plaque_camion') final String? plaqueCamion,
      @JsonKey(name: 'plaque_remorque') final String? plaqueRemorque,
      @JsonKey(name: 'transporteur') final String? transporteur,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      @JsonKey(name: 'created_by') final String? createdBy,
      @JsonKey(name: 'validated_by') final String? validatedBy,
      final String? note}) = _$SortieProduitImpl;

  factory _SortieProduit.fromJson(Map<String, dynamic> json) =
      _$SortieProduitImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'citerne_id')
  String get citerneId;
  @override
  @JsonKey(name: 'produit_id')
  String get produitId;
  @override
  @JsonKey(name: 'client_id')
  String? get clientId;
  @override
  @JsonKey(name: 'partenaire_id')
  String? get partenaireId;
  @override
  @JsonKey(name: 'index_avant')
  double get indexAvant;
  @override
  @JsonKey(name: 'index_apres')
  double get indexApres;
  @override
  @JsonKey(name: 'volume_ambiant')
  double? get volumeAmbiant;
  @override
  @JsonKey(name: 'volume_corrige_15c')
  double? get volumeCorrige15c;
  @override
  @JsonKey(name: 'temperature_ambiante_c')
  double? get temperatureAmbianteC;
  @override
  @JsonKey(name: 'densite_a_15')
  double? get densiteA15;
  @override
  @JsonKey(name: 'statut')
  String get statut;
  @override
  @JsonKey(name: 'proprietaire_type')
  String get proprietaireType;
  @override
  @JsonKey(name: 'date_sortie')
  DateTime? get dateSortie;
  @override
  @JsonKey(name: 'chauffeur_nom')
  String? get chauffeurNom;
  @override
  @JsonKey(name: 'plaque_camion')
  String? get plaqueCamion;
  @override
  @JsonKey(name: 'plaque_remorque')
  String? get plaqueRemorque;
  @override
  @JsonKey(name: 'transporteur')
  String? get transporteur;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'created_by')
  String? get createdBy;
  @override
  @JsonKey(name: 'validated_by')
  String? get validatedBy;
  @override
  String? get note;

  /// Create a copy of SortieProduit
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SortieProduitImplCopyWith<_$SortieProduitImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
