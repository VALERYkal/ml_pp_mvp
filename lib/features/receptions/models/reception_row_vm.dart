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
  });
}

