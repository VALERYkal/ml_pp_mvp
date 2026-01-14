import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration de l'environnement de l'application
class AppEnv {
  /// Nom de l'environnement (DEV / STAGING / PROD)
  final String envName;

  /// URL Supabase
  final String supabaseUrl;

  /// Clé anonyme Supabase
  final String supabaseAnonKey;

  const AppEnv._({
    required this.envName,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
  });

  /// Charger la configuration depuis dart-define, puis .env.local, puis .env
  static Future<AppEnv> load() async {
    // 1. Priorité absolue: dart-define (CI/Release)
    final envFromDefine = const String.fromEnvironment('SUPABASE_ENV', defaultValue: '');
    final urlFromDefine = const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    final keyFromDefine = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    final allowProdDebug = const String.fromEnvironment('ALLOW_PROD_DEBUG', defaultValue: '') == 'true';

    String envName;
    String supabaseUrl;
    String supabaseAnonKey;

    if (urlFromDefine.isNotEmpty && keyFromDefine.isNotEmpty) {
      // Dart-define présent: utiliser ces valeurs (priorité absolue)
      envName = envFromDefine.isNotEmpty ? envFromDefine : 'PROD';
      supabaseUrl = urlFromDefine;
      supabaseAnonKey = keyFromDefine;
      debugPrint('✅ AppEnv: Utilisation des --dart-define (priorité)');
    } else {
      // Dart-define absent: charger .env.local puis .env (dev local uniquement)
      // ⚠️ Sur WEB, on ne charge PAS .env.local (pas dans assets, 404 garanti)
      bool loaded = false;

      if (!kIsWeb) {
        // Sur mobile/desktop: essayer .env.local d'abord
        try {
          await dotenv.load(fileName: '.env.local');
          loaded = true;
          debugPrint('📄 AppEnv: Chargé .env.local (local/dev)');
        } catch (e) {
          debugPrint('⚠️ AppEnv: .env.local non trouvé, tentative .env');
        }
      } else {
        // Sur WEB: skip .env.local (pas dans assets), aller directement à .env
        debugPrint('🌐 AppEnv: Mode WEB détecté, skip .env.local');
      }

      // Fallback vers .env si .env.local absent ou si on est sur web
      if (!loaded) {
        try {
          await dotenv.load(fileName: '.env');
          debugPrint('📄 AppEnv: Chargé .env');
        } catch (e) {
          debugPrint('❌ AppEnv: Aucun fichier .env trouvé');
        }
      }

      envName = dotenv.env['SUPABASE_ENV'] ?? 'STAGING';
      supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      
      if (kIsWeb && (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty)) {
        throw StateError(
          '❌ Sur WEB, SUPABASE_URL et SUPABASE_ANON_KEY doivent être définis via --dart-define.\n'
          'Commande: flutter run -d chrome --dart-define=SUPABASE_ENV=STAGING --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...\n'
          'Voir README.md pour les valeurs STAGING.'
        );
      }
    }

    // Validation
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw StateError(
        '❌ SUPABASE_URL ou SUPABASE_ANON_KEY manquants.\n'
        'Définis via --dart-define ou via .env.local/.env\n'
        'Voir .env.example pour le format attendu.',
      );
    }

    // Normaliser envName
    envName = envName.toUpperCase();
    if (envName != 'DEV' && envName != 'STAGING' && envName != 'PROD') {
      envName = 'DEV';
    }

    final env = AppEnv._(
      envName: envName,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
    );

    // Garde-fou PROD en debug
    if (kDebugMode && envName == 'PROD' && !allowProdDebug) {
      throw StateError(
        '❌ PROD est bloqué en mode DEBUG.\n'
        'Pour forcer PROD en debug, définis ALLOW_PROD_DEBUG=true via --dart-define.\n'
        'En local/dev, utilise STAGING.',
      );
    }

    // Log de démarrage (sans afficher la clé complète)
    debugPrint('🌍 AppEnv: $envName');
    debugPrint('📍 Supabase: ${_maskUrl(supabaseUrl)}');

    return env;
  }

  /// Validation fail-fast: vérifie que l'URL correspond à l'environnement déclaré
  /// Doit être appelé AVANT Supabase.initialize()
  void validateOrThrow() {
    const stagingRef = 'jgquhldzcisjnbotnskr';
    
    if (envName == 'STAGING') {
      if (!supabaseUrl.contains(stagingRef)) {
        throw StateError(
          '❌ ERREUR CRITIQUE: SUPABASE_ENV=STAGING mais URL ne contient pas le ref STAGING.\n'
          'Ref attendu: $stagingRef\n'
          'URL actuelle: ${_maskUrl(supabaseUrl)}\n'
          'Vérifiez vos --dart-define ou .env/.env.local'
        );
      }
    } else if (envName == 'PROD') {
      if (supabaseUrl.contains(stagingRef)) {
        throw StateError(
          '❌ ERREUR CRITIQUE: SUPABASE_ENV=PROD mais URL contient le ref STAGING.\n'
          'Ref STAGING détecté: $stagingRef\n'
          'URL actuelle: ${_maskUrl(supabaseUrl)}\n'
          'Vérifiez vos --dart-define ou .env/.env.local'
        );
      }
    }
    
    // Validation supplémentaire: URL doit être valide
    try {
      final uri = Uri.parse(supabaseUrl);
      if (!uri.hasScheme || !uri.hasAuthority) {
        throw StateError(
          '❌ SUPABASE_URL invalide: ${_maskUrl(supabaseUrl)}\n'
          'Format attendu: https://xxx.supabase.co'
        );
      }
    } catch (e) {
      if (e is StateError) rethrow;
      throw StateError(
        '❌ SUPABASE_URL invalide (parse error): ${_maskUrl(supabaseUrl)}'
      );
    }
  }

  static String _maskUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return '${uri.scheme}://${uri.host}';
    } catch (e) {
      return url.length > 30 ? '${url.substring(0, 30)}...' : url;
    }
  }

  /// Est-ce l'environnement PROD?
  bool get isProd => envName == 'PROD';

  /// Est-ce l'environnement STAGING?
  bool get isStaging => envName == 'STAGING';

  /// Est-ce l'environnement DEV?
  bool get isDev => envName == 'DEV';

  /// Garde-fou PROD (fail-fast si PROD sans autorisation explicite)
  void assertProdGuard({bool allowProdDebug = false}) {
    if (kDebugMode && isProd && !allowProdDebug) {
      throw StateError(
        '❌ PROD est bloqué en mode DEBUG.\n'
        'Pour forcer PROD en debug, définis ALLOW_PROD_DEBUG=true via --dart-define.',
      );
    }
  }
}

/// Provider pour l'environnement (accessible globalement)
final appEnvProvider = FutureProvider<AppEnv>((ref) async {
  return await AppEnv.load();
});

/// Provider synchronisé (une fois chargé, toujours disponible)
final appEnvSyncProvider = Provider<AppEnv>((ref) {
  throw UnimplementedError('appEnvSyncProvider must be overridden');
});
