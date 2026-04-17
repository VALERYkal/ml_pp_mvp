// 📌 Module : Finance fournisseur lot — Models
// 🧭 Lecture via vues DB, écriture via tables minimales.

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

DateTime? _toDateTimeOrNull(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String? _toNullableString(dynamic value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) return null;
  return raw;
}

/// Projection de lecture finale de la facture fournisseur lot.
class FournisseurFactureLot {
  final String factureId;
  final String invoiceNo;
  final String? dealReference;
  final String fournisseurLotId;
  final int nbReceptions;
  final double totalVolume15c;
  final double totalVolume20c;
  final double quantiteFacturee20c;
  final double ecartVolume20c;
  final String statutRapprochement;
  final double prixUnitaireUsd;
  final double montantTotalUsd;
  final double montantRegleUsd;
  final double soldeRestantUsd;
  final String statutPaiement;
  final DateTime? dateFacture;
  final DateTime? dateEcheance;
  final DateTime? createdAt;

  const FournisseurFactureLot({
    required this.factureId,
    required this.invoiceNo,
    required this.dealReference,
    required this.fournisseurLotId,
    required this.nbReceptions,
    required this.totalVolume15c,
    required this.totalVolume20c,
    required this.quantiteFacturee20c,
    required this.ecartVolume20c,
    required this.statutRapprochement,
    required this.prixUnitaireUsd,
    required this.montantTotalUsd,
    required this.montantRegleUsd,
    required this.soldeRestantUsd,
    required this.statutPaiement,
    required this.dateFacture,
    required this.dateEcheance,
    required this.createdAt,
  });

  factory FournisseurFactureLot.fromMap(Map<String, dynamic> map) {
    return FournisseurFactureLot(
      factureId: map['facture_id']?.toString() ?? '',
      invoiceNo: map['invoice_no']?.toString() ?? '',
      dealReference: _toNullableString(map['deal_reference']),
      fournisseurLotId: map['fournisseur_lot_id']?.toString() ?? '',
      nbReceptions: _toInt(map['nb_receptions']),
      totalVolume15c: _toDouble(map['total_volume_15c']),
      totalVolume20c: _toDouble(map['total_volume_20c']),
      quantiteFacturee20c: _toDouble(map['quantite_facturee_20c']),
      ecartVolume20c: _toDouble(map['ecart_volume_20c']),
      statutRapprochement: map['statut_rapprochement']?.toString() ?? '',
      prixUnitaireUsd: _toDouble(map['prix_unitaire_usd']),
      montantTotalUsd: _toDouble(map['montant_total_usd']),
      montantRegleUsd: _toDouble(map['montant_regle_usd']),
      soldeRestantUsd: _toDouble(map['solde_restant_usd']),
      statutPaiement: map['statut_paiement']?.toString() ?? '',
      dateFacture: _toDateTimeOrNull(map['date_facture']),
      dateEcheance: _toDateTimeOrNull(map['date_echeance']),
      createdAt: _toDateTimeOrNull(map['created_at']),
    );
  }
}

/// Projection de lecture rapprochement lot (vue minimale).
class FournisseurRapprochementLot {
  final String factureId;
  final String invoiceNo;
  final String? dealReference;
  final String fournisseurLotId;
  final int nbReceptions;
  final double totalVolume15c;
  final double totalVolume20c;
  final double quantiteFacturee20c;
  final double ecartVolume20c;
  final double prixUnitaireUsd;
  final double montantTotalUsd;
  final String statutRapprochement;

  const FournisseurRapprochementLot({
    required this.factureId,
    required this.invoiceNo,
    required this.dealReference,
    required this.fournisseurLotId,
    required this.nbReceptions,
    required this.totalVolume15c,
    required this.totalVolume20c,
    required this.quantiteFacturee20c,
    required this.ecartVolume20c,
    required this.prixUnitaireUsd,
    required this.montantTotalUsd,
    required this.statutRapprochement,
  });

