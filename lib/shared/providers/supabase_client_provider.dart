import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Source injectable du SupabaseClient.
/// PROD: Supabase.instance.client
/// TEST: override possible via ProviderScope overrides.
final supabaseClientProvider = riverpod.Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
