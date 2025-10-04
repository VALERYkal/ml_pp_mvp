// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reception_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ReceptionInput _$ReceptionInputFromJson(Map<String, dynamic> json) {
  return _ReceptionInput.fromJson(json);
}

/// @nodoc
mixin _$ReceptionInput {
  String get proprietaireType => throw _privateConstructorUsedError; // 'MONALUXE' | 'PARTENAIRE'
  String? get partenaireId => throw _privateConstructorUsedError; // requis si PARTENAIRE
  String get citerneId => throw _privateConstructorUsedError; // citerne active
  String get produitCode =>
      throw _privateConstructorUsedError; // 'ESS' | 'AGO' (reste utile pour calcul @15°C)
  String? get produitId =>
      throw _privateConstructorUsedError; // <-- NEW: override direct du produit (UUID)
  double? get indexAvant => throw _privateConstructorUsedError;
  double? get indexApres => throw _privateConstructorUsedError;
  double? get temperatureC => throw _privateConstructorUsedError;
  double? get densiteA15 => throw _privateConstructorUsedError;
  DateTime? get dateReception => throw _privateConstructorUsedError; // SQL date -> yyyy-MM-dd
  String? get coursDeRouteId =>
      throw _privateConstructorUsedError; // requis si Monaluxe lié à un cours 'arrivé'
  String? get note => throw _privateConstructorUsedError;

  /// Serializes this ReceptionInput to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ReceptionInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ReceptionInputCopyWith<ReceptionInput> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ReceptionInputCopyWith<$Res> {
  factory $ReceptionInputCopyWith(ReceptionInput value, $Res Function(ReceptionInput) then) =
      _$ReceptionInputCopyWithImpl<$Res, ReceptionInput>;
  @useResult
  $Res call({
    String proprietaireType,
    String? partenaireId,
    String citerneId,
    String produitCode,
    String? produitId,
    double? indexAvant,
    double? indexApres,
    double? temperatureC,
    double? densiteA15,
    DateTime? dateReception,
    String? coursDeRouteId,
    String? note,
  });
}

/// @nodoc
class _$ReceptionInputCopyWithImpl<$Res, $Val extends ReceptionInput>
    implements $ReceptionInputCopyWith<$Res> {
  _$ReceptionInputCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ReceptionInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? proprietaireType = null,
    Object? partenaireId = freezed,
    Object? citerneId = null,
    Object? produitCode = null,
    Object? produitId = freezed,
    Object? indexAvant = freezed,
    Object? indexApres = freezed,
    Object? temperatureC = freezed,
    Object? densiteA15 = freezed,
    Object? dateReception = freezed,
    Object? coursDeRouteId = freezed,
    Object? note = freezed,
  }) {
    return _then(
      _value.copyWith(
            proprietaireType: null == proprietaireType
                ? _value.proprietaireType
                : proprietaireType // ignore: cast_nullable_to_non_nullable
                      as String,
            partenaireId: freezed == partenaireId
                ? _value.partenaireId
                : partenaireId // ignore: cast_nullable_to_non_nullable
                      as String?,
            citerneId: null == citerneId
                ? _value.citerneId
                : citerneId // ignore: cast_nullable_to_non_nullable
                      as String,
            produitCode: null == produitCode
                ? _value.produitCode
                : produitCode // ignore: cast_nullable_to_non_nullable
                      as String,
            produitId: freezed == produitId
                ? _value.produitId
                : produitId // ignore: cast_nullable_to_non_nullable
                      as String?,
            indexAvant: freezed == indexAvant
                ? _value.indexAvant
                : indexAvant // ignore: cast_nullable_to_non_nullable
                      as double?,
            indexApres: freezed == indexApres
                ? _value.indexApres
                : indexApres // ignore: cast_nullable_to_non_nullable
                      as double?,
            temperatureC: freezed == temperatureC
                ? _value.temperatureC
                : temperatureC // ignore: cast_nullable_to_non_nullable
                      as double?,
            densiteA15: freezed == densiteA15
                ? _value.densiteA15
                : densiteA15 // ignore: cast_nullable_to_non_nullable
                      as double?,
            dateReception: freezed == dateReception
                ? _value.dateReception
                : dateReception // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            coursDeRouteId: freezed == coursDeRouteId
                ? _value.coursDeRouteId
                : coursDeRouteId // ignore: cast_nullable_to_non_nullable
                      as String?,
            note: freezed == note
                ? _value.note
                : note // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ReceptionInputImplCopyWith<$Res> implements $ReceptionInputCopyWith<$Res> {
  factory _$$ReceptionInputImplCopyWith(
    _$ReceptionInputImpl value,
    $Res Function(_$ReceptionInputImpl) then,
  ) = __$$ReceptionInputImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String proprietaireType,
    String? partenaireId,
    String citerneId,
    String produitCode,
    String? produitId,
    double? indexAvant,
    double? indexApres,
    double? temperatureC,
    double? densiteA15,
    DateTime? dateReception,
    String? coursDeRouteId,
    String? note,
  });
}

