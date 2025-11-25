// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reception.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Reception _$ReceptionFromJson(Map<String, dynamic> json) {
  return _Reception.fromJson(json);
}

/// @nodoc
mixin _$Reception {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'cours_de_route_id')
  String get coursDeRouteId => throw _privateConstructorUsedError;
  @JsonKey(name: 'citerne_id')
  String get citerneId => throw _privateConstructorUsedError;
  @JsonKey(name: 'produit_id')
  String get produitId => throw _privateConstructorUsedError;
  @JsonKey(name: 'partenaire_id')
  String? get partenaireId => throw _privateConstructorUsedError;
  @JsonKey(name: 'index_avant')
  double get indexAvant => throw _privateConstructorUsedError;
  @JsonKey(name: 'index_apres')
  double get indexApres => throw _privateConstructorUsedError;
  @JsonKey(name: 'temperature_ambiante_c')
  double? get temperatureAmbianteC => throw _privateConstructorUsedError;
  @JsonKey(name: 'densite_a_15')
  double? get densiteA15 => throw _privateConstructorUsedError;
  @JsonKey(name: 'volume_corrige_15c')
  double? get volumeCorrige15c => throw _privateConstructorUsedError;
  @JsonKey(name: 'volume_ambiant')
  double? get volumeAmbiant => throw _privateConstructorUsedError;
  @JsonKey(name: 'proprietaire_type')
  @OwnerTypeConverter()
  OwnerType get proprietaireType => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  String? get statut => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  String? get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'validated_by')
  String? get validatedBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_reception')
  DateTime? get dateReception => throw _privateConstructorUsedError;

  /// Serializes this Reception to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Reception
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReceptionCopyWith<Reception> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReceptionCopyWith<$Res> {
  factory $ReceptionCopyWith(Reception value, $Res Function(Reception) then) =
      _$ReceptionCopyWithImpl<$Res, Reception>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'cours_de_route_id') String coursDeRouteId,
      @JsonKey(name: 'citerne_id') String citerneId,
      @JsonKey(name: 'produit_id') String produitId,
      @JsonKey(name: 'partenaire_id') String? partenaireId,
      @JsonKey(name: 'index_avant') double indexAvant,
      @JsonKey(name: 'index_apres') double indexApres,
      @JsonKey(name: 'temperature_ambiante_c') double? temperatureAmbianteC,
      @JsonKey(name: 'densite_a_15') double? densiteA15,
      @JsonKey(name: 'volume_corrige_15c') double? volumeCorrige15c,
      @JsonKey(name: 'volume_ambiant') double? volumeAmbiant,
      @JsonKey(name: 'proprietaire_type')
      @OwnerTypeConverter()
      OwnerType proprietaireType,
      String? note,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      String? statut,
      @JsonKey(name: 'created_by') String? createdBy,
      @JsonKey(name: 'validated_by') String? validatedBy,
      @JsonKey(name: 'date_reception') DateTime? dateReception});
}

