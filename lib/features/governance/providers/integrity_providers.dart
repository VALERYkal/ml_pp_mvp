import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import '../../../shared/providers/supabase_client_provider.dart';
import '../data/integrity_repository.dart';
import '../domain/integrity_check.dart';

/// Provider du repository d'intégrité.
final integrityRepositoryProvider =
    riverpod.Provider<IntegrityRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return IntegrityRepository(client);
});

/// Liste des alertes (limit 200, tri CRITICAL > WARN > last_detected_at desc).
final integrityAlertsProvider =
    riverpod.FutureProvider.autoDispose<List<IntegrityCheck>>((ref) async {
  final repo = ref.watch(integrityRepositoryProvider);
  return repo.fetchAlerts(limit: 200);
});

/// Alias pour compatibilité.
final integrityChecksProvider = integrityAlertsProvider;

/// Comptages CRITICAL et WARN dérivés de integrityAlertsProvider.
final integrityCountsProvider =
    riverpod.Provider.autoDispose<({int critical, int warn})>((ref) {
  final async = ref.watch(integrityAlertsProvider);
  return async.when(
    data: (list) => (
      critical: list.where((c) => c.isCritical).length,
      warn: list.where((c) => c.isWarn).length,
    ),
    loading: () => (critical: 0, warn: 0),
    error: (_, __) => (critical: 0, warn: 0),
  );
});
