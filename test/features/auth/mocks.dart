// 📌 Module : Auth Tests - Mocks
// 🧑 Auteur : Valery Kalonga
// 📅 Date : 2025-01-27
// 🧭 Description : Mocks pour les tests d'authentification et de profil

import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ml_pp_mvp/core/services/auth_service.dart';
import 'package:ml_pp_mvp/features/profil/data/profil_service.dart';

// Génère les mocks avec mockito
@GenerateMocks([
  SupabaseClient,
  GoTrueClient,
  AuthResponse,
  User,
  Session,
  AuthState,
  PostgrestClient,
  PostgrestQueryBuilder,
  PostgrestFilterBuilder,
  PostgrestTransformBuilder,
  AuthService,
  ProfilService,
])
void main() {
  // Ce fichier sert uniquement à générer les mocks
  // Les tests sont dans les fichiers séparés
}