/// @nodoc
class _$ReceptionCopyWithImpl<$Res, $Val extends Reception>
    implements $ReceptionCopyWith<$Res> {
  _$ReceptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Reception
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? coursDeRouteId = null,
    Object? citerneId = null,
    Object? produitId = null,
    Object? partenaireId = freezed,
    Object? indexAvant = null,
    Object? indexApres = null,
    Object? temperatureAmbianteC = freezed,
    Object? densiteA15 = freezed,
    Object? volumeCorrige15c = freezed,
    Object? volumeAmbiant = freezed,
    Object? proprietaireType = null,
    Object? note = freezed,
    Object? createdAt = freezed,
    Object? statut = freezed,
    Object? createdBy = freezed,
    Object? validatedBy = freezed,
    Object? dateReception = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      coursDeRouteId: null == coursDeRouteId
          ? _value.coursDeRouteId
          : coursDeRouteId // ignore: cast_nullable_to_non_nullable
              as String,
      citerneId: null == citerneId
          ? _value.citerneId
          : citerneId // ignore: cast_nullable_to_non_nullable
              as String,
      produitId: null == produitId
          ? _value.produitId
          : produitId // ignore: cast_nullable_to_non_nullable
              as String,
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
      temperatureAmbianteC: freezed == temperatureAmbianteC
          ? _value.temperatureAmbianteC
          : temperatureAmbianteC // ignore: cast_nullable_to_non_nullable
              as double?,
      densiteA15: freezed == densiteA15
          ? _value.densiteA15
          : densiteA15 // ignore: cast_nullable_to_non_nullable
              as double?,
      volumeCorrige15c: freezed == volumeCorrige15c
          ? _value.volumeCorrige15c
          : volumeCorrige15c // ignore: cast_nullable_to_non_nullable
              as double?,
      volumeAmbiant: freezed == volumeAmbiant
          ? _value.volumeAmbiant
          : volumeAmbiant // ignore: cast_nullable_to_non_nullable
              as double?,
      proprietaireType: null == proprietaireType
          ? _value.proprietaireType
          : proprietaireType // ignore: cast_nullable_to_non_nullable
              as OwnerType,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      statut: freezed == statut
          ? _value.statut
          : statut // ignore: cast_nullable_to_non_nullable
              as String?,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      validatedBy: freezed == validatedBy
          ? _value.validatedBy
          : validatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      dateReception: freezed == dateReception
          ? _value.dateReception
          : dateReception // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ReceptionImplCopyWith<$Res>
    implements $ReceptionCopyWith<$Res> {
  factory _$$ReceptionImplCopyWith(
          _$ReceptionImpl value, $Res Function(_$ReceptionImpl) then) =
      __$$ReceptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'cours_de_route_id') String coursDeRouteId,
      @JsonKey(name: 'citerne_id') String citerneId,
      @JsonKey(name: 'produit_id') String produitId,
      @JsonKey(name: 'partenaire_id') String? partenaireId,
      @JsonKey(name: 'index_avant') double indexAvant,
      @JsonKey(name: 'index_apres') double indexApres,
      @JsonKey(name: 'temperature_ambiante_c') double? temperatureAmbianteC,
      @JsonKey(name: 'densite_a_15') double? densiteA15,
      @JsonKey(name: 'volume_corrige_15c') double? volumeCorrige15c,
      @JsonKey(name: 'volume_ambiant') double? volumeAmbiant,
      @JsonKey(name: 'proprietaire_type')
      @OwnerTypeConverter()
      OwnerType proprietaireType,
      String? note,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      String? statut,
      @JsonKey(name: 'created_by') String? createdBy,
      @JsonKey(name: 'validated_by') String? validatedBy,
      @JsonKey(name: 'date_reception') DateTime? dateReception});
}

