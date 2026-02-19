import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/integrity_check.dart';

/// Repository read-only pour public.v_integrity_checks.
/// Aucune écriture DB.
class IntegrityRepository {
  final SupabaseClient client;

  IntegrityRepository(this.client);

  /// Récupère les checks d'intégrité (limit 200 par défaut).
  /// Tri côté Dart : severity CRITICAL > WARN, puis detected_at DESC.
  Future<List<IntegrityCheck>> fetchIntegrityChecks({int limit = 200}) async {
    final response = await client
        .from('v_integrity_checks')
        .select()
        .limit(limit);

    final rows = response as List<dynamic>;
    final list = rows
        .map((r) => IntegrityCheck.fromMap(
              Map<String, dynamic>.from(r as Map),
            ))
        .toList();

    list.sort((a, b) {
      final rankCompare = IntegrityCheck.severityRank(a.severity)
          .compareTo(IntegrityCheck.severityRank(b.severity));
      if (rankCompare != 0) return rankCompare;
      return b.detectedAt.compareTo(a.detectedAt);
    });

    return list;
  }
}
