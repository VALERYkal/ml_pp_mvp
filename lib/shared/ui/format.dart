// ?? Module : Shared UI - Format
// ?? Auteur : Valery Kalonga
// ?? Date : 2025-01-27
// ?? Description : Utilitaires pour le formatage des données

/// Formate une date en format court (YYYY-MM-DD)
///
/// [d] : La date à formater (peut être null)
///
/// Retourne :
/// - `''` si la date est null
/// - `'YYYY-MM-DD'` si la date est valide
///
/// Exemple d'utilisation :
/// ```dart
/// final dateStr = fmtDate(DateTime.now()); // '2025-01-27'
/// final emptyStr = fmtDate(null); // ''
/// ```
String fmtDate(DateTime? d) {
  if (d == null) return '';
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Formate un volume en litres avec unité
///
/// [volume] : Le volume en litres (peut être null)
///
/// Retourne :
/// - `''` si le volume est null
/// - `'XXX L'` si le volume est valide
///
/// Exemple d'utilisation :
/// ```dart
/// final volumeStr = fmtVolume(1500.5); // '1501 L'
/// final emptyStr = fmtVolume(null); // ''
/// ```
String fmtVolume(double? volume) {
  if (volume == null) return '';
  return '${volume.toStringAsFixed(0)} L';
}

/// Formate un nom à partir d'une map d'identifiants
///
/// [map] : Map des identifiants vers noms
/// [id] : Identifiant à rechercher (peut être null)
/// [def] : Valeur par défaut si non trouvé
///
/// Retourne :
/// - [def] si l'id est null ou non trouvé
/// - Le nom correspondant si trouvé
///
/// Exemple d'utilisation :
/// ```dart
/// final nom = nameOf(fournisseurs, 'uuid-123', def: '');
/// ```
String nameOf(Map<String, String> map, String? id, {String def = ''}) {
  if (id == null || id.isEmpty) return def;
  return map[id] ?? def;
}

