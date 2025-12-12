// 📌 Module : Cours de Route - Utils
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Constantes pour le module cours de route

/// Constantes pour le module cours de route
/// 
/// Contient :
/// - UUIDs des produits ESS/AGO
/// - Liste des pays pour l'autocomplete
/// - Valeurs par défaut
class CoursRouteConstants {
  // UUIDs des produits (existants dans le code)
  static const String produitEssId = '640cf7ec-1616-4503-a484-0a61afb20005';
  static const String produitAgoId = '452b557c-e974-4315-b6c2-cda8487db428';

  // Liste des pays pour l'autocomplete
  static const List<String> paysSuggestions = [
    'Tanzanie', 'Zibambwe', 'Zambie', 'Mozambique', 'Angola', 
    'Namibie', 'Afrique du Sud', 'Kenya', 'Ouganda', 'Burundi',
  ];

  // Statut initial pour les nouveaux cours
  static const String statutInitial = 'chargement';

  // Nom du dépôt par défaut
  static const String depotDefault = 'Monaluxe';

  // Couleurs pour les badges de statut (usage futur)
  static const Map<String, int> statutColors = {
    'chargement': 0xFF2196F3, // Bleu
    'transit': 0xFFFF9800,     // Orange
    'frontiere': 0xFF9C27B0,   // Violet
    'arrive': 0xFF4CAF50,      // Vert
    'decharge': 0xFF607D8B,    // Gris
  };
}
