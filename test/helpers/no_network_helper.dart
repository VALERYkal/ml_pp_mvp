/// Helper pour bloquer tout accès réseau en tests
/// Dans cette version de Flutter, on utilise l'injection de dépendance
/// au lieu de bloquer HttpOverrides
class NoNetworkHelper {
  /// Bloque tous les accès HTTP en tests
  /// Note: Cette version utilise l'injection de dépendance dans les services
  /// au lieu de bloquer HttpOverrides globalement
  static void blockNetwork() {
    // Pas d'action nécessaire - les tests utilisent l'injection de dépendance
  }
  
  /// Restaure les overrides HTTP originaux
  static void restoreNetwork() {
    // Pas d'action nécessaire - les tests utilisent l'injection de dépendance
  }
}
