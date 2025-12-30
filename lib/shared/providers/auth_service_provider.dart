// lib/shared/providers/auth_service_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

import 'package:ml_pp_mvp/core/services/auth_service.dart';

/// Provider production : construit AuthService à partir du client Supabase global.
/// Override dans les tests si nécessaire.
final authServiceProvider = Provider<AuthService>((ref) {
  final client = Supabase.instance.client;
  return AuthService.withSupabase(client);
});

/// Provider family : permet d'injecter un SupabaseClient custom (tests / preview).
final authServiceByClientProvider =
    Provider.family<AuthService, SupabaseClient>((ref, client) {
      return AuthService.withSupabase(client);
    });
