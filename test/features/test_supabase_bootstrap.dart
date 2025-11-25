import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabaseForTests() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pour les tests, on Ã©vite l'initialisation complÃ¨te de Supabase
  // qui nÃ©cessite des plugins natifs non disponibles en test
  // On utilise une approche mockÃ©e ou on skip l'initialisation
  try {
    // VÃ©rifier si Supabase est dÃ©jÃ  initialisÃ©
    Supabase.instance.client;
  } catch (_) {
    // En mode test, on ne fait pas d'initialisation rÃ©elle
    // Les providers seront mockÃ©s dans les tests individuels
    // await Supabase.initialize(
    //   url: 'https://test.supabase.co',
    //   anonKey: 'test_key',
    //   debug: false,
    // );
  }
}

