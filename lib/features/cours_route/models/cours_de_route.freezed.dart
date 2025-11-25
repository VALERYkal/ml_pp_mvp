// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'cours_de_route.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

CoursDeRoute _$CoursDeRouteFromJson(Map<String, dynamic> json) {
  return _CoursDeRoute.fromJson(json);
}

/// @nodoc
mixin _$CoursDeRoute {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'fournisseur_id')
  String get fournisseurId => throw _privateConstructorUsedError;
  @JsonKey(name: 'produit_id')
  String get produitId =>
      throw _privateConstructorUsedError; // champs d'affichage non sérialisés
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get produitNom => throw _privateConstructorUsedError;
  @JsonKey(name: 'produit_code')
  String? get produitCode => throw _privateConstructorUsedError;
  @JsonKey(name: 'depot_destination_id')
  String get depotDestinationId => throw _privateConstructorUsedError;
  String? get transporteur => throw _privateConstructorUsedError;
  @JsonKey(name: 'plaque_camion')
  String? get plaqueCamion => throw _privateConstructorUsedError;
  @JsonKey(name: 'plaque_remorque')
  String? get plaqueRemorque => throw _privateConstructorUsedError;
  String? get chauffeur => throw _privateConstructorUsedError;
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get chauffeurNom => throw _privateConstructorUsedError;
  double? get volume => throw _privateConstructorUsedError;
  String? get pays => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_chargement')
  DateTime? get dateChargement => throw _privateConstructorUsedError;
  @JsonKey(name: 'date_arrivee_prevue')
  DateTime? get dateArriveePrevue => throw _privateConstructorUsedError;
  @JsonKey(name: 'statut')
  StatutCours get statut => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this CoursDeRoute to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CoursDeRoute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CoursDeRouteCopyWith<CoursDeRoute> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CoursDeRouteCopyWith<$Res> {
  factory $CoursDeRouteCopyWith(
          CoursDeRoute value, $Res Function(CoursDeRoute) then) =
      _$CoursDeRouteCopyWithImpl<$Res, CoursDeRoute>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'fournisseur_id') String fournisseurId,
      @JsonKey(name: 'produit_id') String produitId,
      @JsonKey(includeFromJson: false, includeToJson: false) String? produitNom,
      @JsonKey(name: 'produit_code') String? produitCode,
      @JsonKey(name: 'depot_destination_id') String depotDestinationId,
      String? transporteur,
      @JsonKey(name: 'plaque_camion') String? plaqueCamion,
      @JsonKey(name: 'plaque_remorque') String? plaqueRemorque,
      String? chauffeur,
      @JsonKey(includeFromJson: false, includeToJson: false)
      String? chauffeurNom,
      double? volume,
      String? pays,
      @JsonKey(name: 'date_chargement') DateTime? dateChargement,
      @JsonKey(name: 'date_arrivee_prevue') DateTime? dateArriveePrevue,
      @JsonKey(name: 'statut') StatutCours statut,
      String? note,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class _$CoursDeRouteCopyWithImpl<$Res, $Val extends CoursDeRoute>
    implements $CoursDeRouteCopyWith<$Res> {
  _$CoursDeRouteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CoursDeRoute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fournisseurId = null,
    Object? produitId = null,
    Object? produitNom = freezed,
    Object? produitCode = freezed,
    Object? depotDestinationId = null,
    Object? transporteur = freezed,
    Object? plaqueCamion = freezed,
    Object? plaqueRemorque = freezed,
    Object? chauffeur = freezed,
    Object? chauffeurNom = freezed,
    Object? volume = freezed,
    Object? pays = freezed,
    Object? dateChargement = freezed,
    Object? dateArriveePrevue = freezed,
    Object? statut = null,
    Object? note = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fournisseurId: null == fournisseurId
          ? _value.fournisseurId
          : fournisseurId // ignore: cast_nullable_to_non_nullable
              as String,
      produitId: null == produitId
          ? _value.produitId
          : produitId // ignore: cast_nullable_to_non_nullable
              as String,
      produitNom: freezed == produitNom
          ? _value.produitNom
          : produitNom // ignore: cast_nullable_to_non_nullable
              as String?,
      produitCode: freezed == produitCode
          ? _value.produitCode
          : produitCode // ignore: cast_nullable_to_non_nullable
              as String?,
      depotDestinationId: null == depotDestinationId
          ? _value.depotDestinationId
          : depotDestinationId // ignore: cast_nullable_to_non_nullable
              as String,
      transporteur: freezed == transporteur
          ? _value.transporteur
          : transporteur // ignore: cast_nullable_to_non_nullable
              as String?,
      plaqueCamion: freezed == plaqueCamion
          ? _value.plaqueCamion
          : plaqueCamion // ignore: cast_nullable_to_non_nullable
              as String?,
      plaqueRemorque: freezed == plaqueRemorque
          ? _value.plaqueRemorque
          : plaqueRemorque // ignore: cast_nullable_to_non_nullable
              as String?,
      chauffeur: freezed == chauffeur
          ? _value.chauffeur
          : chauffeur // ignore: cast_nullable_to_non_nullable
              as String?,
      chauffeurNom: freezed == chauffeurNom
          ? _value.chauffeurNom
          : chauffeurNom // ignore: cast_nullable_to_non_nullable
              as String?,
      volume: freezed == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double?,
      pays: freezed == pays
          ? _value.pays
          : pays // ignore: cast_nullable_to_non_nullable
              as String?,
      dateChargement: freezed == dateChargement
          ? _value.dateChargement
          : dateChargement // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dateArriveePrevue: freezed == dateArriveePrevue
          ? _value.dateArriveePrevue
          : dateArriveePrevue // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      statut: null == statut
          ? _value.statut
          : statut // ignore: cast_nullable_to_non_nullable
              as StatutCours,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CoursDeRouteImplCopyWith<$Res>
    implements $CoursDeRouteCopyWith<$Res> {
  factory _$$CoursDeRouteImplCopyWith(
          _$CoursDeRouteImpl value, $Res Function(_$CoursDeRouteImpl) then) =
      __$$CoursDeRouteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'fournisseur_id') String fournisseurId,
      @JsonKey(name: 'produit_id') String produitId,
      @JsonKey(includeFromJson: false, includeToJson: false) String? produitNom,
      @JsonKey(name: 'produit_code') String? produitCode,
      @JsonKey(name: 'depot_destination_id') String depotDestinationId,
      String? transporteur,
      @JsonKey(name: 'plaque_camion') String? plaqueCamion,
      @JsonKey(name: 'plaque_remorque') String? plaqueRemorque,
      String? chauffeur,
      @JsonKey(includeFromJson: false, includeToJson: false)
      String? chauffeurNom,
      double? volume,
      String? pays,
      @JsonKey(name: 'date_chargement') DateTime? dateChargement,
      @JsonKey(name: 'date_arrivee_prevue') DateTime? dateArriveePrevue,
      @JsonKey(name: 'statut') StatutCours statut,
      String? note,
      @JsonKey(name: 'created_at') DateTime? createdAt,
      @JsonKey(name: 'updated_at') DateTime? updatedAt});
}

