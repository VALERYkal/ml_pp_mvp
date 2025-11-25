// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profil.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Profil _$ProfilFromJson(Map<String, dynamic> json) {
  return _Profil.fromJson(json);
}

/// @nodoc
mixin _$Profil {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'user_id')
  String? get userId => throw _privateConstructorUsedError;
  @JsonKey(name: 'nom_complet')
  String? get nomComplet => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  @JsonKey(name: 'depot_id')
  String? get depotId => throw _privateConstructorUsedError;
  String? get email => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Profil to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Profil
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfilCopyWith<Profil> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfilCopyWith<$Res> {
  factory $ProfilCopyWith(Profil value, $Res Function(Profil) then) =
      _$ProfilCopyWithImpl<$Res, Profil>;
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String? userId,
      @JsonKey(name: 'nom_complet') String? nomComplet,
      String role,
      @JsonKey(name: 'depot_id') String? depotId,
      String? email,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class _$ProfilCopyWithImpl<$Res, $Val extends Profil>
    implements $ProfilCopyWith<$Res> {
  _$ProfilCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Profil
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = freezed,
    Object? nomComplet = freezed,
    Object? role = null,
    Object? depotId = freezed,
    Object? email = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      nomComplet: freezed == nomComplet
          ? _value.nomComplet
          : nomComplet // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      depotId: freezed == depotId
          ? _value.depotId
          : depotId // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfilImplCopyWith<$Res> implements $ProfilCopyWith<$Res> {
  factory _$$ProfilImplCopyWith(
          _$ProfilImpl value, $Res Function(_$ProfilImpl) then) =
      __$$ProfilImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @JsonKey(name: 'user_id') String? userId,
      @JsonKey(name: 'nom_complet') String? nomComplet,
      String role,
      @JsonKey(name: 'depot_id') String? depotId,
      String? email,
      @JsonKey(name: 'created_at') DateTime? createdAt});
}

/// @nodoc
class __$$ProfilImplCopyWithImpl<$Res>
    extends _$ProfilCopyWithImpl<$Res, _$ProfilImpl>
    implements _$$ProfilImplCopyWith<$Res> {
  __$$ProfilImplCopyWithImpl(
      _$ProfilImpl _value, $Res Function(_$ProfilImpl) _then)
      : super(_value, _then);

  /// Create a copy of Profil
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = freezed,
    Object? nomComplet = freezed,
    Object? role = null,
    Object? depotId = freezed,
    Object? email = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$ProfilImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: freezed == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String?,
      nomComplet: freezed == nomComplet
          ? _value.nomComplet
          : nomComplet // ignore: cast_nullable_to_non_nullable
              as String?,
      role: null == role
          ? _value.role
          : role // ignore: cast_nullable_to_non_nullable
              as String,
      depotId: freezed == depotId
          ? _value.depotId
          : depotId // ignore: cast_nullable_to_non_nullable
              as String?,
      email: freezed == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfilImpl implements _Profil {
  const _$ProfilImpl(
      {required this.id,
      @JsonKey(name: 'user_id') this.userId,
      @JsonKey(name: 'nom_complet') this.nomComplet,
      required this.role,
      @JsonKey(name: 'depot_id') this.depotId,
      this.email,
      @JsonKey(name: 'created_at') this.createdAt});

  factory _$ProfilImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfilImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'user_id')
  final String? userId;
  @override
  @JsonKey(name: 'nom_complet')
  final String? nomComplet;
  @override
  final String role;
  @override
  @JsonKey(name: 'depot_id')
  final String? depotId;
  @override
  final String? email;
  @override
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  @override
  String toString() {
    return 'Profil(id: $id, userId: $userId, nomComplet: $nomComplet, role: $role, depotId: $depotId, email: $email, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfilImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.nomComplet, nomComplet) ||
                other.nomComplet == nomComplet) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.depotId, depotId) || other.depotId == depotId) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, id, userId, nomComplet, role, depotId, email, createdAt);

  /// Create a copy of Profil
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfilImplCopyWith<_$ProfilImpl> get copyWith =>
      __$$ProfilImplCopyWithImpl<_$ProfilImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfilImplToJson(
      this,
    );
  }
}

abstract class _Profil implements Profil {
  const factory _Profil(
      {required final String id,
      @JsonKey(name: 'user_id') final String? userId,
      @JsonKey(name: 'nom_complet') final String? nomComplet,
      required final String role,
      @JsonKey(name: 'depot_id') final String? depotId,
      final String? email,
      @JsonKey(name: 'created_at') final DateTime? createdAt}) = _$ProfilImpl;

  factory _Profil.fromJson(Map<String, dynamic> json) = _$ProfilImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'user_id')
  String? get userId;
  @override
  @JsonKey(name: 'nom_complet')
  String? get nomComplet;
  @override
  String get role;
  @override
  @JsonKey(name: 'depot_id')
  String? get depotId;
  @override
  String? get email;
  @override
  @JsonKey(name: 'created_at')
  DateTime? get createdAt;

  /// Create a copy of Profil
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfilImplCopyWith<_$ProfilImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
