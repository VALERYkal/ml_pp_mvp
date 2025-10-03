import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initSupabaseForTests() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pour les tests, on évite l'initialisation complète de Supabase
  // qui nécessite des plugins natifs non disponibles en test
  // On utilise une approche mockée ou on skip l'initialisation
  try {
    // Vérifier si Supabase est déjà initialisé
    Supabase.instance.client;
  } catch (_) {
    // En mode test, on ne fait pas d'initialisation réelle
    // Les providers seront mockés dans les tests individuels
    // await Supabase.initialize(
    //   url: 'https://test.supabase.co',
    //   anonKey: 'test_key',
    //   debug: false,
    // );
  }
}
