// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fournisseur.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Fournisseur _$FournisseurFromJson(Map<String, dynamic> json) {
  return _Fournisseur.fromJson(json);
}

/// @nodoc
mixin _$Fournisseur {
  String get id => throw _privateConstructorUsedError;
  String get nom => throw _privateConstructorUsedError;
  @JsonKey(name: 'contact_personne')
  String? get contactPersonne => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  String? get telephone => throw _privateConstructorUsedError;
  String? get adresse => throw _privateConstructorUsedError;
  String? get pays => throw _privateConstructorUsedError;
  @JsonKey(name: 'note_supplementaire')
  String? get noteSupplementaire => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Fournisseur to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Fournisseur
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FournisseurCopyWith<Fournisseur> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FournisseurCopyWith<$Res> {
  factory $FournisseurCopyWith(
    Fournisseur value,
    $Res Function(Fournisseur) then,
  ) = _$FournisseurCopyWithImpl<$Res, Fournisseur>;
  @useResult
  $Res call({
    String id,
    String nom,
    @JsonKey(name: 'contact_personne') String? contactPersonne,
    String? email,
    String? telephone,
    String? adresse,
    String? pays,
    @JsonKey(name: 'note_supplementaire') String? noteSupplementaire,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class _$FournisseurCopyWithImpl<$Res, $Val extends Fournisseur>
    implements $FournisseurCopyWith<$Res> {
  _$FournisseurCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Fournisseur
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nom = null,
    Object? contactPersonne = freezed,
    Object? email = freezed,
    Object? telephone = freezed,
    Object? adresse = freezed,
    Object? pays = freezed,
    Object? noteSupplementaire = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            nom: null == nom
                ? _value.nom
                : nom // ignore: cast_nullable_to_non_nullable
                      as String,
            contactPersonne: freezed == contactPersonne
                ? _value.contactPersonne
                : contactPersonne // ignore: cast_nullable_to_non_nullable
                      as String?,
            email: freezed == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String?,
            telephone: freezed == telephone
                ? _value.telephone
                : telephone // ignore: cast_nullable_to_non_nullable
                      as String?,
            adresse: freezed == adresse
                ? _value.adresse
                : adresse // ignore: cast_nullable_to_non_nullable
                      as String?,
            pays: freezed == pays
                ? _value.pays
                : pays // ignore: cast_nullable_to_non_nullable
                      as String?,
            noteSupplementaire: freezed == noteSupplementaire
                ? _value.noteSupplementaire
                : noteSupplementaire // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: freezed == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FournisseurImplCopyWith<$Res>
    implements $FournisseurCopyWith<$Res> {
  factory _$$FournisseurImplCopyWith(
    _$FournisseurImpl value,
    $Res Function(_$FournisseurImpl) then,
  ) = __$$FournisseurImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String nom,
    @JsonKey(name: 'contact_personne') String? contactPersonne,
    String? email,
    String? telephone,
    String? adresse,
    String? pays,
    @JsonKey(name: 'note_supplementaire') String? noteSupplementaire,
    @JsonKey(name: 'created_at') DateTime? createdAt,
  });
}

/// @nodoc
class __$$FournisseurImplCopyWithImpl<$Res>
    extends _$FournisseurCopyWithImpl<$Res, _$FournisseurImpl>
    implements _$$FournisseurImplCopyWith<$Res> {
  __$$FournisseurImplCopyWithImpl(
    _$FournisseurImpl _value,
    $Res Function(_$FournisseurImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Fournisseur
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nom = null,
    Object? contactPersonne = freezed,
    Object? email = freezed,
    Object? telephone = freezed,
    Object? adresse = freezed,
    Object? pays = freezed,
    Object? noteSupplementaire = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(
      _$FournisseurImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        nom: null == nom
            ? _value.nom
            : nom // ignore: cast_nullable_to_non_nullable
                  as String,
        contactPersonne: freezed == contactPersonne
            ? _value.contactPersonne
            : contactPersonne // ignore: cast_nullable_to_non_nullable
                  as String?,
        email: freezed == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String?,
        telephone: freezed == telephone
            ? _value.telephone
            : telephone // ignore: cast_nullable_to_non_nullable
                  as String?,
        adresse: freezed == adresse
            ? _value.adresse
            : adresse // ignore: cast_nullable_to_non_nullable
                  as String?,
        pays: freezed == pays
            ? _value.pays
            : pays // ignore: cast_nullable_to_non_nullable
                  as String?,
        noteSupplementaire: freezed == noteSupplementaire
            ? _value.noteSupplementaire
            : noteSupplementaire // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: freezed == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FournisseurImpl implements _Fournisseur {
  const _$FournisseurImpl({
    required this.id,
    required this.nom,
    @JsonKey(name: 'contact_personne') this.contactPersonne,
    this.email,
    this.telephone,
    this.adresse,
    this.pays,
    @JsonKey(name: 'note_supplementaire') this.noteSupplementaire,
    @JsonKey(name: 'created_at') this.createdAt,
  });

  factory _$FournisseurImpl.fromJson(Map<String, dynamic> json) =>
      _$$FournisseurImplFromJson(json);

  @override
  final String id;
  @override
  final String nom;
  @override
  @JsonKey(name: 'contact_personne')
  final String? contactPersonne;
  @override
  final String? email;
  @override
  final String? telephone;
  @override
  final String? adresse;
  @override
  final String? pays;
  @override
  @JsonKey(name: 'note_supplementaire')
  final String? noteSupplementaire;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Fournisseur(id: $id, nom: $nom, contactPersonne: $contactPersonne, email: $email, telephone: $telephone, adresse: $adresse, pays: $pays, noteSupplementaire: $noteSupplementaire, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FournisseurImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nom, nom) || other.nom == nom) &&
            (identical(other.contactPersonne, contactPersonne) ||
                other.contactPersonne == contactPersonne) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.telephone, telephone) ||
                other.telephone == telephone) &&
            (identical(other.adresse, adresse) || other.adresse == adresse) &&
            (identical(other.pays, pays) || other.pays == pays) &&
            (identical(other.noteSupplementaire, noteSupplementaire) ||
                other.noteSupplementaire == noteSupplementaire) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    nom,
    contactPersonne,
    email,
    telephone,
    adresse,
    pays,
    noteSupplementaire,
    createdAt,
  );

  /// Create a copy of Fournisseur
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FournisseurImplCopyWith<_$FournisseurImpl> get copyWith =>
      __$$FournisseurImplCopyWithImpl<_$FournisseurImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FournisseurImplToJson(this);
  }
}

abstract class _Fournisseur implements Fournisseur {
  const factory _Fournisseur({
    required final String id,
    required final String nom,
    @JsonKey(name: 'contact_personne') final String? contactPersonne,
    final String? email,
    final String? telephone,
    final String? adresse,
    final String? pays,
    @JsonKey(name: 'note_supplementaire') final String? noteSupplementaire,
    @JsonKey(name: 'created_at') final DateTime? createdAt,
  }) = _$FournisseurImpl;

  factory _Fournisseur.fromJson(Map<String, dynamic> json) =
      _$FournisseurImpl.fromJson;

  @override
  String get id;
  @override
  String get nom;
  @override
  @JsonKey(name: 'contact_personne')
  String? get contactPersonne;
  @override
  String? get email;
  @override
  String? get telephone;
  @override
  String? get adresse;
  @override
  String? get pays;
  @override
  @JsonKey(name: 'note_supplementaire')
  String? get noteSupplementaire;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of Fournisseur
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FournisseurImplCopyWith<_$FournisseurImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
