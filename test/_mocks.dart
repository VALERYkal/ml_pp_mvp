// test/_mocks.dart
import 'package:mockito/annotations.dart';
import 'package:supabase/supabase.dart'
    show SupabaseClient, AuthResponse, GoTrueClient, User, Session;

// Tes services à mocker utilisés dans les tests
import 'package:ml_pp_mvp/features/auth/data/auth_service.dart';
import 'package:ml_pp_mvp/features/profil/data/profil_service.dart';
import 'package:ml_pp_mvp/features/cours_route/data/cours_de_route_service.dart';

@GenerateMocks([
  // Supabase
  SupabaseClient,
  GoTrueClient,
  AuthResponse,
  User,
  Session,

  // Services app
  AuthService,
  ProfilService,
  CoursDeRouteService,
])

// ⚠️ INDISPENSABLE pour que mockito génère le fichier
part '_mocks.mocks.dart';
