// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fournisseur_lot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FournisseurLot _$FournisseurLotFromJson(Map<String, dynamic> json) {
  return _FournisseurLot.fromJson(json);
}

/// @nodoc
mixin _$FournisseurLot {
  /// Identifiant unique du lot
  String get id => throw _privateConstructorUsedError;

  /// Référence vers `fournisseurs.id`
  @JsonKey(name: 'fournisseur_id')
  String get fournisseurId => throw _privateConstructorUsedError;

  /// Nom du fournisseur (jointure / affichage)
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get fournisseurNom => throw _privateConstructorUsedError;

  /// Référence vers `produits.id`
  @JsonKey(name: 'produit_id')
  String get produitId => throw _privateConstructorUsedError;

  /// Nom du produit (jointure / affichage)
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get produitNom => throw _privateConstructorUsedError;

  /// Code produit (jointure / affichage)
  @JsonKey(name: 'produit_code')
  String? get produitCode => throw _privateConstructorUsedError;

  /// Référence métier fournisseur
  String get reference => throw _privateConstructorUsedError;

  /// Date du lot
  @JsonKey(name: 'date_lot')
  DateTime? get dateLot => throw _privateConstructorUsedError;

  /// Statut du lot
  @JsonKey(name: 'statut')
  @StatutFournisseurLotConverter()
  StatutFournisseurLot get statut => throw _privateConstructorUsedError;

  /// Note libre
  String? get note => throw _privateConstructorUsedError;

  /// Date de création
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Date de mise à jour
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this FournisseurLot to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FournisseurLot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FournisseurLotCopyWith<FournisseurLot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FournisseurLotCopyWith<$Res> {
  factory $FournisseurLotCopyWith(
    FournisseurLot value,
    $Res Function(FournisseurLot) then,
  ) = _$FournisseurLotCopyWithImpl<$Res, FournisseurLot>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'fournisseur_id') String fournisseurId,
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? fournisseurNom,
    @JsonKey(name: 'produit_id') String produitId,
    @JsonKey(includeFromJson: false, includeToJson: false) String? produitNom,
    @JsonKey(name: 'produit_code') String? produitCode,
    String reference,
    @JsonKey(name: 'date_lot') DateTime? dateLot,
    @JsonKey(name: 'statut')
    @StatutFournisseurLotConverter()
    StatutFournisseurLot statut,
    String? note,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class _$FournisseurLotCopyWithImpl<$Res, $Val extends FournisseurLot>
    implements $FournisseurLotCopyWith<$Res> {
  _$FournisseurLotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FournisseurLot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fournisseurId = null,
    Object? fournisseurNom = freezed,
    Object? produitId = null,
    Object? produitNom = freezed,
    Object? produitCode = freezed,
    Object? reference = null,
    Object? dateLot = freezed,
    Object? statut = null,
    Object? note = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            fournisseurId: null == fournisseurId
                ? _value.fournisseurId
                : fournisseurId // ignore: cast_nullable_to_non_nullable
                      as String,
            fournisseurNom: freezed == fournisseurNom
                ? _value.fournisseurNom
                : fournisseurNom // ignore: cast_nullable_to_non_nullable
                      as String?,
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
            reference: null == reference
                ? _value.reference
                : reference // ignore: cast_nullable_to_non_nullable
                      as String,
            dateLot: freezed == dateLot
                ? _value.dateLot
                : dateLot // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            statut: null == statut
                ? _value.statut
                : statut // ignore: cast_nullable_to_non_nullable
                      as StatutFournisseurLot,
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
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FournisseurLotImplCopyWith<$Res>
    implements $FournisseurLotCopyWith<$Res> {
  factory _$$FournisseurLotImplCopyWith(
    _$FournisseurLotImpl value,
    $Res Function(_$FournisseurLotImpl) then,
  ) = __$$FournisseurLotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'fournisseur_id') String fournisseurId,
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? fournisseurNom,
    @JsonKey(name: 'produit_id') String produitId,
    @JsonKey(includeFromJson: false, includeToJson: false) String? produitNom,
    @JsonKey(name: 'produit_code') String? produitCode,
    String reference,
    @JsonKey(name: 'date_lot') DateTime? dateLot,
    @JsonKey(name: 'statut')
    @StatutFournisseurLotConverter()
    StatutFournisseurLot statut,
    String? note,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  });
}

