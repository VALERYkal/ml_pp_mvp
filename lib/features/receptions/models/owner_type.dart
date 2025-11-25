import 'package:freezed_annotation/freezed_annotation.dart';

enum OwnerType { MONALUXE, PARTENAIRE }

class OwnerTypeConverter implements JsonConverter<OwnerType, String> {
  const OwnerTypeConverter();

  @override
  OwnerType fromJson(String json) =>
      json.toUpperCase() == 'PARTENAIRE' ? OwnerType.PARTENAIRE : OwnerType.MONALUXE;

  @override
  String toJson(OwnerType value) =>
      value == OwnerType.PARTENAIRE ? 'PARTENAIRE' : 'MONALUXE';
}

