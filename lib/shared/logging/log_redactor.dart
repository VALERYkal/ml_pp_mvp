import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';

/// Masque les secrets (tokens) dans les logs.
/// S'applique à tout ce qui passe par debugPrint / print (via debugPrintOverride).
class LogRedactor {
  static final _tokenKeys = <String>[
    'access_token',
    'refresh_token',
    'provider_token',
    'provider_refresh_token',
  ];

  /// Masque les secrets dans une chaîne de caractères.
  /// 
  /// Masque :
  /// - access_token, refresh_token, provider_token, provider_refresh_token dans JSON ou texte
  /// - headers Authorization: Bearer <token>
  /// - JWT au format xxx.yyy.zzz
  static String redactSecrets(String input) {
    var out = input;

    // Masquage JSON style: "access_token":"...."
    for (final k in _tokenKeys) {
      out = out.replaceAllMapped(
        RegExp('"$k"\\s*:\\s*"[^"]*"'),
        (m) => '"$k":"<REDACTED>"',
      );
      // Masquage aussi sans guillemets (cas texte brut)
      out = out.replaceAllMapped(
        RegExp('$k\\s*[:=]\\s*[A-Za-z0-9._~+/-]+=*', caseSensitive: false),
        (_) => '$k:<REDACTED>',
      );
    }

    // Masquage header Bearer
    out = out.replaceAllMapped(
      RegExp(r'Authorization:\s*Bearer\s+[A-Za-z0-9._~+/-]+=*', caseSensitive: false),
      (_) => 'Authorization: Bearer <REDACTED>',
    );

    // Masquage JWT (format xxx.yyy.zzz avec base64url)
    // Pattern: au moins 3 segments séparés par des points, chaque segment base64url
    out = out.replaceAllMapped(
      RegExp(r'\b[A-Za-z0-9\-_]{20,}\.[A-Za-z0-9\-_]{20,}\.[A-Za-z0-9\-_]{20,}\b'),
      (_) => '<JWT_REDACTED>',
    );

    return out;
  }

  /// Alias pour compatibilité avec l'ancien code
  static String redact(String message) => redactSecrets(message);

  /// Helper pour logger de manière sécurisée (redaction automatique).
  /// 
  /// Utilise debugPrint avec redaction automatique des secrets.
  static void safePrint(Object? o) {
    debugPrint(redactSecrets(o?.toString() ?? 'null'));
  }

  /// Installe un override global de debugPrint (debug uniquement).
  static void install() {
    if (!kDebugMode) return;

    debugPrint = (String? message, {int? wrapWidth}) {
      if (message == null) return;
      final safe = redactSecrets(message);
      dev.log(safe, name: 'app');
    };
  }
}
