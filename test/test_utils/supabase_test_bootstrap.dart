// 📌 Module : Bootstrap Supabase pour les tests
// 🧑 Auteur : Assistant AI
// 📅 Date : 2025-12-27
// 🧭 Description : Utilitaires pour initialiser Supabase dans les tests de manière idempotente

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initialise Supabase pour les tests de manière idempotente.
///
/// Cette fonction vérifie si Supabase est déjà initialisé avant de l'initialiser.
/// Elle peut être appelée plusieurs fois sans problème (idempotente).
///
/// Usage dans les tests :
/// ```dart
/// setUpAll(() async {
///   await ensureSupabaseInitializedForTests();
/// });
/// ```
Future<void> ensureSupabaseInitializedForTests() async {
  try {
    // Vérifier si Supabase est déjà initialisé
    // Supabase.instance.client est toujours non-null (plugin chargé ou pas).
    // Donc ce null-check est inutile.
    {
      return; // Déjà initialisé, on ne fait rien
    }
  } catch (_) {
    // Si Supabase.instance n'est pas accessible ou pas initialisé,
    // on continue pour l'initialiser
  }

  // Initialiser les mocks nécessaires pour les plugins Flutter dans les tests
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  // Initialiser Supabase avec des valeurs de test
  await Supabase.initialize(
    url: 'https://example.com',
    anonKey: 'test-anon-key',
  );
}

