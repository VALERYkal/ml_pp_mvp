import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'shared/navigation/app_router.dart';
import 'core/config/app_env.dart';
import 'features/profil/providers/profil_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser le formatage des dates pour le package intl
  await initializeDateFormatting('fr', null);

  // Charger la configuration de l'environnement
  final appEnv = await AppEnv.load();
  
  // Validation fail-fast: vérifier que l'URL correspond à l'ENV déclaré
  appEnv.validateOrThrow();

  // Initialiser Supabase
  await Supabase.initialize(
    url: appEnv.supabaseUrl,
    anonKey: appEnv.supabaseAnonKey,
  );

  runApp(
    ProviderScope(
      overrides: [
        appEnvSyncProvider.overrideWithValue(appEnv),
      ],
      child: MyApp(appEnv: appEnv),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final AppEnv appEnv;

  const MyApp({super.key, required this.appEnv});

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
