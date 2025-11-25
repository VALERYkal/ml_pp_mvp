// ?? Module : Sorties - Models
// ?? Description : Modèle pour afficher les citernes avec leurs stocks

/// Modèle léger pour afficher une citerne avec ses stocks actuels
class CiterneWithStockForSortie {
  final String id;
  final String nom;
  final double? capaciteTotale;
  final double? stockAmbiant;
  final double? stock15c;
  final DateTime? date;

  const CiterneWithStockForSortie({
    required this.id,
    required this.nom,
    this.capaciteTotale,
    this.stockAmbiant,
    this.stock15c,
    this.date,
  });

  /// Crée une instance depuis les données Supabase
  factory CiterneWithStockForSortie.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic d) {
      if (d == null) return null;
      try {
        return DateTime.parse(d.toString());
      } catch (_) {
        return null;
      }
    }

    return CiterneWithStockForSortie(
      id: map['id'] as String,
      nom: map['nom']?.toString() ?? 'Sans nom',
      capaciteTotale: (map['capacite_totale'] as num?)?.toDouble(),
      stockAmbiant: (map['stock_ambiant'] as num?)?.toDouble(),
      stock15c: (map['stock_15c'] as num?)?.toDouble(),
      date: parseDate(map['date_jour']),
    );
  }

  /// Formate le stock ambiant avec 1 décimale
  String get stockAmbiantFormatted =>
      stockAmbiant != null ? '${stockAmbiant!.toStringAsFixed(1)} L' : 'N/A';

  /// Formate le stock 15°C avec 1 décimale
  String get stock15cFormatted =>
      stock15c != null ? '${stock15c!.toStringAsFixed(1)} L' : 'N/A';

  /// Formate la capacité avec 1 décimale
  String get capaciteTotaleFormatted => capaciteTotale != null
      ? '${capaciteTotale!.toStringAsFixed(1)} L'
      : 'N/A';

  /// Retourne le texte pour l'affichage dans le subtitle
  String get stockDisplayText =>
      'Stock: $stockAmbiantFormatted  $stock15cFormatted (15°C)';

  /// Retourne le texte complet avec capacité
  String get fullDisplayText =>
      '$stockDisplayText  Capacité: $capaciteTotaleFormatted';
}

