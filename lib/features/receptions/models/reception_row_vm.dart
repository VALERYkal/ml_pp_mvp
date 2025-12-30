class ReceptionRowVM {
  final String id;
  final DateTime dateReception;
  final String propriete; // MONALUXE | PARTENAIRE
  final String produitLabel; // ex: G.O · Gasoil/AGO
  final String citerneNom;
  final double? vol15;
  final double? volAmb;
  final String? cdrShort; // ex: #7c04fb2e
  final String? cdrPlaques; // ex: 6668 / 7789
  final String? fournisseurNom;
  final String? partenaireNom;

  ReceptionRowVM({
    required this.id,
    required this.dateReception,
    required this.propriete,
    required this.produitLabel,
    required this.citerneNom,
    required this.vol15,
    required this.volAmb,
    this.cdrShort,
    this.cdrPlaques,
    this.fournisseurNom,
    this.partenaireNom,
  });

  /// Getter calculé pour la colonne "Source"
  /// Règle métier :
  /// 1. Si cours_de_route_id non null → Source = fournisseur du CDR
  /// 2. Sinon, si partenaire_id non null → Source = partenaire propriétaire
  /// 3. Sinon → Source = —
  String get sourceLabel {
    // 1. Si lié à un CDR avec fournisseur connu
    if (fournisseurNom != null && fournisseurNom!.isNotEmpty) {
      return fournisseurNom!;
    }

    // 2. Sinon, si réception partenaire
    if (partenaireNom != null && partenaireNom!.isNotEmpty) {
      return partenaireNom!;
    }

    // 3. Sinon, rien à afficher
    return '—';
  }
}
