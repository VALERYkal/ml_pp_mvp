import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:postgrest/postgrest.dart';

@GenerateNiceMocks([
  MockSpec<SupabaseClient>(),
  MockSpec<PostgrestClient>(),
  MockSpec<PostgrestFilterBuilder>(),
])
void main() {}

