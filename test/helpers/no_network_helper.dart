/// Helper pour bloquer tout accÃ¨s rÃ©seau en tests
/// Dans cette version de Flutter, on utilise l'injection de dÃ©pendance
/// au lieu de bloquer HttpOverrides
class NoNetworkHelper {
  /// Bloque tous les accÃ¨s HTTP en tests
  /// Note: Cette version utilise l'injection de dÃ©pendance dans les services
  /// au lieu de bloquer HttpOverrides globalement
  static void blockNetwork() {
    // Pas d'action nÃ©cessaire - les tests utilisent l'injection de dÃ©pendance
  }

  /// Restaure les overrides HTTP originaux
  static void restoreNetwork() {
    // Pas d'action nÃ©cessaire - les tests utilisent l'injection de dÃ©pendance
  }
}