/// @nodoc
class __$$FournisseurLotImplCopyWithImpl<$Res>
    extends _$FournisseurLotCopyWithImpl<$Res, _$FournisseurLotImpl>
    implements _$$FournisseurLotImplCopyWith<$Res> {
  __$$FournisseurLotImplCopyWithImpl(
    _$FournisseurLotImpl _value,
    $Res Function(_$FournisseurLotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FournisseurLot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? fournisseurId = null,
    Object? fournisseurNom = freezed,
    Object? produitId = null,
    Object? produitNom = freezed,
    Object? produitCode = freezed,
    Object? reference = null,
    Object? dateLot = freezed,
    Object? statut = null,
    Object? note = freezed,
    Object? createdAt = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$FournisseurLotImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        fournisseurId: null == fournisseurId
            ? _value.fournisseurId
            : fournisseurId // ignore: cast_nullable_to_non_nullable
                  as String,
        fournisseurNom: freezed == fournisseurNom
            ? _value.fournisseurNom
            : fournisseurNom // ignore: cast_nullable_to_non_nullable
                  as String?,
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
        reference: null == reference
            ? _value.reference
            : reference // ignore: cast_nullable_to_non_nullable
                  as String,
        dateLot: freezed == dateLot
            ? _value.dateLot
            : dateLot // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        statut: null == statut
            ? _value.statut
            : statut // ignore: cast_nullable_to_non_nullable
                  as StatutFournisseurLot,
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
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FournisseurLotImpl implements _FournisseurLot {
  const _$FournisseurLotImpl({
    required this.id,
    @JsonKey(name: 'fournisseur_id') required this.fournisseurId,
    @JsonKey(includeFromJson: false, includeToJson: false) this.fournisseurNom,
    @JsonKey(name: 'produit_id') required this.produitId,
    @JsonKey(includeFromJson: false, includeToJson: false) this.produitNom,
    @JsonKey(name: 'produit_code') this.produitCode,
    required this.reference,
    @JsonKey(name: 'date_lot') this.dateLot,
    @JsonKey(name: 'statut')
    @StatutFournisseurLotConverter()
    this.statut = StatutFournisseurLot.ouvert,
    this.note,
    @JsonKey(name: 'created_at') this.createdAt,
    @JsonKey(name: 'updated_at') this.updatedAt,
  });

  factory _$FournisseurLotImpl.fromJson(Map<String, dynamic> json) =>
      _$$FournisseurLotImplFromJson(json);

  /// Identifiant unique du lot
  @override
  final String id;

  /// Référence vers `fournisseurs.id`
  @override
  @JsonKey(name: 'fournisseur_id')
  final String fournisseurId;

  /// Nom du fournisseur (jointure / affichage)
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? fournisseurNom;

  /// Référence vers `produits.id`
  @override
  @JsonKey(name: 'produit_id')
  final String produitId;

  /// Nom du produit (jointure / affichage)
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? produitNom;

  /// Code produit (jointure / affichage)
  @override
  @JsonKey(name: 'produit_code')
  final String? produitCode;

  /// Référence métier fournisseur
  @override
  final String reference;

  /// Date du lot
  @override
  @JsonKey(name: 'date_lot')
  final DateTime? dateLot;

  /// Statut du lot
  @override
  @JsonKey(name: 'statut')
  @StatutFournisseurLotConverter()
  final StatutFournisseurLot statut;

  /// Note libre
  @override
  final String? note;

  /// Date de création
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  /// Date de mise à jour
  @override
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'FournisseurLot(id: $id, fournisseurId: $fournisseurId, fournisseurNom: $fournisseurNom, produitId: $produitId, produitNom: $produitNom, produitCode: $produitCode, reference: $reference, dateLot: $dateLot, statut: $statut, note: $note, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FournisseurLotImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.fournisseurId, fournisseurId) ||
                other.fournisseurId == fournisseurId) &&
            (identical(other.fournisseurNom, fournisseurNom) ||
                other.fournisseurNom == fournisseurNom) &&
            (identical(other.produitId, produitId) ||
                other.produitId == produitId) &&
            (identical(other.produitNom, produitNom) ||
                other.produitNom == produitNom) &&
            (identical(other.produitCode, produitCode) ||
                other.produitCode == produitCode) &&
            (identical(other.reference, reference) ||
                other.reference == reference) &&
            (identical(other.dateLot, dateLot) || other.dateLot == dateLot) &&
            (identical(other.statut, statut) || other.statut == statut) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    fournisseurId,
    fournisseurNom,
    produitId,
    produitNom,
    produitCode,
    reference,
    dateLot,
    statut,
    note,
    createdAt,
    updatedAt,
  );

  /// Create a copy of FournisseurLot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FournisseurLotImplCopyWith<_$FournisseurLotImpl> get copyWith =>
      __$$FournisseurLotImplCopyWithImpl<_$FournisseurLotImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$FournisseurLotImplToJson(this);
  }
}

abstract class _FournisseurLot implements FournisseurLot {
  const factory _FournisseurLot({
    required final String id,
    @JsonKey(name: 'fournisseur_id') required final String fournisseurId,
    @JsonKey(includeFromJson: false, includeToJson: false)
    final String? fournisseurNom,
    @JsonKey(name: 'produit_id') required final String produitId,
    @JsonKey(includeFromJson: false, includeToJson: false)
    final String? produitNom,
    @JsonKey(name: 'produit_code') final String? produitCode,
    required final String reference,
    @JsonKey(name: 'date_lot') final DateTime? dateLot,
    @JsonKey(name: 'statut')
    @StatutFournisseurLotConverter()
    final StatutFournisseurLot statut,
    final String? note,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
    @JsonKey(name: 'updated_at') final DateTime? updatedAt,
  }) = _$FournisseurLotImpl;

  factory _FournisseurLot.fromJson(Map<String, dynamic> json) =
      _$FournisseurLotImpl.fromJson;

  /// Identifiant unique du lot
  @override
  String get id;

  /// Référence vers `fournisseurs.id`
  @override
  @JsonKey(name: 'fournisseur_id')
  String get fournisseurId;

  /// Nom du fournisseur (jointure / affichage)
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get fournisseurNom;

  /// Référence vers `produits.id`
  @override
  @JsonKey(name: 'produit_id')
  String get produitId;

  /// Nom du produit (jointure / affichage)
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get produitNom;

  /// Code produit (jointure / affichage)
  @override
  @JsonKey(name: 'produit_code')
  String? get produitCode;

  /// Référence métier fournisseur
  @override
  String get reference;

  /// Date du lot
  @override
  @JsonKey(name: 'date_lot')
  DateTime? get dateLot;

  /// Statut du lot
  @override
  @JsonKey(name: 'statut')
  @StatutFournisseurLotConverter()
  StatutFournisseurLot get statut;

  /// Note libre
  @override
  String? get note;

  /// Date de création
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Date de mise à jour
  @override
  @JsonKey(name: 'updated_at')
  DateTime? get updatedAt;

  /// Create a copy of FournisseurLot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FournisseurLotImplCopyWith<_$FournisseurLotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
