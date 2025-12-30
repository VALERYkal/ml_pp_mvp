/// Modèle pour représenter un snapshot de stock agrégé par citerne.
///
/// Source de données : `v_citerne_stock_snapshot_agg`
/// Contient le stock total (MONALUXE + PARTENAIRE) pour une citerne donnée.
class CiterneStockSnapshot {
  final String citerneId;
  final String citerneNom;
  final String depotId;
  final String produitId;
  final double stockAmbiantTotal;
  final double stock15cTotal;
  final DateTime lastSnapshotAt;
  final double capaciteTotale;
  final double capaciteSecurite;

  CiterneStockSnapshot({
    required this.citerneId,
    required this.citerneNom,
    required this.depotId,
    required this.produitId,
    required this.stockAmbiantTotal,
    required this.stock15cTotal,
    required this.lastSnapshotAt,
    required this.capaciteTotale,
    required this.capaciteSecurite,
  });

  factory CiterneStockSnapshot.fromMap(Map<String, dynamic> map) {
    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) {
        final parsed = double.tryParse(v);
        if (parsed != null) return parsed;
      }
      return 0.0;
    }

    DateTime _parseDateTime(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      if (v is String) {
        try {
          return DateTime.parse(v);
        } catch (_) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return CiterneStockSnapshot(
      citerneId: map['citerne_id'] as String,
      citerneNom: map['citerne_nom'] as String,
      depotId: map['depot_id'] as String,
      produitId: map['produit_id'] as String,
      stockAmbiantTotal: _toDouble(map['stock_ambiant_total']),
      stock15cTotal: _toDouble(map['stock_15c_total']),
      lastSnapshotAt: _parseDateTime(map['last_snapshot_at']),
      capaciteTotale: _toDouble(map['capacite_totale']),
      capaciteSecurite: _toDouble(map['capacite_securite']),
    );
  }
}
