/* ===========================================================
   ML_PP MVP — Modern Reception Validation Service
   Rôle: Service de validation moderne avec gestion d'erreurs élégante
   et feedback utilisateur en temps réel
   =========================================================== */
import 'package:flutter/material.dart';

/// Service de validation moderne pour les réceptions
class ModernReceptionValidationService {
  /// Valide les données d'une réception avec feedback détaillé
  static ValidationResult validateReceptionData({
    required String? ownerType,
    required String? coursDeRouteId,
    required String? partenaireId,
    required String? produitId,
    required String? citerneId,
    required double? indexAvant,
    required double? indexApres,
    required double? temperature,
    required double? densite,
  }) {
    final errors = <ValidationError>[];
    final warnings = <ValidationWarning>[];

    // Validation du propriétaire
    if (ownerType == null || ownerType.isEmpty) {
      errors.add(
        ValidationError(
          field: 'ownerType',
          message: 'Le type de propriétaire est requis',
          code: 'OWNER_REQUIRED',
        ),
      );
    }

    // Validation spécifique selon le type de propriétaire
    if (ownerType == 'MONALUXE') {
      if (coursDeRouteId == null || coursDeRouteId.isEmpty) {
        errors.add(
          ValidationError(
            field: 'coursDeRouteId',
            message:
                'Un cours de route est requis pour les réceptions Monaluxe',
            code: 'COURS_REQUIRED',
          ),
        );
      }
    } else if (ownerType == 'PARTENAIRE') {
      if (partenaireId == null || partenaireId.isEmpty) {
        errors.add(
          ValidationError(
            field: 'partenaireId',
            message: 'Un partenaire est requis pour les réceptions externes',
            code: 'PARTNER_REQUIRED',
          ),
        );
      }
    }

    // Validation du produit
    if (produitId == null || produitId.isEmpty) {
      errors.add(
        ValidationError(
          field: 'produitId',
          message: 'Un produit doit être sélectionné',
          code: 'PRODUCT_REQUIRED',
        ),
      );
    }

    // Validation de la citerne
    if (citerneId == null || citerneId.isEmpty) {
      errors.add(
        ValidationError(
          field: 'citerneId',
          message: 'Une citerne doit être sélectionnée',
          code: 'TANK_REQUIRED',
        ),
      );
    }

    // Validation des indices
    if (indexAvant == null) {
      errors.add(
        ValidationError(
          field: 'indexAvant',
          message: 'L\'index avant est requis',
          code: 'INDEX_BEFORE_REQUIRED',
        ),
      );
    } else if (indexAvant < 0) {
      errors.add(
        ValidationError(
          field: 'indexAvant',
          message: 'L\'index avant ne peut pas être négatif',
          code: 'INDEX_BEFORE_NEGATIVE',
        ),
      );
    }

    if (indexApres == null) {
      errors.add(
        ValidationError(
          field: 'indexApres',
          message: 'L\'index après est requis',
          code: 'INDEX_AFTER_REQUIRED',
        ),
      );
    } else if (indexApres < 0) {
      errors.add(
        ValidationError(
          field: 'indexApres',
          message: 'L\'index après ne peut pas être négatif',
          code: 'INDEX_AFTER_NEGATIVE',
        ),
      );
    }

    // Validation de cohérence des indices
    if (indexAvant != null && indexApres != null) {
      if (indexApres <= indexAvant) {
        errors.add(
          ValidationError(
            field: 'indexApres',
            message: 'L\'index après doit être supérieur à l\'index avant',
            code: 'INDEX_INCONSISTENT',
          ),
        );
      } else {
        final volumeBrut = indexApres - indexAvant;
        if (volumeBrut > 50000) {
          warnings.add(
            ValidationWarning(
              field: 'volumeBrut',
              message:
                  'Volume brut très élevé (${volumeBrut.toStringAsFixed(0)} L). Vérifiez les indices.',
              code: 'HIGH_VOLUME',
            ),
          );
        }
      }
    }

    // Validation de la température
    if (temperature == null) {
      errors.add(
        ValidationError(
          field: 'temperature',
          message: 'La température est requise',
          code: 'TEMPERATURE_REQUIRED',
        ),
      );
    } else if (temperature < -20 || temperature > 50) {
      warnings.add(
        ValidationWarning(
          field: 'temperature',
          message:
              'Température inhabituelle (${temperature.toStringAsFixed(1)}°C). Vérifiez la mesure.',
          code: 'UNUSUAL_TEMPERATURE',
        ),
      );
    }

    // Validation de la densité
    if (densite == null) {
      errors.add(
        ValidationError(
          field: 'densite',
          message: 'La densité est requise',
          code: 'DENSITY_REQUIRED',
        ),
      );
    } else if (densite < 0.7 || densite > 1.0) {
      warnings.add(
        ValidationWarning(
          field: 'densite',
          message:
              'Densité inhabituelle (${densite.toStringAsFixed(3)}). Vérifiez la mesure.',
          code: 'UNUSUAL_DENSITY',
        ),
      );
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Valide un champ spécifique en temps réel
  static FieldValidationResult validateField({
    required String fieldName,
    required dynamic value,
    Map<String, dynamic>? context,
  }) {
    switch (fieldName) {
      case 'indexAvant':
        return _validateIndex(value, 'avant');
      case 'indexApres':
        return _validateIndex(value, 'après');
      case 'temperature':
        return _validateTemperature(value);
      case 'densite':
        return _validateDensity(value);
      case 'coursDeRouteId':
        return _validateCoursDeRoute(value);
      case 'partenaireId':
        return _validatePartenaire(value);
      case 'produitId':
        return _validateProduit(value);
      case 'citerneId':
        return _validateCiterne(value);
      default:
        return FieldValidationResult(
          isValid: true,
          message: null,
          type: ValidationType.info,
        );
    }
  }

  static FieldValidationResult _validateIndex(dynamic value, String type) {
    if (value == null || value.toString().isEmpty) {
      return FieldValidationResult(
        isValid: false,
        message: 'Index $type requis',
        type: ValidationType.error,
      );
    }

    final numValue = double.tryParse(value.toString());
    if (numValue == null) {
      return FieldValidationResult(
        isValid: false,
        message: 'Format invalide pour l\'index $type',
        type: ValidationType.error,
      );
    }

    if (numValue < 0) {
      return FieldValidationResult(
        isValid: false,
        message: 'L\'index $type ne peut pas être négatif',
        type: ValidationType.error,
      );
    }

    if (numValue > 1000000) {
      return FieldValidationResult(
        isValid: false,
        message: 'Index $type très élevé. Vérifiez la mesure.',
        type: ValidationType.warning,
      );
    }

    return FieldValidationResult(
      isValid: true,
      message: 'Index $type valide',
      type: ValidationType.success,
    );
  }

  static FieldValidationResult _validateTemperature(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return FieldValidationResult(
        isValid: false,
        message: 'Température requise',
        type: ValidationType.error,
      );
    }

    final numValue = double.tryParse(value.toString());
    if (numValue == null) {
      return FieldValidationResult(
        isValid: false,
        message: 'Format invalide pour la température',
        type: ValidationType.error,
      );
    }

    if (numValue < -20 || numValue > 50) {
      return FieldValidationResult(
        isValid: false,
        message: 'Température inhabituelle (${numValue.toStringAsFixed(1)}°C)',
        type: ValidationType.warning,
      );
    }

    return FieldValidationResult(
      isValid: true,
      message: 'Température valide',
      type: ValidationType.success,
    );
  }

  static FieldValidationResult _validateDensity(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return FieldValidationResult(
        isValid: false,
        message: 'Densité requise',
        type: ValidationType.error,
      );
    }

    final numValue = double.tryParse(value.toString());
    if (numValue == null) {
      return FieldValidationResult(
        isValid: false,
        message: 'Format invalide pour la densité',
        type: ValidationType.error,
      );
    }

    if (numValue < 0.7 || numValue > 1.0) {
      return FieldValidationResult(
        isValid: false,
        message: 'Densité inhabituelle (${numValue.toStringAsFixed(3)})',
        type: ValidationType.warning,
      );
    }

    return FieldValidationResult(
      isValid: true,
      message: 'Densité valide',
      type: ValidationType.success,
    );
  }

