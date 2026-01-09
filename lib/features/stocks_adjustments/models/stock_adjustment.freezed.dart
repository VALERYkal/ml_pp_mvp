// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_adjustment.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

StockAdjustment _$StockAdjustmentFromJson(Map<String, dynamic> json) {
  return _StockAdjustment.fromJson(json);
}

/// @nodoc
mixin _$StockAdjustment {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'mouvement_type')
  String get mouvementType => throw _privateConstructorUsedError;
  @JsonKey(name: 'mouvement_id')
  String get mouvementId => throw _privateConstructorUsedError;
  @JsonKey(name: 'delta_ambiant')
  double get deltaAmbiant => throw _privateConstructorUsedError;
  @JsonKey(name: 'delta_15c')
  double get delta15c => throw _privateConstructorUsedError;
  String get reason => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_by')
  String get createdBy => throw _privateConstructorUsedError;
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this StockAdjustment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StockAdjustment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StockAdjustmentCopyWith<StockAdjustment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StockAdjustmentCopyWith<$Res> {
  factory $StockAdjustmentCopyWith(
    StockAdjustment value,
    $Res Function(StockAdjustment) then,
  ) = _$StockAdjustmentCopyWithImpl<$Res, StockAdjustment>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'mouvement_type') String mouvementType,
    @JsonKey(name: 'mouvement_id') String mouvementId,
    @JsonKey(name: 'delta_ambiant') double deltaAmbiant,
    @JsonKey(name: 'delta_15c') double delta15c,
    String reason,
    @JsonKey(name: 'created_by') String createdBy,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class _$StockAdjustmentCopyWithImpl<$Res, $Val extends StockAdjustment>
    implements $StockAdjustmentCopyWith<$Res> {
  _$StockAdjustmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StockAdjustment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mouvementType = null,
    Object? mouvementId = null,
    Object? deltaAmbiant = null,
    Object? delta15c = null,
    Object? reason = null,
    Object? createdBy = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            mouvementType: null == mouvementType
                ? _value.mouvementType
                : mouvementType // ignore: cast_nullable_to_non_nullable
                      as String,
            mouvementId: null == mouvementId
                ? _value.mouvementId
                : mouvementId // ignore: cast_nullable_to_non_nullable
                      as String,
            deltaAmbiant: null == deltaAmbiant
                ? _value.deltaAmbiant
                : deltaAmbiant // ignore: cast_nullable_to_non_nullable
                      as double,
            delta15c: null == delta15c
                ? _value.delta15c
                : delta15c // ignore: cast_nullable_to_non_nullable
                      as double,
            reason: null == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String,
            createdBy: null == createdBy
                ? _value.createdBy
                : createdBy // ignore: cast_nullable_to_non_nullable
                      as String,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StockAdjustmentImplCopyWith<$Res>
    implements $StockAdjustmentCopyWith<$Res> {
  factory _$$StockAdjustmentImplCopyWith(
    _$StockAdjustmentImpl value,
    $Res Function(_$StockAdjustmentImpl) then,
  ) = __$$StockAdjustmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'mouvement_type') String mouvementType,
    @JsonKey(name: 'mouvement_id') String mouvementId,
    @JsonKey(name: 'delta_ambiant') double deltaAmbiant,
    @JsonKey(name: 'delta_15c') double delta15c,
    String reason,
    @JsonKey(name: 'created_by') String createdBy,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class __$$StockAdjustmentImplCopyWithImpl<$Res>
    extends _$StockAdjustmentCopyWithImpl<$Res, _$StockAdjustmentImpl>
    implements _$$StockAdjustmentImplCopyWith<$Res> {
  __$$StockAdjustmentImplCopyWithImpl(
    _$StockAdjustmentImpl _value,
    $Res Function(_$StockAdjustmentImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StockAdjustment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mouvementType = null,
    Object? mouvementId = null,
    Object? deltaAmbiant = null,
    Object? delta15c = null,
    Object? reason = null,
    Object? createdBy = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$StockAdjustmentImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        mouvementType: null == mouvementType
            ? _value.mouvementType
            : mouvementType // ignore: cast_nullable_to_non_nullable
                  as String,
        mouvementId: null == mouvementId
            ? _value.mouvementId
            : mouvementId // ignore: cast_nullable_to_non_nullable
                  as String,
        deltaAmbiant: null == deltaAmbiant
            ? _value.deltaAmbiant
            : deltaAmbiant // ignore: cast_nullable_to_non_nullable
                  as double,
        delta15c: null == delta15c
            ? _value.delta15c
            : delta15c // ignore: cast_nullable_to_non_nullable
                  as double,
        reason: null == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String,
        createdBy: null == createdBy
            ? _value.createdBy
            : createdBy // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StockAdjustmentImpl implements _StockAdjustment {
  const _$StockAdjustmentImpl({
    required this.id,
    @JsonKey(name: 'mouvement_type') required this.mouvementType,
    @JsonKey(name: 'mouvement_id') required this.mouvementId,
    @JsonKey(name: 'delta_ambiant') required this.deltaAmbiant,
    @JsonKey(name: 'delta_15c') required this.delta15c,
    required this.reason,
    @JsonKey(name: 'created_by') required this.createdBy,
    @JsonKey(name: 'created_at') required this.createdAt,
  });

  factory _$StockAdjustmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$StockAdjustmentImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'mouvement_type')
  final String mouvementType;
  @override
  @JsonKey(name: 'mouvement_id')
  final String mouvementId;
  @override
  @JsonKey(name: 'delta_ambiant')
  final double deltaAmbiant;
  @override
  @JsonKey(name: 'delta_15c')
  final double delta15c;
  @override
  final String reason;
  @override
  @JsonKey(name: 'created_by')
  final String createdBy;
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'StockAdjustment(id: $id, mouvementType: $mouvementType, mouvementId: $mouvementId, deltaAmbiant: $deltaAmbiant, delta15c: $delta15c, reason: $reason, createdBy: $createdBy, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StockAdjustmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.mouvementType, mouvementType) ||
                other.mouvementType == mouvementType) &&
            (identical(other.mouvementId, mouvementId) ||
                other.mouvementId == mouvementId) &&
            (identical(other.deltaAmbiant, deltaAmbiant) ||
                other.deltaAmbiant == deltaAmbiant) &&
            (identical(other.delta15c, delta15c) ||
                other.delta15c == delta15c) &&
            (identical(other.reason, reason) || other.reason == reason) &&
            (identical(other.createdBy, createdBy) ||
                other.createdBy == createdBy) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    mouvementType,
    mouvementId,
    deltaAmbiant,
    delta15c,
    reason,
    createdBy,
    createdAt,
  );

  /// Create a copy of StockAdjustment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StockAdjustmentImplCopyWith<_$StockAdjustmentImpl> get copyWith =>
      __$$StockAdjustmentImplCopyWithImpl<_$StockAdjustmentImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StockAdjustmentImplToJson(this);
  }
}

abstract class _StockAdjustment implements StockAdjustment {
  const factory _StockAdjustment({
    required final String id,
    @JsonKey(name: 'mouvement_type') required final String mouvementType,
    @JsonKey(name: 'mouvement_id') required final String mouvementId,
    @JsonKey(name: 'delta_ambiant') required final double deltaAmbiant,
    @JsonKey(name: 'delta_15c') required final double delta15c,
    required final String reason,
    @JsonKey(name: 'created_by') required final String createdBy,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
  }) = _$StockAdjustmentImpl;

  factory _StockAdjustment.fromJson(Map<String, dynamic> json) =
      _$StockAdjustmentImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'mouvement_type')
  String get mouvementType;
  @override
  @JsonKey(name: 'mouvement_id')
  String get mouvementId;
  @override
  @JsonKey(name: 'delta_ambiant')
  double get deltaAmbiant;
  @override
  @JsonKey(name: 'delta_15c')
  double get delta15c;
  @override
  String get reason;
  @override
  @JsonKey(name: 'created_by')
  String get createdBy;
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of StockAdjustment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StockAdjustmentImplCopyWith<_$StockAdjustmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
