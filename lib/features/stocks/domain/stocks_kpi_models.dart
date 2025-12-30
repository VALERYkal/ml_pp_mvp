// lib/features/stocks/domain/stocks_kpi_models.dart

class DepotGlobalStockKpi {
  final String depotId;
  final String depotNom;
  final String produitId;
  final String produitNom;
  final double stockAmbiant;
  final double stock15C;
  final double volumeReceptionAmbiant;
  final double volumeReception15C;
  final double volumeSortieAmbiant;
  final double volumeSortie15C;

  const DepotGlobalStockKpi({
    required this.depotId,
    required this.depotNom,
    required this.produitId,
    required this.produitNom,
    required this.stockAmbiant,
    required this.stock15C,
    required this.volumeReceptionAmbiant,
    required this.volumeReception15C,
    required this.volumeSortieAmbiant,
    required this.volumeSortie15C,
  });

  factory DepotGlobalStockKpi.fromMap(Map<String, dynamic> map) {
    double _toDouble(dynamic v) => v == null ? 0.0 : (v as num).toDouble();

    return DepotGlobalStockKpi(
      depotId: map['depot_id'] as String,
      depotNom: map['depot_nom'] as String,
      produitId: map['produit_id'] as String,
      produitNom: map['produit_nom'] as String,
      stockAmbiant: _toDouble(map['stock_ambiant']),
      stock15C: _toDouble(map['stock_15c']),
      volumeReceptionAmbiant: _toDouble(map['volume_reception_ambiant']),
      volumeReception15C: _toDouble(map['volume_reception_15c']),
      volumeSortieAmbiant: _toDouble(map['volume_sortie_ambiant']),
      volumeSortie15C: _toDouble(map['volume_sortie_15c']),
    );
  }
}

class DepotOwnerStockKpi {
  final String depotId;
  final String depotNom;
  final String proprietaireType;
  final double stockAmbiant;
  final double stock15C;

  const DepotOwnerStockKpi({
    required this.depotId,
    required this.depotNom,
    required this.proprietaireType,
    required this.stockAmbiant,
    required this.stock15C,
  });

  factory DepotOwnerStockKpi.fromMap(Map<String, dynamic> map) {
    double _toDouble(dynamic v) => v == null ? 0.0 : (v as num).toDouble();

    return DepotOwnerStockKpi(
      depotId: map['depot_id'] as String,
      depotNom: map['depot_nom'] as String,
      proprietaireType: map['proprietaire_type'] as String,
      stockAmbiant: _toDouble(map['stock_ambiant']),
      stock15C: _toDouble(map['stock_15c']),
    );
  }
}

class CiterneOwnerStockSnapshot {
  final String citerneId;
  final String citerneNom;
  final String depotId;
  final String depotNom;
  final String produitId;
  final String produitNom;
  final String proprietaireType;
  final double stockAmbiant;
  final double stock15C;
  final double volumeReceptionAmbiant;
  final double volumeReception15C;
  final double volumeSortieAmbiant;
  final double volumeSortie15C;
  final DateTime dateJour;

  const CiterneOwnerStockSnapshot({
    required this.citerneId,
    required this.citerneNom,
    required this.depotId,
    required this.depotNom,
    required this.produitId,
    required this.produitNom,
    required this.proprietaireType,
    required this.stockAmbiant,
    required this.stock15C,
    required this.volumeReceptionAmbiant,
    required this.volumeReception15C,
    required this.volumeSortieAmbiant,
    required this.volumeSortie15C,
    required this.dateJour,
  });

  factory CiterneOwnerStockSnapshot.fromMap(Map<String, dynamic> map) {
    double _toDouble(dynamic v) => v == null ? 0.0 : (v as num).toDouble();

    DateTime _toDate(dynamic v) {
      if (v is DateTime) return v;
      if (v is String) return DateTime.parse(v);
      throw ArgumentError('Invalid date_jour: $v');
    }

    return CiterneOwnerStockSnapshot(
      citerneId: map['citerne_id'] as String,
      citerneNom: map['citerne_nom'] as String,
      depotId: map['depot_id'] as String,
      depotNom: map['depot_nom'] as String,
      produitId: map['produit_id'] as String,
      produitNom: map['produit_nom'] as String,
      proprietaireType: map['proprietaire_type'] as String,
      stockAmbiant: _toDouble(map['stock_ambiant']),
      stock15C: _toDouble(map['stock_15c']),
      volumeReceptionAmbiant: _toDouble(map['volume_reception_ambiant']),
      volumeReception15C: _toDouble(map['volume_reception_15c']),
      volumeSortieAmbiant: _toDouble(map['volume_sortie_ambiant']),
      volumeSortie15C: _toDouble(map['volume_sortie_15c']),
      dateJour: _toDate(map['date_jour']),
    );
  }
}

class CiterneGlobalStockSnapshot {
  final String citerneId;
  final String citerneNom;
  final String depotId;
  final String depotNom;
  final String produitId;
  final String produitNom;
  final double stockAmbiant;
  final double stock15C;
  final double volumeReceptionAmbiant;
  final double volumeReception15C;
  final double volumeSortieAmbiant;
  final double volumeSortie15C;
  final DateTime dateDernierMouvement;

  const CiterneGlobalStockSnapshot({
    required this.citerneId,
    required this.citerneNom,
    required this.depotId,
    required this.depotNom,
    required this.produitId,
    required this.produitNom,
    required this.stockAmbiant,
    required this.stock15C,
    required this.volumeReceptionAmbiant,
    required this.volumeReception15C,
    required this.volumeSortieAmbiant,
    required this.volumeSortie15C,
    required this.dateDernierMouvement,
  });

  factory CiterneGlobalStockSnapshot.fromMap(Map<String, dynamic> map) {
    double _toDouble(dynamic v) => v == null ? 0.0 : (v as num).toDouble();

    DateTime _toDate(dynamic v) {
      if (v == null) return DateTime.now();
      if (v is DateTime) return v;
      if (v is String) return DateTime.parse(v);
      throw ArgumentError('Invalid date_dernier_mouvement: $v');
    }

    return CiterneGlobalStockSnapshot(
      citerneId: map['citerne_id'] as String,
      citerneNom: map['citerne_nom'] as String,
      depotId: map['depot_id'] as String,
      depotNom: map['depot_nom'] as String,
      produitId: map['produit_id'] as String,
      produitNom: map['produit_nom'] as String,
      stockAmbiant: _toDouble(map['stock_ambiant']),
      stock15C: _toDouble(map['stock_15c']),
      volumeReceptionAmbiant: _toDouble(map['volume_reception_ambiant']),
      volumeReception15C: _toDouble(map['volume_reception_15c']),
      volumeSortieAmbiant: _toDouble(map['volume_sortie_ambiant']),
      volumeSortie15C: _toDouble(map['volume_sortie_15c']),
      dateDernierMouvement: _toDate(map['date_dernier_mouvement']),
    );
  }
}