/// @nodoc
class __$$ReceptionImplCopyWithImpl<$Res>
    extends _$ReceptionCopyWithImpl<$Res, _$ReceptionImpl>
    implements _$$ReceptionImplCopyWith<$Res> {
  __$$ReceptionImplCopyWithImpl(
      _$ReceptionImpl _value, $Res Function(_$ReceptionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Reception
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? coursDeRouteId = null,
    Object? citerneId = null,
    Object? produitId = null,
    Object? partenaireId = freezed,
    Object? indexAvant = null,
    Object? indexApres = null,
    Object? temperatureAmbianteC = freezed,
    Object? densiteA15 = freezed,
    Object? volumeCorrige15c = freezed,
    Object? volumeAmbiant = freezed,
    Object? proprietaireType = null,
    Object? note = freezed,
    Object? createdAt = freezed,
    Object? statut = freezed,
    Object? createdBy = freezed,
    Object? validatedBy = freezed,
    Object? dateReception = freezed,
  }) {
    return _then(_$ReceptionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      coursDeRouteId: null == coursDeRouteId
          ? _value.coursDeRouteId
          : coursDeRouteId // ignore: cast_nullable_to_non_nullable
              as String,
      citerneId: null == citerneId
          ? _value.citerneId
          : citerneId // ignore: cast_nullable_to_non_nullable
              as String,
      produitId: null == produitId
          ? _value.produitId
          : produitId // ignore: cast_nullable_to_non_nullable
              as String,
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
      temperatureAmbianteC: freezed == temperatureAmbianteC
          ? _value.temperatureAmbianteC
          : temperatureAmbianteC // ignore: cast_nullable_to_non_nullable
              as double?,
      densiteA15: freezed == densiteA15
          ? _value.densiteA15
          : densiteA15 // ignore: cast_nullable_to_non_nullable
              as double?,
      volumeCorrige15c: freezed == volumeCorrige15c
          ? _value.volumeCorrige15c
          : volumeCorrige15c // ignore: cast_nullable_to_non_nullable
              as double?,
      volumeAmbiant: freezed == volumeAmbiant
          ? _value.volumeAmbiant
          : volumeAmbiant // ignore: cast_nullable_to_non_nullable
              as double?,
      proprietaireType: null == proprietaireType
          ? _value.proprietaireType
          : proprietaireType // ignore: cast_nullable_to_non_nullable
              as OwnerType,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      statut: freezed == statut
          ? _value.statut
          : statut // ignore: cast_nullable_to_non_nullable
              as String?,
      createdBy: freezed == createdBy
          ? _value.createdBy
          : createdBy // ignore: cast_nullable_to_non_nullable
              as String?,
      validatedBy: freezed == validatedBy
          ? _value.validatedBy
          : validatedBy // ignore: cast_nullable_to_non_nullable
              as String?,
      dateReception: freezed == dateReception
          ? _value.dateReception
          : dateReception // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ReceptionImpl implements _Reception {
  const _$ReceptionImpl(
      {required this.id,
      @JsonKey(name: 'cours_de_route_id') required this.coursDeRouteId,
      @JsonKey(name: 'citerne_id') required this.citerneId,
      @JsonKey(name: 'produit_id') required this.produitId,
      @JsonKey(name: 'partenaire_id') this.partenaireId,
      @JsonKey(name: 'index_avant') required this.indexAvant,
      @JsonKey(name: 'index_apres') required this.indexApres,
      @JsonKey(name: 'temperature_ambiante_c') this.temperatureAmbianteC,
      @JsonKey(name: 'densite_a_15') this.densiteA15,
      @JsonKey(name: 'volume_corrige_15c') this.volumeCorrige15c,
      @JsonKey(name: 'volume_ambiant') this.volumeAmbiant,
      @JsonKey(name: 'proprietaire_type')
      @OwnerTypeConverter()
      required this.proprietaireType,
      this.note,
      @JsonKey(name: 'created_at') this.createdAt,
      this.statut,
      @JsonKey(name: 'created_by') this.createdBy,
      @JsonKey(name: 'validated_by') this.validatedBy,
      @JsonKey(name: 'date_reception') this.dateReception});

  factory _$ReceptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReceptionImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'cours_de_route_id')
  final String coursDeRouteId;
  @override
  @JsonKey(name: 'citerne_id')
  final String citerneId;
  @override
  @JsonKey(name: 'produit_id')
  final String produitId;
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
  @JsonKey(name: 'temperature_ambiante_c')
  final double? temperatureAmbianteC;
  @override
  @JsonKey(name: 'densite_a_15')
  final double? densiteA15;
  @override
  @JsonKey(name: 'volume_corrige_15c')
  final double? volumeCorrige15c;
  @override
  @JsonKey(name: 'volume_ambiant')
  final double? volumeAmbiant;
  @override
  @JsonKey(name: 'proprietaire_type')
  @OwnerTypeConverter()
  final OwnerType proprietaireType;
  @override
  final String? note;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  final String? statut;
  @override
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @override
  @JsonKey(name: 'validated_by')
  final String? validatedBy;
  @override
  @JsonKey(name: 'date_reception')
  final DateTime? dateReception;

  @override
  String toString() {
    return 'Reception(id: $id, coursDeRouteId: $coursDeRouteId, citerneId: $citerneId, produitId: $produitId, partenaireId: $partenaireId, indexAvant: $indexAvant, indexApres: $indexApres, temperatureAmbianteC: $temperatureAmbianteC, densiteA15: $densiteA15, volumeCorrige15c: $volumeCorrige15c, volumeAmbiant: $volumeAmbiant, proprietaireType: $proprietaireType, note: $note, createdAt: $createdAt, statut: $statut, createdBy: $createdBy, validatedBy: $validatedBy, dateReception: $dateReception)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReceptionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.coursDeRouteId, coursDeRouteId) ||
                other.coursDeRouteId == coursDeRouteId) &&
            (identical(other.citerneId, citerneId) ||
                other.citerneId == citerneId) &&
            (identical(other.produitId, produitId) ||
                other.produitId == produitId) &&
            (identical(other.partenaireId, partenaireId) ||
                other.partenaireId == partenaireId) &&
            (identical(other.indexAvant, indexAvant) ||
                other.indexAvant == indexAvant) &&
            (identical(other.indexApres, indexApres) ||
                other.indexApres == indexApres) &&
            (identical(other.temperatureAmbianteC, temperatureAmbianteC) ||
                other.temperatureAmbianteC == temperatureAmbianteC) &&
            (identical(other.densiteA15, densiteA15) ||
                other.densiteA15 == densiteA15) &&
            (identical(other.volumeCorrige15c, volumeCorrige15c) ||
                other.volumeCorrige15c == volumeCorrige15c) &&
            (identical(other.volumeAmbiant, volumeAmbiant) ||
                other.volumeAmbiant == volumeAmbiant) &&
            (identical(other.proprietaireType, proprietaireType) ||
                other.proprietaireType == proprietaireType) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.statut, statut) || other.statut == statut) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.validatedBy, validatedBy) ||
                other.validatedBy == validatedBy) &&
            (identical(other.dateReception, dateReception) ||
                other.dateReception == dateReception));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      coursDeRouteId,
      citerneId,
      produitId,
      partenaireId,
      indexAvant,
      indexApres,
      temperatureAmbianteC,
      densiteA15,
      volumeCorrige15c,
      volumeAmbiant,
      proprietaireType,
      note,
      createdAt,
      statut,
      createdBy,
      validatedBy,
      dateReception);

  /// Create a copy of Reception
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReceptionImplCopyWith<_$ReceptionImpl> get copyWith =>
      __$$ReceptionImplCopyWithImpl<_$ReceptionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReceptionImplToJson(
      this,
    );
  }
}