  static FieldValidationResult _validateCoursDeRoute(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return FieldValidationResult(
        isValid: false,
        message: 'Cours de route requis',
        type: ValidationType.error,
      );
    }

    return FieldValidationResult(
      isValid: true,
      message: 'Cours de route sélectionné',
      type: ValidationType.success,
    );
  }

  static FieldValidationResult _validatePartenaire(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return FieldValidationResult(
        isValid: false,
        message: 'Partenaire requis',
        type: ValidationType.error,
      );
    }

    return FieldValidationResult(
      isValid: true,
      message: 'Partenaire sélectionné',
      type: ValidationType.success,
    );
  }

  static FieldValidationResult _validateProduit(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return FieldValidationResult(
        isValid: false,
        message: 'Produit requis',
        type: ValidationType.error,
      );
    }

    return FieldValidationResult(
      isValid: true,
      message: 'Produit sélectionné',
      type: ValidationType.success,
    );
  }

  static FieldValidationResult _validateCiterne(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return FieldValidationResult(
        isValid: false,
        message: 'Citerne requise',
        type: ValidationType.error,
      );
    }

    return FieldValidationResult(
      isValid: true,
      message: 'Citerne sélectionnée',
      type: ValidationType.success,
    );
  }
}

/// Résultat de validation globale
class ValidationResult {
  final bool isValid;
  final List<ValidationError> errors;
  final List<ValidationWarning> warnings;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  /// Retourne le message d'erreur principal
  String? get primaryErrorMessage {
    if (errors.isEmpty) return null;
    return errors.first.message;
  }

  /// Retourne tous les messages d'erreur
  List<String> get errorMessages => errors.map((e) => e.message).toList();

  /// Retourne tous les messages d'avertissement
  List<String> get warningMessages => warnings.map((w) => w.message).toList();
}

/// Résultat de validation d'un champ spécifique
class FieldValidationResult {
  final bool isValid;
  final String? message;
  final ValidationType type;

  const FieldValidationResult({
    required this.isValid,
    required this.message,
    required this.type,
  });
}

/// Erreur de validation
class ValidationError {
  final String field;
  final String message;
  final String code;

  const ValidationError({
    required this.field,
    required this.message,
    required this.code,
  });
}

/// Avertissement de validation
class ValidationWarning {
  final String field;
  final String message;
  final String code;

  const ValidationWarning({
    required this.field,
    required this.message,
    required this.code,
  });
}

/// Type de validation
enum ValidationType { success, warning, error, info }

/// Extension pour obtenir la couleur appropriée selon le type de validation
extension ValidationTypeExtension on ValidationType {
  Color getColor(ThemeData theme) {
    switch (this) {
      case ValidationType.success:
        return Colors.green;
      case ValidationType.warning:
        return Colors.orange;
      case ValidationType.error:
        return theme.colorScheme.error;
      case ValidationType.info:
        return theme.colorScheme.primary;
    }
  }

  IconData getIcon() {
    switch (this) {
      case ValidationType.success:
        return Icons.check_circle_rounded;
      case ValidationType.warning:
        return Icons.warning_rounded;
      case ValidationType.error:
        return Icons.error_rounded;
      case ValidationType.info:
        return Icons.info_rounded;
    }
  }
}
