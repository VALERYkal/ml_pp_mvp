import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'shared/navigation/app_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/profil/providers/profil_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:ml_pp_mvp/shared/logging/log_redactor.dart';

bool _hasInvalidHeaderChars(String v) => v.contains('…') || v.contains('\n') || v.contains('\r');

String _stripOuterQuotes(String v) {
  final s = v.trim();
  if (s.length >= 2) {
    final first = s[0];
    final last = s[s.length - 1];
    final isQuotePair = (first == '"' && last == '"') || (first == "'" && last == "'");
    if (isQuotePair) return s.substring(1, s.length - 1);
  }
  return s;
}

String _readEnv(String key) {
  // Note: String.fromEnvironment nécessite une constante de compilation
  // On utilise une approche conditionnelle pour chaque clé connue
  final fromDefine = key == 'SUPABASE_URL'
      ? const String.fromEnvironment('SUPABASE_URL')
      : (key == 'SUPABASE_ANON_KEY'
          ? const String.fromEnvironment('SUPABASE_ANON_KEY')
          : '');
  final raw = fromDefine.isNotEmpty ? fromDefine : (dotenv.env[key] ?? '');
  return _stripOuterQuotes(raw);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LogRedactor.install();
  // En PROD (Web), on n'utilise PAS dotenv. Les secrets doivent venir via --dart-define.
  // En local/dev, dotenv est autorisé.
  const isProd = bool.fromEnvironment('dart.vm.product');
  if (!isProd) {
    await dotenv.load(fileName: ".env");
  }

  // Initialiser le formatage des dates pour le package intl
  await initializeDateFormatting('fr', null);

  // Lecture et nettoyage des variables d'environnement
  final supabaseUrl = _readEnv('SUPABASE_URL');
  final supabaseAnonKey = _readEnv('SUPABASE_ANON_KEY');

  // Logs safe (sans contenu sensible)
  LogRedactor.safePrint('[ENV] SUPABASE_URL len=${supabaseUrl.length} ok=${supabaseUrl.isNotEmpty}');
  LogRedactor.safePrint('[ENV] SUPABASE_ANON_KEY len=${supabaseAnonKey.length} ok=${supabaseAnonKey.isNotEmpty}');

  // Validation AVANT Supabase.initialize
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'Supabase URL/KEY manquants (définis via --dart-define ou --env)',
    );
  }

  if (_hasInvalidHeaderChars(supabaseUrl) || _hasInvalidHeaderChars(supabaseAnonKey)) {
    throw StateError(
      'Supabase URL/KEY invalides: caractères interdits détectés (ellipsis ou newline). '
      'Re-copier la valeur originale sans troncature.',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    // ⚠️ CORRECTIF : S'assurer que profilAuthSyncProvider est lu au boot
    ref.watch(profilAuthSyncProvider);

    return MaterialApp.router(
      title: 'ML_PP MVP',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blueGrey,
        textTheme: GoogleFonts.notoSansTextTheme(),
      ),
    );
  }
}
