import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Modèle pour une citerne sous seuil
class CiterneSousSeuil {
  final String id;
  final String nom;
  final double capaciteTotale;
  final double stockActuel;
  final double capaciteSecurite;
  final String produitNom;

  const CiterneSousSeuil({
    required this.id,
    required this.nom,
    required this.capaciteTotale,
    required this.stockActuel,
    required this.capaciteSecurite,
    required this.produitNom,
  });
}

/// Provider pour les citernes sous seuil de sécurité
final citernesSousSeuilProvider = FutureProvider<List<CiterneSousSeuil>>((ref) async {
  // Simuler un délai de chargement
  await Future.delayed(const Duration(milliseconds: 500));

  // Simuler des données de citernes sous seuil
  return [
    const CiterneSousSeuil(
      id: 'c1',
      nom: 'Citerne A1',
      capaciteTotale: 50000,
      stockActuel: 8000,
      capaciteSecurite: 10000,
      produitNom: 'Essence 95',
    ),
    const CiterneSousSeuil(
      id: 'c2',
      nom: 'Citerne B2',
      capaciteTotale: 30000,
      stockActuel: 5000,
      capaciteSecurite: 8000,
      produitNom: 'Gasoil',
    ),
  ];
});
