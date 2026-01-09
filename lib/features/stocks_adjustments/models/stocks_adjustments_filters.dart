// 📌 Module : Stocks Adjustments - Filtres
// 🧭 Description : Modèle simple pour les filtres de la liste des ajustements

class StocksAdjustmentsFilters {
  final String? movementType; // 'RECEPTION' | 'SORTIE' | null (tous)
  final int? rangeDays; // 7, 30, 90, ou null (tout)
  final String reasonQuery; // Recherche dans la raison

  const StocksAdjustmentsFilters({
    this.movementType,
    this.rangeDays,
    this.reasonQuery = '',
  });

  StocksAdjustmentsFilters copyWith({
    String? movementType,
    int? rangeDays,
    String? reasonQuery,
  }) {
    return StocksAdjustmentsFilters(
      movementType: movementType ?? this.movementType,
      rangeDays: rangeDays ?? this.rangeDays,
      reasonQuery: reasonQuery ?? this.reasonQuery,
    );
  }

  bool get isEmpty =>
      movementType == null && rangeDays == null && reasonQuery.isEmpty;
}