/// @nodoc
class __$$CoursDeRouteImplCopyWithImpl<$Res>
    extends _$CoursDeRouteCopyWithImpl<$Res, _$CoursDeRouteImpl>
    implements _$$CoursDeRouteImplCopyWith<$Res> {
  __$$CoursDeRouteImplCopyWithImpl(
      _$CoursDeRouteImpl _value, $Res Function(_$CoursDeRouteImpl) _then)
      : super(_value, _then);

  /// Create a copy of CoursDeRoute
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fournisseurId = null,
    Object? produitId = null,
    Object? produitNom = freezed,
    Object? produitCode = freezed,
    Object? depotDestinationId = null,
    Object? transporteur = freezed,
    Object? plaqueCamion = freezed,
    Object? plaqueRemorque = freezed,
    Object? chauffeur = freezed,
    Object? chauffeurNom = freezed,
    Object? volume = freezed,
    Object? pays = freezed,
    Object? dateChargement = freezed,
    Object? dateArriveePrevue = freezed,
    Object? statut = null,
    Object? note = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(_$CoursDeRouteImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      fournisseurId: null == fournisseurId
          ? _value.fournisseurId
          : fournisseurId // ignore: cast_nullable_to_non_nullable
              as String,
      produitId: null == produitId
          ? _value.produitId
          : produitId // ignore: cast_nullable_to_non_nullable
              as String,
      produitNom: freezed == produitNom
          ? _value.produitNom
          : produitNom // ignore: cast_nullable_to_non_nullable
              as String?,
      produitCode: freezed == produitCode
          ? _value.produitCode
          : produitCode // ignore: cast_nullable_to_non_nullable
              as String?,
      depotDestinationId: null == depotDestinationId
          ? _value.depotDestinationId
          : depotDestinationId // ignore: cast_nullable_to_non_nullable
              as String,
      transporteur: freezed == transporteur
          ? _value.transporteur
          : transporteur // ignore: cast_nullable_to_non_nullable
              as String?,
      plaqueCamion: freezed == plaqueCamion
          ? _value.plaqueCamion
          : plaqueCamion // ignore: cast_nullable_to_non_nullable
              as String?,
      plaqueRemorque: freezed == plaqueRemorque
          ? _value.plaqueRemorque
          : plaqueRemorque // ignore: cast_nullable_to_non_nullable
              as String?,
      chauffeur: freezed == chauffeur
          ? _value.chauffeur
          : chauffeur // ignore: cast_nullable_to_non_nullable
              as String?,
      chauffeurNom: freezed == chauffeurNom
          ? _value.chauffeurNom
          : chauffeurNom // ignore: cast_nullable_to_non_nullable
              as String?,
      volume: freezed == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double?,
      pays: freezed == pays
          ? _value.pays
          : pays // ignore: cast_nullable_to_non_nullable
              as String?,
      dateChargement: freezed == dateChargement
          ? _value.dateChargement
          : dateChargement // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      dateArriveePrevue: freezed == dateArriveePrevue
          ? _value.dateArriveePrevue
          : dateArriveePrevue // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      statut: null == statut
          ? _value.statut
          : statut // ignore: cast_nullable_to_non_nullable
              as StatutCours,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updatedAt: freezed == updatedAt
          ? _value.updatedAt
          : updatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CoursDeRouteImpl implements _CoursDeRoute {
  const _$CoursDeRouteImpl(
      {required this.id,
      @JsonKey(name: 'fournisseur_id') required this.fournisseurId,
      @JsonKey(name: 'produit_id') required this.produitId,
      @JsonKey(includeFromJson: false, includeToJson: false) this.produitNom,
      @JsonKey(name: 'produit_code') this.produitCode,
      @JsonKey(name: 'depot_destination_id') required this.depotDestinationId,
      this.transporteur,
      @JsonKey(name: 'plaque_camion') this.plaqueCamion,
      @JsonKey(name: 'plaque_remorque') this.plaqueRemorque,
      this.chauffeur,
      @JsonKey(includeFromJson: false, includeToJson: false) this.chauffeurNom,
      this.volume,
      this.pays,
      @JsonKey(name: 'date_chargement') this.dateChargement,
      @JsonKey(name: 'date_arrivee_prevue') this.dateArriveePrevue,
      @JsonKey(name: 'statut') required this.statut,
      this.note,
      @JsonKey(name: 'created_at') this.createdAt,
      @JsonKey(name: 'updated_at') this.updatedAt});

  factory _$CoursDeRouteImpl.fromJson(Map<String, dynamic> json) =>
      _$$CoursDeRouteImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'fournisseur_id')
  final String fournisseurId;
  @override
  @JsonKey(name: 'produit_id')
  final String produitId;
// champs d'affichage non sérialisés
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? produitNom;
  @override
  @JsonKey(name: 'produit_code')
  final String? produitCode;
  @override
  @JsonKey(name: 'depot_destination_id')
  final String depotDestinationId;
  @override
  final String? transporteur;
  @override
  @JsonKey(name: 'plaque_camion')
  final String? plaqueCamion;
  @override
  @JsonKey(name: 'plaque_remorque')
  final String? plaqueRemorque;
  @override
  final String? chauffeur;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? chauffeurNom;
  @override
  final double? volume;
  @override
  final String? pays;
  @override
  @JsonKey(name: 'date_chargement')
  final DateTime? dateChargement;
  @override
  @JsonKey(name: 'date_arrivee_prevue')
  final DateTime? dateArriveePrevue;
  @override
  @JsonKey(name: 'statut')
  final StatutCours statut;
  @override
  final String? note;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'CoursDeRoute(id: $id, fournisseurId: $fournisseurId, produitId: $produitId, produitNom: $produitNom, produitCode: $produitCode, depotDestinationId: $depotDestinationId, transporteur: $transporteur, plaqueCamion: $plaqueCamion, plaqueRemorque: $plaqueRemorque, chauffeur: $chauffeur, chauffeurNom: $chauffeurNom, volume: $volume, pays: $pays, dateChargement: $dateChargement, dateArriveePrevue: $dateArriveePrevue, statut: $statut, note: $note, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CoursDeRouteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fournisseurId, fournisseurId) ||
                other.fournisseurId == fournisseurId) &&
            (identical(other.produitId, produitId) ||
                other.produitId == produitId) &&
            (identical(other.produitNom, produitNom) ||
                other.produitNom == produitNom) &&
            (identical(other.produitCode, produitCode) ||
                other.produitCode == produitCode) &&
            (identical(other.depotDestinationId, depotDestinationId) ||
                other.depotDestinationId == depotDestinationId) &&
            (identical(other.transporteur, transporteur) ||
                other.transporteur == transporteur) &&
            (identical(other.plaqueCamion, plaqueCamion) ||
                other.plaqueCamion == plaqueCamion) &&
            (identical(other.plaqueRemorque, plaqueRemorque) ||
                other.plaqueRemorque == plaqueRemorque) &&
            (identical(other.chauffeur, chauffeur) ||
                other.chauffeur == chauffeur) &&
            (identical(other.chauffeurNom, chauffeurNom) ||
                other.chauffeurNom == chauffeurNom) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.pays, pays) || other.pays == pays) &&
            (identical(other.dateChargement, dateChargement) ||
                other.dateChargement == dateChargement) &&
            (identical(other.dateArriveePrevue, dateArriveePrevue) ||
                other.dateArriveePrevue == dateArriveePrevue) &&
            (identical(other.statut, statut) || other.statut == statut) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        fournisseurId,
        produitId,
        produitNom,
        produitCode,
        depotDestinationId,
        transporteur,
        plaqueCamion,
        plaqueRemorque,
        chauffeur,
        chauffeurNom,
        volume,
        pays,
        dateChargement,
        dateArriveePrevue,
        statut,
        note,
        createdAt,
        updatedAt
      ]);

  /// Create a copy of CoursDeRoute
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CoursDeRouteImplCopyWith<_$CoursDeRouteImpl> get copyWith =>
      __$$CoursDeRouteImplCopyWithImpl<_$CoursDeRouteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CoursDeRouteImplToJson(
      this,
    );
  }
}

