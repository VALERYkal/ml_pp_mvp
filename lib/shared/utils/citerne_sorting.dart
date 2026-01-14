import '../referentiels/referentiels.dart';

/// Utilitaires de tri pour les citernes
///
/// Permet de trier les citernes par numéro extrait du nom (ex: TANK1, TANK2, ...)
/// avec fallback alphabétique si aucun nombre n'est trouvé.

/// Extrait le premier nombre trouvé dans une chaîne.
///
/// Exemples:
/// - "TANK12" -> 12
/// - "Cuve 5" -> 5
/// - "Alpha" -> 999999 (fallback pour tri alphabétique)
int extractFirstNumber(String s) {
  if (s.isEmpty) return 999999;

  // Chercher le premier nombre dans la chaîne
  final regex = RegExp(r'\d+');
  final match = regex.firstMatch(s);

  if (match != null) {
    return int.parse(match.group(0)!);
  }

  // Aucun nombre trouvé -> retourner 999999 pour tri alphabétique
  return 999999;
}

/// Trie une liste de citernes par numéro extrait du nom, puis alphabétiquement.
///
/// Ordre de tri:
/// 1. Par numéro extrait du nom (ascendant)
/// 2. Si même numéro ou aucun numéro: tri alphabétique sur le nom
///
/// Exemples:
/// - ["TANK3", "TANK1", "TANK6", "TANK2"] -> ["TANK1", "TANK2", "TANK3", "TANK6"]
/// - ["Cuve 10", "Cuve 2", "Cuve A"] -> ["Cuve 2", "Cuve 10", "Cuve A"]
/// - ["Alpha", "Beta"] -> ["Alpha", "Beta"] (tri alphabétique)
List<CiterneRef> sortCiternesForReception(List<CiterneRef> citernes) {
  final sorted = List<CiterneRef>.from(citernes);

  sorted.sort((a, b) {
    final numA = extractFirstNumber(a.nom);
    final numB = extractFirstNumber(b.nom);

    // Si les deux ont un numéro valide (< 999999), trier par numéro
    if (numA < 999999 && numB < 999999) {
      if (numA != numB) {
        return numA.compareTo(numB);
      }
      // Même numéro -> tri alphabétique sur le nom
      return a.nom.compareTo(b.nom);
    }

    // Si un seul a un numéro valide, celui avec numéro vient en premier
    if (numA < 999999 && numB == 999999) {
      return -1;
    }
    if (numA == 999999 && numB < 999999) {
      return 1;
    }

    // Aucun des deux n'a de numéro -> tri alphabétique
    return a.nom.compareTo(b.nom);
  });

  return sorted;
}
