// 📌 Module : Réceptions - Owner Type Enum
// 🧭 Description : Type de propriétaire pour une réception

import 'package:freezed_annotation/freezed_annotation.dart';

enum OwnerType {
  monaluxe('MONALUXE'),
  partenaire('PARTENAIRE');

  final String value;
  const OwnerType(this.value);

  static OwnerType? fromString(String? value) {
    if (value == null) return null;
    final v = value.trim().toUpperCase();
    for (final e in OwnerType.values) {
      if (e.value == v) return e;
    }
    return null;
  }

  String toJson() => value;
  @override
  String toString() => value;
}

/// Convertisseur JSON pour OwnerType
class OwnerTypeConverter implements JsonConverter<OwnerType, String> {
  const OwnerTypeConverter();

  @override
  OwnerType fromJson(String json) => OwnerType.fromString(json) ?? OwnerType.monaluxe;

  @override
  String toJson(OwnerType object) => object.toJson();
}


