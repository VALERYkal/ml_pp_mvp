import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/integrity_check.dart';

/// Repository pour public.system_alerts (source intégrité avec workflow ACK/RESOLVE).
class IntegrityRepository {
  final SupabaseClient client;

  IntegrityRepository(this.client);

  /// Récupère les alertes (limit 200).
  /// Tri: severity CRITICAL > WARN, puis last_detected_at DESC.
  Future<List<IntegrityCheck>> fetchAlerts({int limit = 200}) async {
    final response = await client
        .from('system_alerts')
        .select()
        .order('last_detected_at', ascending: false)
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

  /// ACK une alerte.
  Future<void> ackAlert(String id) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Utilisateur non connecté');

    await client.from('system_alerts').update({
      'status': 'ACK',
      'acknowledged_at': DateTime.now().toUtc().toIso8601String(),
      'acknowledged_by': uid,
    }).eq('id', id);
  }

  /// RESOLVE une alerte.
  Future<void> resolveAlert(String id) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) throw StateError('Utilisateur non connecté');

    await client.from('system_alerts').update({
      'status': 'RESOLVED',
      'resolved_at': DateTime.now().toUtc().toIso8601String(),
      'resolved_by': uid,
    }).eq('id', id);
  }
}