/// @nodoc
class __$$ReceptionInputImplCopyWithImpl<$Res>
    extends _$ReceptionInputCopyWithImpl<$Res, _$ReceptionInputImpl>
    implements _$$ReceptionInputImplCopyWith<$Res> {
  __$$ReceptionInputImplCopyWithImpl(
    _$ReceptionInputImpl _value,
    $Res Function(_$ReceptionInputImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ReceptionInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? proprietaireType = null,
    Object? partenaireId = freezed,
    Object? citerneId = null,
    Object? produitCode = null,
    Object? produitId = freezed,
    Object? indexAvant = freezed,
    Object? indexApres = freezed,
    Object? temperatureC = freezed,
    Object? densiteA15 = freezed,
    Object? dateReception = freezed,
    Object? coursDeRouteId = freezed,
    Object? note = freezed,
  }) {
    return _then(
      _$ReceptionInputImpl(
        proprietaireType: null == proprietaireType
            ? _value.proprietaireType
            : proprietaireType // ignore: cast_nullable_to_non_nullable
                  as String,
        partenaireId: freezed == partenaireId
            ? _value.partenaireId
            : partenaireId // ignore: cast_nullable_to_non_nullable
                  as String?,
        citerneId: null == citerneId
            ? _value.citerneId
            : citerneId // ignore: cast_nullable_to_non_nullable
                  as String,
        produitCode: null == produitCode
            ? _value.produitCode
            : produitCode // ignore: cast_nullable_to_non_nullable
                  as String,
        produitId: freezed == produitId
            ? _value.produitId
            : produitId // ignore: cast_nullable_to_non_nullable
                  as String?,
        indexAvant: freezed == indexAvant
            ? _value.indexAvant
            : indexAvant // ignore: cast_nullable_to_non_nullable
                  as double?,
        indexApres: freezed == indexApres
            ? _value.indexApres
            : indexApres // ignore: cast_nullable_to_non_nullable
                  as double?,
        temperatureC: freezed == temperatureC
            ? _value.temperatureC
            : temperatureC // ignore: cast_nullable_to_non_nullable
                  as double?,
        densiteA15: freezed == densiteA15
            ? _value.densiteA15
            : densiteA15 // ignore: cast_nullable_to_non_nullable
                  as double?,
        dateReception: freezed == dateReception
            ? _value.dateReception
            : dateReception // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        coursDeRouteId: freezed == coursDeRouteId
            ? _value.coursDeRouteId
            : coursDeRouteId // ignore: cast_nullable_to_non_nullable
                  as String?,
        note: freezed == note
            ? _value.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ReceptionInputImpl implements _ReceptionInput {
  const _$ReceptionInputImpl({
    required this.proprietaireType,
    this.partenaireId,
    required this.citerneId,
    required this.produitCode,
    this.produitId,
    this.indexAvant,
    this.indexApres,
    this.temperatureC,
    this.densiteA15,
    this.dateReception,
    this.coursDeRouteId,
    this.note,
  });

  factory _$ReceptionInputImpl.fromJson(Map<String, dynamic> json) =>
      _$$ReceptionInputImplFromJson(json);

  @override
  final String proprietaireType;
  // 'MONALUXE' | 'PARTENAIRE'
  @override
  final String? partenaireId;
  // requis si PARTENAIRE
  @override
  final String citerneId;
  // citerne active
  @override
  final String produitCode;
  // 'ESS' | 'AGO' (reste utile pour calcul @15°C)
  @override
  final String? produitId;
  // <-- NEW: override direct du produit (UUID)
  @override
  final double? indexAvant;
  @override
  final double? indexApres;
  @override
  final double? temperatureC;
  @override
  final double? densiteA15;
  @override
  final DateTime? dateReception;
  // SQL date -> yyyy-MM-dd
  @override
  final String? coursDeRouteId;
  // requis si Monaluxe lié à un cours 'arrivé'
  @override
  final String? note;

  @override
  String toString() {
    return 'ReceptionInput(proprietaireType: $proprietaireType, partenaireId: $partenaireId, citerneId: $citerneId, produitCode: $produitCode, produitId: $produitId, indexAvant: $indexAvant, indexApres: $indexApres, temperatureC: $temperatureC, densiteA15: $densiteA15, dateReception: $dateReception, coursDeRouteId: $coursDeRouteId, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ReceptionInputImpl &&
            (identical(other.proprietaireType, proprietaireType) ||
                other.proprietaireType == proprietaireType) &&
            (identical(other.partenaireId, partenaireId) || other.partenaireId == partenaireId) &&
            (identical(other.citerneId, citerneId) || other.citerneId == citerneId) &&
            (identical(other.produitCode, produitCode) || other.produitCode == produitCode) &&
            (identical(other.produitId, produitId) || other.produitId == produitId) &&
            (identical(other.indexAvant, indexAvant) || other.indexAvant == indexAvant) &&
            (identical(other.indexApres, indexApres) || other.indexApres == indexApres) &&
            (identical(other.temperatureC, temperatureC) || other.temperatureC == temperatureC) &&
            (identical(other.densiteA15, densiteA15) || other.densiteA15 == densiteA15) &&
            (identical(other.dateReception, dateReception) ||
                other.dateReception == dateReception) &&
            (identical(other.coursDeRouteId, coursDeRouteId) ||
                other.coursDeRouteId == coursDeRouteId) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    proprietaireType,
    partenaireId,
    citerneId,
    produitCode,
    produitId,
    indexAvant,
    indexApres,
    temperatureC,
    densiteA15,
    dateReception,
    coursDeRouteId,
    note,
  );

  /// Create a copy of ReceptionInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ReceptionInputImplCopyWith<_$ReceptionInputImpl> get copyWith =>
      __$$ReceptionInputImplCopyWithImpl<_$ReceptionInputImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ReceptionInputImplToJson(this);
  }
}

abstract class _ReceptionInput implements ReceptionInput {
  const factory _ReceptionInput({
    required final String proprietaireType,
    final String? partenaireId,
    required final String citerneId,
    required final String produitCode,
    final String? produitId,
    final double? indexAvant,
    final double? indexApres,
    final double? temperatureC,
    final double? densiteA15,
    final DateTime? dateReception,
    final String? coursDeRouteId,
    final String? note,
  }) = _$ReceptionInputImpl;

  factory _ReceptionInput.fromJson(Map<String, dynamic> json) = _$ReceptionInputImpl.fromJson;

  @override
  String get proprietaireType; // 'MONALUXE' | 'PARTENAIRE'
  @override
  String? get partenaireId; // requis si PARTENAIRE
  @override
  String get citerneId; // citerne active
  @override
  String get produitCode; // 'ESS' | 'AGO' (reste utile pour calcul @15°C)
  @override
  String? get produitId; // <-- NEW: override direct du produit (UUID)
  @override
  double? get indexAvant;
  @override
  double? get indexApres;
  @override
  double? get temperatureC;
  @override
  double? get densiteA15;
  @override
  DateTime? get dateReception; // SQL date -> yyyy-MM-dd
  @override
  String? get coursDeRouteId; // requis si Monaluxe lié à un cours 'arrivé'
  @override
  String? get note;

  /// Create a copy of ReceptionInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ReceptionInputImplCopyWith<_$ReceptionInputImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
