import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'shared/navigation/app_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'features/profil/providers/profil_provider.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialiser le formatage des dates pour le package intl
  await initializeDateFormatting('fr', null);

  final urlFromDefine = const String.fromEnvironment('SUPABASE_URL');
  final keyFromDefine = const String.fromEnvironment('SUPABASE_ANON_KEY');

  final supabaseUrl = urlFromDefine.isNotEmpty ? urlFromDefine : (dotenv.env['SUPABASE_URL'] ?? '');
  final supabaseAnonKey = keyFromDefine.isNotEmpty
      ? keyFromDefine
      : (dotenv.env['SUPABASE_ANON_KEY'] ?? '');

  assert(
    supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty,
    'Supabase URL/KEY manquants (définis via --dart-define ou .env)',
  );

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
