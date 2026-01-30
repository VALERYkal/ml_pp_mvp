// 📌 Module : Utils - App Logging
// 🧭 Description : Helper pour le logging en mode développement uniquement
// 🚫 PROD-SAFE: Les logs ne s'affichent qu'en mode debug, pas en production
// 🚫 CI-SAFE: Les logs sont silencieux en CI et en tests pour réduire le bruit

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Log un message en mode développement uniquement (silencieux en CI/tests)
///
/// Cette fonction utilise `debugPrint()` uniquement si :
/// - `kDebugMode == true` (mode développement)
/// - ET `Platform.environment['CI'] != 'true'` (pas en CI)
///
/// En tests et CI, cette fonction est silencieuse pour réduire le bruit.
/// En production, les logs sont complètement supprimés (tree-shaking).
///
/// Usage:
/// ```dart
/// appLog('Erreur lors de l\'enregistrement: $error');
/// ```
void appLog(String message) {
  // Silencieux en production (kDebugMode == false)
  if (!kDebugMode) return;

  // Silencieux en CI et en tests (détection via variable d'environnement)
  final isCI = Platform.environment['CI'] == 'true' ||
      Platform.environment['CONTINUOUS_INTEGRATION'] == 'true';
  if (isCI) return;

  // Afficher uniquement en développement local
  debugPrint(message);
}

