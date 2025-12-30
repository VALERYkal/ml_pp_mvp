// 📌 Module : Shared Constants - Cours Status
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Constantes et logique pour les statuts de cours de route

import 'package:ml_pp_mvp/features/cours_route/models/cours_de_route.dart';

/// Flux de progression des statuts de cours de route
const List<String> kCoursFlow = [
  'chargement',
  'transit',
  'frontière',
  'arrivé',
  'déchargé',
];

/// Vérifie si un statut est terminal (fin de progression)
///
/// [statut] : Le statut à vérifier
///
/// Retourne :
/// - `true` : Le statut est terminal
/// - `false` : Le statut permet encore une progression
bool isTerminal(String statut) => statut == 'déchargé';

/// Retourne le statut suivant dans la progression
///
/// [statut] : Le statut actuel
///
/// Retourne :
/// - `String?` : Le prochain statut dans la séquence
/// - `null` : Si le statut est terminal ou invalide
String? nextOf(String statut) {
  final index = kCoursFlow.indexOf(statut);
  if (index < 0 || index >= kCoursFlow.length - 1) {
    return null;
  }
  return kCoursFlow[index + 1];
}

/// Retourne le statut précédent dans la progression
///
/// [statut] : Le statut actuel
///
/// Retourne :
/// - `String?` : Le statut précédent dans la séquence
/// - `null` : Si le statut est le premier ou invalide
String? previousOf(String statut) {
  final index = kCoursFlow.indexOf(statut);
  if (index <= 0) {
    return null;
  }
  return kCoursFlow[index - 1];
}

/// Vérifie si une transition entre deux statuts est autorisée
///
/// [from] : Statut de départ
/// [to] : Statut d'arrivée
///
/// Retourne :
/// - `true` : La transition est autorisée
/// - `false` : La transition est interdite
bool isTransitionAllowed(String from, String to) {
  final fromIndex = kCoursFlow.indexOf(from);
  final toIndex = kCoursFlow.indexOf(to);

  if (fromIndex < 0 || toIndex < 0) {
    return false;
  }

  // Transition autorisée uniquement vers le statut suivant
  return toIndex == fromIndex + 1;
}

/// Retourne tous les statuts disponibles
///
/// Retourne :
/// - `List<String>` : Liste de tous les statuts dans l'ordre de progression
List<String> getAllStatuses() => List.from(kCoursFlow);

/// Retourne les statuts actifs (non terminaux)
///
/// Retourne :
/// - `List<String>` : Liste des statuts qui permettent encore une progression
List<String> getActiveStatuses() =>
    kCoursFlow.take(kCoursFlow.length - 1).toList();

/// Convertit un StatutCours enum en String pour l'affichage
///
/// [statut] : Le statut enum
///
/// Retourne :
/// - `String` : Représentation textuelle du statut
String statutToString(StatutCours statut) {
  switch (statut) {
    case StatutCours.chargement:
      return 'Chargement';
    case StatutCours.transit:
      return 'Transit';
    case StatutCours.frontiere:
      return 'Frontière';
    case StatutCours.arrive:
      return 'Arrivé';
    case StatutCours.decharge:
      return 'Déchargé';
  }
}

/// Retourne la couleur appropriée pour un statut
///
/// [statut] : Le statut
///
/// Retourne :
/// - `int` : Code couleur ARGB
int getStatutColor(String statut) {
  switch (statut) {
    case 'chargement':
      return 0xFF2196F3; // Bleu
    case 'transit':
      return 0xFFFF9800; // Orange
    case 'frontière':
      return 0xFF9C27B0; // Violet
    case 'arrivé':
      return 0xFF4CAF50; // Vert
    case 'déchargé':
      return 0xFF607D8B; // Gris
    default:
      return 0xFF757575; // Gris par défaut
  }
}

/// Retourne l'icône appropriée pour un statut
///
/// [statut] : Le statut
///
/// Retourne :
/// - `String` : Nom de l'icône Material
String getStatutIcon(String statut) {
  switch (statut) {
    case 'chargement':
      return 'local_shipping';
    case 'transit':
      return 'directions_car';
    case 'frontière':
      return 'border_crossing';
    case 'arrivé':
      return 'location_on';
    case 'déchargé':
      return 'check_circle';
    default:
      return 'help';
  }
}
