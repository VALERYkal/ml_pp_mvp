// 📌 Module : Sorties - Models
// 🧭 Description : Modèle pour afficher les citernes avec leurs stocks

/// Modèle léger pour afficher une citerne avec ses stocks actuels
class CiterneWithStockForSortie {
  final String id;
  final String nom;
  final double capaciteTotale;
  final double stockAmbiant;
  final double stock15c;

  const CiterneWithStockForSortie({
    required this.id,
    required this.nom,
    required this.capaciteTotale,
    required this.stockAmbiant,
    required this.stock15c,
  });

  /// Crée une instance depuis les données Supabase
  factory CiterneWithStockForSortie.fromMap(Map<String, dynamic> map) {
    return CiterneWithStockForSortie(
      id: map['id'] as String,
      nom: map['nom']?.toString() ?? 'Sans nom',
      capaciteTotale: (map['capacite_totale'] as num?)?.toDouble() ?? 0.0,
      stockAmbiant: (map['stock_ambiant'] as num?)?.toDouble() ?? 0.0,
      stock15c: (map['stock_15c'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Formate le stock ambiant avec 1 décimale
  String get stockAmbiantFormatted => '${stockAmbiant.toStringAsFixed(1)} L';

  /// Formate le stock 15°C avec 1 décimale
  String get stock15cFormatted => '${stock15c.toStringAsFixed(1)} L';

  /// Formate la capacité avec 1 décimale
  String get capaciteTotaleFormatted => '${capaciteTotale.toStringAsFixed(1)} L';

  /// Retourne le texte pour l'affichage dans le subtitle
  String get stockDisplayText => 'Stock: $stockAmbiantFormatted • $stock15cFormatted (15°C)';

  /// Retourne le texte complet avec capacité
  String get fullDisplayText => '$stockDisplayText — Capacité: $capaciteTotaleFormatted';
}
