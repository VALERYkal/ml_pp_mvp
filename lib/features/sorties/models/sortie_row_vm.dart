class SortieRowVM {
  final String id;
  final DateTime dateSortie;
  final String propriete; // MONALUXE | PARTENAIRE
  final String produitLabel; // ex: ESS · Essence
  final String citerneNom;
  final double? vol15;
  final double? volAmb;
  final String? beneficiaireNom; // client_nom ou partenaire_nom selon proprietaire_type
  final String statut; // validee | brouillon

  SortieRowVM({
    required this.id,
    required this.dateSortie,
    required this.propriete,
    required this.produitLabel,
    required this.citerneNom,
    required this.vol15,
    required this.volAmb,
    this.beneficiaireNom,
    required this.statut,
  });
}

