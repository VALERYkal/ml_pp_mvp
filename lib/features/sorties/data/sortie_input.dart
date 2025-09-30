/* ===========================================================
   ML_PP — SortieInput (DTO brouillon)
   Conforme à public.sorties_produit
   =========================================================== */
class SortieInput {
  final String citerneId;
  final String produitId;
  final String? clientId;
  final String? partenaireId;
  final String proprietaireType; // 'MONALUXE' | 'PARTENAIRE'
  final double? indexAvant;
  final double? indexApres;
  final double? temperatureC;
  final double? densiteA15;
  final double? volume15c; // optionnel
  final String? note;
  final DateTime? dateSortie;
  final String? chauffeurNom;
  final String? plaqueCamion;
  final String? plaqueRemorque;
  final String? transporteur;

  const SortieInput({
    required this.citerneId,
    required this.produitId,
    this.clientId,
    this.partenaireId,
    this.proprietaireType = 'MONALUXE',
    this.indexAvant,
    this.indexApres,
    this.temperatureC,
    this.densiteA15,
    this.volume15c,
    this.note,
    this.dateSortie,
    this.chauffeurNom,
    this.plaqueCamion,
    this.plaqueRemorque,
    this.transporteur,
  });
}