  factory FournisseurRapprochementLot.fromMap(Map<String, dynamic> map) {
    return FournisseurRapprochementLot(
      factureId: map['facture_id']?.toString() ?? '',
      invoiceNo: map['invoice_no']?.toString() ?? '',
      dealReference: _toNullableString(map['deal_reference']),
      fournisseurLotId: map['fournisseur_lot_id']?.toString() ?? '',
      nbReceptions: _toInt(map['nb_receptions']),
      totalVolume15c: _toDouble(map['total_volume_15c']),
      totalVolume20c: _toDouble(map['total_volume_20c']),
      quantiteFacturee20c: _toDouble(map['quantite_facturee_20c']),
      ecartVolume20c: _toDouble(map['ecart_volume_20c']),
      prixUnitaireUsd: _toDouble(map['prix_unitaire_usd']),
      montantTotalUsd: _toDouble(map['montant_total_usd']),
      statutRapprochement: map['statut_rapprochement']?.toString() ?? '',
    );
  }
}

/// Payload d'insertion sur `public.fournisseur_facture_lot_min`.
class CreateFournisseurFactureLotInput {
  final String fournisseurLotId;
  final String invoiceNo;
  final String? dealReference;
  final DateTime dateFacture;
  final DateTime? dateEcheance;
  final double quantiteFacturee20c;
  final double prixUnitaireUsd;

  const CreateFournisseurFactureLotInput({
    required this.fournisseurLotId,
    required this.invoiceNo,
    required this.dealReference,
    required this.dateFacture,
    required this.dateEcheance,
    required this.quantiteFacturee20c,
    required this.prixUnitaireUsd,
  });

  Map<String, dynamic> toMap() {
    return {
      'fournisseur_lot_id': fournisseurLotId.trim(),
      'invoice_no': invoiceNo.trim(),
      'deal_reference': _toNullableString(dealReference),
      'date_facture': dateFacture.toIso8601String().split('T').first,
      'date_echeance': dateEcheance?.toIso8601String().split('T').first,
      'quantite_facturee_20c': quantiteFacturee20c,
      'prix_unitaire_usd': prixUnitaireUsd,
    };
  }
}

/// Payload d'insertion sur `public.fournisseur_paiement_lot_min`.
class CreateFournisseurPaiementLotInput {
  final String fournisseurFactureId;
  final DateTime? datePaiement;
  final double montantPayeUsd;
  final String? modePaiement;
  final String? referencePaiement;
  final String? note;

  const CreateFournisseurPaiementLotInput({
    required this.fournisseurFactureId,
    required this.datePaiement,
    required this.montantPayeUsd,
    required this.modePaiement,
    required this.referencePaiement,
    required this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'fournisseur_facture_id': fournisseurFactureId.trim(),
      if (datePaiement != null) 'date_paiement': datePaiement!.toIso8601String(),
      'montant_paye_usd': montantPayeUsd,
      'mode_paiement': _toNullableString(modePaiement),
      'reference_paiement': _toNullableString(referencePaiement),
      'note': _toNullableString(note),
    };
  }
}

/// Projection de lecture d'un paiement fournisseur lot.
class FournisseurPaiementLot {
  final String paiementId;
  final String fournisseurFactureId;
  final DateTime? datePaiement;
  final double montantPayeUsd;
  final String? modePaiement;
  final String? referencePaiement;
  final String? note;
  final DateTime? createdAt;

  const FournisseurPaiementLot({
    required this.paiementId,
    required this.fournisseurFactureId,
    required this.datePaiement,
    required this.montantPayeUsd,
    required this.modePaiement,
    required this.referencePaiement,
    required this.note,
    required this.createdAt,
  });

  factory FournisseurPaiementLot.fromMap(Map<String, dynamic> map) {
    return FournisseurPaiementLot(
      paiementId: map['id']?.toString() ?? '',
      fournisseurFactureId: map['fournisseur_facture_id']?.toString() ?? '',
      datePaiement: _toDateTimeOrNull(map['date_paiement']),
      montantPayeUsd: _toDouble(map['montant_paye_usd']),
      modePaiement: _toNullableString(map['mode_paiement']),
      referencePaiement: _toNullableString(map['reference_paiement']),
      note: _toNullableString(map['note']),
      createdAt: _toDateTimeOrNull(map['created_at']),
    );
  }
}