abstract class _CoursDeRoute implements CoursDeRoute {
  const factory _CoursDeRoute(
      {required final String id,
      @JsonKey(name: 'fournisseur_id') required final String fournisseurId,
      @JsonKey(name: 'produit_id') required final String produitId,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final String? produitNom,
      @JsonKey(name: 'produit_code') final String? produitCode,
      @JsonKey(name: 'depot_destination_id')
      required final String depotDestinationId,
      final String? transporteur,
      @JsonKey(name: 'plaque_camion') final String? plaqueCamion,
      @JsonKey(name: 'plaque_remorque') final String? plaqueRemorque,
      final String? chauffeur,
      @JsonKey(includeFromJson: false, includeToJson: false)
      final String? chauffeurNom,
      final double? volume,
      final String? pays,
      @JsonKey(name: 'date_chargement') final DateTime? dateChargement,
      @JsonKey(name: 'date_arrivee_prevue') final DateTime? dateArriveePrevue,
      @JsonKey(name: 'statut') required final StatutCours statut,
      final String? note,
      @JsonKey(name: 'created_at') final DateTime? createdAt,
      @JsonKey(name: 'updated_at')
      final DateTime? updatedAt}) = _$CoursDeRouteImpl;

  factory _CoursDeRoute.fromJson(Map<String, dynamic> json) =
      _$CoursDeRouteImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'fournisseur_id')
  String get fournisseurId;
  @override
  @JsonKey(name: 'produit_id')
  String get produitId; // champs d'affichage non sérialisés
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get produitNom;
  @override
  @JsonKey(name: 'produit_code')
  String? get produitCode;
  @override
  @JsonKey(name: 'depot_destination_id')
  String get depotDestinationId;
  @override
  String? get transporteur;
  @override
  @JsonKey(name: 'plaque_camion')
  String? get plaqueCamion;
  @override
  @JsonKey(name: 'plaque_remorque')
  String? get plaqueRemorque;
  @override
  String? get chauffeur;
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get chauffeurNom;
  @override
  double? get volume;
  @override
  String? get pays;
  @override
  @JsonKey(name: 'date_chargement')
  DateTime? get dateChargement;
  @override
  @JsonKey(name: 'date_arrivee_prevue')
  DateTime? get dateArriveePrevue;
  @override
  @JsonKey(name: 'statut')
  StatutCours get statut;
  @override
  String? get note;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of CoursDeRoute
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CoursDeRouteImplCopyWith<_$CoursDeRouteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
