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
/// - ET `Platform.environment['FLUTTER_TEST'] != 'true'` (pas en tests)
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
  if (_isCiOrTest()) return;

  // Afficher uniquement en développement local (flutter run)
  debugPrint(message);
}

/// Détecte si on est en environnement CI ou en tests
bool _isCiOrTest() {
  // Sur Web, Platform.environment est unsupported (crash "Unsupported operation")
  // On ne tente pas de détecter CI/test via env runtime sur Web
  if (kIsWeb) {
    return false;
  }

  // Encadrer l'accès à Platform.environment par try/catch (sécurité supplémentaire)
  try {
    final env = Platform.environment;
    return env['CI'] == 'true' ||
        env['CONTINUOUS_INTEGRATION'] == 'true' ||
        env['FLUTTER_TEST'] == 'true';
  } catch (_) {
    // En cas d'erreur (plateforme non supportée), on considère qu'on n'est pas en CI/test
    return false;
  }
}
