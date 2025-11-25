// ?? Module : Shared Utils
// ?? Description : Utilitaires de formatage des volumes

/// Utilitaires pour le formatage des volumes
class VolumeFormatter {
  /// Formate un volume avec unité (L)
  ///
  /// [volume] : Volume à formater (peut être num, String, ou null)
  /// [decimals] : Nombre de décimales (défaut: 1)
  ///
  /// Retourne :
  /// - `String` : Volume formaté avec unité (ex: "1,234.5 L")
  /// - `''` : Si le volume est null ou invalide
  static String formatVolume(dynamic volume, {int decimals = 1}) {
    if (volume == null) return '';

    try {
      final v = double.tryParse(volume.toString());
      if (v == null || !v.isFinite) return '';

      return '${v.toStringAsFixed(decimals)} L';
    } catch (e) {
      return '';
    }
  }

  /// Formate un volume avec unité et précision adaptée
  ///
  /// [volume] : Volume à formater
  ///
  /// Retourne :
  /// - `String` : Volume formaté avec précision adaptée
  /// - `''` : Si le volume est null ou invalide
  static String formatVolumeSmart(dynamic volume) {
    if (volume == null) return '';

    try {
      final v = double.tryParse(volume.toString());
      if (v == null || !v.isFinite) return '';

      // Si le volume est entier, pas de décimales
      if (v == v.toInt()) {
        return '${v.toInt()} L';
      }

      // Sinon, 1 décimale
      return '${v.toStringAsFixed(1)} L';
    } catch (e) {
      return '';
    }
  }

  /// Formate un volume en format compact (ex: "1 000 L")
  ///
  /// [volume] : Volume à formater
  ///
  /// Retourne :
  /// - `String` : Volume formaté en format compact
  /// - `''` : Si le volume est null ou invalide
  static String formatVolumeCompact(dynamic volume) {
    if (volume == null) return '';

    try {
      final v = double.tryParse(volume.toString());
      if (v == null || !v.isFinite) return '';

      if (v >= 1000) {
        return '${(v / 1000).toStringAsFixed(0)} 000 L';
      } else if (v >= 1) {
        return '${v.toStringAsFixed(1)} L';
      } else {
        return '${(v * 1000).toStringAsFixed(0)} mL';
      }
    } catch (e) {
      return '';
    }
  }

  /// Formate un pourcentage
  ///
  /// [value] : Valeur à formater (0.0 à 1.0)
  ///
  /// Retourne :
  /// - `String` : Pourcentage formaté (ex: "85.5%")
  /// - `''` : Si la valeur est null ou invalide
  static String formatPercentage(dynamic value) {
    if (value == null) return '';

    try {
      final v = double.tryParse(value.toString());
      if (v == null || !v.isFinite) return '';

      return '${(v * 100).toStringAsFixed(1)}%';
    } catch (e) {
      return '';
    }
  }
}




