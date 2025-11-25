// test/_mocks.dart
import 'package:mockito/annotations.dart';

// Types Supabase cÃ´tÃ© Flutter (auth & session)
import 'package:supabase_flutter/supabase_flutter.dart'
    show SupabaseClient, GoTrueClient, AuthResponse, User, Session;

// Query builder cÃ´tÃ© supabase (point d'entrÃ©e .from)
import 'package:supabase/supabase.dart' show SupabaseQueryBuilder;

// ChaÃ®ne Postgrest utilisÃ©e par les tests (select/eq/order/single)
import 'package:postgrest/postgrest.dart'
    show PostgrestQueryBuilder, PostgrestFilterBuilder, PostgrestTransformBuilder;

@GenerateMocks([
  // Clients & modÃ¨les d'auth
  SupabaseClient,
  GoTrueClient,
  AuthResponse,
  User,
  Session,

  // ChaÃ®ne de requÃªtes Supabase/Postgrest
  SupabaseQueryBuilder,
  PostgrestQueryBuilder,
  PostgrestFilterBuilder,
  PostgrestTransformBuilder,
])
void main() {}

