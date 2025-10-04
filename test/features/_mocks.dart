// test/_mocks.dart
import 'package:mockito/annotations.dart';

// Types Supabase côté Flutter (auth & session)
import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, GoTrueClient, AuthResponse, User, Session;

// Query builder côté supabase (point d'entrée .from)
import 'package:supabase/supabase.dart' show SupabaseQueryBuilder;

// Chaîne Postgrest utilisée par les tests (select/eq/order/single)
import 'package:postgrest/postgrest.dart'
    show PostgrestQueryBuilder, PostgrestFilterBuilder, PostgrestTransformBuilder;

@GenerateMocks([
  // Clients & modèles d'auth
  SupabaseClient,
  GoTrueClient,
  AuthResponse,
  User,
  Session,

  // Chaîne de requêtes Supabase/Postgrest
  SupabaseQueryBuilder,
  PostgrestQueryBuilder,
  PostgrestFilterBuilder,
  PostgrestTransformBuilder,
])
void main() {}
