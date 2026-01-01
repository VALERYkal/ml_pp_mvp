// 📌 Module : Utils - App Logging
// 🧭 Description : Helper pour le logging en mode développement uniquement
// 🚫 PROD-SAFE: Les logs ne s'affichent qu'en mode debug, pas en production

import 'package:flutter/foundation.dart';

/// Log un message en mode développement uniquement
///
/// Cette fonction utilise `assert()` avec `debugPrint()` pour garantir
/// que les logs ne s'affichent qu'en mode debug et sont complètement
/// supprimés en production (tree-shaking).
///
/// Usage:
/// ```dart
/// appLog('Erreur lors de l\'enregistrement: $error');
/// ```
void appLog(String message) {
  assert(() {
    debugPrint(message);
    return true;
  }());
}