abstract class _Reception implements Reception {
  const factory _Reception(
      {required final String id,
      @JsonKey(name: 'cours_de_route_id') required final String coursDeRouteId,
      @JsonKey(name: 'citerne_id') required final String citerneId,
      @JsonKey(name: 'produit_id') required final String produitId,
      @JsonKey(name: 'partenaire_id') final String? partenaireId,
      @JsonKey(name: 'index_avant') required final double indexAvant,
      @JsonKey(name: 'index_apres') required final double indexApres,
      @JsonKey(name: 'temperature_ambiante_c')
      final double? temperatureAmbianteC,
      @JsonKey(name: 'densite_a_15') final double? densiteA15,
      @JsonKey(name: 'volume_corrige_15c') final double? volumeCorrige15c,
      @JsonKey(name: 'volume_ambiant') final double? volumeAmbiant,
      @JsonKey(name: 'proprietaire_type')
      @OwnerTypeConverter()
      required final OwnerType proprietaireType,
      final String? note,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      final String? statut,
      @JsonKey(name: 'created_by') final String? createdBy,
      @JsonKey(name: 'validated_by') final String? validatedBy,
      @JsonKey(name: 'date_reception')
      final DateTime? dateReception}) = _$ReceptionImpl;

  factory _Reception.fromJson(Map<String, dynamic> json) =
      _$ReceptionImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'cours_de_route_id')
  String get coursDeRouteId;
  @override
  @JsonKey(name: 'citerne_id')
  String get citerneId;
  @override
  @JsonKey(name: 'produit_id')
  String get produitId;
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
  @JsonKey(name: 'temperature_ambiante_c')
  double? get temperatureAmbianteC;
  @override
  @JsonKey(name: 'densite_a_15')
  double? get densiteA15;
  @override
  @JsonKey(name: 'volume_corrige_15c')
  double? get volumeCorrige15c;
  @override
  @JsonKey(name: 'volume_ambiant')
  double? get volumeAmbiant;
  @override
  @JsonKey(name: 'proprietaire_type')
  @OwnerTypeConverter()
  OwnerType get proprietaireType;
  @override
  String? get note;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  String? get statut;
  @override
  @JsonKey(name: 'created_by')
  String? get createdBy;
  @override
  @JsonKey(name: 'validated_by')
  String? get validatedBy;
  @override
  @JsonKey(name: 'date_reception')
  DateTime? get dateReception;

  /// Create a copy of Reception
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReceptionImplCopyWith<_$ReceptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
